import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Index,
    JSON,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from app.db.session import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class Conversation(Base):
    """SQLAlchemy model representing an AI chat conversation session owned by a user."""

    __tablename__ = "conversations"

    id = Column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        index=True,
        doc="Unique UUID primary key for the conversation",
    )
    user_id = Column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        doc="Owner user ID",
    )
    title = Column(
        String(255),
        nullable=False,
        default="New Conversation",
        doc="Human-readable conversation title or auto-generated query preview",
    )
    document_ids = Column(
        JSON().with_variant(JSONB, "postgresql"),
        nullable=True,
        default=list,
        doc="Optional list of document UUIDs to scope this conversation to",
    )
    is_archived = Column(
        Boolean,
        default=False,
        nullable=False,
        index=True,
        doc="Whether this conversation is archived and hidden from default active list",
    )
    archived_at = Column(
        DateTime(timezone=True),
        nullable=True,
        doc="Timestamp when conversation was archived",
    )
    created_at = Column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
        index=True,
        doc="Timestamp when conversation was created",
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=utc_now,
        onupdate=utc_now,
        nullable=False,
        index=True,
        doc="Timestamp of the latest message or interaction",
    )

    # Relationships
    user = relationship("User", back_populates="conversations")
    messages = relationship(
        "Message",
        back_populates="conversation",
        cascade="all, delete-orphan",
        order_by="Message.created_at.asc()",
    )

    __table_args__ = (
        Index("idx_conversations_user_updated", "user_id", "updated_at"),
        Index("idx_conversations_user_archived_updated", "user_id", "is_archived", "updated_at"),
    )


class Message(Base):
    """SQLAlchemy model representing an individual user or assistant message with RAG citations."""

    __tablename__ = "messages"

    id = Column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
        index=True,
        doc="Unique UUID primary key for the message",
    )
    conversation_id = Column(
        String(36),
        ForeignKey("conversations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        doc="Parent conversation ID",
    )
    user_id = Column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        doc="Owner user ID for partition pruning and access isolation",
    )
    role = Column(
        String(20),
        nullable=False,
        doc="Message author role: 'user' or 'assistant'",
    )
    content = Column(
        Text,
        nullable=False,
        doc="Message text content",
    )
    citations = Column(
        JSON().with_variant(JSONB, "postgresql"),
        nullable=True,
        default=list,
        doc="Structured array of citation metadata for assistant grounding",
    )
    retrieval_metadata = Column(
        JSON().with_variant(JSONB, "postgresql"),
        nullable=True,
        default=dict,
        doc="Retrieval diagnostics (top_k, search time, candidate count)",
    )
    token_usage = Column(
        JSON().with_variant(JSONB, "postgresql"),
        nullable=True,
        default=dict,
        doc="Token usage statistics (prompt_tokens, completion_tokens, total_tokens)",
    )
    created_at = Column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
        index=True,
        doc="Timestamp when message was generated",
    )

    # Relationships
    conversation = relationship("Conversation", back_populates="messages")
    user = relationship("User")

    __table_args__ = (
        Index("idx_messages_conversation_created", "conversation_id", "created_at"),
        Index("idx_messages_user_created", "user_id", "created_at"),
    )

