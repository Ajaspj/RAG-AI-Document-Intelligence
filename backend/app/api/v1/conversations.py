from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.chat import (
    ConversationDetailResponse,
    ConversationListResponse,
    ConversationResponse,
    CreateConversationRequest,
    QuickChatRequest,
    SendMessageRequest,
    SendMessageResponse,
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
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve paginated conversations belonging to the authenticated user, ordered by most recent activity."""
    items, total = ConversationService.get_user_conversations(
        db=db,
        user_id=current_user.id,
        skip=skip,
        limit=limit,
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
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve full chronological conversation message history, including source citations."""
    return ConversationService.get_conversation_detail(
        db=db,
        conversation_id=conversation_id,
        user_id=current_user.id,
    )


@router.delete(
    "/{conversation_id}",
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
    return {
        "id": conversation_id,
        "message": "Conversation deleted successfully.",
        "success": True,
    }


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

