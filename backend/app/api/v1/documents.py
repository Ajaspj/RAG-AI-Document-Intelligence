from typing import List, Optional
from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.document import (
    DocumentDeleteResponse,
    DocumentResponse,
)
from app.services.document_service import DocumentService

router = APIRouter(prefix="/documents", tags=["Documents"])


@router.get("", response_model=List[DocumentResponse])
def get_documents(
    skip: int = Query(0, ge=0, description="Number of documents to skip"),
    limit: int = Query(50, ge=1, le=100, description="Max documents to return"),
    search: Optional[str] = Query(None, description="Search term for original filename"),
    status: Optional[str] = Query(None, description="Filter by status (pending, completed, failed, etc.)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve all uploaded documents for the authenticated user with optional search and status filtering."""
    docs, _ = DocumentService.get_user_documents(
        db=db,
        user_id=current_user.id,
        skip=skip,
        limit=limit,
        search=search,
        status_filter=status,
    )
    return docs


@router.post("/upload", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
async def upload_document(
    file: UploadFile = File(..., description="Document file to upload (PDF, DOCX, TXT up to 20MB)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Upload a document (PDF, DOCX, TXT) with validation, chunked streaming storage, and database persistence."""
    doc = await DocumentService.upload_document(
        db=db,
        upload_file=file,
        current_user=current_user,
    )
    return doc


@router.get("/{document_id}", response_model=DocumentResponse)
def get_document_details(
    document_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve metadata for a specific document owned by the authenticated user."""
    doc = DocumentService.get_user_document_by_id(
        db=db,
        document_id=document_id,
        user_id=current_user.id,
    )
    return doc


@router.delete("/{document_id}", response_model=DocumentDeleteResponse)
def delete_document(
    document_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a document record from the database and remove its physical file from disk."""
    DocumentService.delete_user_document(
        db=db,
        document_id=document_id,
        user_id=current_user.id,
    )
    return DocumentDeleteResponse(
        id=document_id,
        message="Document deleted successfully.",
        success=True,
    )


@router.get("/{document_id}/download")
def download_document(
    document_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Download the raw stored document file for the authenticated owner."""
    file_path, doc = DocumentService.get_document_file_path(
        db=db,
        document_id=document_id,
        user_id=current_user.id,
    )
    return FileResponse(
        path=str(file_path),
        filename=doc.original_filename,
        media_type=doc.mime_type,
    )
