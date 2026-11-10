from collections import defaultdict
from typing import Any, Dict, List, Optional, Set
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.schemas.search import (
    RAGContextChunk,
    RAGRetrievalRequest,
    RAGRetrievalResponse,
    RAGSourceReference,
)
from app.services.chunking_service import ChunkingService
from app.services.embedding_service import EmbeddingService
from app.services.search_service import SearchService
from app.services.vector_service import VectorService


class RAGRetrievalService:
    """Service that retrieves and token-budgets grounded document context for RAG generation."""

    @classmethod
    def retrieve_context(
        cls,
        db: Session,
        user_id: str,
        request: RAGRetrievalRequest,
    ) -> RAGRetrievalResponse:
        """Retrieve most relevant chunks for a question, packing them strictly within the configured context token budget.

        Workflow:
        1. Validate query and token budget parameters.
        2. Verify document ownership if document_ids are supplied.
        3. Generate normalized query embedding via gemini-embedding-001 (RETRIEVAL_QUERY).
        4. Retrieve top_k candidates via pgvector cosine distance.
        5. Greedily pack chunks into context budget in relevance order.
        6. Aggregate source citations (pages and chunk indices per document).
        """
        clean_query = request.query.strip()
        if not clean_query:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Query cannot be empty or whitespace.",
            )

        if len(clean_query) > settings.MAX_QUERY_LENGTH_CHARS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Query exceeds maximum character length of {settings.MAX_QUERY_LENGTH_CHARS}.",
            )

        # Enforce bounds on top_k
        top_k = min(
            request.top_k or settings.RAG_DEFAULT_TOP_K,
            settings.RAG_MAX_TOP_K,
        )

        # Context token budget
        token_budget = request.context_token_budget or settings.RAG_CONTEXT_TOKEN_BUDGET

        # Verify document access
        scoped_doc_ids = SearchService.verify_document_ownership(
            db=db,
            user_id=user_id,
            document_ids=request.document_ids,
        )

        # Generate query vector
        try:
            query_vector = EmbeddingService.generate_query_embedding(clean_query)
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Failed to generate query embedding: {str(exc)}",
            )

        # Fetch candidate chunks ordered by cosine similarity
        raw_candidates = VectorService.search_similar_chunks(
            db=db,
            user_id=user_id,
            query_embedding=query_vector,
            top_k=top_k,
            document_ids=scoped_doc_ids,
            min_similarity=settings.SEMANTIC_SEARCH_MIN_SIMILARITY,
        )

        # Pack chunks greedily into token budget
        selected_chunks: List[RAGContextChunk] = []
        accumulated_tokens = 0
        seen_chunks: Set[str] = set()

        # Source aggregation structure: doc_id -> {"name": doc_name, "pages": set(), "chunks": set()}
        sources_map: Dict[str, Dict[str, Any]] = defaultdict(
            lambda: {"name": "", "pages": set(), "chunks": set()}
        )

        for chunk, doc_name, similarity, _ in raw_candidates:
            if chunk.id in seen_chunks:
                continue

            # Determine token count (use stored token_count or compute estimate)
            token_count = (
                chunk.token_count
                if chunk.token_count and chunk.token_count > 0
                else ChunkingService.estimate_token_count(chunk.content)
            )

            # Check token budget
            if accumulated_tokens + token_count > token_budget and selected_chunks:
                # Context budget reached
                break

            seen_chunks.add(chunk.id)
            accumulated_tokens += token_count

            # Track sources
            sources_map[chunk.document_id]["name"] = doc_name
            if chunk.page_number:
                sources_map[chunk.document_id]["pages"].add(chunk.page_number)
            sources_map[chunk.document_id]["chunks"].add(chunk.chunk_index)

            selected_chunks.append(
                RAGContextChunk(
                    chunk_id=chunk.id,
                    document_id=chunk.document_id,
                    document_name=doc_name,
                    chunk_index=chunk.chunk_index,
                    content=chunk.content,
                    page_number=chunk.page_number,
                    similarity_score=round(similarity, 4),
                    estimated_tokens=token_count,
                    metadata=chunk.metadata,
                )
            )

        # Build consolidated source reference list
        source_references: List[RAGSourceReference] = []
        for doc_id, data in sources_map.items():
            source_references.append(
                RAGSourceReference(
                    document_id=doc_id,
                    document_name=data["name"],
                    page_numbers=sorted(list(data["pages"])),
                    chunk_indices=sorted(list(data["chunks"])),
                )
            )

        return RAGRetrievalResponse(
            query=clean_query,
            total_chunks=len(selected_chunks),
            estimated_tokens=accumulated_tokens,
            context_chunks=selected_chunks,
            sources=source_references,
        )
