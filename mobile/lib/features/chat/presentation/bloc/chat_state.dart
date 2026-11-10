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
  final String? successMessage;
  final bool showArchived;
  final String searchQuery;
  final bool isLoadingOlderMessages;
  final bool hasMoreMessages;
  final String? nextCursor;

  const ChatState({
    this.status = ChatStatus.initial,
    this.conversations = const [],
    this.activeConversation,
    this.messages = const [],
    this.scopedDocumentIds = const [],
    this.errorMessage,
    this.successMessage,
    this.showArchived = false,
    this.searchQuery = '',
    this.isLoadingOlderMessages = false,
    this.hasMoreMessages = false,
    this.nextCursor,
  });

  bool get isLoading =>
      status == ChatStatus.loadingConversations || status == ChatStatus.loadingMessages;
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
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    bool? showArchived,
    String? searchQuery,
    bool? isLoadingOlderMessages,
    bool? hasMoreMessages,
    String? nextCursor,
    bool clearNextCursor = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      activeConversation: clearActiveConversation
          ? null
          : (activeConversation ?? this.activeConversation),
      messages: messages ?? this.messages,
      scopedDocumentIds: scopedDocumentIds ?? this.scopedDocumentIds,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      showArchived: showArchived ?? this.showArchived,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingOlderMessages: isLoadingOlderMessages ?? this.isLoadingOlderMessages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
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
        successMessage,
        showArchived,
        searchQuery,
        isLoadingOlderMessages,
        hasMoreMessages,
        nextCursor,
      ];
}

