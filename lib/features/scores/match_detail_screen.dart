import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/app_providers.dart';
import '../../models/fixture.dart';
import '../../models/fixture_event.dart';
import '../../models/team.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';
import '../community/post_tile.dart';
import 'fan_ratings_section.dart';

class MatchDetailScreen extends ConsumerWidget {
  final int fixtureId;
  const MatchDetailScreen({super.key, required this.fixtureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(fixtureDetailProvider(fixtureId));
    return Scaffold(
      appBar: AppBar(title: const Text('Match')),
      body: AsyncView(
        value: detail,
        loading: const _DetailSkeleton(),
        onRetry: () => ref.invalidate(fixtureDetailProvider(fixtureId)),
        data: (f) => RefreshIndicator(
          color: context.terrace.brand,
          onRefresh: () => ref.refresh(fixtureDetailProvider(fixtureId).future),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _Scoreboard(fixture: f),
              if (f.events.isNotEmpty) ...[
                const _SectionLabel('Timeline'),
                _Timeline(fixture: f),
              ],
              if (f.isLive || f.isFinished) ...[
                const _SectionLabel('Fan ratings'),
                FanRatingsSection(fixture: f),
              ],
              const _SectionLabel('Match info'),
              _MatchInfo(fixture: f),
              if (f.hasThread) ...[
                const _SectionLabel('Match thread'),
                _ThreadPreview(fixtureId: f.id),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  final Fixture fixture;
  const _Scoreboard({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final f = fixture;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.brandSubtle, t.surface],
        ),
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Column(
        children: [
          if (f.league != null)
            Text(
              '${f.league!.name}${f.round != null ? " · ${f.round}" : ""}'.toUpperCase(),
              style: TerraceTextStyles.overline(context, color: t.brand),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _TeamColumn(team: f.homeTeam)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    if (f.hasScore)
                      Text(
                        '${f.homeScore}  ${f.awayScore}',
                        style: TerraceTextStyles.scoreboard(context, size: 40),
                      )
                    else
                      Text(
                        f.kickoffAt != null
                            ? DateFormat('HH:mm').format(f.kickoffAt!.toLocal())
                            : 'TBD',
                        style: TerraceTextStyles.scoreboard(context, size: 30),
                      ),
                    const SizedBox(height: 8),
                    _StatusPill(fixture: f),
                  ],
                ),
              ),
              Expanded(child: _TeamColumn(team: f.awayTeam)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final Team? team;
  const _TeamColumn({required this.team});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: team == null ? null : () => context.push('/team/${team!.id}'),
      child: Column(
        children: [
          TeamCrest(team: team, size: 54),
          const SizedBox(height: 10),
          Text(
            team?.displayName ?? 'TBD',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Fixture fixture;
  const _StatusPill({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final f = fixture;
    if (f.isLive) return LiveBadge(detail: f.isHalftime ? 'HT' : (f.statusDetail ?? "${f.minute ?? 0}'"));
    final label = switch (f.status) {
      FixtureStatus.finished => 'FULL TIME',
      FixtureStatus.postponed => 'POSTPONED',
      FixtureStatus.canceled => 'CANCELLED',
      _ => f.kickoffAt != null ? DateFormat('EEE d MMM').format(f.kickoffAt!.toLocal()) : 'SCHEDULED',
    };
    return Text(label.toUpperCase(), style: TerraceTextStyles.overline(context, color: t.textSecondary));
  }
}

class _Timeline extends StatelessWidget {
  final Fixture fixture;
  const _Timeline({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final events = [...fixture.events]..sort((a, b) => a.minute.compareTo(b.minute));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [for (final e in events) _EventRow(event: e, fixture: fixture)],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final FixtureEvent event;
  final Fixture fixture;
  const _EventRow({required this.event, required this.fixture});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final isHome = event.teamId != null && event.teamId == fixture.homeTeam?.id;
    final (icon, color) = _iconFor(event.type, t);

    final detail = Column(
      crossAxisAlignment: isHome ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          event.player?.name ?? _label(event.type),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        if (event.relatedPlayer != null || event.detail != null)
          Text(
            event.type == FixtureEventType.substitution && event.relatedPlayer != null
                ? 'for ${event.relatedPlayer!.name}'
                : (event.detail ?? ''),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );

    final minuteChip = Container(
      width: 42,
      alignment: Alignment.center,
      child: Text(event.minuteLabel, style: TerraceTextStyles.mono(context, size: 12, weight: FontWeight.w700)),
    );

    final iconBox = Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: color),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: isHome
            ? [Expanded(child: Align(alignment: Alignment.centerLeft, child: detail)), iconBox, minuteChip, const Spacer()]
            : [const Spacer(), minuteChip, iconBox, Expanded(child: Align(alignment: Alignment.centerRight, child: detail))],
      ),
    );
  }

  (IconData, Color) _iconFor(FixtureEventType type, TerraceTheme t) {
    switch (type) {
      case FixtureEventType.goal:
      case FixtureEventType.penalty:
        return (LucideIcons.circleDot, t.brand);
      case FixtureEventType.ownGoal:
        return (LucideIcons.circleDot, t.danger);
      case FixtureEventType.missedPenalty:
        return (LucideIcons.circleOff, t.textMuted);
      case FixtureEventType.yellow:
        return (LucideIcons.square, t.warning);
      case FixtureEventType.red:
        return (LucideIcons.square, t.danger);
      case FixtureEventType.substitution:
        return (LucideIcons.repeat, t.info);
      case FixtureEventType.varReview:
        return (LucideIcons.monitor, t.textSecondary);
      case FixtureEventType.unknown:
        return (LucideIcons.dot, t.textMuted);
    }
  }

  String _label(FixtureEventType type) => switch (type) {
        FixtureEventType.goal || FixtureEventType.penalty => 'Goal',
        FixtureEventType.ownGoal => 'Own goal',
        FixtureEventType.missedPenalty => 'Missed penalty',
        FixtureEventType.yellow => 'Yellow card',
        FixtureEventType.red => 'Red card',
        FixtureEventType.substitution => 'Substitution',
        FixtureEventType.varReview => 'VAR review',
        FixtureEventType.unknown => 'Event',
      };
}

class _MatchInfo extends StatelessWidget {
  final Fixture fixture;
  const _MatchInfo({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final f = fixture;
    final rows = <(IconData, String, String)>[
      if (f.kickoffAt != null)
        (LucideIcons.calendar, 'Kickoff', DateFormat('EEE d MMM y · HH:mm').format(f.kickoffAt!.toLocal())),
      if (f.venue != null) (LucideIcons.mapPin, 'Venue', f.venue!),
      if (f.league != null) (LucideIcons.trophy, 'Competition', f.league!.name),
      if (f.round != null) (LucideIcons.flag, 'Round', f.round!),
      if (f.season != null) (LucideIcons.calendarDays, 'Season', f.season!),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.xl),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: t.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 18, color: t.textMuted),
                  const SizedBox(width: 12),
                  Text(rows[i].$2, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      rows[i].$3,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThreadPreview extends ConsumerWidget {
  final int fixtureId;
  const _ThreadPreview({required this.fixtureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.terrace;
    final thread = ref.watch(fixtureThreadProvider(fixtureId));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.xl),
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: thread.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Thread unavailable right now.', style: Theme.of(context).textTheme.bodyMedium),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(LucideIcons.messageCircle, size: 18, color: t.textMuted),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Be the first to post on match day.', style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            );
          }
          final preview = posts.take(2).toList();
          return Column(
            children: [
              for (var i = 0; i < preview.length; i++) ...[
                if (i > 0) Divider(height: 1, color: t.border),
                PostTile(post: preview[i]),
              ],
              Divider(height: 1, color: t.border),
              InkWell(
                onTap: () => context.push('/thread/$fixtureId'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Open match thread',
                          style: TextStyle(color: t.brand, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.arrowRight, size: 16, color: t.brand),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(text.toUpperCase(), style: TerraceTextStyles.overline(context)),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Skeleton(height: 150, radius: TerraceRadii.xl),
        SizedBox(height: 20),
        Skeleton(width: 120, height: 14),
        SizedBox(height: 16),
        Skeleton(height: 60, radius: TerraceRadii.lg),
        SizedBox(height: 10),
        Skeleton(height: 60, radius: TerraceRadii.lg),
      ],
    );
  }
}
