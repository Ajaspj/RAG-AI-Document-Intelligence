import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../bloc/documents_bloc.dart';
import '../bloc/documents_event.dart';
import '../bloc/documents_state.dart';
import '../widgets/document_filter_chips.dart';
import '../widgets/document_list_item.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/document_upload_sheet.dart';
import '../widgets/upload_progress_card.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch initial load
    context.read<DocumentsBloc>().add(const LoadDocuments());
  }

  void _openUploadSheet(BuildContext context) {
    DocumentUploadSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Upload',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _openUploadSheet(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<DocumentsBloc, DocumentsState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final filterCounts = {
              'All': state.totalCount,
              'PDF': state.documents.where((d) => d.fileExtension == 'pdf').length,
              'DOCX': state.documents.where((d) => d.fileExtension == 'docx').length,
              'TXT': state.documents.where((d) => d.fileExtension == 'txt').length,
              'Processing': state.processingCount,
              'Completed': state.completedCount,
              'Failed': state.failedCount,
            };

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context.read<DocumentsBloc>().add(const RefreshDocuments());
              },
              child: Column(
                children: [
                  // Search & Filter Header (Always accessible)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        DocumentSearchBar(
                          initialQuery: state.searchQuery,
                          onQueryChanged: (query) {
                            context.read<DocumentsBloc>().add(SearchQueryChanged(query));
                          },
                        ),
                        const SizedBox(height: 12),

                        // Filter Chips
                        DocumentFilterChips(
                          selectedFilter: state.selectedFilter,
                          counts: filterCounts,
                          onFilterSelected: (filter) {
                            context.read<DocumentsBloc>().add(FilterTypeChanged(filter));
                          },
                        ),
                        const SizedBox(height: 16),

                        // Active In-Flight Upload Card (if uploading)
                        if (state.isUploading) ...[
                          UploadProgressCard(
                            filename: state.uploadingDocument?.filename ??
                                state.selectedFile?.name ??
                                'Document',
                            progress: state.uploadProgress,
                            bytesSent: state.bytesSent,
                            totalBytes: state.totalBytes,
                            onCancel: () {
                              context.read<DocumentsBloc>().add(const CancelUploadRequested());
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Document Count & Supported Formats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.selectedFilter == 'All' && state.searchQuery.isEmpty
                                  ? 'All Files (${state.totalCount})'
                                  : 'Filtered Results (${state.filteredCount})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Max ${AppConstants.maxFileSizeFormatted}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // Documents List Area
                  Expanded(
                    child: _buildContent(context, state),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Upload Document',
        onPressed: () => _openUploadSheet(context),
        child: const Icon(Icons.upload_file_rounded),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DocumentsState state) {
    if (state.isLoading && state.documents.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == DocumentsStatus.failure && state.documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load documents',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                state.errorMessage ?? 'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  context.read<DocumentsBloc>().add(const LoadDocuments());
                },
              ),
            ],
          ),
        ),
      );
    }

    if (state.documents.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: EmptyStateWidget(
            icon: Icons.folder_open_rounded,
            title: 'No documents uploaded yet',
            description:
                'Upload your PDF, DOCX, or TXT files to enable AI extraction, semantic chunking, and grounded intelligence.',
            actionLabel: 'Upload Document',
            onAction: () => _openUploadSheet(context),
          ),
        ),
      );
    }

    if (state.filteredDocuments.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: EmptyStateWidget(
            icon: Icons.search_off_rounded,
            title: 'No matching documents',
            description: state.searchQuery.isNotEmpty
                ? 'No documents found matching "${state.searchQuery}". Try a different keyword or reset filters.'
                : 'No documents match the filter "${state.selectedFilter}".',
            actionLabel: 'Clear Filters',
            onAction: () {
              context.read<DocumentsBloc>().add(const FilterTypeChanged('All'));
              context.read<DocumentsBloc>().add(const SearchQueryChanged(''));
            },
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      itemCount: state.filteredDocuments.length,
      itemBuilder: (context, index) {
        final doc = state.filteredDocuments[index];
        return DocumentListItem(
          document: doc,
          onTap: () {
            context.push('/documents/${doc.id}', extra: doc);
          },
          onRetry: () {
            context.read<DocumentsBloc>().add(RetryUploadRequested(doc));
          },
          onDelete: () {
            context.read<DocumentsBloc>().add(DeleteDocumentRequested(doc.id));
          },
        );
      },
    );
  }
}
