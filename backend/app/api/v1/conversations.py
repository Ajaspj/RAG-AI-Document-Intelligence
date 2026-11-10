from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.chat import (
    ConversationActionResponse,
    ConversationDetailResponse,
    ConversationListResponse,
    ConversationResponse,
    CreateConversationRequest,
    MessageListResponse,
    QuickChatRequest,
    SendMessageRequest,
    SendMessageResponse,
    UpdateConversationRequest,
)
from app.services.conversation_service import ConversationService

router = APIRouter(prefix="/conversations", tags=["Conversations & Grounded Chat"])


@router.post(
    "",
    response_model=ConversationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new conversation thread",
)
def create_conversation(
    request: CreateConversationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create an empty conversation thread with optional document associations."""
    conv = ConversationService.create_conversation(
        db=db,
        user_id=current_user.id,
        title=request.title,
        document_ids=request.document_ids,
    )
    return ConversationResponse(
        id=conv.id,
        user_id=conv.user_id,
        title=conv.title,
        document_ids=conv.document_ids or [],
        is_archived=conv.is_archived,
        archived_at=conv.archived_at,
        created_at=conv.created_at,
        updated_at=conv.updated_at,
        message_count=0,
        latest_message=None,
    )


@router.get(
    "",
    response_model=ConversationListResponse,
    status_code=status.HTTP_200_OK,
    summary="List authenticated user's conversations",
)
def list_conversations(
    skip: int = Query(0, ge=0, description="Number of conversations to skip"),
    limit: int = Query(20, ge=1, le=100, description="Max conversations to return"),
    search: Optional[str] = Query(None, description="Filter conversations by title substring"),
    is_archived: bool = Query(False, description="Filter active (False) or archived (True) threads"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve paginated conversations belonging to the authenticated user, with optional search and archive filtering."""
    items, total = ConversationService.get_user_conversations(
        db=db,
        user_id=current_user.id,
        skip=skip,
        limit=limit,
        search=search,
        is_archived=is_archived,
    )
    return ConversationListResponse(items=items, total=total)


@router.get(
    "/{conversation_id}",
    response_model=ConversationDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Get conversation history",
)
def get_conversation_history(
    conversation_id: str,
    limit: int = Query(50, ge=1, le=100, description="Max messages to return"),
    before: Optional[str] = Query(None, description="Cursor: Message ID to fetch older messages before"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve chronological conversation message history with pagination support, including citations."""
    return ConversationService.get_conversation_detail(
        db=db,
        conversation_id=conversation_id,
        user_id=current_user.id,
        limit=limit,
        before=before,
    )


@router.patch(
    "/{conversation_id}",
    response_model=ConversationResponse,
    status_code=status.HTTP_200_OK,
    summary="Update conversation title or archive status",
)
def update_conversation(
    conversation_id: str,
    request: UpdateConversationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Rename a conversation thread and/or change its archived status."""
    return ConversationService.update_conversation(
        db=db,
        user_id=current_user.id,
        conversation_id=conversation_id,
        title=request.title,
        is_archived=request.is_archived,
    )


@router.post(
    "/{conversation_id}/archive",
    response_model=ConversationActionResponse,
    status_code=status.HTTP_200_OK,
    summary="Archive conversation",
)
def archive_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark a conversation thread as archived."""
    ConversationService.update_conversation(
        db=db,
        user_id=current_user.id,
        conversation_id=conversation_id,
        is_archived=True,
    )
    return ConversationActionResponse(
        id=conversation_id,
        message="Conversation archived successfully.",
        success=True,
    )


@router.post(
    "/{conversation_id}/restore",
    response_model=ConversationActionResponse,
    status_code=status.HTTP_200_OK,
    summary="Restore archived conversation",
)
def restore_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Restore an archived conversation back to active status."""
    ConversationService.update_conversation(
        db=db,
        user_id=current_user.id,
        conversation_id=conversation_id,
        is_archived=False,
    )
    return ConversationActionResponse(
        id=conversation_id,
        message="Conversation restored successfully.",
        success=True,
    )


@router.get(
    "/{conversation_id}/messages",
    response_model=MessageListResponse,
    status_code=status.HTTP_200_OK,
    summary="Get paginated older messages",
)
def get_conversation_messages(
    conversation_id: str,
    limit: int = Query(30, ge=1, le=100, description="Max messages to fetch"),
    before: Optional[str] = Query(None, description="Cursor: Message ID to fetch older messages before"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Fetch older messages in chronological order for backwards scrollback pagination."""
    return ConversationService.get_conversation_messages(
        db=db,
        conversation_id=conversation_id,
        user_id=current_user.id,
        limit=limit,
        before=before,
    )


@router.delete(
    "/{conversation_id}",
    response_model=ConversationActionResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete conversation",
)
def delete_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a conversation and all its associated messages."""
    ConversationService.delete_conversation(
        db=db,
        conversation_id=conversation_id,
        user_id=current_user.id,
    )
    return ConversationActionResponse(
        id=conversation_id,
        message="Conversation deleted successfully.",
        success=True,
    )


@router.post(
    "/{conversation_id}/messages",
    response_model=SendMessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Send a message to a conversation",
)
def send_message(
    conversation_id: str,
    request: SendMessageRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Post a question in a conversation, retrieve grounded document context, call Gemini, and persist the grounded response with verifiable citations."""
    return ConversationService.send_message(
        db=db,
        user_id=current_user.id,
        conversation_id=conversation_id,
        content=request.content,
        document_ids=request.document_ids,
    )


@router.post(
    "/quick-chat",
    response_model=SendMessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create conversation and send first message",
)
def quick_chat(
    request: QuickChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Single-call convenience endpoint to create a conversation and receive the first grounded answer."""
    return ConversationService.quick_chat(
        db=db,
        user_id=current_user.id,
        content=request.content,
        title=request.title,
        document_ids=request.document_ids,
    )

