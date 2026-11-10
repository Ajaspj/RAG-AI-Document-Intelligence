from pathlib import Path
from typing import List
import fitz  # PyMuPDF

from app.schemas.extraction import ExtractedElement, ExtractionResult
from app.services.extractors.base_extractor import BaseExtractor


class PdfExtractor(BaseExtractor):
    """PyMuPDF-based text extractor for PDF documents with page tracking and scanned-document detection."""

    def extract(self, file_path: Path) -> ExtractionResult:
        warnings: List[str] = []
        elements: List[ExtractedElement] = []
        total_chars = 0
        doc = None

        try:
            doc = fitz.open(str(file_path))
        except Exception as exc:
            return ExtractionResult(
                elements=[],
                total_characters=0,
                warnings=[f"Failed to open PDF document: {str(exc)}"],
                error_message="The PDF file is corrupted or could not be read.",
            )

        try:
            # 1. Check encryption / password protection
            if doc.is_encrypted:
                return ExtractionResult(
                    elements=[],
                    total_characters=0,
                    warnings=["PDF is password-protected or encrypted."],
                    error_message="The PDF is password-protected. Decryption is not supported.",
                )

            page_count = len(doc)
            if page_count == 0:
                return ExtractionResult(
                    elements=[],
                    total_characters=0,
                    warnings=["PDF has 0 pages."],
                    error_message="The document contains no pages.",
                )

            empty_page_count = 0
            has_images_count = 0

            # 2. Extract page by page
            for page_idx in range(page_count):
                page_num = page_idx + 1
                page = doc[page_idx]

                # Check if page has images (useful for scanned PDF detection)
                images = page.get_images()
                if images:
                    has_images_count += 1

                # Extract text
                page_text = page.get_text("text")
                clean_text = page_text.strip()

                if not clean_text:
                    empty_page_count += 1
                    continue

                elements.append(
                    ExtractedElement(
                        text=clean_text,
                        page_number=page_num,
                        element_type="page",
                        metadata={"raw_char_count": len(clean_text)},
                    )
                )
                total_chars += len(clean_text)

            # 3. Detect scanned / image-only PDFs
            is_scanned = False
            if total_chars < 50 and has_images_count > 0:
                is_scanned = True
                warnings.append(
                    "Document appears to be a scanned image-only PDF with no extractable text. "
                    "Optical Character Recognition (OCR) is not currently supported."
                )

            if empty_page_count > 0:
                warnings.append(f"{empty_page_count} of {page_count} page(s) contained no extractable text.")

            # Extract document metadata
            doc_meta = {
                "page_count": page_count,
                "title": doc.metadata.get("title") or None,
                "author": doc.metadata.get("author") or None,
                "subject": doc.metadata.get("subject") or None,
                "creator": doc.metadata.get("creator") or None,
                "format": "PDF",
            }

            return ExtractionResult(
                elements=elements,
                total_characters=total_chars,
                metadata=doc_meta,
                warnings=warnings,
                is_scanned=is_scanned,
            )

        except Exception as exc:
            return ExtractionResult(
                elements=[],
                total_characters=0,
                warnings=[f"Error during PDF text extraction: {str(exc)}"],
                error_message=f"Failed to process PDF content: {str(exc)}",
            )
        finally:
            if doc is not None:
                doc.close()

