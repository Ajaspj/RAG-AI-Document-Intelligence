import os
from pathlib import Path
from typing import Optional, Tuple
from fastapi import HTTPException, UploadFile, status

from app.core.config import settings

# Supported MIME type mappings
MIME_TYPE_MAP = {
    "pdf": "application/pdf",
    "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "txt": "text/plain",
}

# Magic signatures
PDF_MAGIC = b"%PDF-"
ZIP_MAGIC = b"PK\x03\x04"


class ValidationService:
    @staticmethod
    def sanitize_filename(filename: Optional[str]) -> str:
        """Strip directory traversal elements, null bytes, and control characters from the original filename."""
        if not filename:
            return "unnamed_document"

        # Extract only the base name (prevents path traversal)
        base_name = Path(filename).name
        # Remove null bytes and trailing whitespace
        sanitized = base_name.replace("\x00", "").strip()

        # Fallback if filename becomes empty
        if not sanitized or sanitized in (".", ".."):
            sanitized = "unnamed_document"

        return sanitized

    @staticmethod
    def extract_extension(filename: str) -> str:
        """Extract and normalize lowercase file extension without the leading dot."""
        ext = os.path.splitext(filename)[1].lower().lstrip(".")
        return ext

    @classmethod
    async def validate_document(
        cls,
        upload_file: UploadFile,
    ) -> Tuple[str, str, str]:
        """Validate an uploaded document's extension, size, and magic bytes.

        Returns:
            Tuple of (sanitized_original_filename, file_extension, canonical_mime_type)

        Raises:
            HTTPException with appropriate 400, 413, or 415 status code.
        """
        original_filename = cls.sanitize_filename(upload_file.filename)
        extension = cls.extract_extension(original_filename)

        # 1. Validate file extension
        if not extension or extension not in settings.ALLOWED_DOCUMENT_EXTENSIONS:
            allowed = ", ".join(f".{ext}" for ext in settings.ALLOWED_DOCUMENT_EXTENSIONS)
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=f"Unsupported file type '.{extension}'. Allowed types are: {allowed}.",
            )

        # 2. Pre-check file size if Content-Length header or UploadFile size is provided
        if upload_file.size is not None and upload_file.size > settings.MAX_FILE_SIZE_BYTES:
            max_mb = settings.MAX_FILE_SIZE_BYTES // (1024 * 1024)
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File exceeds maximum allowed size of {max_mb} MB.",
            )

        # 3. Inspect magic bytes / initial content
        header_sample = await upload_file.read(2048)
        # Seek back to beginning so subsequent streaming can read the entire file
        await upload_file.seek(0)

        if not header_sample:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Uploaded file is empty (0 bytes).",
            )

        canonical_mime = MIME_TYPE_MAP[extension]

        if extension == "pdf":
            # PDF header check: %PDF- in the first 1024 bytes
            if PDF_MAGIC not in header_sample[:1024]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="File has a .pdf extension but its content does not have a valid PDF header (%PDF-).",
                )

        elif extension == "docx":
            # DOCX is an OpenXML ZIP container: starts with PK\x03\x04
            if not header_sample.startswith(ZIP_MAGIC):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="File has a .docx extension but its content is not a valid OpenXML Word document.",
                )

        elif extension == "txt":
            # Text file check: should be valid text without binary null bytes
            if b"\x00" in header_sample:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="File has a .txt extension but contains binary data.",
                )
            try:
                # Try UTF-8 decode of sample
                header_sample.decode("utf-8")
            except UnicodeDecodeError:
                try:
                    # Fallback check for Latin-1 / ASCII
                    header_sample.decode("latin-1")
                except Exception:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="File content could not be decoded as text.",
                    )

        return original_filename, extension, canonical_mime

