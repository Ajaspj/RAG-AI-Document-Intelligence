import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/selected_file.dart';

class DocumentModel extends Document {
  const DocumentModel({
    required super.id,
    required super.filename,
    required super.originalFilename,
    required super.fileExtension,
    required super.fileSize,
    required super.mimeType,
    required super.status,
    required super.uploadedAt,
    super.updatedAt,
    super.processingProgress = 0.0,
    super.errorMessage,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      originalFilename: json['original_filename'] as String? ??
          json['originalFilename'] as String? ??
          json['filename'] as String? ??
          '',
      fileExtension: (json['file_extension'] as String? ??
              json['fileExtension'] as String? ??
              '')
          .toLowerCase()
          .replaceAll('.', ''),
      fileSize: json['file_size'] as int? ?? json['fileSize'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ??
          json['mimeType'] as String? ??
          'application/octet-stream',
      status: DocumentStatus.fromString(json['status'] as String?),
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'] as String) ?? DateTime.now()
          : (json['uploadedAt'] != null
              ? DateTime.tryParse(json['uploadedAt'] as String) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : (json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'] as String)
              : null),
      processingProgress: (json['processing_progress'] as num? ??
              json['processingProgress'] as num? ??
              0.0)
          .toDouble(),
      errorMessage: json['error_message'] as String? ?? json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'original_filename': originalFilename,
      'file_extension': fileExtension,
      'file_size': fileSize,
      'mime_type': mimeType,
      'status': status.name,
      'uploaded_at': uploadedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'processing_progress': processingProgress,
      'error_message': errorMessage,
    };
  }

  factory DocumentModel.fromSelectedFile(
    SelectedFile file, {
    String? id,
    DocumentStatus status = DocumentStatus.uploading,
    double progress = 0.0,
  }) {
    return DocumentModel(
      id: id ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
      filename: file.name,
      originalFilename: file.name,
      fileExtension: file.extension,
      fileSize: file.size,
      mimeType: file.mimeType ?? 'application/octet-stream',
      status: status,
      uploadedAt: DateTime.now(),
      processingProgress: progress,
    );
  }
}

