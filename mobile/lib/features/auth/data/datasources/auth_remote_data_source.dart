import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/user_model.dart';

class AuthResponseData {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponseData({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

abstract class AuthRemoteDataSource {
  Future<AuthResponseData> signIn(String email, String password);
  Future<AuthResponseData> signUp(String fullName, String email, String password);
  Future<UserModel> getMe();
  Future<String> forgotPassword(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AuthResponseData> signIn(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return AuthResponseData(
        accessToken: data['access_token'] as String,
        refreshToken: (data['refresh_token'] ?? '') as String,
        user: user,
      );
    } on DioException catch (e) {
      throw NetworkExceptions.handleDioError(e);
    }
  }

  @override
  Future<AuthResponseData> signUp(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return AuthResponseData(
        accessToken: data['access_token'] as String,
        refreshToken: (data['refresh_token'] ?? '') as String,
        user: user,
      );
    } on DioException catch (e) {
      throw NetworkExceptions.handleDioError(e);
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw NetworkExceptions.handleDioError(e);
    }
  }

  @override
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['message'] ?? 'Password reset request submitted successfully.') as String;
    } on DioException catch (e) {
      throw NetworkExceptions.handleDioError(e);
    }
  }
}
