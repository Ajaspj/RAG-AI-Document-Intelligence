import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final DocumentStatus status;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor, icon) = switch (status) {
      DocumentStatus.pending => (
        AppColors.statusPending,
        AppColors.statusPendingBg,
        Icons.access_time_rounded,
      ),
      DocumentStatus.uploading => (
        AppColors.statusUploading,
        AppColors.statusUploadingBg,
        Icons.cloud_upload_outlined,
      ),
      DocumentStatus.processing => (
        AppColors.statusProcessing,
        AppColors.statusProcessingBg,
        Icons.sync_rounded,
      ),
      DocumentStatus.completed => (
        AppColors.statusCompleted,
        AppColors.statusCompletedBg,
        Icons.check_circle_outline_rounded,
      ),
      DocumentStatus.failed => (
        AppColors.statusFailed,
        AppColors.statusFailedBg,
        Icons.error_outline_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
