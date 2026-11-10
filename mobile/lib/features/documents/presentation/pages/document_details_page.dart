import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/document.dart';
import '../bloc/documents_bloc.dart';
import '../bloc/documents_event.dart';
import '../widgets/document_status_indicator.dart';

class DocumentDetailsPage extends StatelessWidget {
  final Document document;

  const DocumentDetailsPage({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileIconData = _getFileTypeVisuals(document.fileExtension);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Document Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete document',
            onPressed: () => _showDeleteConfirmationDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero File Header Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: fileIconData.containerColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        fileIconData.icon,
                        color: fileIconData.iconColor,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      document.filename,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DocumentStatusIndicator(status: document.status),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Processing Status Details
              Text(
                'Processing Lifecycle',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pipeline State',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          document.status.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (document.isProcessing || document.isUploading) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: document.processingProgress > 0
                              ? document.processingProgress
                              : null,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                    if (document.errorMessage != null &&
                        document.errorMessage!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                document.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // File Metadata Section
              Text(
                'File Specifications',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMetaTile('Original Filename', document.originalFilename),
                    const Divider(height: 1),
                    _buildMetaTile('File Size', document.formattedFileSize),
                    const Divider(height: 1),
                    _buildMetaTile('Format', document.fileExtension.toUpperCase()),
                    const Divider(height: 1),
                    _buildMetaTile('MIME Type', document.mimeType),
                    const Divider(height: 1),
                    _buildMetaTile('Uploaded At', document.uploadedAt.toLocal().toString().split('.')[0]),
                    if (document.updatedAt != null) ...[
                      const Divider(height: 1),
                      _buildMetaTile('Last Updated', document.updatedAt!.toLocal().toString().split('.')[0]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              if (document.isCompleted) ...[
                AppButton(
                  label: 'Ask Questions in AI Chat',
                  icon: Icons.chat_bubble_outline_rounded,
                  isFullWidth: true,
                  onPressed: () {
                    // Navigate to AI Chat tab
                    context.go('/chat');
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (document.canRetry) ...[
                AppButton(
                  label: 'Retry Document Upload',
                  icon: Icons.refresh_rounded,
                  isFullWidth: true,
                  onPressed: () {
                    context.read<DocumentsBloc>().add(RetryUploadRequested(document));
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showDeleteConfirmationDialog(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Delete Document',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
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
          'Are you sure you want to permanently delete "${document.filename}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DocumentsBloc>().add(DeleteDocumentRequested(document.id));
              Navigator.pop(context); // Exit details page
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  _FileTypeVisuals _getFileTypeVisuals(String ext) {
    switch (ext.toLowerCase()) {
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

