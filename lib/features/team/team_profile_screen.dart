import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/app_providers.dart';
import '../../models/player.dart';
import '../../models/team.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';

class TeamProfileScreen extends ConsumerWidget {
  final int teamId;
  const TeamProfileScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamDetailProvider(teamId));
    return Scaffold(
      body: AsyncView(
        value: team,
        loading: const Center(child: CircularProgressIndicator()),
        onRetry: () => ref.invalidate(teamDetailProvider(teamId)),
        data: (t) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(t.displayName, style: const TextStyle(fontSize: 16)),
                background: _TeamHeader(team: t),
              ),
            ),
            SliverToBoxAdapter(child: _FollowBar(team: t)),
            SliverToBoxAdapter(child: _MetaRow(team: t)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text('FIXTURES', style: TerraceTextStyles.overline(context)),
              ),
            ),
            _TeamFixtures(teamId: teamId),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text('SQUAD', style: TerraceTextStyles.overline(context)),
              ),
            ),
            _TeamSquad(teamId: teamId),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _TeamHeader extends StatelessWidget {
  final Team team;
  const _TeamHeader({required this.team});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.brand, t.brandHover],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: TeamCrest(team: team, size: 64),
              ),
              const SizedBox(height: 10),
              Text(
                team.name,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (team.country != null)
                Text(team.country!, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowBar extends StatelessWidget {
  final Team team;
  const _FollowBar({required this.team});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: FollowButton(type: 'team', id: team.id, initialFollowing: team.isFollowing),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Team team;
  const _MetaRow({required this.team});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      if (team.venue != null) (LucideIcons.mapPin, 'Venue', team.venue!),
      if (team.founded != null) (LucideIcons.calendar, 'Founded', '${team.founded}'),
      if (team.league != null) (LucideIcons.trophy, 'League', team.league!.name),
    ];
    if (items.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          for (final it in items)
            Expanded(child: _MetaCell(icon: it.$1, label: it.$2, value: it.$3)),
        ],
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaCell({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.md),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: t.brand),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: TerraceTextStyles.overline(context)),
        ],
      ),
    );
  }
}

class _TeamFixtures extends ConsumerWidget {
  final int teamId;
  const _TeamFixtures({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixtures = ref.watch(teamFixturesProvider(teamId));
    return fixtures.when(
      loading: () => const SliverToBoxAdapter(child: MatchCardSkeleton()),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Fixtures unavailable.', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('No fixtures listed.'),
            ),
          );
        }
        return SliverList.builder(
          itemCount: list.length,
          itemBuilder: (context, i) => MatchCard(
            fixture: list[i],
            showLeague: true,
            onTap: () => context.push('/match/${list[i].id}'),
          ),
        );
      },
    );
  }
}

class _TeamSquad extends ConsumerWidget {
  final int teamId;
  const _TeamSquad({required this.teamId});

  // Group ordering for positions.
  static const _order = ['Goalkeeper', 'Defender', 'Midfielder', 'Forward'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squad = ref.watch(teamSquadProvider(teamId));
    return squad.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Squad unavailable.', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
      data: (players) {
        if (players.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('No squad listed.'),
            ),
          );
        }
        final groups = <String, List<Player>>{};
        for (final p in players) {
          groups.putIfAbsent(p.position ?? 'Other', () => []).add(p);
        }
        final keys = groups.keys.toList()
          ..sort((a, b) {
            final ia = _order.indexWhere((o) => a.startsWith(o));
            final ib = _order.indexWhere((o) => b.startsWith(o));
            return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
          });

        final children = <Widget>[];
        for (final key in keys) {
          children.add(Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Text(key.toUpperCase(), style: TerraceTextStyles.overline(context)),
          ));
          for (final p in groups[key]!) {
            children.add(_PlayerRow(player: p));
          }
        }
        return SliverList(delegate: SliverChildListDelegate(children));
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final Player player;
  const _PlayerRow({required this.player});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/player/${player.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  player.shirtNumber != null ? '${player.shirtNumber}' : '–',
                  style: TerraceTextStyles.mono(context, size: 14, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              InitialAvatar(imageUrl: player.photo, initials: player.initials, size: 34, seed: player.id),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                    if (player.nationality != null)
                      Text(player.nationality!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
