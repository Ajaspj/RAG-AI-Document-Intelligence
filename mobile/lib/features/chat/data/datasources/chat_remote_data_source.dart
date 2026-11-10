import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversationModel>> getConversations({
    int skip = 0,
    int limit = 20,
    String? search,
    bool isArchived = false,
  });
  Future<ConversationModel> createConversation({String? title, List<String>? documentIds});
  Future<ConversationModel> updateConversation(
    String conversationId, {
    String? title,
    bool? isArchived,
  });
  Future<void> archiveConversation(String conversationId);
  Future<void> restoreConversation(String conversationId);
  Future<List<ChatMessageModel>> getMessages(String conversationId, {int limit = 50, String? before});
  Future<List<ChatMessageModel>> getOlderMessages(
    String conversationId, {
    required String before,
    int limit = 30,
  });
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
  Future<List<ConversationModel>> getConversations({
    int skip = 0,
    int limit = 20,
    String? search,
    bool isArchived = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        'is_archived': isArchived,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await apiClient.client.get(
        '/conversations',
        queryParameters: queryParams,
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
  Future<ConversationModel> updateConversation(
    String conversationId, {
    String? title,
    bool? isArchived,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title.trim();
      if (isArchived != null) body['is_archived'] = isArchived;

      final response = await apiClient.client.patch(
        '/conversations/$conversationId',
        data: body,
      );

      if (response.statusCode == 200) {
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
  Future<void> archiveConversation(String conversationId) async {
    try {
      final response = await apiClient.client.post(
        '/conversations/$conversationId/archive',
      );
      if (response.statusCode != 200) {
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
  Future<void> restoreConversation(String conversationId) async {
    try {
      final response = await apiClient.client.post(
        '/conversations/$conversationId/restore',
      );
      if (response.statusCode != 200) {
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
  Future<List<ChatMessageModel>> getMessages(String conversationId, {int limit = 50, String? before}) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (before != null) queryParams['before'] = before;

      final response = await apiClient.client.get(
        '/conversations/$conversationId',
        queryParameters: queryParams,
      );

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
  Future<List<ChatMessageModel>> getOlderMessages(
    String conversationId, {
    required String before,
    int limit = 30,
  }) async {
    try {
      final response = await apiClient.client.get(
        '/conversations/$conversationId/messages',
        queryParameters: {
          'limit': limit,
          'before': before,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['items'] is List) {
          return (data['items'] as List)
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

