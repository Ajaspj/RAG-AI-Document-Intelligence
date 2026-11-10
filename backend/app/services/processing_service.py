import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.document import Document
from app.services.chunking_service import ChunkingService
from app.services.embedding_service import EmbeddingService, GeminiEmbeddingError
from app.services.extraction_service import ExtractionService
from app.services.storage_service import StorageService
from app.services.vector_service import VectorService

logger = logging.getLogger(__name__)


class ProcessingService:
    """Coordinates the end-to-end ingestion pipeline: extraction, chunking, embedding generation, and vector persistence."""

    @classmethod
    def process_document(
        cls,
        db: Session,
        document_id: str,
        user_id: str,
    ) -> Document:
        """Run the ingestion pipeline synchronously within a given DB session.

        Lifecycle: pending -> processing -> completed (or failed).
        """
        # 1. Load document and verify ownership
        doc = (
            db.query(Document)
            .filter(Document.id == document_id, Document.user_id == user_id)
            .first()
        )
        if not doc:
            raise ValueError(f"Document '{document_id}' not found for user '{user_id}'.")

        logger.info(f"Starting ingestion processing for document {doc.id} ('{doc.original_filename}')")

        # 2. Update status to 'processing'
        doc.status = "processing"
        doc.error_message = None
        doc.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(doc)

        try:
            # 3. Retrieve stored file path
            file_path = StorageService.get_file_path(doc.storage_path)

            # 4. Extract text according to format
            extraction = ExtractionService.extract_document(
                file_path=file_path,
                extension=doc.file_extension,
            )

            # Check for extraction failures
            if extraction.error_message:
                raise ValueError(extraction.error_message)

            if extraction.is_scanned:
                raise ValueError(
                    "The document appears to be an image-only scanned PDF without extractable text. "
                    "OCR is not currently supported."
                )

            if not extraction.has_content:
                raise ValueError("The document contains no extractable text.")

            # 5. Chunk extracted text with conservative token limits
            chunks = ChunkingService.create_chunks(
                extraction=extraction,
                document_id=doc.id,
                user_id=doc.user_id,
            )

            if not chunks:
                raise ValueError("Could not extract any meaningful text chunks from document.")

            logger.info(f"Generated {len(chunks)} text chunks for document {doc.id}. Requesting Gemini embeddings...")

            # 6. Generate Gemini embeddings for chunks
            chunk_texts = [c.content for c in chunks]
            embeddings = EmbeddingService.generate_document_embeddings(
                texts=chunk_texts,
                title=doc.original_filename,
            )

            if len(embeddings) != len(chunks):
                raise ValueError(
                    f"Embedding count mismatch: generated {len(embeddings)} vectors for {len(chunks)} chunks."
                )

            # Attach generated vectors to ChunkCreate schemas
            for idx, chunk_schema in enumerate(chunks):
                chunk_schema.embedding = embeddings[idx]

            # 7. Persist chunks via VectorService (clearing previous chunks to avoid duplicates on retry)
            VectorService.delete_chunks_by_document(
                db=db,
                document_id=doc.id,
                user_id=doc.user_id,
            )

            VectorService.store_document_chunks(
                db=db,
                document_id=doc.id,
                user_id=doc.user_id,
                chunks_data=chunks,
            )

            # 8. Mark document as completed
            doc.status = "completed"
            doc.error_message = None
            doc.updated_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(doc)

            logger.info(
                f"Successfully completed ingestion for document {doc.id} "
                f"({len(chunks)} chunks embedded and stored in pgvector)."
            )
            return doc

        except (ValueError, GeminiEmbeddingError) as known_err:
            db.rollback()
            err_msg = str(known_err)
            logger.warning(f"Document ingestion failed for {doc.id}: {err_msg}")
            doc.status = "failed"
            doc.error_message = err_msg
            doc.updated_at = datetime.now(timezone.utc)
            db.commit()
            return doc

        except Exception as unexpected_err:
            db.rollback()
            err_msg = f"Unexpected processing error: {str(unexpected_err)}"
            logger.error(f"Unexpected document ingestion failure for {doc.id}: {err_msg}", exc_info=True)
            doc.status = "failed"
            doc.error_message = err_msg
            doc.updated_at = datetime.now(timezone.utc)
            db.commit()
            return doc

    @classmethod
    def process_document_background(
        cls,
        document_id: str,
        user_id: str,
    ) -> None:
        """Background task entry point. Creates and safely terminates an isolated database session."""
        db: Session = SessionLocal()
        try:
            cls.process_document(
                db=db,
                document_id=document_id,
                user_id=user_id,
            )
        except Exception as exc:
            logger.error(f"Background document processing task failed: {str(exc)}", exc_info=True)
        finally:
            db.close()

