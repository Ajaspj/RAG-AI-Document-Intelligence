import 'package:equatable/equatable.dart';
import 'chat_message.dart';

class Conversation extends Equatable {
  final String id;
  final String userId;
  final String title;
  final List<String> documentIds;
  final bool isArchived;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final ChatMessage? latestMessage;

  const Conversation({
    required this.id,
    required this.userId,
    required this.title,
    this.documentIds = const [],
    this.isArchived = false,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.latestMessage,
  });

  Conversation copyWith({
    String? id,
    String? userId,
    String? title,
    List<String>? documentIds,
    bool? isArchived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    ChatMessage? latestMessage,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      documentIds: documentIds ?? this.documentIds,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      latestMessage: latestMessage ?? this.latestMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        documentIds,
        isArchived,
        archivedAt,
        createdAt,
        updatedAt,
        messageCount,
        latestMessage,
      ];
}

