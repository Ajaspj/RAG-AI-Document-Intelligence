import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';

enum ChatStatus {
  initial,
  loadingConversations,
  loadingMessages,
  loaded,
  sending,
  error,
}

class ChatState extends Equatable {
  final ChatStatus status;
  final List<Conversation> conversations;
  final Conversation? activeConversation;
  final List<ChatMessage> messages;
  final List<String> scopedDocumentIds;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.conversations = const [],
    this.activeConversation,
    this.messages = const [],
    this.scopedDocumentIds = const [],
    this.errorMessage,
  });

  bool get isLoading => status == ChatStatus.loadingConversations || status == ChatStatus.loadingMessages;
  bool get isSending => status == ChatStatus.sending;
  bool get hasActiveConversation => activeConversation != null;

  ChatState copyWith({
    ChatStatus? status,
    List<Conversation>? conversations,
    Conversation? activeConversation,
    bool clearActiveConversation = false,
    List<ChatMessage>? messages,
    List<String>? scopedDocumentIds,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      activeConversation: clearActiveConversation ? null : (activeConversation ?? this.activeConversation),
      messages: messages ?? this.messages,
      scopedDocumentIds: scopedDocumentIds ?? this.scopedDocumentIds,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        conversations,
        activeConversation,
        messages,
        scopedDocumentIds,
        errorMessage,
      ];
}

