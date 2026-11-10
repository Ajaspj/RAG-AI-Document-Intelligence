from typing import List, Optional
from fastapi import APIRouter, BackgroundTasks, Depends, File, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_user
from app.db.session import get_db
from app.models.chunk import DocumentChunk
from app.models.user import User
from app.schemas.document import (
    DocumentDeleteResponse,
    DocumentReprocessResponse,
    DocumentResponse,
    DocumentStatusResponse,
)
from app.services.document_service import DocumentService
from app.services.processing_service import ProcessingService

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
    background_tasks: BackgroundTasks,
    file: UploadFile = File(..., description="Document file to upload (PDF, DOCX, TXT up to 20MB)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Upload a document with streaming validation and storage, then automatically trigger background text extraction, chunking, and Gemini embedding generation."""
    # 1. Validate file format and persist safely to storage and DB
    doc = await DocumentService.upload_document(
        db=db,
        upload_file=file,
        current_user=current_user,
    )

    # 2. Schedule asynchronous background ingestion (extraction -> chunking -> gemini embedding -> pgvector)
    background_tasks.add_task(
        ProcessingService.process_document_background,
        document_id=doc.id,
        user_id=current_user.id,
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


@router.get("/{document_id}/status", response_model=DocumentStatusResponse)
def get_document_status(
    document_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Query live processing status, chunk count, and failure details for an uploaded document."""
    doc = DocumentService.get_user_document_by_id(
        db=db,
        document_id=document_id,
        user_id=current_user.id,
    )
    chunk_count = (
        db.query(DocumentChunk)
        .filter(DocumentChunk.document_id == document_id)
        .count()
    )
    return DocumentStatusResponse(
        id=doc.id,
        status=doc.status,
        error_message=doc.error_message,
        chunk_count=chunk_count,
        updated_at=doc.updated_at,
    )


@router.post("/{document_id}/process", response_model=DocumentReprocessResponse)
def reprocess_document(
    document_id: str,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Trigger or retry background ingestion (text extraction, chunking, and embedding generation) for an existing document."""
    doc = DocumentService.get_user_document_by_id(
        db=db,
        document_id=document_id,
        user_id=current_user.id,
    )
    background_tasks.add_task(
        ProcessingService.process_document_background,
        document_id=doc.id,
        user_id=current_user.id,
    )
    return DocumentReprocessResponse(
        id=doc.id,
        status="processing",
        message="Document ingestion re-processing scheduled in background.",
    )


@router.delete("/{document_id}", response_model=DocumentDeleteResponse)
def delete_document(
    document_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a document record, its physical file from disk, and all associated vector chunks."""
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
