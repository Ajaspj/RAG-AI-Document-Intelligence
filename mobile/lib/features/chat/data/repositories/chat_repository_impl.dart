import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  const ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Conversation>> getConversations({
    int skip = 0,
    int limit = 20,
    String? search,
    bool isArchived = false,
  }) {
    return remoteDataSource.getConversations(
      skip: skip,
      limit: limit,
      search: search,
      isArchived: isArchived,
    );
  }

  @override
  Future<Conversation> createConversation({String? title, List<String>? documentIds}) {
    return remoteDataSource.createConversation(title: title, documentIds: documentIds);
  }

  @override
  Future<Conversation> updateConversation(
    String conversationId, {
    String? title,
    bool? isArchived,
  }) {
    return remoteDataSource.updateConversation(
      conversationId,
      title: title,
      isArchived: isArchived,
    );
  }

  @override
  Future<void> archiveConversation(String conversationId) {
    return remoteDataSource.archiveConversation(conversationId);
  }

  @override
  Future<void> restoreConversation(String conversationId) {
    return remoteDataSource.restoreConversation(conversationId);
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId, {int limit = 50, String? before}) {
    return remoteDataSource.getMessages(conversationId, limit: limit, before: before);
  }

  @override
  Future<List<ChatMessage>> getOlderMessages(
    String conversationId, {
    required String before,
    int limit = 30,
  }) {
    return remoteDataSource.getOlderMessages(conversationId, before: before, limit: limit);
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    List<String>? documentIds,
  }) {
    return remoteDataSource.sendMessage(
      conversationId: conversationId,
      content: content,
      documentIds: documentIds,
    );
  }

  @override
  Future<ChatMessage> quickChat({
    required String content,
    String? title,
    List<String>? documentIds,
  }) {
    return remoteDataSource.quickChat(
      content: content,
      title: title,
      documentIds: documentIds,
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) {
    return remoteDataSource.deleteConversation(conversationId);
  }
}

