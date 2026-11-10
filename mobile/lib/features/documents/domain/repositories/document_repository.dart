import '../entities/document.dart';
import '../entities/selected_file.dart';

abstract class DocumentRepository {
  /// Launches the system document picker and validates the selected file
  Future<SelectedFile?> pickDocument();

  /// Uploads a selected document to the server with real-time progress callbacks
  Future<Document> uploadDocument(
    SelectedFile file, {
    void Function(int sent, int total)? onProgress,
  });

  /// Cancels an in-flight document upload
  void cancelUpload();

  /// Fetches all documents owned by the authenticated user
  Future<List<Document>> getDocuments();

  /// Fetches details for a specific document
  Future<Document> getDocumentById(String id);

  /// Deletes a document by ID
  Future<void> deleteDocument(String id);

  /// Retries a previously failed document upload
  Future<Document> retryUpload(Document document);
}

