import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService storageService;

  Dio get client => dio;

  ApiClient({required this.storageService, String? baseUrl}) {
    final defaultUrl = _resolveBaseUrl(baseUrl);

    dio = Dio(
      BaseOptions(
        baseUrl: defaultUrl,
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

  static String _resolveBaseUrl(String? overrideUrl) {
    if (overrideUrl != null && overrideUrl.isNotEmpty) {
      return overrideUrl;
    }

    try {
      if (Platform.isAndroid) {
        return '${AppConstants.defaultAndroidBaseUrl}/api/v1';
      }
    } catch (_) {}

    return '${AppConstants.defaultIosBaseUrl}/api/v1';
  }
}
