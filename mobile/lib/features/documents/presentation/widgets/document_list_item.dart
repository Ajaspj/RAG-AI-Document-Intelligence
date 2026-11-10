import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/document.dart';
import 'document_status_indicator.dart';

class DocumentListItem extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  const DocumentListItem({
    super.key,
    required this.document,
    this.onTap,
    this.onRetry,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileIconData = _getFileTypeVisuals();

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // File Type Icon Container
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: fileIconData.containerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              fileIconData.icon,
              color: fileIconData.iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      document.formattedFileSize,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: AppColors.border, fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      document.formattedUploadedAt,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Status Badge
                DocumentStatusIndicator(
                  status: document.status,
                  isCompact: true,
                ),
              ],
            ),
          ),

          // Action Menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'details':
                  onTap?.call();
                  break;
                case 'retry':
                  onRetry?.call();
                  break;
                case 'delete':
                  _showDeleteConfirmationDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('View Details'),
                  ],
                ),
              ),
              if (document.canRetry)
                const PopupMenuItem(
                  value: 'retry',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Retry Upload'),
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
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to permanently delete "${document.filename}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  _FileTypeVisuals _getFileTypeVisuals() {
    switch (document.fileExtension.toLowerCase()) {
      case 'pdf':
        return const _FileTypeVisuals(
          icon: Icons.picture_as_pdf_rounded,
          iconColor: Color(0xFFE53935),
          containerColor: Color(0xFFFFEBEE),
        );
      case 'docx':
      case 'doc':
        return const _FileTypeVisuals(
          icon: Icons.description_rounded,
          iconColor: Color(0xFF1E88E5),
          containerColor: Color(0xFFE3F2FD),
        );
      case 'txt':
      default:
        return const _FileTypeVisuals(
          icon: Icons.article_rounded,
          iconColor: Color(0xFF00897B),
          containerColor: Color(0xFFE0F2F1),
        );
    }
  }
}

class _FileTypeVisuals {
  final IconData icon;
  final Color iconColor;
  final Color containerColor;

  const _FileTypeVisuals({
    required this.icon,
    required this.iconColor,
    required this.containerColor,
  });
}

