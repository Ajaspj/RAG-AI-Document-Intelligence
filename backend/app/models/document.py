import uuid
from datetime import datetime, timezone
from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, Index, String, Text
from sqlalchemy.orm import relationship

from app.db.session import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class Document(Base):
    __tablename__ = "documents"

    id = Column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        index=True,
        doc="Unique UUID primary key for the document",
    )
    user_id = Column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        doc="Foreign key reference to document owner in users table",
    )
    filename = Column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
        doc="Generated safe server-side unique filename (UUID-based)",
    )
    original_filename = Column(
        String(255),
        nullable=False,
        doc="Original filename uploaded by the user",
    )
    file_extension = Column(
        String(10),
        nullable=False,
        index=True,
        doc="File extension (pdf, docx, txt)",
    )
    mime_type = Column(
        String(100),
        nullable=False,
        doc="MIME type detected and verified during upload",
    )
    file_size = Column(
        BigInteger,
        nullable=False,
        doc="Size of the file in bytes",
    )
    storage_path = Column(
        String(500),
        nullable=False,
        doc="Relative or absolute filesystem storage path",
    )
    file_hash = Column(
        String(64),
        nullable=True,
        index=True,
        doc="SHA-256 cryptographic checksum of file content",
    )
    status = Column(
        String(20),
        default="pending",
        nullable=False,
        index=True,
        doc="Lifecycle state: pending, uploading, processing, completed, failed",
    )
    error_message = Column(
        Text,
        nullable=True,
        doc="Error description if processing failed",
    )
    created_at = Column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
        index=True,
        doc="Timestamp when document record was created",
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=utc_now,
        onupdate=utc_now,
        nullable=False,
        doc="Timestamp when document record was last updated",
    )

    # Relationships
    owner = relationship("User", back_populates="documents")
    chunks = relationship("DocumentChunk", back_populates="document", cascade="all, delete-orphan", passive_deletes=True)

    __table_args__ = (
        Index("idx_documents_user_created", "user_id", "created_at"),
        Index("idx_documents_user_status", "user_id", "status"),
    )

