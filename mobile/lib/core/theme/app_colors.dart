import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary & Brand (Indigo & Violet Palette)
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryContainer = Color(0xFFEEF2FF);

  // Secondary & Accents
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFEDE9FE);
  static const Color accent = Color(0xFF0891B2);
  static const Color accentLight = Color(0xFFE0F2FE);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // Standard Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEFF6FF);

  // Document Processing State Colors
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusUploading = Color(0xFF2563EB);
  static const Color statusUploadingBg = Color(0xFFEFF6FF);
  static const Color statusProcessing = Color(0xFF7C3AED);
  static const Color statusProcessingBg = Color(0xFFF5F3FF);
  static const Color statusCompleted = Color(0xFF059669);
  static const Color statusCompletedBg = Color(0xFFD1FAE5);
  static const Color statusFailed = Color(0xFFDC2626);
  static const Color statusFailedBg = Color(0xFFFEE2E2);

  // Card Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
