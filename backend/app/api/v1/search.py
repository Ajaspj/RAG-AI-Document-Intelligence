from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.search import (
    RAGRetrievalRequest,
    RAGRetrievalResponse,
    SemanticSearchRequest,
    SemanticSearchResponse,
)
from app.services.rag_service import RAGRetrievalService
from app.services.search_service import SearchService

router = APIRouter(prefix="/search", tags=["Search & RAG Retrieval"])


@router.post(
    "/semantic",
    response_model=SemanticSearchResponse,
    status_code=status.HTTP_200_OK,
    summary="Semantic Vector Search across Document Chunks",
)
def semantic_search(
    request: SemanticSearchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Perform cosine similarity vector search over the authenticated user's processed document chunks.

    Supports optional document scoping and similarity threshold filtering.
    """
    return SearchService.semantic_search(
        db=db,
        user_id=current_user.id,
        request=request,
    )


@router.post(
    "/retrieve",
    response_model=RAGRetrievalResponse,
    status_code=status.HTTP_200_OK,
    summary="Token-Budgeted RAG Context Retrieval",
)
def retrieve_rag_context(
    request: RAGRetrievalRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve grounded, token-budgeted context chunks and source citations for downstream LLM generation.

    Greedily selects the most relevant chunks strictly adhering to the configured context token ceiling.
    """
    return RAGRetrievalService.retrieve_context(
        db=db,
        user_id=current_user.id,
        request=request,
    )

