import logging
import math
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.chunk import DocumentChunk
from app.models.document import Document
from app.schemas.chunk import ChunkCreate, ChunkSimilarityResponse, ChunkUpdate

logger = logging.getLogger(__name__)


class VectorService:
    """Service layer for document chunk persistence, embedding management, and pgvector similarity retrieval.

    Configured for Gemini gemini-embedding-001 with 768 dimensions and unit normalization.
    """

    @staticmethod
    def normalize_vector(vector: List[float]) -> List[float]:
        """Normalize a dense vector to unit Euclidean norm (L2 norm = 1.0).

        Ensures 768-dimensional embeddings from gemini-embedding-001 are normalized
        before database storage for optimal cosine similarity retrieval in pgvector.
        """
        squared_sum = sum(x * x for x in vector)
        norm = math.sqrt(squared_sum)
        if norm == 0.0 or math.isclose(norm, 1.0, rel_tol=1e-5):
            return vector
        return [float(x / norm) for x in vector]

    @classmethod
    def store_document_chunks(
        cls,
        db: Session,
        document_id: str,
        user_id: str,
        chunks_data: List[ChunkCreate],
    ) -> List[DocumentChunk]:
        """Bulk store document chunks for a validated user document.

        Normalizes embeddings before persisting to PostgreSQL.
        """
        # 1. Verify document ownership
        doc = (
            db.query(Document)
            .filter(Document.id == document_id, Document.user_id == user_id)
            .first()
        )
        if not doc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found or access denied.",
            )

        now = datetime.now(timezone.utc)
        chunk_models: List[DocumentChunk] = []

        for data in chunks_data:
            embedding_val = None
            # Validate embedding dimension if provided and normalize
            if data.embedding is not None:
                if len(data.embedding) != settings.EMBEDDING_DIMENSION:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=(
                            f"Embedding dimension mismatch: expected {settings.EMBEDDING_DIMENSION}, "
                            f"got {len(data.embedding)}."
                        ),
                    )
                embedding_val = (
                    cls.normalize_vector(data.embedding)
                    if settings.EMBEDDING_NORMALIZE
                    else data.embedding
                )

            chunk = DocumentChunk(
                id=str(uuid.uuid4()),
                document_id=document_id,
                user_id=user_id,
                chunk_index=data.chunk_index,
                content=data.content,
                token_count=data.token_count,
                page_number=data.page_number,
                embedding=embedding_val,
                chunk_metadata=data.metadata or {},
                created_at=now,
                updated_at=now,
            )
            chunk_models.append(chunk)

        try:
            db.add_all(chunk_models)
            db.commit()
            for chunk in chunk_models:
                db.refresh(chunk)
            return chunk_models
        except Exception as exc:
            db.rollback()
            logger.error("Failed to store document chunks: %s", exc, exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to store document chunks.",
            )

    @classmethod
    def update_chunk_embedding(
        cls,
        db: Session,
        chunk_id: str,
        user_id: str,
        embedding: List[float],
    ) -> DocumentChunk:
        """Update and normalize the vector embedding for an existing document chunk."""
        if len(embedding) != settings.EMBEDDING_DIMENSION:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Embedding dimension mismatch: expected {settings.EMBEDDING_DIMENSION}, "
                    f"got {len(embedding)}."
                ),
            )

        chunk = (
            db.query(DocumentChunk)
            .filter(DocumentChunk.id == chunk_id, DocumentChunk.user_id == user_id)
            .first()
        )
        if not chunk:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chunk not found or access denied.",
            )

        # Normalize 768-dim vector before persistence
        processed_embedding = (
            cls.normalize_vector(embedding)
            if settings.EMBEDDING_NORMALIZE
            else embedding
        )
        chunk.embedding = processed_embedding
        chunk.updated_at = datetime.now(timezone.utc)

        try:
            db.commit()
            db.refresh(chunk)
            return chunk
        except Exception as exc:
            db.rollback()
            logger.error("Failed to update chunk embedding: %s", exc, exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update chunk embedding.",
            )

    @classmethod
    def get_chunks_by_document(
        cls,
        db: Session,
        document_id: str,
        user_id: str,
        skip: int = 0,
        limit: int = 100,
    ) -> Tuple[List[DocumentChunk], int]:
        """Retrieve paginated chunks belonging to a document, ordered sequentially by chunk_index."""
        query = db.query(DocumentChunk).filter(
            DocumentChunk.document_id == document_id,
            DocumentChunk.user_id == user_id,
        )
        total = query.count()
        chunks = (
            query.order_by(DocumentChunk.chunk_index.asc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        return chunks, total

    @classmethod
    def search_similar_chunks(
        cls,
        db: Session,
        user_id: str,
        query_embedding: List[float],
        top_k: int = 5,
        document_id: Optional[str] = None,
        document_ids: Optional[List[str]] = None,
        min_similarity: Optional[float] = None,
    ) -> List[Tuple[DocumentChunk, str, float, float]]:
        """Perform vector cosine similarity search across document chunks.

        Enforces strict user isolation and optional multi-document scoping.
        Joins with Document table to fetch original filename in a single query.
        Query embedding is normalized to match normalized stored document vectors.

        Returns:
            List of tuples: (chunk, document_original_filename, similarity_score, distance)
        """
        # Validate query embedding dimension
        if len(query_embedding) != settings.EMBEDDING_DIMENSION:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Query vector dimension mismatch: expected {settings.EMBEDDING_DIMENSION}, "
                    f"got {len(query_embedding)}."
                ),
            )

        # Normalize query vector for cosine metric consistency
        normalized_query = (
            cls.normalize_vector(query_embedding)
            if settings.EMBEDDING_NORMALIZE
            else query_embedding
        )

        # Distance expression via pgvector cosine distance operator <=>
        distance_expr = DocumentChunk.embedding.cosine_distance(normalized_query).label("distance")

        # Query chunks joined with Document, scoped by user_id and non-null embedding
        query = (
            db.query(DocumentChunk, Document.original_filename, distance_expr)
            .join(Document, DocumentChunk.document_id == Document.id)
            .filter(
                DocumentChunk.user_id == user_id,
                DocumentChunk.embedding.isnot(None),
            )
        )

        # Optional multiple or single document constraints
        if document_ids:
            query = query.filter(DocumentChunk.document_id.in_(document_ids))
        elif document_id:
            query = query.filter(DocumentChunk.document_id == document_id)

        # Distance filter if minimum similarity is specified (cosine similarity = 1 - distance)
        if min_similarity is not None:
            max_distance = max(0.0, 1.0 - min_similarity)
            query = query.filter(distance_expr <= max_distance)

        # Order by nearest neighbor (lowest distance) and apply top_k limit
        results = query.order_by(distance_expr.asc()).limit(top_k).all()

        formatted_results: List[Tuple[DocumentChunk, str, float, float]] = []
        for chunk, doc_filename, dist in results:
            distance_val = float(dist)
            similarity = max(0.0, min(1.0, 1.0 - distance_val))
            formatted_results.append((chunk, doc_filename, similarity, distance_val))

        return formatted_results

    @classmethod
    def delete_chunks_by_document(
        cls,
        db: Session,
        document_id: str,
        user_id: str,
    ) -> int:
        """Delete all chunks for a document owned by the user.

        Returns:
            Number of deleted chunk records.
        """
        deleted_count = (
            db.query(DocumentChunk)
            .filter(
                DocumentChunk.document_id == document_id,
                DocumentChunk.user_id == user_id,
            )
            .delete(synchronize_session=False)
        )
        try:
            db.commit()
            return deleted_count
        except Exception as exc:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to delete document chunks: {str(exc)}",
            )
