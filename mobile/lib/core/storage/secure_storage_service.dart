import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  static const String _keyAccessToken = AppConstants.tokenStorageKey;
  static const String _keyRefreshToken = AppConstants.refreshTokenStorageKey;
  static const String _keyUserData = AppConstants.userStorageKey;
  static const String _keyHasSeenOnboarding = 'documind_has_seen_onboarding';

  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _keyAccessToken, value: token);
    } catch (_) {
      // Avoid printing sensitive tokens in logs
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _keyRefreshToken, value: token);
    } catch (_) {
      // Avoid printing sensitive tokens in logs
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserData(String userJson) async {
    try {
      await _storage.write(key: _keyUserData, value: userJson);
    } catch (_) {}
  }

  Future<String?> getUserData() async {
    try {
      return await _storage.read(key: _keyUserData);
    } catch (_) {
      return null;
    }
  }

  Future<void> setHasSeenOnboarding(bool seen) async {
    try {
      await _storage.write(key: _keyHasSeenOnboarding, value: seen.toString());
    } catch (_) {}
  }

  Future<bool> hasSeenOnboarding() async {
    try {
      final value = await _storage.read(key: _keyHasSeenOnboarding);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserData);
    } catch (_) {}
  }
}
