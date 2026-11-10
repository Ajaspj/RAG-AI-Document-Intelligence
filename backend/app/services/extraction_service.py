from pathlib import Path
from typing import Dict, Type
from fastapi import HTTPException, status

from app.schemas.extraction import ExtractionResult
from app.services.extractors.base_extractor import BaseExtractor
from app.services.extractors.docx_extractor import DocxExtractor
from app.services.extractors.pdf_extractor import PdfExtractor
from app.services.extractors.txt_extractor import TxtExtractor


class ExtractionService:
    """Orchestrates format-specific document extraction for PDF, DOCX, and TXT files."""

    _EXTRACTORS: Dict[str, Type[BaseExtractor]] = {
        "pdf": PdfExtractor,
        "docx": DocxExtractor,
        "txt": TxtExtractor,
    }

    @classmethod
    def get_extractor(cls, extension: str) -> BaseExtractor:
        """Resolve the appropriate extractor instance for the given file extension."""
        clean_ext = extension.lower().lstrip(".")
        extractor_cls = cls._EXTRACTORS.get(clean_ext)
        if not extractor_cls:
            raise ValueError(f"No extractor registered for file extension '{clean_ext}'.")
        return extractor_cls()

    @classmethod
    def extract_document(cls, file_path: Path, extension: str) -> ExtractionResult:
        """Extract text and structure from a stored document.

        Args:
            file_path: Absolute or relative resolved path to document.
            extension: File extension (pdf, docx, txt).

        Returns:
            ExtractionResult containing structured text, metadata, and warnings.
        """
        clean_ext = extension.lower().lstrip(".")
        if clean_ext not in cls._EXTRACTORS:
            return ExtractionResult(
                elements=[],
                total_characters=0,
                warnings=[f"Unsupported extension: {clean_ext}"],
                error_message=f"File extension '.{clean_ext}' is not supported for extraction.",
            )

        extractor = cls.get_extractor(clean_ext)
        return extractor.extract(file_path)

