import '../entities/document.dart';
import '../repositories/document_repository.dart';

class GetDocumentsUseCase {
  final DocumentRepository repository;

  const GetDocumentsUseCase(this.repository);

  Future<List<Document>> call() {
    return repository.getDocuments();
  }
}

