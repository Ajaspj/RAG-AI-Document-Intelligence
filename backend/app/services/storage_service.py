import hashlib
import os
import uuid
from pathlib import Path
from typing import Optional, Tuple
from fastapi import HTTPException, UploadFile, status

from app.core.config import settings

# 64 KB streaming buffer
STREAM_CHUNK_SIZE = 64 * 1024


class StorageService:
    @staticmethod
    def get_storage_root() -> Path:
        """Resolve and ensure the root document storage directory exists."""
        raw_path = settings.DOCUMENT_STORAGE_DIR
        # If relative, resolve relative to the backend project root (two levels up from app/services)
        if os.path.isabs(raw_path):
            storage_dir = Path(raw_path)
        else:
            backend_root = Path(__file__).resolve().parent.parent.parent
            storage_dir = backend_root / raw_path

        storage_dir = storage_dir.resolve()
        storage_dir.mkdir(parents=True, exist_ok=True)
        return storage_dir

    @classmethod
    def validate_path_safety(cls, target_path: Path) -> Path:
        """Ensure the target path is strictly within the allowed storage directory, preventing directory traversal attacks."""
        storage_root = cls.get_storage_root()
        resolved_target = target_path.resolve()

        try:
            # Python 3.9+ standard method
            if not resolved_target.is_relative_to(storage_root):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid storage path: path traversal detected.",
                )
        except AttributeError:
            if os.path.commonpath([str(storage_root), str(resolved_target)]) != str(storage_root):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid storage path: path traversal detected.",
                )

        return resolved_target

    @classmethod
    def generate_server_filename(cls, extension: str) -> str:
        """Generate a cryptographically unique server-side filename using UUID v4 and the clean extension."""
        clean_ext = extension.lstrip(".").lower()
        unique_id = uuid.uuid4().hex
        return f"{unique_id}.{clean_ext}"

    @classmethod
    async def save_upload_file(
        cls,
        upload_file: UploadFile,
        extension: str,
        max_size_bytes: Optional[int] = None,
    ) -> Tuple[str, str, int, str]:
        """Stream an uploaded file to disk in chunks, simultaneously computing its SHA-256 checksum and enforcing maximum size constraints.

        Returns:
            Tuple of (server_filename, storage_path_str, file_size_bytes, sha256_hash_hex)

        Raises:
            HTTPException 413 if size exceeds max_size_bytes.
            HTTPException 500 on I/O error (with automatic file cleanup).
        """
        if max_size_bytes is None:
            max_size_bytes = settings.MAX_FILE_SIZE_BYTES

        server_filename = cls.generate_server_filename(extension)
        storage_root = cls.get_storage_root()
        target_path = storage_root / server_filename
        cls.validate_path_safety(target_path)

        hasher = hashlib.sha256()
        total_bytes = 0

        try:
            with open(target_path, "wb") as destination:
                while True:
                    chunk = await upload_file.read(STREAM_CHUNK_SIZE)
                    if not chunk:
                        break

                    total_bytes += len(chunk)
                    if max_size_bytes and total_bytes > max_size_bytes:
                        destination.close()
                        # Clean up partial file immediately
                        if target_path.exists():
                            target_path.unlink(missing_ok=True)

                        max_mb = max_size_bytes // (1024 * 1024)
                        raise HTTPException(
                            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                            detail=f"File exceeds maximum allowed size of {max_mb} MB.",
                        )

                    hasher.update(chunk)
                    destination.write(chunk)

        except HTTPException:
            # Re-raise HTTP exceptions (e.g. 413) after ensuring cleanup
            if target_path.exists():
                target_path.unlink(missing_ok=True)
            raise
        except Exception as exc:
            # Clean up on any filesystem/IO error
            if target_path.exists():
                target_path.unlink(missing_ok=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to persist file to storage: {str(exc)}",
            )

        file_hash = hasher.hexdigest()
        # Store relative path to storage root or string path
        storage_path_str = str(target_path)

        return server_filename, storage_path_str, total_bytes, file_hash

    @classmethod
    def get_file_path(cls, storage_path: str) -> Path:
        """Resolve a stored document path and verify it exists and is safe."""
        path = Path(storage_path)
        if not path.is_absolute():
            path = cls.get_storage_root() / path

        resolved_path = cls.validate_path_safety(path)
        if not resolved_path.exists() or not resolved_path.is_file():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Stored document file not found on disk.",
            )
        return resolved_path

    @classmethod
    def delete_file(cls, storage_path: str) -> bool:
        """Safely delete a stored file from disk if it exists."""
        try:
            path = Path(storage_path)
            if not path.is_absolute():
                path = cls.get_storage_root() / path

            resolved_path = cls.validate_path_safety(path)
            if resolved_path.exists() and resolved_path.is_file():
                resolved_path.unlink()
                return True
            return False
        except HTTPException:
            raise
        except Exception:
            # Log or tolerate file deletion errors (e.g. file already gone)
            return False

