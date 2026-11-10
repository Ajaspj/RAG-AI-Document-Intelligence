import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  ChatBloc({required this.chatRepository}) : super(const ChatState()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<SelectConversationEvent>(_onSelectConversation);
    on<NewConversationEvent>(_onNewConversation);
    on<SendMessageEvent>(_onSendMessage);
    on<DeleteConversationEvent>(_onDeleteConversation);
    on<SetScopedDocumentsEvent>(_onSetScopedDocuments);
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loadingConversations));
    try {
      final conversations = await chatRepository.getConversations();
      emit(state.copyWith(
        status: ChatStatus.loaded,
        conversations: conversations,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSelectConversation(
    SelectConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loadingMessages));
    try {
      final conversation = state.conversations.firstWhere(
        (c) => c.id == event.conversationId,
        orElse: () => Conversation(
          id: event.conversationId,
          userId: '',
          title: 'Conversation',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final messages = await chatRepository.getMessages(event.conversationId);

      emit(state.copyWith(
        status: ChatStatus.loaded,
        activeConversation: conversation,
        messages: messages,
        scopedDocumentIds: conversation.documentIds,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onNewConversation(
    NewConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(
      clearActiveConversation: true,
      messages: [],
      scopedDocumentIds: event.documentIds ?? [],
      status: ChatStatus.loaded,
    ));
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final cleanContent = event.content.strip();
    if (cleanContent.isEmpty) return;

    // Optimistically create user message
    final optimisticUserMsg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: state.activeConversation?.id ?? '',
      role: MessageRole.user,
      content: cleanContent,
      createdAt: DateTime.now(),
      isSending: true,
    );

    final updatedMessages = List<ChatMessage>.from(state.messages)..add(optimisticUserMsg);
    emit(state.copyWith(
      status: ChatStatus.sending,
      messages: updatedMessages,
    ));

    try {
      ChatMessage assistantMessage;
      if (state.activeConversation != null) {
        // Send message to active conversation
        assistantMessage = await chatRepository.sendMessage(
          conversationId: state.activeConversation!.id,
          content: cleanContent,
          documentIds: state.scopedDocumentIds.isNotEmpty ? state.scopedDocumentIds : null,
        );
      } else {
        // Single round-trip quick-chat
        assistantMessage = await chatRepository.quickChat(
          content: cleanContent,
          documentIds: state.scopedDocumentIds.isNotEmpty ? state.scopedDocumentIds : null,
        );
      }

      // Refresh full message list to ensure proper IDs and citations
      final refreshedMessages = await chatRepository.getMessages(assistantMessage.conversationId);
      final refreshedConversations = await chatRepository.getConversations();

      final active = refreshedConversations.firstWhere(
        (c) => c.id == assistantMessage.conversationId,
        orElse: () => Conversation(
          id: assistantMessage.conversationId,
          userId: '',
          title: cleanContent.split(' ').take(6).join(' '),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      emit(state.copyWith(
        status: ChatStatus.loaded,
        activeConversation: active,
        conversations: refreshedConversations,
        messages: refreshedMessages,
      ));
    } catch (e) {
      // Remove optimistic message on error or mark error
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Failed to generate response: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await chatRepository.deleteConversation(event.conversationId);
      final updatedList = state.conversations.where((c) => c.id != event.conversationId).toList();
      final bool wasActive = state.activeConversation?.id == event.conversationId;

      emit(state.copyWith(
        conversations: updatedList,
        clearActiveConversation: wasActive,
        messages: wasActive ? [] : state.messages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onSetScopedDocuments(
    SetScopedDocumentsEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(scopedDocumentIds: event.documentIds));
  }
}

extension StringStrip on String {
  String strip() => trim();
}

