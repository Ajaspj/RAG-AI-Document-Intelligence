import '../entities/document.dart';
import '../repositories/document_repository.dart';

class RetryUploadUseCase {
  final DocumentRepository repository;

  const RetryUploadUseCase(this.repository);

  Future<Document> call(Document document) {
    return repository.retryUpload(document);
  }
}

