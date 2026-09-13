import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api/api_client.dart';
import '../core/config.dart';
import '../core/providers.dart';
import '../core/result.dart';
import '../models/models.dart';

/// Authentication state: who is signed in (if anyone) and whether we are busy.
class AuthState {
  final User? user;
  final bool isLoading;
  final bool bootstrapped;

  const AuthState({this.user, this.isLoading = false, this.bootstrapped = false});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    Object? user = _sentinel,
    bool? isLoading,
    bool? bootstrapped,
  }) =>
      AuthState(
        user: identical(user, _sentinel) ? this.user : user as User?,
        isLoading: isLoading ?? this.isLoading,
        bootstrapped: bootstrapped ?? this.bootstrapped,
      );
}

const Object _sentinel = Object();

/// Owns the Sanctum token (persisted in flutter_secure_storage — Keychain/Keystore) and the current User.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _bootstrap();
  }

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);
  FlutterSecureStorage get _storage => _ref.read(secureStorageProvider);

  /// Restore a persisted token on launch and fetch the profile.
  Future<void> _bootstrap() async {
    var token = await _storage.read(key: PrefsKeys.authToken);

    // One-time migration: move any legacy token out of plain SharedPreferences into secure storage.
    final prefs = _ref.read(sharedPrefsProvider);
    final legacy = prefs.getString(PrefsKeys.authToken);
    if (legacy != null) {
      token ??= legacy;
      if (legacy.isNotEmpty) {
        await _storage.write(key: PrefsKeys.authToken, value: legacy);
      }
      await prefs.remove(PrefsKeys.authToken);
    }

    if (token == null || token.isEmpty) {
      state = state.copyWith(bootstrapped: true);
      return;
    }
    _ref.read(tokenProvider.notifier).state = token;
    try {
      final res = await _api.get('/auth/me');
      state = state.copyWith(user: _api.mapData(res, User.fromJson), bootstrapped: true);
    } on DioException {
      // Token expired/invalid — clear it silently.
      await _clearToken();
      state = state.copyWith(user: null, bootstrapped: true);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.post('/auth/login', body: {
        'email': email,
        'password': password,
        'device_name': 'terrace-app',
      });
      await _consumeAuthPayload(res.data);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      throw AppFailure.fromDio(e);
    }
  }

  /// Email a 6-digit code for sign-up (`register`) or password reset (`reset`).
  Future<void> requestOtp({required String email, required String purpose}) async {
    try {
      await _api.post('/auth/otp/request', body: {'email': email, 'purpose': purpose});
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String otp,
    String? username,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.post('/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
        'otp': otp,
        if (username != null && username.isNotEmpty) 'username': username,
      });
      await _consumeAuthPayload(res.data);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      throw AppFailure.fromDio(e);
    }
  }

  /// Reset a password using the emailed code (no auth state change).
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      await _api.post('/auth/password/reset', body: {
        'email': email,
        'otp': otp,
        'password': password,
      });
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on DioException {
      // Best-effort; we clear locally regardless.
    }
    await _clearToken();
    state = state.copyWith(user: null, isLoading: false);
  }

  /// Permanently delete the account, then sign out locally.
  Future<void> deleteAccount() async {
    try {
      await _api.delete('/auth/account');
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
    await _clearToken();
    state = state.copyWith(user: null, isLoading: false);
  }

  /// Re-fetch /auth/me (e.g. after a profile or premium change).
  Future<void> refresh() async {
    if (_ref.read(tokenProvider) == null) return;
    try {
      final res = await _api.get('/auth/me');
      state = state.copyWith(user: _api.mapData(res, User.fromJson));
    } on DioException {
      // ignore; keep last-known user
    }
  }

  Future<void> _consumeAuthPayload(dynamic data) async {
    final map = (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final token = map['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: PrefsKeys.authToken, value: token);
      _ref.read(tokenProvider.notifier).state = token;
    }
    final userMap = map['user'];
    final user = (userMap is Map) ? User.fromJson(Map<String, dynamic>.from(userMap)) : null;
    state = state.copyWith(user: user, isLoading: false);

    if (user != null) {
      unawaited(_registerPush());
    }
  }

  /// Best-effort FCM device-token registration for push (no-op without Firebase / on web).
  Future<void> _registerPush() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await _api.post('/push-tokens', body: {
        'token': fcmToken,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
    } catch (_) {
      // Push is optional — never block sign-in on it.
    }
  }

  Future<void> _clearToken() async {
    await _storage.delete(key: PrefsKeys.authToken);
    _ref.read(tokenProvider.notifier).state = null;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));

/// Convenience: the current signed-in user, or null.
final currentUserProvider = Provider<User?>((ref) => ref.watch(authControllerProvider).user);
