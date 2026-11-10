import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  const ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Conversation>> getConversations({int skip = 0, int limit = 20}) {
    return remoteDataSource.getConversations(skip: skip, limit: limit);
  }

  @override
  Future<Conversation> createConversation({String? title, List<String>? documentIds}) {
    return remoteDataSource.createConversation(title: title, documentIds: documentIds);
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) {
    return remoteDataSource.getMessages(conversationId);
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

