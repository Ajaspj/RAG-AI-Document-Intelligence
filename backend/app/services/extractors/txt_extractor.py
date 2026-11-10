from pathlib import Path
from typing import List

from app.schemas.extraction import ExtractedElement, ExtractionResult
from app.services.extractors.base_extractor import BaseExtractor

FALLBACK_ENCODINGS = ["utf-8", "utf-8-sig", "cp1252", "latin-1"]


class TxtExtractor(BaseExtractor):
    """Text extractor for plain text files with robust multi-encoding detection and line-ending normalization."""

    def extract(self, file_path: Path) -> ExtractionResult:
        warnings: List[str] = []
        raw_bytes = None

        try:
            with open(file_path, "rb") as f:
                raw_bytes = f.read()
        except Exception as exc:
            return ExtractionResult(
                elements=[],
                total_characters=0,
                warnings=[f"Failed to read file: {str(exc)}"],
                error_message="Could not access text file on disk.",
            )

        if not raw_bytes:
            return ExtractionResult(
                elements=[],
                total_characters=0,
                warnings=["Text file is empty (0 bytes)."],
            )

        # Attempt decoding with fallback chain
        decoded_text = None
        used_encoding = None

        for enc in FALLBACK_ENCODINGS:
            try:
                decoded_text = raw_bytes.decode(enc)
                used_encoding = enc
                break
            except UnicodeDecodeError:
                continue

        if decoded_text is None:
            return ExtractionResult(
                elements=[],
                total_characters=0,
                warnings=["File could not be decoded with standard text encodings."],
                error_message="Unsupported text encoding; binary content detected.",
            )

        if used_encoding != "utf-8":
            warnings.append(f"Decoded using fallback encoding: {used_encoding}")

        # Normalize line endings
        normalized_text = decoded_text.replace("\r\n", "\n").replace("\r", "\n")

        # Split into meaningful paragraphs (blocks separated by two or more newlines)
        raw_paragraphs = normalized_text.split("\n\n")
        elements: List[ExtractedElement] = []
        total_chars = 0

        for idx, block in enumerate(raw_paragraphs):
            cleaned = block.strip()
            if not cleaned:
                continue

            elements.append(
                ExtractedElement(
                    text=cleaned,
                    element_type="paragraph",
                    metadata={"paragraph_index": idx, "encoding": used_encoding},
                )
            )
            total_chars += len(cleaned)

        if total_chars == 0:
            warnings.append("Text file contains only whitespace.")

        metadata = {
            "encoding": used_encoding,
            "paragraph_count": len(elements),
            "line_count": normalized_text.count("\n") + 1,
            "format": "TXT",
        }

        return ExtractionResult(
            elements=elements,
            total_characters=total_chars,
            metadata=metadata,
            warnings=warnings,
        )

