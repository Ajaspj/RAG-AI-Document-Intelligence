import logging
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, Tuple
from fastapi import HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.models.document import Document
from app.models.user import User
from app.services.storage_service import StorageService
from app.services.validation_service import ValidationService

logger = logging.getLogger(__name__)


class DocumentService:
    @classmethod
    async def upload_document(
        cls,
        db: Session,
        upload_file: UploadFile,
        current_user: User,
    ) -> Document:
        """Coordinate validation, streaming file persistence, and database record creation for an uploaded document."""
        # 1. Validate file extension, size header, and magic bytes
        original_filename, extension, mime_type = await ValidationService.validate_document(upload_file)

        # 2. Persist file to storage with chunked streaming and hashing
        server_filename, storage_path, file_size, file_hash = await StorageService.save_upload_file(
            upload_file=upload_file,
            extension=extension,
        )

        # 3. Create database record
        document_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)
        doc = Document(
            id=document_id,
            user_id=current_user.id,
            filename=server_filename,
            original_filename=original_filename,
            file_extension=extension,
            mime_type=mime_type,
            file_size=file_size,
            storage_path=storage_path,
            file_hash=file_hash,
            status="pending",
            error_message=None,
            created_at=now,
            updated_at=now,
        )

        try:
            db.add(doc)
            db.commit()
            db.refresh(doc)
            return doc
        except Exception as exc:
            db.rollback()
            # Clean up the persisted file from disk so no orphaned files remain
            StorageService.delete_file(storage_path)
            logger.error("Failed to record document metadata in database: %s", exc, exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to record document metadata in database.",
            )

    @classmethod
    def get_user_documents(
        cls,
        db: Session,
        user_id: str,
        skip: int = 0,
        limit: int = 50,
        search: Optional[str] = None,
        status_filter: Optional[str] = None,
    ) -> Tuple[List[Document], int]:
        """Retrieve paginated documents belonging to a user, with optional search and status filtering."""
        query = db.query(Document).filter(Document.user_id == user_id)

        if search:
            search_pattern = f"%{search.strip()}%"
            query = query.filter(Document.original_filename.ilike(search_pattern))

        if status_filter:
            query = query.filter(Document.status == status_filter.lower().strip())

        total_count = query.count()
        documents = (
            query.order_by(Document.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

        return documents, total_count

    @classmethod
    def get_user_document_by_id(
        cls,
        db: Session,
        document_id: str,
        user_id: str,
    ) -> Document:
        """Retrieve a specific document by ID, enforcing user ownership."""
        doc = (
            db.query(Document)
            .filter(Document.id == document_id, Document.user_id == user_id)
            .first()
        )
        if not doc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found or access denied.",
            )
        return doc

    @classmethod
    def delete_user_document(
        cls,
        db: Session,
        document_id: str,
        user_id: str,
    ) -> None:
        """Delete a document record from database and its associated physical file from disk."""
        doc = cls.get_user_document_by_id(db, document_id, user_id)
        storage_path = doc.storage_path

        # Delete database record first
        try:
            db.delete(doc)
            db.commit()
        except Exception as exc:
            db.rollback()
            logger.error("Failed to delete document %s: %s", document_id, exc, exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete document record.",
            )

        # Delete physical file from disk
        if storage_path:
            StorageService.delete_file(storage_path)

    @classmethod
    def get_document_file_path(
        cls,
        db: Session,
        document_id: str,
        user_id: str,
    ) -> Tuple[Path, Document]:
        """Verify document ownership and return the resolved Path to the physical file."""
        doc = cls.get_user_document_by_id(db, document_id, user_id)
        file_path = StorageService.get_file_path(doc.storage_path)
        return file_path, doc

