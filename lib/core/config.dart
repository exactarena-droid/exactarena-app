/// Static app configuration.
///
/// [kApiBase] points at the production API by default. To run against a local
/// backend during development, pass --dart-define=API_BASE=http://10.0.2.2:8000/api/v1
/// (Android emulator) or http://127.0.0.1:8000/api/v1 (iOS sim / web / desktop).
const String _apiBaseOverride = String.fromEnvironment('API_BASE');

/// Change this one line to re-point the app at your own server.
const String kApiBaseDefault = 'https://exactarena.com/api/v1';

final String kApiBase = _apiBaseOverride.isNotEmpty ? _apiBaseOverride : kApiBaseDefault;

/// shared_preferences keys.
abstract final class PrefsKeys {
  static const seenOnboarding = 'terrace.seen_onboarding';
  static const authToken = 'terrace.auth_token';
  static const themeMode = 'terrace.theme_mode';
}
