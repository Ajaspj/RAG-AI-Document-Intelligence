from typing import List, Optional, Union
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "DocuMind AI Backend"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"
    
    # Security
    SECRET_KEY: str = "documind-super-secret-dev-key-change-in-production-2026-secure"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, v: str, info) -> str:
        env = info.data.get("ENVIRONMENT", "development")
        if env == "production" and "change-in-production" in v:
            raise ValueError(
                "Insecure default SECRET_KEY detected in production environment! "
                "You must supply a strong, unique secret key via the SECRET_KEY environment variable."
            )
        return v
    
    # Database (PostgreSQL with psycopg driver as primary)
    DATABASE_URL: str = "postgresql+psycopg://documind:documind_pw@localhost:5432/documind_db"
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20
    DB_POOL_TIMEOUT: int = 30
    DB_POOL_RECYCLE: int = 1800  # Recycle connections after 30 minutes
    DB_POOL_PRE_PING: bool = True

    # Gemini API Configuration
    GEMINI_API_KEY: Optional[str] = None

    # Vector & Embedding Configuration (Gemini gemini-embedding-001 with 768 dimensions)
    EMBEDDING_MODEL: str = "gemini-embedding-001"
    EMBEDDING_DIMENSION: int = 768
    EMBEDDING_TASK_TYPE_DOCUMENT: str = "RETRIEVAL_DOCUMENT"
    EMBEDDING_TASK_TYPE_QUERY: str = "RETRIEVAL_QUERY"
    EMBEDDING_NORMALIZE: bool = True
    MAX_EMBEDDING_BATCH_SIZE: int = 32
    EMBEDDING_MAX_RETRIES: int = 3
    EMBEDDING_RETRY_DELAY: float = 1.0

    # Text Chunking Configuration (Conservative token ceiling safely under 2,048 limit)
    CHUNK_SIZE_TOKENS: int = 1500
    CHUNK_OVERLAP_TOKENS: int = 200

    # Semantic Search & RAG Retrieval Configuration
    SEMANTIC_SEARCH_DEFAULT_LIMIT: int = 10
    SEMANTIC_SEARCH_MAX_LIMIT: int = 50
    SEMANTIC_SEARCH_MIN_SIMILARITY: float = 0.5
    RAG_CONTEXT_TOKEN_BUDGET: int = 3000
    RAG_DEFAULT_TOP_K: int = 5
    RAG_MAX_TOP_K: int = 20
    MAX_QUERY_LENGTH_CHARS: int = 4000

    # Gemini Chat Generation Configuration
    GEMINI_CHAT_MODEL: str = "gemini-1.5-flash"
    GEMINI_TEMPERATURE: float = 0.2
    GEMINI_MAX_OUTPUT_TOKENS: int = 1024
    CHAT_HISTORY_TOKEN_BUDGET: int = 2000
    CHAT_DEFAULT_TOP_K: int = 5

    # Vector Indexing Strategy
    VECTOR_INDEX_TYPE: str = "hnsw"
    VECTOR_DISTANCE_STRATEGY: str = "cosine"
    HNSW_M: int = 16
    HNSW_EF_CONSTRUCTION: int = 64
    HNSW_EF_SEARCH: int = 40

    # Document Storage & Ingestion
    DOCUMENT_STORAGE_DIR: str = "./storage/documents"
    MAX_FILE_SIZE_BYTES: int = 20 * 1024 * 1024  # 20 MB
    ALLOWED_DOCUMENT_EXTENSIONS: List[str] = ["pdf", "docx", "txt"]
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:8000",
        "http://10.0.2.2:8000",
    ]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )


settings = Settings()
