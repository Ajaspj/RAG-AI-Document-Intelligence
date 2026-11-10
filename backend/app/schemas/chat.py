from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class CitationItem(BaseModel):
    """Structured source citation linked to an authenticated document chunk."""

    citation_id: str
    document_id: str
    document_name: str
    chunk_id: str
    chunk_index: int
    page_number: Optional[int] = None
    excerpt: str
    similarity_score: Optional[float] = None


class MessageResponse(BaseModel):
    """Message schema representing a user query or grounded assistant response."""

    id: str
    conversation_id: str
    role: str
    content: str
    citations: List[CitationItem] = Field(default_factory=list)
    retrieval_metadata: Dict[str, Any] = Field(default_factory=dict)
    token_usage: Dict[str, Any] = Field(default_factory=dict)
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ConversationResponse(BaseModel):
    """Conversation summary schema for list views."""

    id: str
    user_id: str
    title: str
    document_ids: Optional[List[str]] = Field(default_factory=list)
    is_archived: bool = False
    archived_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    message_count: int = 0
    latest_message: Optional[MessageResponse] = None

    model_config = ConfigDict(from_attributes=True)


class ConversationDetailResponse(ConversationResponse):
    """Full conversation history including sequential messages and pagination metadata."""

    messages: List[MessageResponse] = Field(default_factory=list)
    total_messages: int = 0
    has_more: bool = False
    next_cursor: Optional[str] = None


class CreateConversationRequest(BaseModel):
    """Payload to create a new conversation thread."""

    title: Optional[str] = Field(None, max_length=255, description="Optional title")
    document_ids: Optional[List[str]] = Field(None, description="Optional list of document IDs to scope")


class UpdateConversationRequest(BaseModel):
    """Payload to update/rename or archive/restore a conversation."""

    title: Optional[str] = Field(None, min_length=1, max_length=255, description="Updated conversation title")
    is_archived: Optional[bool] = Field(None, description="Set true to archive, false to restore")


class SendMessageRequest(BaseModel):
    """Payload to post a new question in a conversation."""

    content: str = Field(..., min_length=1, max_length=4000, description="User prompt/question")
    document_ids: Optional[List[str]] = Field(None, description="Optional override of scoped document IDs")


class SendMessageResponse(BaseModel):
    """Response containing both the stored user message and generated assistant response."""

    conversation_id: str
    user_message: MessageResponse
    assistant_message: MessageResponse


class QuickChatRequest(BaseModel):
    """Single-call creation of a conversation with an immediate first message."""

    content: str = Field(..., min_length=1, max_length=4000, description="Initial question")
    title: Optional[str] = Field(None, max_length=255, description="Optional title")
    document_ids: Optional[List[str]] = Field(None, description="Optional document IDs to scope")


class ConversationListResponse(BaseModel):
    items: List[ConversationResponse]
    total: int


class MessageListResponse(BaseModel):
    """Paginated collection of conversation messages."""

    items: List[MessageResponse]
    total: int
    has_more: bool = False
    next_cursor: Optional[str] = None


class ConversationActionResponse(BaseModel):
    id: str
    message: str
    success: bool = True
