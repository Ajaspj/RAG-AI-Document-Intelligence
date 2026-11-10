import '../../domain/entities/chat_message.dart';
import 'citation_model.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.role,
    required super.content,
    super.citations = const [],
    required super.createdAt,
    super.isSending = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final citationsRaw = json['citations'] as List<dynamic>? ?? [];
    final citations = citationsRaw
        .map((c) => CitationModel.fromJson(c as Map<String, dynamic>))
        .toList();

    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? json['conversationId'] as String? ?? '',
      role: MessageRole.fromString(json['role'] as String? ?? 'assistant'),
      content: json['content'] as String? ?? '',
      citations: citations,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role.name,
      'content': content,
      'citations': (citations as List<CitationModel>).map((c) => c.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

