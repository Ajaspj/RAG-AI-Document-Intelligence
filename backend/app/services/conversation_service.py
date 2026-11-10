import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.conversation import Conversation, Message
from app.schemas.chat import (
    CitationItem,
    ConversationDetailResponse,
    ConversationResponse,
    MessageResponse,
    SendMessageResponse,
)
from app.schemas.search import RAGRetrievalRequest
from app.services.chat_generation_service import ChatGenerationService
from app.services.rag_service import RAGRetrievalService
from app.services.search_service import SearchService


class ConversationService:
    """Service orchestrating multi-turn grounded conversations, message persistence, and structured citation linking."""

    @classmethod
    def create_conversation(
        cls,
        db: Session,
        user_id: str,
        title: Optional[str] = None,
        document_ids: Optional[List[str]] = None,
    ) -> Conversation:
        """Create a new user conversation thread with optional scoped document IDs."""
        scoped_docs = SearchService.verify_document_ownership(
            db=db,
            user_id=user_id,
            document_ids=document_ids,
        )

        conv_title = (title.strip() if title and title.strip() else "New Conversation")[:255]
        now = datetime.now(timezone.utc)

        conv = Conversation(
            id=str(uuid.uuid4()),
            user_id=user_id,
            title=conv_title,
            document_ids=scoped_docs or [],
            created_at=now,
            updated_at=now,
        )

        db.add(conv)
        db.commit()
        db.refresh(conv)
        return conv

    @classmethod
    def get_user_conversations(
        cls,
        db: Session,
        user_id: str,
        skip: int = 0,
        limit: int = 20,
    ) -> Tuple[List[ConversationResponse], int]:
        """List paginated conversations for a user, ordered by most recent activity."""
        query = db.query(Conversation).filter(Conversation.user_id == user_id)
        total = query.count()

        convs = (
            query.order_by(Conversation.updated_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

        results: List[ConversationResponse] = []
        for c in convs:
            msg_count = len(c.messages)
            latest = c.messages[-1] if c.messages else None
            latest_dto = (
                MessageResponse(
                    id=latest.id,
                    conversation_id=latest.conversation_id,
                    role=latest.role,
                    content=latest.content,
                    citations=latest.citations or [],
                    retrieval_metadata=latest.retrieval_metadata or {},
                    token_usage=latest.token_usage or {},
                    created_at=latest.created_at,
                )
                if latest
                else None
            )

            results.append(
                ConversationResponse(
                    id=c.id,
                    user_id=c.user_id,
                    title=c.title,
                    document_ids=c.document_ids or [],
                    created_at=c.created_at,
                    updated_at=c.updated_at,
                    message_count=msg_count,
                    latest_message=latest_dto,
                )
            )

        return results, total

    @classmethod
    def get_conversation_detail(
        cls,
        db: Session,
        conversation_id: str,
        user_id: str,
    ) -> ConversationDetailResponse:
        """Retrieve full conversation details with complete sequential message history."""
        conv = (
            db.query(Conversation)
            .filter(Conversation.id == conversation_id, Conversation.user_id == user_id)
            .first()
        )
        if not conv:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found or access denied.",
            )

        messages_dto: List[MessageResponse] = [
            MessageResponse(
                id=m.id,
                conversation_id=m.conversation_id,
                role=m.role,
                content=m.content,
                citations=m.citations or [],
                retrieval_metadata=m.retrieval_metadata or {},
                token_usage=m.token_usage or {},
                created_at=m.created_at,
            )
            for m in conv.messages
        ]

        latest = messages_dto[-1] if messages_dto else None

        return ConversationDetailResponse(
            id=conv.id,
            user_id=conv.user_id,
            title=conv.title,
            document_ids=conv.document_ids or [],
            created_at=conv.created_at,
            updated_at=conv.updated_at,
            message_count=len(messages_dto),
            latest_message=latest,
            messages=messages_dto,
        )

    @classmethod
    def delete_conversation(
        cls,
        db: Session,
        conversation_id: str,
        user_id: str,
    ) -> None:
        """Delete a conversation and its messages cascade."""
        conv = (
            db.query(Conversation)
            .filter(Conversation.id == conversation_id, Conversation.user_id == user_id)
            .first()
        )
        if not conv:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found or access denied.",
            )

        db.delete(conv)
        db.commit()

    @classmethod
    def send_message(
        cls,
        db: Session,
        user_id: str,
        conversation_id: str,
        content: str,
        document_ids: Optional[List[str]] = None,
    ) -> SendMessageResponse:
        """Post a user message, retrieve grounded document context, call Gemini, and persist the grounded response."""
        clean_content = content.strip()
        if not clean_content:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Message content cannot be blank.",
            )

        # 1. Verify conversation access
        conv = (
            db.query(Conversation)
            .filter(Conversation.id == conversation_id, Conversation.user_id == user_id)
            .first()
        )
        if not conv:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Conversation not found or access denied.",
            )

        # 2. Persist user message
        now = datetime.now(timezone.utc)
        user_msg = Message(
            id=str(uuid.uuid4()),
            conversation_id=conversation_id,
            user_id=user_id,
            role="user",
            content=clean_content,
            citations=[],
            retrieval_metadata={},
            token_usage={},
            created_at=now,
        )
        db.add(user_msg)
        db.commit()
        db.refresh(user_msg)

        # 3. Determine effective document scoping
        effective_doc_ids = document_ids or conv.document_ids or None
        if effective_doc_ids:
            effective_doc_ids = SearchService.verify_document_ownership(
                db=db,
                user_id=user_id,
                document_ids=effective_doc_ids,
            )

        # 4. RAG Retrieval via RAGRetrievalService
        rag_request = RAGRetrievalRequest(
            query=clean_content,
            document_ids=effective_doc_ids,
            top_k=settings.CHAT_DEFAULT_TOP_K,
            context_token_budget=settings.RAG_CONTEXT_TOKEN_BUDGET,
        )
        rag_response = RAGRetrievalService.retrieve_context(
            db=db,
            user_id=user_id,
            request=rag_request,
        )

        # 5. Fetch recent conversation history for conversational context (up to 6 recent turns)
        prior_messages = (
            db.query(Message)
            .filter(Message.conversation_id == conversation_id, Message.id != user_msg.id)
            .order_by(Message.created_at.desc())
            .limit(6)
            .all()
        )
        formatted_history = [
            {"role": m.role, "content": m.content}
            for m in reversed(prior_messages)
        ]

        # 6. Generate grounded response with Gemini
        try:
            gen_result = ChatGenerationService.generate_grounded_response(
                user_query=clean_content,
                context_chunks=rag_response.context_chunks,
                history=formatted_history,
            )
        except Exception as exc:
            # Note: User message is preserved, but we do not store a broken assistant message
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"AI generation failed: {str(exc)}",
            )

        # 7. Construct structured citations from actual retrieved chunks
        citations_data: List[Dict[str, Any]] = []
        for chunk in rag_response.context_chunks:
            # 200-char excerpt for supporting evidence
            snippet = chunk.content[:240].strip()
            if len(chunk.content) > 240:
                snippet += "..."

            citations_data.append({
                "citation_id": str(uuid.uuid4()),
                "document_id": chunk.document_id,
                "document_name": chunk.document_name,
                "chunk_id": chunk.chunk_id,
                "chunk_index": chunk.chunk_index,
                "page_number": chunk.page_number,
                "excerpt": snippet,
                "similarity_score": chunk.similarity_score,
            })

        # 8. Persist assistant message
        assistant_now = datetime.now(timezone.utc)
        retrieval_meta = {
            "retrieved_chunk_count": rag_response.total_chunks,
            "estimated_context_tokens": rag_response.estimated_tokens,
            "document_count": len(rag_response.sources),
        }

        assistant_msg = Message(
            id=str(uuid.uuid4()),
            conversation_id=conversation_id,
            user_id=user_id,
            role="assistant",
            content=gen_result["answer"],
            citations=citations_data,
            retrieval_metadata=retrieval_meta,
            token_usage=gen_result.get("token_usage", {}),
            created_at=assistant_now,
        )
        db.add(assistant_msg)

        # 9. Update conversation timestamp and title if initial
        if conv.title == "New Conversation":
            # Auto-generate title from first 6 words of question
            words = clean_content.split()
            auto_title = " ".join(words[:6])
            if len(words) > 6:
                auto_title += "..."
            conv.title = auto_title[:255]

        conv.updated_at = assistant_now
        db.commit()
        db.refresh(assistant_msg)
        db.refresh(conv)

        return SendMessageResponse(
            conversation_id=conversation_id,
            user_message=MessageResponse(
                id=user_msg.id,
                conversation_id=user_msg.conversation_id,
                role=user_msg.role,
                content=user_msg.content,
                citations=[],
                retrieval_metadata={},
                token_usage={},
                created_at=user_msg.created_at,
            ),
            assistant_message=MessageResponse(
                id=assistant_msg.id,
                conversation_id=assistant_msg.conversation_id,
                role=assistant_msg.role,
                content=assistant_msg.content,
                citations=[CitationItem(**c) for c in citations_data],
                retrieval_metadata=retrieval_meta,
                token_usage=gen_result.get("token_usage", {}),
                created_at=assistant_msg.created_at,
            ),
        )

    @classmethod
    def quick_chat(
        cls,
        db: Session,
        user_id: str,
        content: str,
        title: Optional[str] = None,
        document_ids: Optional[List[str]] = None,
    ) -> SendMessageResponse:
        """Create a new conversation and post the initial message in a single round-trip."""
        conv = cls.create_conversation(
            db=db,
            user_id=user_id,
            title=title,
            document_ids=document_ids,
        )
        return cls.send_message(
            db=db,
            user_id=user_id,
            conversation_id=conv.id,
            content=content,
            document_ids=document_ids,
        )

