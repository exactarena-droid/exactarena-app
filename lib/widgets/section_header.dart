import 'package:flutter/material.dart';

import '../theme/terrace_theme.dart';

/// An editorial section header: small uppercase eyebrow + bold display title,
/// with an optional trailing action. Deliberately left-aligned (not centered).
class SectionHeader extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: TerraceTextStyles.overline(context, color: t.brand),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
