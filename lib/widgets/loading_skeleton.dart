import 'package:flutter/material.dart';

import '../theme/terrace_theme.dart';
import '../theme/terrace_tokens.dart';

/// A subtle shimmering placeholder block. Warm surfaces, gentle 1.2s sweep.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const Skeleton({super.key, this.width, this.height = 14, this.radius = TerraceRadii.sm});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final base = t.surfaceMuted;
    final highlight = t.surfaceInset;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * _c.value, 0),
              end: Alignment(1 - 2 * _c.value, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton shaped like a MatchCard row.
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.xl),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Skeleton(width: 32, height: 32, radius: 8),
              SizedBox(width: 12),
              Expanded(child: Skeleton(width: 120)),
              SizedBox(width: 12),
              Skeleton(width: 24, height: 22, radius: 6),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Skeleton(width: 32, height: 32, radius: 8),
              SizedBox(width: 12),
              Expanded(child: Skeleton(width: 100)),
              SizedBox(width: 12),
              Skeleton(width: 24, height: 22, radius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// A column of [MatchCardSkeleton]s for first-load lists.
class ListSkeleton extends StatelessWidget {
  final int count;
  const ListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: count,
      itemBuilder: (context, i) => const MatchCardSkeleton(),
    );
  }
}
