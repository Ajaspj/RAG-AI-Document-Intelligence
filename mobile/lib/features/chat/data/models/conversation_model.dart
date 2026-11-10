import '../../domain/entities/conversation.dart';
import 'chat_message_model.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.userId,
    required super.title,
    super.documentIds = const [],
    required super.createdAt,
    required super.updatedAt,
    super.messageCount = 0,
    super.latestMessage,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final docIdsRaw = json['document_ids'] as List<dynamic>? ?? json['documentIds'] as List<dynamic>? ?? [];
    final docIds = docIdsRaw.map((e) => e.toString()).toList();

    ChatMessageModel? latest;
    if (json['latest_message'] is Map<String, dynamic>) {
      latest = ChatMessageModel.fromJson(json['latest_message'] as Map<String, dynamic>);
    } else if (json['latestMessage'] is Map<String, dynamic>) {
      latest = ChatMessageModel.fromJson(json['latestMessage'] as Map<String, dynamic>);
    }

    return ConversationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      title: json['title'] as String? ?? 'New Conversation',
      documentIds: docIds,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : (json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
              : DateTime.now()),
      messageCount: json['message_count'] as int? ?? json['messageCount'] as int? ?? 0,
      latestMessage: latest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'document_ids': documentIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'message_count': messageCount,
    };
  }
}

