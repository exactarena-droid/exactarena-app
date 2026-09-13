import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../providers.dart';

/// Thin Dio wrapper for the Terrace API.
///
/// - Base URL is [kApiBase] (Android emulator host; see config for iOS/web note).
/// - A request interceptor attaches the bearer token from [tokenProvider].
/// - Helpers unwrap the `{ data: ... }` envelope the API uses.
class ApiClient {
  final Dio dio;
  ApiClient(this.dio);

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      dio.get(path, queryParameters: _clean(query));

  Future<Response<dynamic>> post(String path, {Object? body}) =>
      dio.post(path, data: body);

  Future<Response<dynamic>> put(String path, {Object? body}) =>
      dio.put(path, data: body);

  Future<Response<dynamic>> delete(String path, {Object? body}) =>
      dio.delete(path, data: body);

  /// Unwrap a single resource `{ "data": {...} }` and map it.
  T mapData<T>(Response<dynamic> res, T Function(Map<String, dynamic>) fromJson) {
    final body = res.data;
    final data = (body is Map && body.containsKey('data')) ? body['data'] : body;
    return fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Unwrap a collection `{ "data": [...] }` (or a bare list) and map each item.
  List<T> mapList<T>(Response<dynamic> res, T Function(Map<String, dynamic>) fromJson) {
    final body = res.data;
    final list = (body is Map && body.containsKey('data')) ? body['data'] : body;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? q) {
    if (q == null) return null;
    final out = <String, dynamic>{};
    q.forEach((k, v) {
      if (v != null) out[k] = v;
    });
    return out.isEmpty ? null : out;
  }
}

/// Dio instance with the bearer-token interceptor wired to [tokenProvider].
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBase,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
      // We handle non-2xx ourselves via AppFailure, but let Dio throw so
      // repositories can catch DioException in one place.
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(tokenProvider);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
