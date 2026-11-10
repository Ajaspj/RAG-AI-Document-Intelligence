import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversationModel>> getConversations({int skip = 0, int limit = 20});
  Future<ConversationModel> createConversation({String? title, List<String>? documentIds});
  Future<List<ChatMessageModel>> getMessages(String conversationId);
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String content,
    List<String>? documentIds,
  });
  Future<ChatMessageModel> quickChat({
    required String content,
    String? title,
    List<String>? documentIds,
  });
  Future<void> deleteConversation(String conversationId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  const ChatRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<ConversationModel>> getConversations({int skip = 0, int limit = 20}) async {
    try {
      final response = await apiClient.client.get(
        '/conversations',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['items'] is List) {
          return (data['items'] as List)
              .map((item) => ConversationModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          return data
              .map((item) => ConversationModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw NetworkExceptions.fromStatusCode(response.statusCode ?? 500, response.data);
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
  Future<ConversationModel> createConversation({String? title, List<String>? documentIds}) async {
    try {
      final response = await apiClient.client.post(
        '/conversations',
        data: {
          if (title != null) 'title': title,
          if (documentIds != null) 'document_ids': documentIds,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ConversationModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw NetworkExceptions.fromStatusCode(response.statusCode ?? 500, response.data);
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
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    try {
      final response = await apiClient.client.get('/conversations/$conversationId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['messages'] is List) {
          return (data['messages'] as List)
              .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw NetworkExceptions.fromStatusCode(response.statusCode ?? 500, response.data);
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
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String content,
    List<String>? documentIds,
  }) async {
    try {
      final response = await apiClient.client.post(
        '/conversations/$conversationId/messages',
        data: {
          'content': content,
          if (documentIds != null) 'document_ids': documentIds,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final assistantData = data['assistant_message'] as Map<String, dynamic>;
        return ChatMessageModel.fromJson(assistantData);
      } else {
        throw NetworkExceptions.fromStatusCode(response.statusCode ?? 500, response.data);
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
  Future<ChatMessageModel> quickChat({
    required String content,
    String? title,
    List<String>? documentIds,
  }) async {
    try {
      final response = await apiClient.client.post(
        '/conversations/quick-chat',
        data: {
          'content': content,
          if (title != null) 'title': title,
          if (documentIds != null) 'document_ids': documentIds,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final assistantData = data['assistant_message'] as Map<String, dynamic>;
        return ChatMessageModel.fromJson(assistantData);
      } else {
        throw NetworkExceptions.fromStatusCode(response.statusCode ?? 500, response.data);
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
  Future<void> deleteConversation(String conversationId) async {
    try {
      final response = await apiClient.client.delete('/conversations/$conversationId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw NetworkExceptions.fromStatusCode(response.statusCode ?? 500, response.data);
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

