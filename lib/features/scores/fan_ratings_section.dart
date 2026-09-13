import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/app_providers.dart';
import '../../data/auth_controller.dart';
import '../../data/repositories.dart';
import '../../models/fixture.dart';
import '../../models/fixture_ratings.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';

/// "Fan ratings" surface on the match-detail screen: a Man-of-the-Match hero
/// plus a per-side list of players fans can rate 1–10. This is opinion on a
/// past PERFORMANCE (like a MOTM vote), never a forecast — see COMPLIANCE.md.
class FanRatingsSection extends ConsumerWidget {
  final Fixture fixture;
  const FanRatingsSection({super.key, required this.fixture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratings = ref.watch(fixtureRatingsProvider(fixture.id));
    return ratings.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Skeleton(height: 132, radius: TerraceRadii.xl),
            SizedBox(height: 12),
            Skeleton(height: 64, radius: TerraceRadii.lg),
            SizedBox(height: 10),
            Skeleton(height: 64, radius: TerraceRadii.lg),
          ],
        ),
      ),
      // Failing softly: a sport section should never blow up the whole screen.
      error: (e, _) => const SizedBox.shrink(),
      data: (r) => _RatingsBody(fixture: fixture, ratings: r),
    );
  }
}

class _RatingsBody extends StatelessWidget {
  final Fixture fixture;
  final FixtureRatings ratings;
  const _RatingsBody({required this.fixture, required this.ratings});

  @override
  Widget build(BuildContext context) {
    final home = ratings.players.where((p) => p.isHome).toList();
    final away = ratings.players.where((p) => !p.isHome).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ratings.motm != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _MotmHero(verdict: ratings.motm!, fixture: fixture),
          ),
        if (!ratings.canRate)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _RatingsClosedNote(),
          ),
        if (home.isNotEmpty) ...[
          _SideHeading(
            label: fixture.homeTeam?.displayName ?? 'Home',
            count: home.length,
          ),
          for (final row in home)
            _PlayerRatingTile(fixture: fixture, row: row, canRate: ratings.canRate),
        ],
        if (away.isNotEmpty) ...[
          _SideHeading(
            label: fixture.awayTeam?.displayName ?? 'Away',
            count: away.length,
          ),
          for (final row in away)
            _PlayerRatingTile(fixture: fixture, row: row, canRate: ratings.canRate),
        ],
      ],
    );
  }
}

/// Man-of-the-Match hero — Floodlight-amber accent, crown, big tabular average.
class _MotmHero extends StatelessWidget {
  final PlayerVerdict verdict;
  final Fixture fixture;
  const _MotmHero({required this.verdict, required this.fixture});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final accent = t.accent;
    final p = verdict.player;
    final shirt = p.shirtNumber;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TerraceRadii.xl),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.14), t.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.crown, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'MAN OF THE MATCH',
                style: TerraceTextStyles.overline(context, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ShirtBadge(number: shirt, color: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.position ?? 'Fan verdict',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        verdict.avg.toStringAsFixed(1),
                        style: TerraceTextStyles.scoreboard(context, size: 38)
                            .copyWith(color: accent),
                      ),
                      const SizedBox(width: 2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '/10',
                          style: TerraceTextStyles.mono(context, size: 13, color: t.textMuted),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${verdict.votes} fans rated',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShirtBadge extends StatelessWidget {
  final int? number;
  final Color color;
  const _ShirtBadge({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(TerraceRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: number == null
          ? Icon(LucideIcons.user, size: 22, color: color)
          : Text(
              '$number',
              style: TerraceTextStyles.mono(context, size: 22, weight: FontWeight.w700, color: color),
            ),
    );
  }
}

class _SideHeading extends StatelessWidget {
  final String label;
  final int count;
  const _SideHeading({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: TerraceTextStyles.overline(context)),
          const SizedBox(width: 8),
          Text('· $count', style: TerraceTextStyles.overline(context, color: t.textMuted)),
        ],
      ),
    );
  }
}

class _PlayerRatingTile extends ConsumerWidget {
  final Fixture fixture;
  final PlayerRatingRow row;
  final bool canRate;
  const _PlayerRatingTile({required this.fixture, required this.row, required this.canRate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.terrace;
    final p = row.player;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.lg),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          _MiniShirt(number: p.shirtNumber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (p.position != null) ...[
                      Text(p.position!, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${row.votes} ${row.votes == 1 ? "vote" : "votes"}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RatingPill(avg: row.avg, votes: row.votes),
          const SizedBox(width: 8),
          _RateControl(
            fixture: fixture,
            row: row,
            canRate: canRate,
          ),
        ],
      ),
    );
  }
}

class _MiniShirt extends StatelessWidget {
  final int? number;
  const _MiniShirt({required this.number});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceMuted,
        borderRadius: BorderRadius.circular(TerraceRadii.sm),
      ),
      child: number == null
          ? Icon(LucideIcons.user, size: 18, color: t.textMuted)
          : Text(
              '$number',
              style: TerraceTextStyles.mono(context, size: 15, weight: FontWeight.w700, color: t.textSecondary),
            ),
    );
  }
}

