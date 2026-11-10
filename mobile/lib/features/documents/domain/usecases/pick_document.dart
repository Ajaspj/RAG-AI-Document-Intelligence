import '../entities/selected_file.dart';
import '../repositories/document_repository.dart';

class PickDocumentUseCase {
  final DocumentRepository repository;

  const PickDocumentUseCase(this.repository);

  Future<SelectedFile?> call() {
    return repository.pickDocument();
  }
}

