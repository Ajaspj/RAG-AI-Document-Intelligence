import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final displayName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Workspace Owner';
    final displayEmail = user?.email.isNotEmpty == true ? user!.email : 'user@documind.ai';
    final initials = displayName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account & Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // User Profile Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      initials.isNotEmpty ? initials : 'AI',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Free Developer Tier',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Storage Overview
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Document Storage',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '0 MB / 100 MB',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.0,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Max upload size: ${AppConstants.maxFileSizeFormatted} per file',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            Text(
              'Preferences',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: 'System default (Light)',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.dns_outlined,
                    title: 'API Server Endpoint',
                    subtitle: AppConstants.defaultAndroidBaseUrl,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.shield_outlined,
                    title: 'Data & Privacy',
                    subtitle: 'Documents stored locally & isolated',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Session & Account
            AppCard(
              padding: EdgeInsets.zero,
              child: _buildSettingTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                subtitle: 'Clear local session token',
                titleColor: AppColors.error,
                iconColor: AppColors.error,
                showArrow: false,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text(
                        'Are you sure you want to sign out of DocuMind AI?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            context.read<AuthBloc>().add(const SignOutRequested());
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'DocuMind AI v1.0.0 • Mobile Client',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: showArrow
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
