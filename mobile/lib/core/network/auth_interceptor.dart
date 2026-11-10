import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService storageService;
  final Dio dio;

  AuthInterceptor({
    required this.storageService,
    required this.dio,
  });

  // Paths that do not require an authorization header
  static const List<String> _publicPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/health',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = _publicPaths.any((path) => options.path.contains(path));

    if (!isPublic) {
      final token = await storageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only attempt refresh on 401 for non-auth endpoints
    final isAuthEndpoint = _publicPaths.any((path) => err.requestOptions.path.contains(path));

    if (err.response?.statusCode == 401 && !isAuthEndpoint) {
      final refreshToken = await storageService.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Attempt refresh using an independent request
          final response = await dio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: Options(
              headers: {'Authorization': null},
            ),
          );

          if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
            final newAccessToken = response.data['access_token'] as String;
            final newRefreshToken = response.data['refresh_token'] as String?;

            await storageService.saveAccessToken(newAccessToken);
            if (newRefreshToken != null) {
              await storageService.saveRefreshToken(newRefreshToken);
            }

            // Retry original request with new token
            final originalOptions = err.requestOptions;
            originalOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await dio.fetch(originalOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Refresh failed - clear session
          await storageService.clearSession();
        }
      } else {
        await storageService.clearSession();
      }
    }

    return handler.next(err);
  }
}
