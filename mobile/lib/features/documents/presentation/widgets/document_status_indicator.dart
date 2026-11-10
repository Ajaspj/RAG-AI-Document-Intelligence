import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class DocumentStatusIndicator extends StatelessWidget {
  final DocumentStatus status;
  final bool isCompact;

  const DocumentStatusIndicator({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.foregroundColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == DocumentStatus.uploading ||
              status == DocumentStatus.processing) ...[
            SizedBox(
              height: isCompact ? 10 : 12,
              width: isCompact ? 10 : 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(config.foregroundColor),
              ),
            ),
            const SizedBox(width: 6),
          ] else ...[
            Icon(
              config.icon,
              size: isCompact ? 12 : 14,
              color: config.foregroundColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayName,
            style: TextStyle(
              color: config.foregroundColor,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig() {
    switch (status) {
      case DocumentStatus.completed:
        return const _StatusConfig(
          backgroundColor: AppColors.statusCompletedBg,
          foregroundColor: AppColors.statusCompleted,
          icon: Icons.check_circle_rounded,
        );
      case DocumentStatus.processing:
        return const _StatusConfig(
          backgroundColor: AppColors.statusProcessingBg,
          foregroundColor: AppColors.statusProcessing,
          icon: Icons.sync_rounded,
        );
      case DocumentStatus.uploading:
        return const _StatusConfig(
          backgroundColor: AppColors.statusUploadingBg,
          foregroundColor: AppColors.statusUploading,
          icon: Icons.cloud_upload_rounded,
        );
      case DocumentStatus.failed:
        return const _StatusConfig(
          backgroundColor: AppColors.statusFailedBg,
          foregroundColor: AppColors.statusFailed,
          icon: Icons.error_outline_rounded,
        );
      case DocumentStatus.pending:
        return const _StatusConfig(
          backgroundColor: AppColors.statusPendingBg,
          foregroundColor: AppColors.statusPending,
          icon: Icons.schedule_rounded,
        );
    }
  }
}

class _StatusConfig {
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  const _StatusConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });
}
