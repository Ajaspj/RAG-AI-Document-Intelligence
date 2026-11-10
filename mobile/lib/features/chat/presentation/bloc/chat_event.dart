import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversationsEvent extends ChatEvent {
  const LoadConversationsEvent();
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

