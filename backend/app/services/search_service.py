from typing import List, Optional, Set
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.document import Document
from app.schemas.search import (
    SemanticSearchRequest,
    SemanticSearchResponse,
    SemanticSearchResultItem,
)
from app.services.embedding_service import EmbeddingService
from app.services.vector_service import VectorService


class SearchService:
    """Service handling semantic similarity search across user document chunks using pgvector."""

    @classmethod
    def verify_document_ownership(
        cls,
        db: Session,
        user_id: str,
        document_ids: Optional[List[str]],
    ) -> Optional[List[str]]:
        """Verify that all provided document IDs exist and belong strictly to the authenticated user.

        Raises:
            HTTPException 404 or 403 if any document is not accessible by this user.
        """
        if not document_ids:
            return None

        # Clean and deduplicate IDs
        clean_ids = list(set(doc_id.strip() for doc_id in document_ids if doc_id.strip()))
        if not clean_ids:
            return None

        owned_docs = (
            db.query(Document.id)
            .filter(Document.id.in_(clean_ids), Document.user_id == user_id)
            .all()
        )
        owned_ids = {doc[0] for doc in owned_docs}

        # Check for any inaccessible document ID
        inaccessible = set(clean_ids) - owned_ids
        if inaccessible:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied or document not found for {len(inaccessible)} document(s).",
            )

        return clean_ids

    @classmethod
    def semantic_search(
        cls,
        db: Session,
        user_id: str,
        request: SemanticSearchRequest,
    ) -> SemanticSearchResponse:
        """Perform vector cosine similarity search across chunks owned by the authenticated user.

        Workflow:
        1. Sanitize & validate natural language query.
        2. Validate ownership of any scoped document_ids.
        3. Generate normalized 768-dim query embedding using gemini-embedding-001 (RETRIEVAL_QUERY).
        4. Execute pgvector <=> cosine distance query.
        5. Apply similarity cutoff, deduplicate, and rank results.
        """
        clean_query = request.query.strip()
        if not clean_query:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Search query cannot be empty or whitespace.",
            )

        if len(clean_query) > settings.MAX_QUERY_LENGTH_CHARS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Query length exceeds the maximum permitted limit of "
                    f"{settings.MAX_QUERY_LENGTH_CHARS} characters."
                ),
            )

        # Enforce bounds on limit
        limit = min(
            request.limit or settings.SEMANTIC_SEARCH_DEFAULT_LIMIT,
            settings.SEMANTIC_SEARCH_MAX_LIMIT,
        )

        # Effective similarity threshold
        threshold = (
            request.similarity_threshold
            if request.similarity_threshold is not None
            else settings.SEMANTIC_SEARCH_MIN_SIMILARITY
        )

        # Verify document access
        scoped_doc_ids = cls.verify_document_ownership(
            db=db,
            user_id=user_id,
            document_ids=request.document_ids,
        )

        # Generate query embedding
        try:
            query_vector = EmbeddingService.generate_query_embedding(clean_query)
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Failed to generate query embedding: {str(exc)}",
            )

        # Retrieve nearest chunks using pgvector cosine distance
        raw_results = VectorService.search_similar_chunks(
            db=db,
            user_id=user_id,
            query_embedding=query_vector,
            top_k=limit,
            document_ids=scoped_doc_ids,
            min_similarity=threshold,
        )

        # Deduplicate identical chunk content and construct response
        items: List[SemanticSearchResultItem] = []
        seen_contents: Set[str] = set()

        for chunk, doc_name, similarity, distance in raw_results:
            content_snippet = chunk.content.strip()
            if content_snippet in seen_contents:
                continue
            seen_contents.add(content_snippet)

            items.append(
                SemanticSearchResultItem(
                    chunk_id=chunk.id,
                    document_id=chunk.document_id,
                    document_name=doc_name,
                    chunk_index=chunk.chunk_index,
                    content=chunk.content,
                    page_number=chunk.page_number,
                    similarity_score=round(similarity, 4),
                    distance=round(distance, 4),
                    metadata=chunk.metadata,
                )
            )

        return SemanticSearchResponse(
            query=clean_query,
            total_results=len(items),
            results=items,
        )

