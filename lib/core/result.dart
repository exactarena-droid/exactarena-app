import 'package:dio/dio.dart';

/// A friendly, render-ready failure. Repositories convert Dio/parse errors
/// into these so the UI never has to inspect raw exceptions.
class AppFailure implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;

  const AppFailure(this.message, {this.statusCode, this.fieldErrors});

  bool get isUnauthorized => statusCode == 401;
  bool get isLocked => statusCode == 423;
  bool get isValidation => statusCode == 422;

  /// First validation message for [field], if any.
  String? fieldError(String field) {
    final list = fieldErrors?[field];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  factory AppFailure.fromDio(DioException e) {
    final res = e.response;
    final status = res?.statusCode;
    final data = res?.data;

    String message = 'Something went wrong. Please try again.';
    Map<String, List<String>>? fields;

    if (data is Map) {
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        message = data['message'] as String;
      }
      final errs = data['errors'];
      if (errs is Map) {
        fields = errs.map((k, v) => MapEntry(
              k.toString(),
              (v is List) ? v.map((e) => e.toString()).toList() : [v.toString()],
            ));
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        message = 'The connection timed out. Check your network and try again.';
        break;
      case DioExceptionType.connectionError:
        message = "Can't reach Terrace right now. Check your connection.";
        break;
      default:
        if (status == 401) message = 'Please sign in to continue.';
        if (status == 403) message = "You don't have access to that.";
        if (status == 404) message = 'Not found.';
        if (status == 423) message = 'This is premium content.';
        break;
    }

    return AppFailure(message, statusCode: status, fieldErrors: fields);
  }

  @override
  String toString() => 'AppFailure($statusCode): $message';
}
