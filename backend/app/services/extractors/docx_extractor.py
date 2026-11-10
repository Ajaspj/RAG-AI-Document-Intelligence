from pathlib import Path
from typing import List
from docx import Document as DocxDocument

from app.schemas.extraction import ExtractedElement, ExtractionResult
from app.services.extractors.base_extractor import BaseExtractor


class DocxExtractor(BaseExtractor):
    """python-docx text extractor preserving paragraph order, headings, and table data."""

    def extract(self, file_path: Path) -> ExtractionResult:
        warnings: List[str] = []
        elements: List[ExtractedElement] = []
        total_chars = 0

        try:
            doc = DocxDocument(str(file_path))
        except Exception as exc:
            return ExtractionResult(
                elements=[],
                total_characters=0,
                warnings=[f"Failed to open DOCX file: {str(exc)}"],
                error_message="The Word document is corrupted or invalid.",
            )

        try:
            # 1. Extract paragraphs in sequential order
            para_count = 0
            for p_idx, para in enumerate(doc.paragraphs):
                text = para.text.strip()
                if not text:
                    continue

                para_count += 1
                style_name = para.style.name if para.style else "Normal"
                is_heading = "Heading" in style_name or "Title" in style_name

                elements.append(
                    ExtractedElement(
                        text=text,
                        section=style_name if is_heading else None,
                        element_type="heading" if is_heading else "paragraph",
                        metadata={
                            "paragraph_index": p_idx,
                            "style": style_name,
                        },
                    )
                )
                total_chars += len(text)

            # 2. Extract tables
            table_count = 0
            for t_idx, table in enumerate(doc.tables):
                table_lines: List[str] = []
                for row in table.rows:
                    row_texts = [cell.text.strip() for cell in row.cells if cell.text.strip()]
                    if row_texts:
                        table_lines.append(" | ".join(row_texts))

                if table_lines:
                    table_count += 1
                    table_content = "\n".join(table_lines)
                    elements.append(
                        ExtractedElement(
                            text=table_content,
                            element_type="table",
                            metadata={
                                "table_index": t_idx,
                                "row_count": len(table_lines),
                            },
                        )
                    )
                    total_chars += len(table_content)

            if total_chars == 0:
                warnings.append("Word document contains no extractable text in paragraphs or tables.")

            # Document metadata
            metadata = {
                "paragraph_count": para_count,
                "table_count": table_count,
                "format": "DOCX",
            }

            return ExtractionResult(
                elements=elements,
                total_characters=total_chars,
                metadata=metadata,
                warnings=warnings,
            )

        except Exception as exc:
            return ExtractionResult(
                elements=[],
                total_characters=0,
                warnings=[f"Error during DOCX extraction: {str(exc)}"],
                error_message=f"Failed to extract text from Word document: {str(exc)}",
            )

