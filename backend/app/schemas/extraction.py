from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class ExtractedElement(BaseModel):
    """Represents a coherent piece of extracted text with structural coordinates."""

    text: str = Field(..., description="Extracted text content")
    page_number: Optional[int] = Field(None, description="1-based source page number")
    section: Optional[str] = Field(None, description="Document section or header, if identified")
    element_type: str = Field("paragraph", description="Structural type: page, paragraph, table, heading")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional element metadata")


class ExtractionResult(BaseModel):
    """Aggregate result of document text extraction."""

    elements: List[ExtractedElement] = Field(default_factory=list, description="Extracted structural elements")
    total_characters: int = Field(0, description="Total characters extracted across all elements")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Document-level metadata")
    warnings: List[str] = Field(default_factory=list, description="Extraction warnings or non-fatal anomalies")
    is_scanned: bool = Field(False, description="True if document appears to be an image-only scanned PDF")
    error_message: Optional[str] = Field(None, description="Critical extraction error message if failed")

    @property
    def has_content(self) -> bool:
        return self.total_characters > 0 and len(self.elements) > 0

