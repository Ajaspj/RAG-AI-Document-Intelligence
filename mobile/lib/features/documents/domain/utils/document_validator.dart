import 'dart:io';

import '../../../../core/constants/app_constants.dart';

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._({required this.isValid, this.errorMessage});

  factory ValidationResult.success() => const ValidationResult._(isValid: true);
  factory ValidationResult.failure(String message) =>
      ValidationResult._(isValid: false, errorMessage: message);
}

class DocumentValidator {
  final int maxSizeBytes;
  final List<String> allowedExtensions;

  const DocumentValidator({
    this.maxSizeBytes = AppConstants.defaultMaxFileSizeBytes,
    this.allowedExtensions = AppConstants.supportedExtensions,
  });

  /// Formatted max file size string (e.g. "20 MB")
  String get formattedMaxSize =>
      '${(maxSizeBytes / (1024 * 1024)).round()} MB';

  /// Validates file extension, size, MIME type and magic number signatures
  Future<ValidationResult> validateFile({
    required String? path,
    required String? name,
    required int? size,
    String? mimeType,
  }) async {
    // 1. Name & Path Presence
    if (name == null || name.trim().isEmpty) {
      return ValidationResult.failure('Invalid file: filename is missing.');
    }

    final trimmedName = name.trim();

    // 2. Extension Extraction & Validation
    final dotIndex = trimmedName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == trimmedName.length - 1) {
      return ValidationResult.failure(
        'The file "$trimmedName" has no extension. Supported formats: ${allowedExtensions.map((e) => e.toUpperCase()).join(', ')}.',
      );
    }

    final extension =
        trimmedName.substring(dotIndex + 1).toLowerCase().trim();
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult.failure(
        'Unsupported file type ".$extension". Please select a PDF, DOCX, or TXT file.',
      );
    }

    // 3. Size Validation
    if (size == null || size <= 0) {
      return ValidationResult.failure(
        'The selected file "$trimmedName" is empty (0 bytes).',
      );
    }

    if (size > maxSizeBytes) {
      final actualMb = (size / (1024 * 1024)).toStringAsFixed(1);
      return ValidationResult.failure(
        'File size ($actualMb MB) exceeds the maximum allowed limit of $formattedMaxSize.',
      );
    }

    // 4. MIME Type Validation (if provided)
    if (mimeType != null && mimeType.isNotEmpty) {
      final expectedMimes = AppConstants.extensionMimeTypes[extension];
      if (expectedMimes != null && !expectedMimes.contains(mimeType.toLowerCase())) {
        // Warning: Some Android providers report application/octet-stream for docx/txt
        // Only reject if completely incompatible (e.g. image/jpeg for .pdf)
        if (mimeType.startsWith('image/') ||
            mimeType.startsWith('video/') ||
            mimeType.startsWith('audio/')) {
          return ValidationResult.failure(
            'MIME type mismatch: "$trimmedName" claims to be .$extension but has media MIME type "$mimeType".',
          );
        }
      }
    }

    // 5. Magic Byte Inspection (Content Sniffing)
    if (path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final headerResult = await _validateMagicBytes(file, extension);
          if (!headerResult.isValid) {
            return headerResult;
          }
        }
      } catch (_) {
        // If file system access fails (e.g. content URI on scoped storage),
        // extension and size validation are sufficient.
      }
    }

    return ValidationResult.success();
  }

  /// Inspects magic bytes to prevent renamed malicious or corrupted files
  Future<ValidationResult> _validateMagicBytes(
      File file, String extension) async {
    try {
      final raf = await file.open(mode: FileMode.read);
      try {
        final buffer = List<int>.filled(8, 0);
        final bytesRead = await raf.readInto(buffer, 0, 8);
        if (bytesRead < 4) {
          return ValidationResult.failure(
            'File is too small or truncated to be a valid $extension file.',
          );
        }

        if (extension == 'pdf') {
          // PDF magic bytes: "%PDF-" -> [0x25, 0x50, 0x44, 0x46, 0x2D]
          final isPdf = buffer[0] == 0x25 &&
              buffer[1] == 0x50 &&
              buffer[2] == 0x44 &&
              buffer[3] == 0x46;
          if (!isPdf) {
            return ValidationResult.failure(
              'Invalid PDF format: file header does not match standard PDF specification.',
            );
          }
        } else if (extension == 'docx') {
          // DOCX is a zip container starting with "PK\x03\x04" -> [0x50, 0x4B, 0x03, 0x04]
          final isZip = buffer[0] == 0x50 &&
              buffer[1] == 0x4B &&
              buffer[2] == 0x03 &&
              buffer[3] == 0x04;
          if (!isZip) {
            return ValidationResult.failure(
              'Invalid DOCX format: file is not a valid OpenXML document package.',
            );
          }
        } else if (extension == 'txt') {
          // TXT should not contain binary null characters (0x00) in the header
          final hasNull = buffer.sublist(0, bytesRead).contains(0x00);
          if (hasNull) {
            return ValidationResult.failure(
              'Invalid text format: binary control characters detected in plain text file.',
            );
          }
        }
      } finally {
        await raf.close();
      }
    } catch (_) {
      // In case of read permission issues, pass soft-validation
    }

    return ValidationResult.success();
  }
}

