import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Optional

from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    JSON,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from app.core.config import settings
from app.db.session import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class DocumentChunk(Base):
    """SQLAlchemy model representing an extracted text chunk of a document, with vector embeddings for RAG retrieval."""

    __tablename__ = "document_chunks"

    id = Column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        index=True,
        doc="Unique UUID primary key for the chunk",
    )
    document_id = Column(
        String(36),
        ForeignKey("documents.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        doc="Foreign key reference to parent document",
    )
    user_id = Column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        doc="Foreign key reference to document owner (enables user-scoped retrieval & partition pruning)",
    )
    chunk_index = Column(
        Integer,
        nullable=False,
        doc="Sequential 0-based position of this chunk within the document",
    )
    content = Column(
        Text,
        nullable=False,
        doc="Extracted text content of the chunk",
    )
    token_count = Column(
        Integer,
        nullable=True,
        doc="Approximate or exact token count of the chunk content",
    )
    page_number = Column(
        Integer,
        nullable=True,
        doc="Source document page number, if applicable",
    )
    embedding = Column(
        Vector(settings.EMBEDDING_DIMENSION),
        nullable=True,
        doc=f"Dense vector embedding ({settings.EMBEDDING_DIMENSION} dimensions for {settings.EMBEDDING_MODEL})",
    )
    # Stored in column 'metadata' in PostgreSQL as JSONB, mapped to chunk_metadata
    chunk_metadata = Column(
        "metadata",
        JSON().with_variant(JSONB, "postgresql"),
        nullable=True,
        default=dict,
        doc="Flexible JSON metadata (e.g. section titles, headers, coordinates)",
    )
    created_at = Column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
        index=True,
        doc="UTC timestamp when chunk record was created",
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=utc_now,
        onupdate=utc_now,
        nullable=False,
        doc="UTC timestamp when chunk record was last updated",
    )

    # Relationships
    document = relationship("Document", back_populates="chunks")
    user = relationship("User", back_populates="chunks")

    __table_args__ = (
        # Ensure a document cannot have duplicate chunks at the same position
        UniqueConstraint("document_id", "chunk_index", name="uq_document_chunk_index"),
        # Compound indexes for fast filtered lookups
        Index("idx_chunks_document_index", "document_id", "chunk_index"),
        Index("idx_chunks_user_document", "user_id", "document_id"),
        Index("idx_chunks_user_created", "user_id", "created_at"),
        # HNSW vector cosine similarity index for lightning-fast approximate nearest neighbor queries
        Index(
            "idx_chunks_embedding_hnsw",
            "embedding",
            postgresql_using="hnsw",
            postgresql_with={
                "m": settings.HNSW_M,
                "ef_construction": settings.HNSW_EF_CONSTRUCTION,
            },
            postgresql_ops={"embedding": "vector_cosine_ops"},
        ),
    )
