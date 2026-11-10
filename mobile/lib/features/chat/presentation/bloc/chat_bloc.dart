import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

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
    on<RenameConversationEvent>(_onRenameConversation);
    on<ArchiveConversationEvent>(_onArchiveConversation);
    on<RestoreConversationEvent>(_onRestoreConversation);
    on<SearchConversationsEvent>(_onSearchConversations);
    on<ToggleArchivedFilterEvent>(_onToggleArchivedFilter);
    on<LoadOlderMessagesEvent>(_onLoadOlderMessages);
    on<DeleteConversationEvent>(_onDeleteConversation);
    on<SetScopedDocumentsEvent>(_onSetScopedDocuments);
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    final bool isArchived = event.isArchived ?? state.showArchived;
    final String search = event.search ?? state.searchQuery;

    emit(state.copyWith(
      status: ChatStatus.loadingConversations,
      showArchived: isArchived,
      searchQuery: search,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));
    try {
      final conversations = await chatRepository.getConversations(
        isArchived: isArchived,
        search: search.isNotEmpty ? search : null,
      );
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
    emit(state.copyWith(
      status: ChatStatus.loadingMessages,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));
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

      final messages = await chatRepository.getMessages(event.conversationId, limit: 50);

      emit(state.copyWith(
        status: ChatStatus.loaded,
        activeConversation: conversation,
        messages: messages,
        scopedDocumentIds: conversation.documentIds,
        hasMoreMessages: messages.length >= 50,
        isLoadingOlderMessages: false,
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
      clearErrorMessage: true,
      clearSuccessMessage: true,
      hasMoreMessages: false,
      isLoadingOlderMessages: false,
    ));
  }

  Future<void> _onRenameConversation(
    RenameConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final updated = await chatRepository.updateConversation(
        event.conversationId,
        title: event.newTitle,
      );

      final updatedList = state.conversations.map((c) {
        return c.id == event.conversationId ? updated : c;
      }).toList();

      final active = state.activeConversation?.id == event.conversationId
          ? updated
          : state.activeConversation;

      emit(state.copyWith(
        conversations: updatedList,
        activeConversation: active,
        successMessage: 'Conversation renamed.',
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to rename conversation: ${e.toString()}',
      ));
    }
  }

  Future<void> _onArchiveConversation(
    ArchiveConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await chatRepository.archiveConversation(event.conversationId);
      final updatedList = state.conversations.where((c) => c.id != event.conversationId).toList();
      final bool wasActive = state.activeConversation?.id == event.conversationId;

      emit(state.copyWith(
        conversations: updatedList,
        clearActiveConversation: wasActive,
        messages: wasActive ? [] : state.messages,
        successMessage: 'Conversation archived.',
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to archive conversation: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRestoreConversation(
    RestoreConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await chatRepository.restoreConversation(event.conversationId);
      final updatedList = state.conversations.where((c) => c.id != event.conversationId).toList();

      emit(state.copyWith(
        conversations: updatedList,
        successMessage: 'Conversation restored to active.',
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to restore conversation: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSearchConversations(
    SearchConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(
      searchQuery: event.query,
      status: ChatStatus.loadingConversations,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));
    try {
      final conversations = await chatRepository.getConversations(
        isArchived: state.showArchived,
        search: event.query.isNotEmpty ? event.query : null,
      );
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

  Future<void> _onToggleArchivedFilter(
    ToggleArchivedFilterEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(
      showArchived: event.showArchived,
      status: ChatStatus.loadingConversations,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));
    try {
      final conversations = await chatRepository.getConversations(
        isArchived: event.showArchived,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
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

  Future<void> _onLoadOlderMessages(
    LoadOlderMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isLoadingOlderMessages || !state.hasMoreMessages || state.messages.isEmpty) {
      return;
    }

    emit(state.copyWith(isLoadingOlderMessages: true));
    try {
      final oldestId = state.messages.first.id;
      final older = await chatRepository.getOlderMessages(
        event.conversationId,
        before: oldestId,
        limit: 30,
      );

      if (older.isEmpty) {
        emit(state.copyWith(
          isLoadingOlderMessages: false,
          hasMoreMessages: false,
        ));
      } else {
        final combined = List<ChatMessage>.from(older)..addAll(state.messages);
        emit(state.copyWith(
          isLoadingOlderMessages: false,
          hasMoreMessages: older.length >= 30,
          messages: combined,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoadingOlderMessages: false,
        errorMessage: 'Failed to load older messages: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final cleanContent = event.content.trim();
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
      clearErrorMessage: true,
      clearSuccessMessage: true,
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
      final refreshedConversations = await chatRepository.getConversations(
        isArchived: state.showArchived,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

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
        successMessage: 'Conversation deleted.',
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


