import 'package:equatable/equatable.dart';

import '../../domain/entities/document.dart';
import '../../domain/entities/selected_file.dart';

abstract class DocumentsEvent extends Equatable {
  const DocumentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocuments extends DocumentsEvent {
  const LoadDocuments();
}

class RefreshDocuments extends DocumentsEvent {
  const RefreshDocuments();
}

class PickDocumentRequested extends DocumentsEvent {
  const PickDocumentRequested();
}

class ClearSelectedDocument extends DocumentsEvent {
  const ClearSelectedDocument();
}

class UploadDocumentRequested extends DocumentsEvent {
  final SelectedFile? file;

  const UploadDocumentRequested({this.file});

  @override
  List<Object?> get props => [file];
}

class CancelUploadRequested extends DocumentsEvent {
  const CancelUploadRequested();
}

class UploadProgressUpdated extends DocumentsEvent {
  final double progress;
  final int bytesSent;
  final int totalBytes;

  const UploadProgressUpdated({
    required this.progress,
    required this.bytesSent,
    required this.totalBytes,
  });

  @override
  List<Object?> get props => [progress, bytesSent, totalBytes];
}

class DeleteDocumentRequested extends DocumentsEvent {
  final String documentId;

  const DeleteDocumentRequested(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

class RetryUploadRequested extends DocumentsEvent {
  final Document document;

  const RetryUploadRequested(this.document);

  @override
  List<Object?> get props => [document];
}

class SearchQueryChanged extends DocumentsEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterTypeChanged extends DocumentsEvent {
  final String filter;

  const FilterTypeChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

