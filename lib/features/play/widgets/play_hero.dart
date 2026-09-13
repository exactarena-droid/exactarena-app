import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/models.dart';
import '../../../theme/terrace_theme.dart';
import '../../../theme/terrace_tokens.dart';
import '../play_screen.dart';

/// The Play hero strip: gameweek name + lock countdown, plus the fan's
/// rank / points / streak as big tabular stats.
class PlayHero extends StatelessWidget {
  final ChallengeRound round;
  final ChallengeMe? me;
  const PlayHero({super.key, required this.round, this.me});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.brightness == Brightness.dark
              ? [TerraceColors.pitch900, t.surface]
              : [TerraceColors.pitch700, TerraceColors.pitch600],
        ),
        borderRadius: BorderRadius.circular(TerraceRadii.xl2),
        boxShadow: t.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'GAMEWEEK',
                style: TerraceTextStyles.overline(context, color: Colors.white.withValues(alpha: 0.7)),
              ),
              const Spacer(),
              _LockChip(round: round),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            round.name,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroStat(
                value: me == null ? '—' : _ordinalShort(me!.rank),
                label: 'Rank',
                emphasised: true,
              ),
              _HeroDivider(),
              _HeroStat(
                value: me == null ? '0' : '${me!.points}',
                label: 'Points',
                emphasised: true,
              ),
              _HeroDivider(),
              _HeroStat(
                value: me == null ? '0' : '${me!.streak}',
                label: 'Streak',
                icon: (me?.streak ?? 0) > 0 ? LucideIcons.flame : null,
              ),
            ],
          ),
          if (me != null && me!.fixtures > 0) ...[
            const SizedBox(height: 16),
            _CalledProgress(called: me!.called, total: me!.fixtures),
          ],
        ],
      ),
    );
  }

  static String _ordinalShort(int n) {
    if (n <= 0) return '—';
    final mod100 = n % 100;
    final mod10 = n % 10;
    String suffix;
    if (mod100 >= 11 && mod100 <= 13) {
      suffix = 'th';
    } else if (mod10 == 1) {
      suffix = 'st';
    } else if (mod10 == 2) {
      suffix = 'nd';
    } else if (mod10 == 3) {
      suffix = 'rd';
    } else {
      suffix = 'th';
    }
    return '$n$suffix';
  }
}

class _LockChip extends StatelessWidget {
  final ChallengeRound round;
  const _LockChip({required this.round});

  @override
  Widget build(BuildContext context) {
    final locked = round.isLocked;
    final fg = Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(TerraceRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(locked ? LucideIcons.lock : LucideIcons.clock, size: 13, color: fg),
          const SizedBox(width: 6),
          locked
              ? Text('Locked',
                  style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700))
              : CountdownText(
                  locksAt: round.locksAt,
                  style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
                ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final bool emphasised;
  final IconData? icon;
  const _HeroStat({
    required this.value,
    required this.label,
    this.emphasised = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TerraceTextStyles.scoreboard(context, size: emphasised ? 32 : 28)
                      .copyWith(color: Colors.white),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _CalledProgress extends StatelessWidget {
  final int called;
  final int total;
  const _CalledProgress({required this.called, required this.total});

  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : (called / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'You’ve called $called of $total',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(TerraceRadii.full),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ],
    );
  }
}
