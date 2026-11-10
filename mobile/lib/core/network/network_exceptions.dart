import 'package:dio/dio.dart';

import '../errors/failure.dart';

class NetworkExceptions {
  NetworkExceptions._();

  static Failure handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Connection timed out. Please check your internet connection.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String message = 'Server error occurred ($statusCode).';

        if (data is Map<String, dynamic>) {
          if (data['detail'] is String) {
            message = data['detail'];
          } else if (data['message'] is String) {
            message = data['message'];
          }
        }

        if (statusCode == 401) {
          return AuthFailure(message, statusCode);
        }
        return ServerFailure(message, statusCode);

      case DioExceptionType.cancel:
        return const ServerFailure('Request was cancelled.');

      case DioExceptionType.connectionError:
        return const NetworkFailure('Cannot reach the server. Please verify the backend service is running.');

      case DioExceptionType.badCertificate:
        return const NetworkFailure('Untrusted security certificate.');

      case DioExceptionType.unknown:
      default:
        return ServerFailure(error.message ?? 'An unexpected network error occurred.');
    }
  }
}
