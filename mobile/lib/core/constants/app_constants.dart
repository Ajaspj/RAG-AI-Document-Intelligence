class AppConstants {
  AppConstants._();

  static const String appName = 'DocuMind AI';
  static const String appTagline = 'RAG Document Intelligence Platform';

  // File Upload Constraints
  static const List<String> supportedExtensions = ['pdf', 'docx', 'txt'];
  static const int defaultMaxFileSizeBytes = 20 * 1024 * 1024; // 20 MB
  static int maxFileSizeBytes = defaultMaxFileSizeBytes;
  static String get maxFileSizeFormatted => '${(maxFileSizeBytes / (1024 * 1024)).round()} MB';

  // Supported MIME Types
  static const Map<String, List<String>> extensionMimeTypes = {
    'pdf': ['application/pdf'],
    'docx': [
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/msword',
      'application/zip',
      'application/octet-stream',
    ],
    'txt': ['text/plain', 'text/csv', 'application/octet-stream'],
  };

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

  bool get isCompleted => this == DocumentStatus.completed;
  bool get isFailed => this == DocumentStatus.failed;
  bool get isProcessing => this == DocumentStatus.processing;
  bool get isUploading => this == DocumentStatus.uploading;
  bool get isPending => this == DocumentStatus.pending;
  bool get canRetry => this == DocumentStatus.failed;

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

