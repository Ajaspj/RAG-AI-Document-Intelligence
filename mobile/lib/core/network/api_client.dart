import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_base_url_resolver.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService storageService;

  Dio get client => dio;

  /// Private internal constructor initializing Dio and registering interceptors once.
  ApiClient._internal({
    required this.storageService,
    required String baseUrl,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(storageService: storageService, dio: dio),
    );
  }

  /// Synchronous constructor.
  ///
  /// Uses [baseUrl] if provided and non-empty. Otherwise, falls back to the
  /// synchronous platform default. For automatic detection of Android Emulator
  /// vs Physical Android Device, prefer [ApiClient.create].
  factory ApiClient({
    required SecureStorageService storageService,
    String? baseUrl,
  }) {
    final effectiveUrl = baseUrl != null && baseUrl.trim().isNotEmpty
        ? ApiBaseUrlResolver.normalizeUrl(baseUrl)
        : _syncFallbackUrl();

    return ApiClient._internal(
      storageService: storageService,
      baseUrl: effectiveUrl,
    );
  }

  /// Asynchronous factory method that automatically detects runtime environment
  /// (Android Emulator vs Physical Device with ADB reverse vs iOS/Desktop)
  /// before constructing the [ApiClient].
  static Future<ApiClient> create({
    required SecureStorageService storageService,
    String? baseUrl,
    ApiBaseUrlResolver? resolver,
  }) async {
    final effectiveResolver = resolver ?? ApiBaseUrlResolver();
    final resolvedUrl =
        await effectiveResolver.resolveBaseUrl(overrideUrl: baseUrl);

    return ApiClient._internal(
      storageService: storageService,
      baseUrl: resolvedUrl,
    );
  }

  /// Updates the base URL on the active Dio instance at runtime.
  void updateBaseUrl(String newUrl) {
    final normalized = ApiBaseUrlResolver.normalizeUrl(newUrl);
    dio.options.baseUrl = normalized;
    developer.log(
      'API Base URL: Updated dynamically -> $normalized',
      name: 'DocuMind.Network',
    );
  }

  /// Synchronous fallback when asynchronous environment detection is bypassed.
  static String _syncFallbackUrl() {
    const envUrl = String.fromEnvironment(
      AppConstants.apiBaseUrlEnvironmentKey,
      defaultValue: '',
    );
    if (envUrl.trim().isNotEmpty) {
      return ApiBaseUrlResolver.normalizeUrl(envUrl);
    }

    try {
      if (Platform.isAndroid) {
        return ApiBaseUrlResolver.normalizeUrl(
          '${AppConstants.defaultAndroidEmulatorBaseUrl}${AppConstants.apiVersionPath}',
        );
      }
    } catch (_) {}

    return ApiBaseUrlResolver.normalizeUrl(
      '${AppConstants.defaultIosBaseUrl}${AppConstants.apiVersionPath}',
    );
  }
}
