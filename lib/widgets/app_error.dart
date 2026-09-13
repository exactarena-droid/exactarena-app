import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/result.dart';
import '../theme/terrace_theme.dart';

/// A friendly inline error with a retry action. Accepts any error object and
/// renders [AppFailure.message] when available.
class AppErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final bool offline;

  const AppErrorView({super.key, required this.error, this.onRetry, this.offline = false});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final message = error is AppFailure
        ? (error as AppFailure).message
        : 'Something went wrong. Please try again.';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                offline ? LucideIcons.wifiOff : LucideIcons.alertTriangle,
                color: t.danger,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              offline ? "You're offline" : 'Could not load',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
