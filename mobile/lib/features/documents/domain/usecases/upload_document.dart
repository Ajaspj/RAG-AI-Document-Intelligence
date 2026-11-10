import '../entities/document.dart';
import '../entities/selected_file.dart';
import '../repositories/document_repository.dart';

class UploadDocumentUseCase {
  final DocumentRepository repository;

  const UploadDocumentUseCase(this.repository);

  Future<Document> call(
    SelectedFile file, {
    void Function(int sent, int total)? onProgress,
  }) {
    return repository.uploadDocument(file, onProgress: onProgress);
  }

  void cancel() {
    repository.cancelUpload();
  }
}

