import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import 'app_error.dart';

/// Renders an AsyncValue with consistent loading / error handling.
/// Pass a custom [loading] (e.g. a skeleton) per surface.
class AsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;

  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        final offline = e is AppFailure && e.statusCode == null;
        return AppErrorView(error: e, onRetry: onRetry, offline: offline);
      },
    );
  }
}
