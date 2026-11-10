from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field, model_validator


class DocumentBase(BaseModel):
    filename: str
    original_filename: str
    file_extension: str
    file_size: int
    mime_type: str
    status: str = "pending"
    processing_progress: float = 0.0
    error_message: Optional[str] = None


class DocumentCreate(DocumentBase):
    pass


class DocumentResponse(BaseModel):
    id: str
    user_id: str
    filename: str
    original_filename: str
    file_extension: str
    file_size: int
    mime_type: str
    status: str = "pending"
    processing_progress: float = 0.0
    error_message: Optional[str] = None
    file_hash: Optional[str] = None
    created_at: datetime
    uploaded_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="before")
    @classmethod
    def populate_uploaded_at(cls, data):
        # Support ORM objects as well as dicts
        if hasattr(data, "created_at") and not hasattr(data, "uploaded_at"):
            # When passed from SQLAlchemy ORM
            return {
                "id": str(data.id),
                "user_id": str(data.user_id),
                "filename": data.filename,
                "original_filename": data.original_filename,
                "file_extension": data.file_extension,
                "file_size": data.file_size,
                "mime_type": data.mime_type,
                "status": data.status,
                "processing_progress": 1.0 if data.status == "completed" else (0.5 if data.status == "processing" else 0.0),
                "error_message": data.error_message,
                "file_hash": data.file_hash,
                "created_at": data.created_at,
                "uploaded_at": data.created_at,
                "updated_at": data.updated_at,
            }
        elif isinstance(data, dict):
            if "uploaded_at" not in data and "created_at" in data:
                data["uploaded_at"] = data["created_at"]
            elif "created_at" not in data and "uploaded_at" in data:
                data["created_at"] = data["uploaded_at"]
        return data


class DocumentListResponse(BaseModel):
    items: List[DocumentResponse]
    total: int


class DocumentDeleteResponse(BaseModel):
    id: str
    message: str
    success: bool = True


class DocumentStatusResponse(BaseModel):
    id: str
    status: str
    error_message: Optional[str] = None
    chunk_count: int = 0
    updated_at: Optional[datetime] = None


class DocumentReprocessResponse(BaseModel):
    id: str
    status: str
    message: str
