import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/app_providers.dart';
import '../../models/fixture.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';

/// Community hub: surfaces match-day threads from live and today's fixtures.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(fixturesProvider(const FixturesQuery(tab: 'live')));
    final today = ref.watch(fixturesProvider(const FixturesQuery(tab: 'today')));

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          const SliverAppBar(pinned: true, floating: true, title: Text('Community')),
        ],
        body: RefreshIndicator(
          color: context.terrace.brand,
          onRefresh: () async {
            ref.invalidate(fixturesProvider(const FixturesQuery(tab: 'live')));
            ref.invalidate(fixturesProvider(const FixturesQuery(tab: 'today')));
          },
          child: AsyncView(
            value: today,
            loading: const ListSkeleton(),
            onRetry: () => ref.invalidate(fixturesProvider(const FixturesQuery(tab: 'today'))),
            data: (todayList) {
              final liveList = live.valueOrNull ?? const <Fixture>[];
              final threads = {
                for (final f in [...liveList, ...todayList])
                  if (f.hasThread) f.id: f,
              }.values.toList();

              if (threads.isEmpty) {
                return ListView(children: const [
                  SizedBox(height: 40),
                  EmptyState(
                    icon: LucideIcons.messagesSquare,
                    title: 'No active threads',
                    message: 'Match-day threads open around kickoff. Check back on match day.',
                  ),
                ]);
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Text('MATCH THREADS', style: TerraceTextStyles.overline(context)),
                  ),
                  for (final f in threads) _ThreadCard(fixture: f),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final Fixture fixture;
  const _ThreadCard({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final f = fixture;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.xl),
        border: Border.all(color: f.isLive ? t.live.withValues(alpha: 0.4) : t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/thread/${f.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                TeamCrest(team: f.homeTeam, size: 30),
                const SizedBox(width: 6),
                TeamCrest(team: f.awayTeam, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${f.homeTeam?.displayName ?? "TBD"} v ${f.awayTeam?.displayName ?? "TBD"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      const SizedBox(height: 2),
                      Text(f.league?.name ?? 'Match thread',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (f.isLive)
                  const LiveBadge()
                else
                  Icon(LucideIcons.messageCircle, size: 18, color: t.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
