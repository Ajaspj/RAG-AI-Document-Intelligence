from abc import ABC, abstractmethod
from pathlib import Path
from app.schemas.extraction import ExtractionResult


class BaseExtractor(ABC):
    """Abstract interface for format-specific document text extractors."""

    @abstractmethod
    def extract(self, file_path: Path) -> ExtractionResult:
        """Extract text and metadata from the target file.

        Args:
            file_path: Validated Path to the document on disk.

        Returns:
            ExtractionResult containing extracted structural elements, character counts, and warnings.
        """
        pass

