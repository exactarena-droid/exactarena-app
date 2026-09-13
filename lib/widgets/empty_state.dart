import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/terrace_theme.dart';

/// Storyset-illustrated empty state. Pass one of the bundled onboarding/empty
/// SVG asset paths, a headline, and an optional supporting line + action.
class EmptyState extends StatelessWidget {
  final String? assetPath; // e.g. 'assets/onboarding/empty-news.svg'
  final IconData? icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    this.assetPath,
    this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assetPath != null)
              SvgPicture.asset(assetPath!, width: 200, height: 170, fit: BoxFit.contain)
            else if (icon != null)
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.brandSubtle, shape: BoxShape.circle),
                child: Icon(icon, size: 34, color: t.brand),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