/// Average-rating pill on a color scale:
///   ≥ 8 pitch-green · 7–8 neutral · 6–7 muted · < 6 rose.
class _RatingPill extends StatelessWidget {
  final double avg;
  final int votes;
  const _RatingPill({required this.avg, required this.votes});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    if (votes == 0) {
      return Container(
        width: 46,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.surfaceMuted,
          borderRadius: BorderRadius.circular(TerraceRadii.md),
        ),
        child: Text('–', style: TerraceTextStyles.tableNum(context, size: 15, color: t.textMuted)),
      );
    }
    final (fg, bg) = _scale(t);
    return Container(
      width: 46,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TerraceRadii.md),
      ),
      child: Text(
        avg.toStringAsFixed(1),
        style: TerraceTextStyles.tableNum(context, size: 15, weight: FontWeight.w700, color: fg),
      ),
    );
  }

  (Color fg, Color bg) _scale(TerraceTheme t) {
    if (avg >= 8) return (t.brand, t.brandSubtle);
    if (avg >= 7) return (t.textPrimary, t.surfaceMuted);
    if (avg >= 6) return (t.textMuted, t.surfaceMuted);
    return (t.danger, t.danger.withValues(alpha: 0.12));
  }
}

class _RateControl extends ConsumerWidget {
  final Fixture fixture;
  final PlayerRatingRow row;
  final bool canRate;
  const _RateControl({required this.fixture, required this.row, required this.canRate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.terrace;
    final mine = row.myRating;

    // Already rated → show the user's own verdict, highlighted; tap to change.
    if (mine != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(TerraceRadii.md),
        onTap: canRate ? () => _open(context, ref) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: t.brand,
            borderRadius: BorderRadius.circular(TerraceRadii.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.check, size: 14, color: t.textOnBrand),
              const SizedBox(width: 5),
              Text(
                'You $mine',
                style: TerraceTextStyles.tableNum(context, size: 13, weight: FontWeight.w700, color: t.textOnBrand),
              ),
            ],
          ),
        ),
      );
    }

    if (!canRate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.surfaceMuted,
          borderRadius: BorderRadius.circular(TerraceRadii.md),
        ),
        child: Icon(LucideIcons.lock, size: 15, color: t.textMuted),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(TerraceRadii.md),
      onTap: () => _open(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.brandSubtle,
          borderRadius: BorderRadius.circular(TerraceRadii.md),
          border: Border.all(color: t.brand.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.star, size: 14, color: t.brand),
            const SizedBox(width: 5),
            Text('Rate', style: TextStyle(color: t.brand, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    // Not signed in → route to the existing auth flow (matches FollowButton).
    if (ref.read(currentUserProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sign in to rate the performance.'),
          action: SnackBarAction(label: 'Sign in', onPressed: () => context.push('/login')),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RateSheet(fixture: fixture, row: row),
    );
  }
}

/// Bottom sheet to pick a 1–10 rating for a player's performance, then POST.
class _RateSheet extends ConsumerStatefulWidget {
  final Fixture fixture;
  final PlayerRatingRow row;
  const _RateSheet({required this.fixture, required this.row});

  @override
  ConsumerState<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends ConsumerState<_RateSheet> {
  late int _value = widget.row.myRating ?? 7;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final p = widget.row.player;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.star, size: 16, color: t.brand),
              const SizedBox(width: 8),
              Text('RATE PERFORMANCE', style: TerraceTextStyles.overline(context, color: t.brand)),
            ],
          ),
          const SizedBox(height: 10),
          Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
          if (p.position != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(p.position!, style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 18),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_value',
                  style: TerraceTextStyles.scoreboard(context, size: 44).copyWith(color: t.brand),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'out of 10',
                    style: TerraceTextStyles.mono(context, size: 13, color: t.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var n = 1; n <= 10; n++) _ScoreChip(value: n, selected: n == _value, onTap: () => setState(() => _value = n)),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.row.myRating == null ? 'Submit verdict' : 'Update verdict'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(ratingsRepositoryProvider).rate(widget.fixture.id, widget.row.player.id, _value);
      ref.invalidate(fixtureRatingsProvider(widget.fixture.id));
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Your verdict on ${widget.row.player.name}: $_value/10.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save your verdict. Try again.')),
      );
    }
  }
}

class _ScoreChip extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;
  const _ScoreChip({required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return InkWell(
      borderRadius: BorderRadius.circular(TerraceRadii.md),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? t.brand : t.surfaceMuted,
          borderRadius: BorderRadius.circular(TerraceRadii.md),
          border: Border.all(color: selected ? t.brand : t.border),
        ),
        child: Text(
          '$value',
          style: TerraceTextStyles.tableNum(
            context,
            size: 17,
            weight: FontWeight.w700,
            color: selected ? t.textOnBrand : t.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Tasteful note shown before kickoff, when fans can't yet rate.
class _RatingsClosedNote extends StatelessWidget {
  const _RatingsClosedNote();

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.surfaceMuted,
        borderRadius: BorderRadius.circular(TerraceRadii.lg),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock, size: 18, color: t.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ratings open at kickoff. Come back to give your fan verdict.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
