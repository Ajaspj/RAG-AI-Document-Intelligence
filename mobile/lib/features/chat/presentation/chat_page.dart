import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import 'bloc/chat_bloc.dart';
import 'bloc/chat_event.dart';
import 'bloc/chat_state.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/conversation_drawer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(const LoadConversationsEvent());
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 80) {
      final state = context.read<ChatBloc>().state;
      if (state.hasActiveConversation &&
          state.hasMoreMessages &&
          !state.isLoadingOlderMessages &&
          state.messages.isNotEmpty) {
        context.read<ChatBloc>().add(
              LoadOlderMessagesEvent(state.activeConversation!.id),
            );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.status == ChatStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Only auto-scroll to bottom on sending or new latest messages, not older prepends
        if (state.status == ChatStatus.sending) {
          _scrollToBottom();
        } else if (state.messages.length > _previousMessageCount && !state.isLoadingOlderMessages) {
          _scrollToBottom();
        }
        _previousMessageCount = state.messages.length;
      },
      builder: (context, state) {
        final title = state.activeConversation?.title ?? 'DocuMind Assistant';

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          endDrawer: const ConversationDrawer(),
          appBar: AppBar(
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: 'New conversation',
                icon: const Icon(Icons.add_comment_outlined),
                onPressed: () {
                  context.read<ChatBloc>().add(const NewConversationEvent());
                },
              ),
              IconButton(
                tooltip: 'Conversation history',
                icon: const Icon(Icons.history_rounded),
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _buildChatBody(context, state),
                ),
                const ChatInputBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatBody(BuildContext context, ChatState state) {
    if (state.status == ChatStatus.loadingMessages) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.messages.isEmpty) {
      return _buildEmptyState(context);
    }

    final hasTopLoader = state.isLoadingOlderMessages;
    final totalCount = state.messages.length + (hasTopLoader ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (hasTopLoader && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final messageIndex = hasTopLoader ? index - 1 : index;
        final message = state.messages[messageIndex];
        return ChatMessageBubble(message: message);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // AI Sparkle Avatar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask anything across your documents',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grounded in your uploaded knowledge base with instant citations, page references, and verifiable answers.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Starter Prompts
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested Questions',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPromptCard(
            context,
            'Summarize key insights',
            'Extract the executive summary and main findings from the latest report.',
          ),
          const SizedBox(height: 10),
          _buildPromptCard(
            context,
            'Check compliance & risks',
            'Identify any compliance risks or legal deadlines outlined in the documents.',
          ),
          const SizedBox(height: 10),
          _buildPromptCard(
            context,
            'Compare key metrics',
            'Compare metrics and performance benchmarks mentioned across files.',
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(BuildContext context, String title, String subtitle) {
    return AppCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () {
          context.read<ChatBloc>().add(SendMessageEvent(subtitle));
        },
      ),
    );
  }
}
