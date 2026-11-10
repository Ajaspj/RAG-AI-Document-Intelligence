import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/entities/selected_file.dart';
import '../models/document_model.dart';

abstract class DocumentRemoteDataSource {
  Future<DocumentModel> uploadDocument(
    SelectedFile file, {
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  });

  Future<List<DocumentModel>> getDocuments();

  Future<DocumentModel> getDocumentById(String id);

  Future<void> deleteDocument(String id);
}

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  final ApiClient apiClient;

  const DocumentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<DocumentModel> uploadDocument(
    SelectedFile file, {
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // MultipartFile.fromFile streams directly from file path without loading whole file to RAM
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await apiClient.client.post(
        '/documents/upload',
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DocumentModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw NetworkExceptions.fromStatusCode(
          response.statusCode ?? 500,
          response.data,
        );
      }
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioException(e);
    } catch (e) {
      if (e is! Exception) {
        throw NetworkExceptions.defaultError(e.toString());
      }
      rethrow;
    }
  }

  @override
  Future<List<DocumentModel>> getDocuments() async {
    try {
      final response = await apiClient.client.get('/documents');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        if (data is List) {
          return data
              .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        if (data is Map<String, dynamic> && data['items'] is List) {
          return (data['items'] as List)
              .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return <DocumentModel>[];
      } else {
        throw NetworkExceptions.fromStatusCode(
          response.statusCode ?? 500,
          response.data,
        );
      }
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioException(e);
    } catch (e) {
      if (e is! Exception) {
        throw NetworkExceptions.defaultError(e.toString());
      }
      rethrow;
    }
  }

  @override
  Future<DocumentModel> getDocumentById(String id) async {
    try {
      final response = await apiClient.client.get('/documents/$id');

      if (response.statusCode == 200) {
        return DocumentModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw NetworkExceptions.fromStatusCode(
          response.statusCode ?? 500,
          response.data,
        );
      }
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioException(e);
    } catch (e) {
      if (e is! Exception) {
        throw NetworkExceptions.defaultError(e.toString());
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      final response = await apiClient.client.delete('/documents/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw NetworkExceptions.fromStatusCode(
          response.statusCode ?? 500,
          response.data,
        );
      }
    } on DioException catch (e) {
      throw NetworkExceptions.fromDioException(e);
    } catch (e) {
      if (e is! Exception) {
        throw NetworkExceptions.defaultError(e.toString());
      }
      rethrow;
    }
  }
}
