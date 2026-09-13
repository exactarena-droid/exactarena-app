import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/terrace_theme.dart';

/// Floodlight-amber PRO badge for premium content. Amber is never the only
/// signal — it always carries the "PRO" label and a crown glyph.
class PremiumBadge extends StatelessWidget {
  final String label;
  final bool compact;
  const PremiumBadge({super.key, this.label = 'PRO', this.compact = false});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.crown, size: compact ? 11 : 13, color: t.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: t.accent,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// A neutral chip for "Sponsored" editorial — clearly labeled, low-key.
class SponsoredChip extends StatelessWidget {
  final String? sponsor;
  const SponsoredChip({super.key, this.sponsor});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final text = sponsor != null && sponsor!.isNotEmpty ? 'Sponsored · $sponsor' : 'Sponsored';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.surfaceInset,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: t.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
