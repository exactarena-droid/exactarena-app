import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart'; // Внасяме localeProvider от главния файл
import '../config.dart';
import '../providers.dart';

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

  T mapData<T>(Response<dynamic> res, T Function(Map<String, dynamic>) fromJson) {
    final body = res.data;
    final data = (body is Map && body.containsKey('data')) ? body['data'] : body;
    return fromJson(Map<String, dynamic>.from(data as Map));
  }

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

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBase,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // ─── АВТОМАТИЧНО ИЗПРАЩАНЕ НА ЕЗИКА КЪМ СЪРВЪРА ───
        final currentLocale = ref.read(localeProvider);
        options.headers['Accept-Language'] = currentLocale.languageCode;
        // ───────────────────────────────────────────────────

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
