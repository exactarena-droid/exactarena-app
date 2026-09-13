import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// SharedPreferences is loaded once in main() and injected via override.
/// Used only for non-sensitive preferences (e.g. theme). The auth token lives in secure storage.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden in main()'),
);

/// OS-backed secure storage (Keychain on iOS, Keystore/EncryptedSharedPreferences on Android).
/// The sensitive Sanctum token is persisted here, never in plain SharedPreferences.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

/// Holds the current Sanctum bearer token (null when signed out).
/// The Dio interceptor reads this to attach Authorization headers.
final tokenProvider = StateProvider<String?>((ref) => null);

/// App theme mode, persisted in shared_preferences. Defaults to light (the
/// brand default), with dark as a first-class match-day option.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs) : super(_read(_prefs));
  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    switch (prefs.getString(PrefsKeys.themeMode)) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(PrefsKeys.themeMode, mode.name);
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    set(next);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(ref.watch(sharedPrefsProvider)),
);
