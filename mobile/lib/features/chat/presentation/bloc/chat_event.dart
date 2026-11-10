import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversationsEvent extends ChatEvent {
  final bool? isArchived;
  final String? search;

  const LoadConversationsEvent({this.isArchived, this.search});

  @override
  List<Object?> get props => [isArchived, search];
}

class SelectConversationEvent extends ChatEvent {
  final String conversationId;

  const SelectConversationEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class NewConversationEvent extends ChatEvent {
  final String? title;
  final List<String>? documentIds;

  const NewConversationEvent({this.title, this.documentIds});

  @override
  List<Object?> get props => [title, documentIds];
}

class SendMessageEvent extends ChatEvent {
  final String content;

  const SendMessageEvent(this.content);

  @override
  List<Object?> get props => [content];
}

class RenameConversationEvent extends ChatEvent {
  final String conversationId;
  final String newTitle;

  const RenameConversationEvent({
    required this.conversationId,
    required this.newTitle,
  });

  @override
  List<Object?> get props => [conversationId, newTitle];
}

class ArchiveConversationEvent extends ChatEvent {
  final String conversationId;

  const ArchiveConversationEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class RestoreConversationEvent extends ChatEvent {
  final String conversationId;

  const RestoreConversationEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SearchConversationsEvent extends ChatEvent {
  final String query;

  const SearchConversationsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ToggleArchivedFilterEvent extends ChatEvent {
  final bool showArchived;

  const ToggleArchivedFilterEvent(this.showArchived);

  @override
  List<Object?> get props => [showArchived];
}

class LoadOlderMessagesEvent extends ChatEvent {
  final String conversationId;

  const LoadOlderMessagesEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class DeleteConversationEvent extends ChatEvent {
  final String conversationId;

  const DeleteConversationEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SetScopedDocumentsEvent extends ChatEvent {
  final List<String> documentIds;

  const SetScopedDocumentsEvent(this.documentIds);

  @override
  List<Object?> get props => [documentIds];
}

