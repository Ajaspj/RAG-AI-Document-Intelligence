import '../entities/chat_message.dart';
import '../entities/conversation.dart';

abstract class ChatRepository {
  Future<List<Conversation>> getConversations({int skip = 0, int limit = 20});
  Future<Conversation> createConversation({String? title, List<String>? documentIds});
  Future<List<ChatMessage>> getMessages(String conversationId);
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

