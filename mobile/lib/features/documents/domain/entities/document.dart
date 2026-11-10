import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class Document extends Equatable {
  final String id;
  final String filename;
  final String originalFilename;
  final String fileExtension;
  final int fileSize;
  final String mimeType;
  final DocumentStatus status;
  final DateTime uploadedAt;
  final DateTime? updatedAt;
  final double processingProgress;
  final String? errorMessage;

  const Document({
    required this.id,
    required this.filename,
    required this.originalFilename,
    required this.fileExtension,
    required this.fileSize,
    required this.mimeType,
    required this.status,
    required this.uploadedAt,
    this.updatedAt,
    this.processingProgress = 0.0,
    this.errorMessage,
  });

  bool get isCompleted => status == DocumentStatus.completed;
  bool get isFailed => status == DocumentStatus.failed;
  bool get isProcessing => status == DocumentStatus.processing;
  bool get isUploading => status == DocumentStatus.uploading;
  bool get isPending => status == DocumentStatus.pending;
  bool get canRetry => status == DocumentStatus.failed;

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedUploadedAt {
    final now = DateTime.now();
    final diff = now.difference(uploadedAt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${uploadedAt.year}-${uploadedAt.month.toString().padLeft(2, '0')}-${uploadedAt.day.toString().padLeft(2, '0')}';
    }
  }

  Document copyWith({
    String? id,
    String? filename,
    String? originalFilename,
    String? fileExtension,
    int? fileSize,
    String? mimeType,
    DocumentStatus? status,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    double? processingProgress,
    String? errorMessage,
  }) {
    return Document(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      originalFilename: originalFilename ?? this.originalFilename,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processingProgress: processingProgress ?? this.processingProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        filename,
        originalFilename,
        fileExtension,
        fileSize,
        mimeType,
        status,
        uploadedAt,
        updatedAt,
        processingProgress,
        errorMessage,
      ];
}

