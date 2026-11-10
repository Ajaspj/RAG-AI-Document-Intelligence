import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';

class OnboardingPage extends StatelessWidget {
  final SecureStorageService storageService;

  const OnboardingPage({
    super.key,
    required this.storageService,
  });

  Future<void> _proceedToSignUp(BuildContext context) async {
    await storageService.setHasSeenOnboarding(true);
    if (context.mounted) {
      context.go('/sign-up');
    }
  }

  Future<void> _proceedToSignIn(BuildContext context) async {
    await storageService.setHasSeenOnboarding(true);
    if (context.mounted) {
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // App Branding Tag
              Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Hero Titles
              Text(
                'Intelligent Documents.\nGrounded Answers.',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload your PDFs, Word documents, and text files. Ask questions and get verified answers with citations directly from your knowledge base.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Feature Highlights Cards
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFeatureItem(
                      icon: Icons.upload_file_rounded,
                      title: 'Multi-Format Ingestion',
                      description: 'Seamlessly extract and process PDF, DOCX, and TXT documents up to 25 MB.',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureItem(
                      icon: Icons.hub_rounded,
                      title: 'Semantic Chunking & Vector DB',
                      description: 'Preserves context and page metadata with PostgreSQL and pgvector embeddings.',
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureItem(
                      icon: Icons.verified_rounded,
                      title: 'Grounded Gemini RAG',
                      description: 'Get accurate answers with clickable citations, source snippets, and page numbers.',
                      color: AppColors.statusCompleted,
                    ),
                  ],
                ),
              ),

              // Actions
              AppButton(
                label: 'Get Started',
                isFullWidth: true,
                onPressed: () => _proceedToSignUp(context),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _proceedToSignIn(context),
                      child: Text(
                        'Sign In',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
