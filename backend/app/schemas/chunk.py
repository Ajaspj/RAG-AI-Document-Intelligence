from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field, model_validator


class ChunkBase(BaseModel):
    chunk_index: int = Field(..., ge=0, description="Sequential 0-based chunk index")
    content: str = Field(..., min_length=1, description="Text content of the chunk")
    token_count: Optional[int] = Field(None, ge=0, description="Token count of content")
    page_number: Optional[int] = Field(None, ge=1, description="1-based page number")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Metadata dictionary")


class ChunkCreate(ChunkBase):
    document_id: str = Field(..., description="Parent document UUID")
    embedding: Optional[List[float]] = Field(None, description="Vector embedding list")


class ChunkUpdate(BaseModel):
    content: Optional[str] = None
    embedding: Optional[List[float]] = None
    token_count: Optional[int] = None
    metadata: Optional[Dict[str, Any]] = None


class ChunkResponse(ChunkBase):
    id: str
    document_id: str
    user_id: str
    has_embedding: bool = False
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="before")
    @classmethod
    def process_attributes(cls, data: Any) -> Any:
        # Handle SQLAlchemy ORM instance
        if hasattr(data, "id"):
            has_emb = getattr(data, "embedding", None) is not None
            meta = getattr(data, "chunk_metadata", None) or getattr(data, "metadata", None) or {}
            return {
                "id": str(data.id),
                "document_id": str(data.document_id),
                "user_id": str(data.user_id),
                "chunk_index": data.chunk_index,
                "content": data.content,
                "token_count": data.token_count,
                "page_number": data.page_number,
                "has_embedding": has_emb,
                "metadata": meta,
                "created_at": data.created_at,
                "updated_at": data.updated_at,
            }
        return data


class ChunkSimilarityResponse(ChunkResponse):
    similarity_score: float = Field(..., description="Cosine similarity score (0.0 to 1.0)")
    distance: float = Field(..., description="Cosine distance metric (<=>)")


class VectorSearchQuery(BaseModel):
    query_embedding: List[float] = Field(..., description="Dense query vector matching configured dimensions")
    top_k: int = Field(5, ge=1, le=50, description="Maximum number of nearest chunks to retrieve")
    document_id: Optional[str] = Field(None, description="Optional document ID filter for single-doc search")
    min_similarity: Optional[float] = Field(None, ge=0.0, le=1.0, description="Minimum cosine similarity cutoff")


class VectorSearchResult(BaseModel):
    query_dimension: int
    total_results: int
    chunks: List[ChunkSimilarityResponse]

