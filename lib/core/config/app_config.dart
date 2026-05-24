// lib/core/config/app_config.dart
//
// Configure at build/run time:
//   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
//   flutter run --dart-define=ENABLE_REMOTE_LOGGING=true
//
// Leave API_BASE_URL empty for offline-only mode (MonumentRegistry fallback).

class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const bool enableRemoteLogging = bool.fromEnvironment(
    'ENABLE_REMOTE_LOGGING',
    defaultValue: false,
  );

  static bool get hasApi => apiBaseUrl.isNotEmpty;

  static bool get remoteLoggingEnabled => hasApi && enableRemoteLogging;
}
