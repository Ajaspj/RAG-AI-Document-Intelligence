from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


# ============================================================================
# Semantic Search Schemas
# ============================================================================

class SemanticSearchRequest(BaseModel):
    """Request payload for semantic vector search across document chunks."""

    query: str = Field(
        ...,
        min_length=1,
        max_length=4000,
        description="Natural language question or search phrase",
    )
    limit: int = Field(
        10,
        ge=1,
        le=50,
        description="Maximum number of relevant chunks to retrieve",
    )
    similarity_threshold: Optional[float] = Field(
        None,
        ge=0.0,
        le=1.0,
        description="Minimum cosine similarity cutoff score (0.0 to 1.0)",
    )
    document_ids: Optional[List[str]] = Field(
        None,
        description="Optional list of document UUIDs to restrict the search scope",
    )


class SemanticSearchResultItem(BaseModel):
    """An individual chunk result from semantic search."""

    chunk_id: str
    document_id: str
    document_name: str
    chunk_index: int
    content: str
    page_number: Optional[int] = None
    similarity_score: float = Field(..., description="Cosine similarity score (0.0 to 1.0)")
    distance: float = Field(..., description="Cosine distance metric (<=>)")
    metadata: Dict[str, Any] = Field(default_factory=dict)


class SemanticSearchResponse(BaseModel):
    """Response payload for semantic search."""

    query: str
    total_results: int
    results: List[SemanticSearchResultItem]


# ============================================================================
# RAG Retrieval Schemas
# ============================================================================

class RAGRetrievalRequest(BaseModel):
    """Request payload for retrieving token-budgeted grounded context for RAG."""

    query: str = Field(
        ...,
        min_length=1,
        max_length=4000,
        description="Natural language user question to retrieve context for",
    )
    document_ids: Optional[List[str]] = Field(
        None,
        description="Optional list of document UUIDs to scope retrieval context",
    )
    top_k: int = Field(
        5,
        ge=1,
        le=20,
        description="Maximum candidate chunks to consider before budget pruning",
    )
    context_token_budget: Optional[int] = Field(
        None,
        ge=200,
        le=8000,
        description="Upper token budget bound for the assembled context",
    )


class RAGSourceReference(BaseModel):
    """Consolidated document source reference for citations."""

    document_id: str
    document_name: str
    page_numbers: List[int] = Field(default_factory=list)
    chunk_indices: List[int] = Field(default_factory=list)


class RAGContextChunk(BaseModel):
    """An individual chunk selected for the RAG LLM context window."""

    chunk_id: str
    document_id: str
    document_name: str
    chunk_index: int
    content: str
    page_number: Optional[int] = None
    similarity_score: float
    estimated_tokens: int
    metadata: Dict[str, Any] = Field(default_factory=dict)


class RAGRetrievalResponse(BaseModel):
    """Response payload containing assembled RAG context and source references."""

    query: str
    total_chunks: int
    estimated_tokens: int
    context_chunks: List[RAGContextChunk]
    sources: List[RAGSourceReference]

