import 'package:equatable/equatable.dart';
import 'chat_message.dart';

class Conversation extends Equatable {
  final String id;
  final String userId;
  final String title;
  final List<String> documentIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final ChatMessage? latestMessage;

  const Conversation({
    required this.id,
    required this.userId,
    required this.title,
    this.documentIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.latestMessage,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        documentIds,
        createdAt,
        updatedAt,
        messageCount,
        latestMessage,
      ];
}

