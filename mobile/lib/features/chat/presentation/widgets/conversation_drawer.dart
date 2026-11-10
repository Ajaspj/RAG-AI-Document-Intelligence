import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/conversation.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import 'rename_conversation_dialog.dart';

class ConversationDrawer extends StatefulWidget {
  const ConversationDrawer({super.key});

  @override
  State<ConversationDrawer> createState() => _ConversationDrawerState();
}

class _ConversationDrawerState extends State<ConversationDrawer> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final currentSearch = context.read<ChatBloc>().state.searchQuery;
    _searchController = TextEditingController(text: currentSearch);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ChatBloc>().add(SearchConversationsEvent(query));
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ChatBloc>().add(const SearchConversationsEvent(''));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
              child: Row(
                children: [
                  const Icon(Icons.forum_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Conversations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close drawer',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // New Conversation Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('New Conversation'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    context.read<ChatBloc>().add(const NewConversationEvent());
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ),

            // Active vs Archived Segmented Filter
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (prev, curr) => prev.showArchived != curr.showArchived,
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Active'),
                        icon: Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Archived'),
                        icon: Icon(Icons.archive_outlined, size: 16),
                      ),
                    ],
                    selected: {state.showArchived},
                    onSelectionChanged: (newSelection) {
                      final selected = newSelection.first;
                      context.read<ChatBloc>().add(ToggleArchivedFilterEvent(selected));
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      selectedForegroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                );
              },
            ),

            const Divider(color: AppColors.border, height: 16),

            // Conversations List
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.status == ChatStatus.loadingConversations &&
                      state.conversations.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.conversations.isEmpty) {
                    final isArchivedTab = state.showArchived;
                    final hasSearch = state.searchQuery.isNotEmpty;

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isArchivedTab
                                  ? Icons.archive_outlined
                                  : Icons.chat_bubble_outline_rounded,
                              size: 40,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              hasSearch
                                  ? 'No matches found'
                                  : (isArchivedTab
                                      ? 'No archived conversations'
                                      : 'No conversations yet'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasSearch
                                  ? 'Try adjusting your search query'
                                  : (isArchivedTab
                                      ? 'Archived conversation threads will appear here'
                                      : 'Start chatting to create your first thread'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: state.conversations.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final conv = state.conversations[index];
                      final isSelected = state.activeConversation?.id == conv.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isSelected
                              ? AppColors.primary
                              : AppColors.background,
                          child: Icon(
                            conv.isArchived
                                ? Icons.archive_outlined
                                : Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        title: Text(
                          conv.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(conv.updatedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (action) => _handleMenuAction(context, action, conv),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                  SizedBox(width: 10),
                                  Text('Rename'),
                                ],
                              ),
                            ),
                            if (!conv.isArchived)
                              const PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(Icons.archive_outlined, size: 18, color: AppColors.textSecondary),
                                    SizedBox(width: 10),
                                    Text('Archive'),
                                  ],
                                ),
                              )
                            else
                              const PopupMenuItem(
                                value: 'restore',
                                child: Row(
                                  children: [
                                    Icon(Icons.unarchive_outlined, size: 18, color: AppColors.textSecondary),
                                    SizedBox(width: 10),
                                    Text('Restore'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                  SizedBox(width: 10),
                                  Text('Delete', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          context.read<ChatBloc>().add(
                                SelectConversationEvent(conv.id),
                              );
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    String action,
    Conversation conversation,
  ) async {
    final bloc = context.read<ChatBloc>();

    switch (action) {
      case 'rename':
        final newTitle = await RenameConversationDialog.show(context, conversation.title);
        if (newTitle != null && newTitle.isNotEmpty && newTitle != conversation.title) {
          bloc.add(RenameConversationEvent(
            conversationId: conversation.id,
            newTitle: newTitle,
          ));
        }
        break;

      case 'archive':
        bloc.add(ArchiveConversationEvent(conversation.id));
        break;

      case 'restore':
        bloc.add(RestoreConversationEvent(conversation.id));
        break;

      case 'delete':
        _confirmDelete(context, conversation);
        break;
    }
  }

  void _confirmDelete(BuildContext context, Conversation conversation) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete conversation?'),
        content: Text(
          'Are you sure you want to delete "${conversation.title}"?\n\n'
          'All messages, document context associations, and grounded citations will be permanently removed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<ChatBloc>().add(
                    DeleteConversationEvent(conversation.id),
                  );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
