import 'dart:developer' as developer;
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Supported client runtime environments for network base URL resolution.
enum DeviceEnvironment {
  androidEmulator,
  androidPhysicalDevice,
  ios,
  desktop,
  web,
  unknown;

  String get displayName {
    switch (this) {
      case DeviceEnvironment.androidEmulator:
        return 'Android Emulator (Loopback 10.0.2.2)';
      case DeviceEnvironment.androidPhysicalDevice:
        return 'Physical Android Device (USB / ADB Reverse 127.0.0.1)';
      case DeviceEnvironment.ios:
        return 'iOS Device / Simulator';
      case DeviceEnvironment.desktop:
        return 'Desktop Host';
      case DeviceEnvironment.web:
        return 'Web Client';
      case DeviceEnvironment.unknown:
        return 'Unknown Host Platform';
    }
  }
}

/// Asynchronously resolves the appropriate API base URL for the current runtime environment.
///
/// URL Resolution Rules:
/// 1. Explicit override URL (if provided) always takes precedence.
/// 2. Android Emulator -> `http://10.0.2.2:8000/api/v1`
/// 3. Physical Android Device -> `http://127.0.0.1:8000/api/v1`
///    (Note: Requires host reverse port forwarding: `adb reverse tcp:8000 tcp:8000`)
/// 4. iOS / Desktop / Web / Other -> `http://127.0.0.1:8000/api/v1`
class ApiBaseUrlResolver {
  final DeviceInfoPlugin _deviceInfo;

  ApiBaseUrlResolver({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Detects the current device and platform environment.
  Future<DeviceEnvironment> detectEnvironment() async {
    if (kIsWeb) {
      return DeviceEnvironment.web;
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.isPhysicalDevice
            ? DeviceEnvironment.androidPhysicalDevice
            : DeviceEnvironment.androidEmulator;
      } else if (Platform.isIOS) {
        return DeviceEnvironment.ios;
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return DeviceEnvironment.desktop;
      }
    } catch (e) {
      developer.log(
        'Warning: Device inspection error ($e). Defaulting to unknown.',
        name: 'DocuMind.Network',
      );
    }

    return DeviceEnvironment.unknown;
  }

  /// Resolves the full API base URL including the `/api/v1` path exactly once.
  ///
  /// URL Resolution Precedence:
  /// 1. Explicit runtime [overrideUrl] parameter (if provided).
  /// 2. Compile-time environment define (`DOCUMIND_API_BASE_URL`).
  /// 3. Platform & device auto-detection defaults (Emulator vs Physical vs iOS/Desktop).
  ///
  /// Safe diagnostic logging is emitted to identify the selected runtime environment
  /// and target URL without exposing any credentials, tokens, or sensitive data.
  Future<String> resolveBaseUrl({String? overrideUrl}) async {
    // 1. Explicit runtime override takes highest precedence
    if (overrideUrl != null && overrideUrl.trim().isNotEmpty) {
      final normalized = normalizeUrl(overrideUrl);
      developer.log(
        'API Base URL: Explicit runtime override applied -> $normalized',
        name: 'DocuMind.Network',
      );
      return normalized;
    }

    // 2. Compile-time environment override (--dart-define=DOCUMIND_API_BASE_URL=...)
    const envUrl = String.fromEnvironment(
      AppConstants.apiBaseUrlEnvironmentKey,
      defaultValue: '',
    );
    if (envUrl.trim().isNotEmpty) {
      final normalized = normalizeUrl(envUrl);
      developer.log(
        'API Base URL: Compile-time define override applied (${AppConstants.apiBaseUrlEnvironmentKey}) -> $normalized',
        name: 'DocuMind.Network',
      );
      return normalized;
    }

    // 3. Automatic platform & device detection
    final environment = await detectEnvironment();
    final String resolvedBase;

    switch (environment) {
      case DeviceEnvironment.androidEmulator:
        resolvedBase =
            '${AppConstants.defaultAndroidEmulatorBaseUrl}${AppConstants.apiVersionPath}';
        developer.log(
          'API Base URL: ${environment.displayName} -> $resolvedBase',
          name: 'DocuMind.Network',
        );
        break;

      case DeviceEnvironment.androidPhysicalDevice:
        resolvedBase =
            '${AppConstants.defaultPhysicalAndroidBaseUrl}${AppConstants.apiVersionPath}';
        developer.log(
          'API Base URL: ${environment.displayName} -> $resolvedBase '
          '[Notice: Ensure "adb reverse tcp:8000 tcp:8000" is active on development workstation]',
          name: 'DocuMind.Network',
        );
        break;

      case DeviceEnvironment.ios:
      case DeviceEnvironment.desktop:
      case DeviceEnvironment.web:
      case DeviceEnvironment.unknown:
        resolvedBase =
            '${AppConstants.defaultIosBaseUrl}${AppConstants.apiVersionPath}';
        developer.log(
          'API Base URL: ${environment.displayName} -> $resolvedBase',
          name: 'DocuMind.Network',
        );
        break;
    }

    return normalizeUrl(resolvedBase);
  }

  /// Sanitizes and formats the URL so that `/api/v1` is present exactly once,
  /// removing redundant trailing slashes.
  static String normalizeUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.endsWith(AppConstants.apiVersionPath)) {
      trimmed = '$trimmed${AppConstants.apiVersionPath}';
    }
    return trimmed;
  }
}

