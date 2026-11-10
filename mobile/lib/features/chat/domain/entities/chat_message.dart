import 'package:equatable/equatable.dart';
import 'citation.dart';

enum MessageRole {
  user,
  assistant;

  bool get isUser => this == MessageRole.user;
  bool get isAssistant => this == MessageRole.assistant;

  static MessageRole fromString(String role) {
    if (role.toLowerCase() == 'user') return MessageRole.user;
    return MessageRole.assistant;
  }
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final List<Citation> citations;
  final DateTime createdAt;
  final bool isSending;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.citations = const [],
    required this.createdAt,
    this.isSending = false,
  });

  bool get hasCitations => citations.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        conversationId,
        role,
        content,
        citations,
        createdAt,
        isSending,
      ];
}

