import re
from typing import Any, Dict, List, Optional

from app.core.config import settings
from app.schemas.chunk import ChunkCreate
from app.schemas.extraction import ExtractedElement, ExtractionResult

# Average characters per token across natural language and markdown text
CHARS_PER_TOKEN = 4


class ChunkingService:
    """Boundary-aware document text chunker with configurable token ceilings and retrieval overlap."""

    @staticmethod
    def estimate_token_count(text: str) -> int:
        """Estimate token count conservatively based on character and word density."""
        if not text:
            return 0
        char_estimate = len(text) / CHARS_PER_TOKEN
        word_estimate = len(text.split()) / 0.75
        # Conservative estimate: take the max of character and word estimates
        return max(1, int(max(char_estimate, word_estimate)))

    @classmethod
    def split_text_into_subchunks(
        cls,
        text: str,
        max_chars: int,
        overlap_chars: int,
    ) -> List[str]:
        """Recursively split text exceeding max_chars along natural linguistic boundaries.

        Hierarchy of split delimiters:
        1. Double newlines (paragraphs)
        2. Single newlines
        3. Sentence endings (. ! ?)
        4. Clauses (; ,)
        5. Words (spaces)
        """
        if len(text) <= max_chars:
            return [text.strip()] if text.strip() else []

        delimiters = ["\n\n", "\n", ". ", "? ", "! ", "; ", ", ", " "]
        chosen_delim = None

        for delim in delimiters:
            if delim in text:
                chosen_delim = delim
                break

        if not chosen_delim:
            # Hard fallback at character boundary without splitting in mid-word if possible
            chunks: List[str] = []
            start = 0
            while start < len(text):
                end = min(start + max_chars, len(text))
                chunks.append(text[start:end].strip())
                if end == len(text):
                    break
                start = max(start + 1, end - overlap_chars)
            return [c for c in chunks if c]

        parts = text.split(chosen_delim)
        result_chunks: List[str] = []
        current_chunk: List[str] = []
        current_len = 0

        for part in parts:
            part_str = part.strip()
            if not part_str:
                continue

            added_len = len(part_str) + len(chosen_delim)

            if current_len + added_len > max_chars and current_chunk:
                merged = chosen_delim.join(current_chunk).strip()
                if merged:
                    result_chunks.append(merged)

                # Maintain overlap from end of current chunk
                overlap_accum: List[str] = []
                accum_len = 0
                for prev_part in reversed(current_chunk):
                    if accum_len + len(prev_part) <= overlap_chars:
                        overlap_accum.insert(0, prev_part)
                        accum_len += len(prev_part)
                    else:
                        break

                current_chunk = overlap_accum
                current_len = sum(len(p) + len(chosen_delim) for p in current_chunk)

            # If an individual part itself is larger than max_chars, split it with next delimiter
            if len(part_str) > max_chars:
                if current_chunk:
                    merged = chosen_delim.join(current_chunk).strip()
                    if merged:
                        result_chunks.append(merged)
                    current_chunk = []
                    current_len = 0

                sub_parts = cls.split_text_into_subchunks(part_str, max_chars, overlap_chars)
                result_chunks.extend(sub_parts)
            else:
                current_chunk.append(part_str)
                current_len += added_len

        if current_chunk:
            merged = chosen_delim.join(current_chunk).strip()
            if merged:
                result_chunks.append(merged)

        return result_chunks

    @classmethod
    def create_chunks(
        cls,
        extraction: ExtractionResult,
        document_id: str,
        user_id: str,
    ) -> List[ChunkCreate]:
        """Convert extracted document elements into structured, boundary-aligned, overlapping chunks.

        Enforces conservative token limits (settings.CHUNK_SIZE_TOKENS <= 1,800) to guarantee
        Gemini embedding-001 (2,048 limit) will never fail due to token overflow.
        """
        max_tokens = settings.CHUNK_SIZE_TOKENS
        overlap_tokens = settings.CHUNK_OVERLAP_TOKENS

        max_chars = max_tokens * CHARS_PER_TOKEN
        overlap_chars = overlap_tokens * CHARS_PER_TOKEN

        raw_chunks: List[Dict[str, Any]] = []
        current_texts: List[str] = []
        current_chars = 0
        current_page: Optional[int] = None
        current_pages: set = set()
        current_sections: set = set()

        for element in extraction.elements:
            elem_text = element.text.strip()
            if not elem_text:
                continue

            elem_page = element.page_number
            elem_section = element.section

            # If element by itself exceeds max chunk size, flush current and split element
            if len(elem_text) > max_chars:
                if current_texts:
                    combined = "\n\n".join(current_texts).strip()
                    if combined:
                        raw_chunks.append({
                            "text": combined,
                            "page": current_page,
                            "pages": sorted(list(current_pages)),
                            "sections": sorted(list(current_sections)),
                        })
                    current_texts = []
                    current_chars = 0
                    current_pages = set()
                    current_sections = set()
                    current_page = None

                sub_texts = cls.split_text_into_subchunks(elem_text, max_chars, overlap_chars)
                for sub in sub_texts:
                    raw_chunks.append({
                        "text": sub,
                        "page": elem_page,
                        "pages": [elem_page] if elem_page else [],
                        "sections": [elem_section] if elem_section else [],
                    })
                continue

            # Check if adding this element would exceed max chunk size
            if current_chars + len(elem_text) + 2 > max_chars and current_texts:
                combined = "\n\n".join(current_texts).strip()
                if combined:
                    raw_chunks.append({
                        "text": combined,
                        "page": current_page,
                        "pages": sorted(list(current_pages)),
                        "sections": sorted(list(current_sections)),
                    })

                # Maintain overlap from the tail of current texts
                overlap_texts: List[str] = []
                overlap_accum = 0
                for prev in reversed(current_texts):
                    if overlap_accum + len(prev) <= overlap_chars:
                        overlap_texts.insert(0, prev)
                        overlap_accum += len(prev)
                    else:
                        break

                current_texts = overlap_texts
                current_chars = sum(len(t) + 2 for t in current_texts)
                # Keep current page references
                current_pages = {elem_page} if elem_page else set()
                current_sections = {elem_section} if elem_section else set()
                current_page = elem_page
            else:
                if current_page is None:
                    current_page = elem_page

            current_texts.append(elem_text)
            current_chars += len(elem_text) + 2
            if elem_page:
                current_pages.add(elem_page)
            if elem_section:
                current_sections.add(elem_section)

        # Flush final chunk
        if current_texts:
            combined = "\n\n".join(current_texts).strip()
            if combined:
                raw_chunks.append({
                    "text": combined,
                    "page": current_page,
                    "pages": sorted(list(current_pages)),
                    "sections": sorted(list(current_sections)),
                })

        # Deduplicate and build ChunkCreate objects
        chunk_models: List[ChunkCreate] = []
        seen_texts = set()

        for idx, item in enumerate(raw_chunks):
            content = item["text"]
            # Avoid empty or exact duplicate chunks
            if not content or content in seen_texts:
                continue
            seen_texts.add(content)

            token_count = cls.estimate_token_count(content)
            meta: Dict[str, Any] = {
                "char_count": len(content),
                "estimated_tokens": token_count,
            }
            if item.get("pages"):
                meta["page_numbers"] = item["pages"]
            if item.get("sections"):
                meta["sections"] = item["sections"]

            chunk_models.append(
                ChunkCreate(
                    document_id=document_id,
                    chunk_index=len(chunk_models),
                    content=content,
                    token_count=token_count,
                    page_number=item.get("page"),
                    metadata=meta,
                )
            )

        return chunk_models

