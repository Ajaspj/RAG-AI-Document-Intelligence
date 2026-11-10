import logging
from typing import List, Optional
from google import genai
from google.genai import types
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from app.core.config import settings
from app.services.vector_service import VectorService

logger = logging.getLogger(__name__)


class GeminiEmbeddingError(Exception):
    """Exception raised when embedding generation encounters unrecoverable API or validation errors."""
    pass


class EmbeddingService:
    """Service wrapping Google GenAI SDK for generating normalized 768-dimensional embeddings using gemini-embedding-001."""

    _client: Optional[genai.Client] = None

    @classmethod
    def get_client(cls) -> genai.Client:
        """Initialize or return the cached Gemini API client."""
        if cls._client is None:
            if not settings.GEMINI_API_KEY or settings.GEMINI_API_KEY.startswith("your-gemini"):
                raise GeminiEmbeddingError(
                    "Gemini API key is not configured. Please set GEMINI_API_KEY in the backend .env configuration."
                )
            try:
                cls._client = genai.Client(api_key=settings.GEMINI_API_KEY)
            except Exception as exc:
                raise GeminiEmbeddingError(f"Failed to initialize Google GenAI Client: {str(exc)}")
        return cls._client

    @classmethod
    def reset_client(cls) -> None:
        """Reset cached client (e.g. if API key changes)."""
        cls._client = None

    @classmethod
    def _embed_batch_with_retry(
        cls,
        client: genai.Client,
        batch: List[str],
        task_type: str,
        title: Optional[str] = None,
    ) -> List[List[float]]:
        """Call Gemini embed_content API with bounded exponential backoff retries."""

        @retry(
            reraise=True,
            stop=stop_after_attempt(settings.EMBEDDING_MAX_RETRIES),
            wait=wait_exponential(multiplier=settings.EMBEDDING_RETRY_DELAY, min=1.0, max=10.0),
            retry=retry_if_exception_type(Exception),
        )
        def _execute_embed():
            config = types.EmbedContentConfig(
                task_type=task_type,
                output_dimensionality=settings.EMBEDDING_DIMENSION,
                title=title if task_type == settings.EMBEDDING_TASK_TYPE_DOCUMENT else None,
            )
            response = client.models.embed_content(
                model=settings.EMBEDDING_MODEL,
                contents=batch,
                config=config,
            )
            return response

        try:
            response = _execute_embed()
        except Exception as exc:
            logger.error(f"Gemini embed_content API call failed after retries: {str(exc)}")
            raise GeminiEmbeddingError(f"Gemini embedding API failed: {str(exc)}")

        if not response or not response.embeddings:
            raise GeminiEmbeddingError("Gemini API returned an empty embedding response.")

        vectors: List[List[float]] = []
        for emb in response.embeddings:
            values = emb.values
            if not values:
                raise GeminiEmbeddingError("Received empty vector values from Gemini API.")
            if len(values) != settings.EMBEDDING_DIMENSION:
                raise GeminiEmbeddingError(
                    f"Vector dimension mismatch: expected {settings.EMBEDDING_DIMENSION}, got {len(values)}."
                )

            # Apply L2 normalization if enabled
            if settings.EMBEDDING_NORMALIZE:
                norm_values = VectorService.normalize_vector(values)
            else:
                norm_values = values

            vectors.append(norm_values)

        return vectors

    @classmethod
    def generate_document_embeddings(
        cls,
        texts: List[str],
        title: Optional[str] = None,
    ) -> List[List[float]]:
        """Generate normalized 768-dimensional embeddings for document chunks using RETRIEVAL_DOCUMENT task type.

        Batches requests according to settings.MAX_EMBEDDING_BATCH_SIZE to avoid hitting payload ceilings.
        """
        if not texts:
            return []

        client = cls.get_client()
        batch_size = max(1, settings.MAX_EMBEDDING_BATCH_SIZE)
        all_embeddings: List[List[float]] = []

        for i in range(0, len(texts), batch_size):
            batch = texts[i : i + batch_size]
            # Filter out any accidentally empty strings (or replace with minimal token)
            sanitized_batch = [t if t.strip() else "..." for t in batch]

            batch_vectors = cls._embed_batch_with_retry(
                client=client,
                batch=sanitized_batch,
                task_type=settings.EMBEDDING_TASK_TYPE_DOCUMENT,
                title=title,
            )
            all_embeddings.extend(batch_vectors)

        return all_embeddings

    @classmethod
    def generate_query_embedding(
        cls,
        query: str,
    ) -> List[float]:
        """Generate a normalized 768-dimensional query embedding using RETRIEVAL_QUERY task type."""
        clean_query = query.strip()
        if not clean_query:
            raise ValueError("Query string cannot be empty.")

        client = cls.get_client()
        vectors = cls._embed_batch_with_retry(
            client=client,
            batch=[clean_query],
            task_type=settings.EMBEDDING_TASK_TYPE_QUERY,
        )
        return vectors[0]

