import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/selected_file.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/utils/document_validator.dart';
import '../datasources/document_remote_data_source.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource remoteDataSource;
  final DocumentValidator validator;
  CancelToken? _cancelToken;

  // Cache for local retry capability
  final Map<String, SelectedFile> _localFileCache = {};

  DocumentRepositoryImpl({
    required this.remoteDataSource,
    this.validator = const DocumentValidator(),
  });

  @override
  Future<SelectedFile?> pickDocument() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: validator.allowedExtensions,
      );

      if (files.isEmpty) {
        return null;
      }

      final platformFile = files.first;
      final path = platformFile.path;
      final name = platformFile.name;
      final size = platformFile.lengthSync() ??
          (path != null ? await File(path).length() : 0);

      // Validate the picked file
      final validation = await validator.validateFile(
        path: path,
        name: name,
        size: size,
      );

      if (!validation.isValid) {
        throw ValidationFailure(
          validation.errorMessage ?? 'Selected document failed validation.',
        );
      }

      if (path == null) {
        throw const ValidationFailure(
          'Could not retrieve a valid file path from the document picker.',
        );
      }

      final ext = name.contains('.')
          ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
          : '';

      return SelectedFile(
        path: path,
        name: name,
        size: size,
        extension: ext,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      if (e is! Failure) {
        throw ValidationFailure(
          'Failed to pick document: ${e.toString()}',
        );
      }
      rethrow;
    }
  }

  @override
  Future<Document> uploadDocument(
    SelectedFile file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      _cancelToken = CancelToken();

      // Ensure file exists before uploading
      final localFile = File(file.path);
      if (!await localFile.exists()) {
        throw const ValidationFailure(
          'The selected file no longer exists at the specified device path.',
        );
      }

      final uploadedDoc = await remoteDataSource.uploadDocument(
        file,
        onSendProgress: onProgress,
        cancelToken: _cancelToken,
      );

      // Cache file path with document ID for retry capability
      _localFileCache[uploadedDoc.id] = file;

      return uploadedDoc;
    } on Failure {
      rethrow;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        throw const ServerFailure('Upload cancelled by user.');
      }
      if (e is! Failure) {
        throw ServerFailure(e.toString());
      }
      rethrow;
    } finally {
      _cancelToken = null;
    }
  }

  @override
  void cancelUpload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User cancelled document upload.');
    }
  }

  @override
  Future<List<Document>> getDocuments() async {
    try {
      return await remoteDataSource.getDocuments();
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<Document> getDocumentById(String id) async {
    try {
      return await remoteDataSource.getDocumentById(id);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      await remoteDataSource.deleteDocument(id);
      _localFileCache.remove(id);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<Document> retryUpload(Document document) async {
    final cachedFile = _localFileCache[document.id];
    if (cachedFile != null) {
      return uploadDocument(cachedFile);
    }

    // If local file path was lost, create a SelectedFile from available path or prompt
    throw const ServerFailure(
      'Cached file reference expired. Please re-select the document to retry.',
    );
  }
}
