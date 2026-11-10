import '../../../../core/errors/failure.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  Future<User> signIn(String email, String password) async {
    try {
      final authData = await remoteDataSource.signIn(email, password);

      await storageService.saveAccessToken(authData.accessToken);
      if (authData.refreshToken.isNotEmpty) {
        await storageService.saveRefreshToken(authData.refreshToken);
      }
      await storageService.saveUserData(authData.user.toJsonString());

      return authData.user;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<User> signUp(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final authData = await remoteDataSource.signUp(fullName, email, password);

      await storageService.saveAccessToken(authData.accessToken);
      if (authData.refreshToken.isNotEmpty) {
        await storageService.saveRefreshToken(authData.refreshToken);
      }
      await storageService.saveUserData(authData.user.toJsonString());

      return authData.user;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await storageService.clearSession();
  }

  @override
  Future<User?> restoreSession() async {
    final token = await storageService.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      // Validate token with live backend
      final user = await remoteDataSource.getMe();
      await storageService.saveUserData(user.toJsonString());
      return user;
    } on Failure catch (_) {
      // If unauthorized, clear session and return null
      await storageService.clearSession();
      return null;
    } catch (_) {
      // If offline, check for cached user data
      final cachedUserJson = await storageService.getUserData();
      if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
        try {
          return UserModel.fromJsonString(cachedUserJson);
        } catch (_) {}
      }
      return null;
    }
  }

  @override
  Future<String> forgotPassword(String email) {
    return remoteDataSource.forgotPassword(email);
  }
}
