import 'package:equatable/equatable.dart';

import '../../domain/entities/document.dart';
import '../../domain/entities/selected_file.dart';

enum DocumentsStatus { initial, loading, success, failure }

enum UploadStatus { idle, selecting, uploading, success, failure, cancelled }

class DocumentsState extends Equatable {
  final DocumentsStatus status;
  final List<Document> documents;
  final List<Document> filteredDocuments;
  final SelectedFile? selectedFile;
  final UploadStatus uploadStatus;
  final double uploadProgress;
  final int bytesSent;
  final int totalBytes;
  final String searchQuery;
  final String selectedFilter;
  final String? errorMessage;
  final String? uploadErrorMessage;
  final Document? uploadingDocument;

  const DocumentsState({
    this.status = DocumentsStatus.initial,
    this.documents = const [],
    this.filteredDocuments = const [],
    this.selectedFile,
    this.uploadStatus = UploadStatus.idle,
    this.uploadProgress = 0.0,
    this.bytesSent = 0,
    this.totalBytes = 0,
    this.searchQuery = '',
    this.selectedFilter = 'All',
    this.errorMessage,
    this.uploadErrorMessage,
    this.uploadingDocument,
  });

  bool get isLoading => status == DocumentsStatus.loading;
  bool get isUploading => uploadStatus == UploadStatus.uploading;
  bool get hasSelectedFile => selectedFile != null;
  int get totalCount => documents.length;
  int get filteredCount => filteredDocuments.length;

  int get completedCount =>
      documents.where((d) => d.isCompleted).length;
  int get processingCount =>
      documents.where((d) => d.isProcessing || d.isUploading).length;
  int get failedCount => documents.where((d) => d.isFailed).length;

  DocumentsState copyWith({
    DocumentsStatus? status,
    List<Document>? documents,
    List<Document>? filteredDocuments,
    SelectedFile? selectedFile,
    bool clearSelectedFile = false,
    UploadStatus? uploadStatus,
    double? uploadProgress,
    int? bytesSent,
    int? totalBytes,
    String? searchQuery,
    String? selectedFilter,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? uploadErrorMessage,
    bool clearUploadErrorMessage = false,
    Document? uploadingDocument,
    bool clearUploadingDocument = false,
  }) {
    return DocumentsState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      filteredDocuments: filteredDocuments ?? this.filteredDocuments,
      selectedFile:
          clearSelectedFile ? null : (selectedFile ?? this.selectedFile),
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      bytesSent: bytesSent ?? this.bytesSent,
      totalBytes: totalBytes ?? this.totalBytes,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      uploadErrorMessage: clearUploadErrorMessage
          ? null
          : (uploadErrorMessage ?? this.uploadErrorMessage),
      uploadingDocument: clearUploadingDocument
          ? null
          : (uploadingDocument ?? this.uploadingDocument),
    );
  }

  @override
  List<Object?> get props => [
        status,
        documents,
        filteredDocuments,
        selectedFile,
        uploadStatus,
        uploadProgress,
        bytesSent,
        totalBytes,
        searchQuery,
        selectedFilter,
        errorMessage,
        uploadErrorMessage,
        uploadingDocument,
      ];
}

