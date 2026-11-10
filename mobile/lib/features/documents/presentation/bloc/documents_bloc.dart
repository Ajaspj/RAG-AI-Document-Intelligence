import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/document_model.dart';
import '../../domain/entities/document.dart';
import '../../domain/usecases/delete_document.dart';
import '../../domain/usecases/get_documents.dart';
import '../../domain/usecases/pick_document.dart';
import '../../domain/usecases/retry_upload.dart';
import '../../domain/usecases/upload_document.dart';
import 'documents_event.dart';
import 'documents_state.dart';

class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  final GetDocumentsUseCase getDocumentsUseCase;
  final PickDocumentUseCase pickDocumentUseCase;
  final UploadDocumentUseCase uploadDocumentUseCase;
  final DeleteDocumentUseCase deleteDocumentUseCase;
  final RetryUploadUseCase retryUploadUseCase;

  DocumentsBloc({
    required this.getDocumentsUseCase,
    required this.pickDocumentUseCase,
    required this.uploadDocumentUseCase,
    required this.deleteDocumentUseCase,
    required this.retryUploadUseCase,
  }) : super(const DocumentsState()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<RefreshDocuments>(_onRefreshDocuments);
    on<PickDocumentRequested>(_onPickDocumentRequested);
    on<ClearSelectedDocument>(_onClearSelectedDocument);
    on<UploadDocumentRequested>(_onUploadDocumentRequested);
    on<CancelUploadRequested>(_onCancelUploadRequested);
    on<UploadProgressUpdated>(_onUploadProgressUpdated);
    on<DeleteDocumentRequested>(_onDeleteDocumentRequested);
    on<RetryUploadRequested>(_onRetryUploadRequested);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<FilterTypeChanged>(_onFilterTypeChanged);
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentsState> emit,
  ) async {
    emit(state.copyWith(status: DocumentsStatus.loading, clearErrorMessage: true));
    try {
      final docs = await getDocumentsUseCase();
      final filtered = _filterDocuments(docs, state.searchQuery, state.selectedFilter);
      emit(state.copyWith(
        status: DocumentsStatus.success,
        documents: docs,
        filteredDocuments: filtered,
      ));
    } on Failure catch (e) {
      emit(state.copyWith(
        status: DocumentsStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshDocuments(
    RefreshDocuments event,
    Emitter<DocumentsState> emit,
  ) async {
    try {
      final docs = await getDocumentsUseCase();
      final filtered = _filterDocuments(docs, state.searchQuery, state.selectedFilter);
      emit(state.copyWith(
        status: DocumentsStatus.success,
        documents: docs,
        filteredDocuments: filtered,
      ));
    } catch (_) {
      // Retain current state on pull-to-refresh network error
    }
  }

  Future<void> _onPickDocumentRequested(
    PickDocumentRequested event,
    Emitter<DocumentsState> emit,
  ) async {
    try {
      final file = await pickDocumentUseCase();
      if (file != null) {
        // Check for duplicate in currently loaded documents
        final isDuplicate = state.documents.any(
          (doc) => doc.filename.toLowerCase() == file.name.toLowerCase() &&
              doc.fileSize == file.size,
        );

        if (isDuplicate) {
          emit(state.copyWith(
            selectedFile: file,
            uploadStatus: UploadStatus.idle,
            uploadErrorMessage:
                'Notice: A document with this filename and size is already uploaded.',
          ));
        } else {
          emit(state.copyWith(
            selectedFile: file,
            uploadStatus: UploadStatus.idle,
            clearUploadErrorMessage: true,
          ));
        }
      }
    } on Failure catch (e) {
      emit(state.copyWith(
        uploadStatus: UploadStatus.failure,
        uploadErrorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        uploadStatus: UploadStatus.failure,
        uploadErrorMessage: e.toString(),
      ));
    }
  }

  void _onClearSelectedDocument(
    ClearSelectedDocument event,
    Emitter<DocumentsState> emit,
  ) {
    emit(state.copyWith(
      clearSelectedFile: true,
      uploadStatus: UploadStatus.idle,
      uploadProgress: 0.0,
      clearUploadErrorMessage: true,
      clearUploadingDocument: true,
    ));
  }

  Future<void> _onUploadDocumentRequested(
    UploadDocumentRequested event,
    Emitter<DocumentsState> emit,
  ) async {
    final file = event.file ?? state.selectedFile;
    if (file == null) {
      emit(state.copyWith(
        uploadStatus: UploadStatus.failure,
        uploadErrorMessage: 'No document selected for upload.',
      ));
      return;
    }

    if (state.isUploading) return;

    final tempDoc = DocumentModel.fromSelectedFile(file);

    emit(state.copyWith(
      uploadStatus: UploadStatus.uploading,
      uploadProgress: 0.0,
      bytesSent: 0,
      totalBytes: file.size,
      uploadingDocument: tempDoc,
      clearUploadErrorMessage: true,
    ));

    try {
      final uploadedDoc = await uploadDocumentUseCase(
        file,
        onProgress: (sent, total) {
          if (!isClosed) {
            add(UploadProgressUpdated(
              progress: total > 0 ? sent / total : 0.0,
              bytesSent: sent,
              totalBytes: total,
            ));
          }
        },
      );

      final updatedDocs = [uploadedDoc, ...state.documents];
      final filtered = _filterDocuments(
        updatedDocs,
        state.searchQuery,
        state.selectedFilter,
      );

      emit(state.copyWith(
        status: DocumentsStatus.success,
        documents: updatedDocs,
        filteredDocuments: filtered,
        uploadStatus: UploadStatus.success,
        uploadProgress: 1.0,
        clearSelectedFile: true,
        clearUploadingDocument: true,
      ));
    } on Failure catch (e) {
      emit(state.copyWith(
        uploadStatus: UploadStatus.failure,
        uploadErrorMessage: e.message,
        clearUploadingDocument: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        uploadStatus: UploadStatus.failure,
        uploadErrorMessage: e.toString(),
      ));
    }
  }

  void _onCancelUploadRequested(
    CancelUploadRequested event,
    Emitter<DocumentsState> emit,
  ) {
    uploadDocumentUseCase.cancel();
    emit(state.copyWith(
      uploadStatus: UploadStatus.cancelled,
      uploadProgress: 0.0,
      clearUploadingDocument: true,
      uploadErrorMessage: 'Upload cancelled.',
    ));
  }

  void _onUploadProgressUpdated(
    UploadProgressUpdated event,
    Emitter<DocumentsState> emit,
  ) {
    if (state.isUploading) {
      emit(state.copyWith(
        uploadProgress: event.progress,
        bytesSent: event.bytesSent,
        totalBytes: event.totalBytes,
      ));
    }
  }

  Future<void> _onDeleteDocumentRequested(
    DeleteDocumentRequested event,
    Emitter<DocumentsState> emit,
  ) async {
    final originalDocs = state.documents;
    // Optimistically remove from list
    final updatedDocs = originalDocs.where((d) => d.id != event.documentId).toList();
    final filtered = _filterDocuments(
      updatedDocs,
      state.searchQuery,
      state.selectedFilter,
    );

    emit(state.copyWith(
      documents: updatedDocs,
      filteredDocuments: filtered,
    ));

    try {
      await deleteDocumentUseCase(event.documentId);
    } on Failure catch (e) {
      // Revert if deletion failed
      final revertedFiltered = _filterDocuments(
        originalDocs,
        state.searchQuery,
        state.selectedFilter,
      );
      emit(state.copyWith(
        documents: originalDocs,
        filteredDocuments: revertedFiltered,
        errorMessage: 'Failed to delete document: ${e.message}',
      ));
    } catch (e) {
      final revertedFiltered = _filterDocuments(
        originalDocs,
        state.searchQuery,
        state.selectedFilter,
      );
      emit(state.copyWith(
        documents: originalDocs,
        filteredDocuments: revertedFiltered,
        errorMessage: 'Failed to delete document: $e',
      ));
    }
  }

  Future<void> _onRetryUploadRequested(
    RetryUploadRequested event,
    Emitter<DocumentsState> emit,
  ) async {
    emit(state.copyWith(
      uploadStatus: UploadStatus.uploading,
      clearUploadErrorMessage: true,
    ));

    try {
      final retriedDoc = await retryUploadUseCase(event.document);
      final updatedDocs = state.documents.map((d) {
        return d.id == event.document.id ? retriedDoc : d;
      }).toList();

      final filtered = _filterDocuments(
        updatedDocs,
        state.searchQuery,
        state.selectedFilter,
      );

      emit(state.copyWith(
        documents: updatedDocs,
        filteredDocuments: filtered,
        uploadStatus: UploadStatus.success,
      ));
    } on Failure catch (e) {
      emit(state.copyWith(
        uploadStatus: UploadStatus.failure,
        uploadErrorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        uploadStatus: UploadStatus.failure,
        uploadErrorMessage: e.toString(),
      ));
    }
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<DocumentsState> emit,
  ) {
    final filtered = _filterDocuments(
      state.documents,
      event.query,
      state.selectedFilter,
    );
    emit(state.copyWith(
      searchQuery: event.query,
      filteredDocuments: filtered,
    ));
  }

  void _onFilterTypeChanged(
    FilterTypeChanged event,
    Emitter<DocumentsState> emit,
  ) {
    final filtered = _filterDocuments(
      state.documents,
      state.searchQuery,
      event.filter,
    );
    emit(state.copyWith(
      selectedFilter: event.filter,
      filteredDocuments: filtered,
    ));
  }

  List<Document> _filterDocuments(
    List<Document> source,
    String query,
    String filter,
  ) {
    return source.where((doc) {
      // 1. Search Query Filter
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesName = doc.filename.toLowerCase().contains(q) ||
            doc.originalFilename.toLowerCase().contains(q);
        if (!matchesName) return false;
      }

      // 2. Category / Status Filter
      switch (filter.toLowerCase()) {
        case 'pdf':
          return doc.fileExtension == 'pdf';
        case 'docx':
          return doc.fileExtension == 'docx';
        case 'txt':
          return doc.fileExtension == 'txt';
        case 'processing':
          return doc.isProcessing || doc.isUploading;
        case 'completed':
          return doc.isCompleted;
        case 'failed':
          return doc.isFailed;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }
}

