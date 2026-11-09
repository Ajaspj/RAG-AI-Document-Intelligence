class AppConstants {
  AppConstants._();

  static const String appName = 'DocuMind AI';
  static const String appTagline = 'RAG Document Intelligence Platform';

  // File Upload Constraints
  static const List<String> supportedExtensions = ['pdf', 'docx', 'txt'];
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB
  static const String maxFileSizeFormatted = '25 MB';

  // Secure Storage Keys
  static const String tokenStorageKey = 'documind_auth_token';
  static const String refreshTokenStorageKey = 'documind_refresh_token';
  static const String userStorageKey = 'documind_user_data';

  // Default API Base URL (Android emulator loopback: 10.0.2.2, default host: 127.0.0.1)
  static const String defaultAndroidBaseUrl = 'http://10.0.2.2:8000';
  static const String defaultIosBaseUrl = 'http://127.0.0.1:8000';
}

/// Document processing lifecycle states
enum DocumentStatus {
  pending,
  uploading,
  processing,
  completed,
  failed;

  String get displayName {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.uploading:
        return 'Uploading';
      case DocumentStatus.processing:
        return 'Processing';
      case DocumentStatus.completed:
        return 'Completed';
      case DocumentStatus.failed:
        return 'Failed';
    }
  }

  static DocumentStatus fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'uploading':
        return DocumentStatus.uploading;
      case 'processing':
        return DocumentStatus.processing;
      case 'completed':
      case 'ready':
        return DocumentStatus.completed;
      case 'failed':
      case 'error':
        return DocumentStatus.failed;
      case 'pending':
      default:
        return DocumentStatus.pending;
    }
  }
}
