import '../entities/chat_message.dart';
import '../entities/conversation.dart';

abstract class ChatRepository {
  Future<List<Conversation>> getConversations({
    int skip = 0,
    int limit = 20,
    String? search,
    bool isArchived = false,
  });
  Future<Conversation> createConversation({String? title, List<String>? documentIds});
  Future<Conversation> updateConversation(
    String conversationId, {
    String? title,
    bool? isArchived,
  });
  Future<void> archiveConversation(String conversationId);
  Future<void> restoreConversation(String conversationId);
  Future<List<ChatMessage>> getMessages(String conversationId, {int limit = 50, String? before});
  Future<List<ChatMessage>> getOlderMessages(
    String conversationId, {
    required String before,
    int limit = 30,
  });
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    List<String>? documentIds,
  });
  Future<ChatMessage> quickChat({
    required String content,
    String? title,
    List<String>? documentIds,
  });
  Future<void> deleteConversation(String conversationId);
}

