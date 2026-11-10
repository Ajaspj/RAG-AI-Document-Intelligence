import '../repositories/document_repository.dart';

class DeleteDocumentUseCase {
  final DocumentRepository repository;

  const DeleteDocumentUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteDocument(id);
  }
}

