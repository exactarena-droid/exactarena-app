import 'package:flutter/material.dart';

import '../theme/terrace_theme.dart';

/// The signature LIVE pulse — the only persistent animation in the product.
/// A soft halo breathes ~1.6s behind a solid broadcast-red dot.
class LiveDot extends StatefulWidget {
  final double size;
  const LiveDot({super.key, this.size = 8});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = context.terrace.live;
    final halo = widget.size * 2.4;
    return SizedBox(
      width: halo,
      height: halo,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size + (halo - widget.size) * t,
                height: widget.size + (halo - widget.size) * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: live.withValues(alpha: (1 - t) * 0.35),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: live),
        ),
      ),
    );
  }
}

/// A LIVE label + pulse pill. Color is never the only signal (text + shape too).
class LiveBadge extends StatelessWidget {
  final String? detail; // e.g. "67'"
  const LiveBadge({super.key, this.detail});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: t.live.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LiveDot(size: 7),
          const SizedBox(width: 5),
          Text(
            detail != null && detail!.isNotEmpty ? detail! : 'LIVE',
            style: TextStyle(
              color: t.live,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
