import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/app_providers.dart';
import '../../models/fixture.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';

class ScoresScreen extends ConsumerStatefulWidget {
  const ScoresScreen({super.key});

  @override
  ConsumerState<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends ConsumerState<ScoresScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            title: const Text('Scores'),
            actions: [
              IconButton(
                tooltip: 'Standings',
                icon: const Icon(LucideIcons.trophy),
                onPressed: () => context.push('/standings'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'Today'),
                    Tab(text: 'Live'),
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Finished'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: const [
            _TodayTab(),
            _FixturesTab(tab: 'live', emptyTitle: 'No live matches', live: true),
            _FixturesTab(tab: 'upcoming', emptyTitle: 'Nothing upcoming'),
            _FixturesTab(tab: 'finished', emptyTitle: 'No results yet'),
          ],
        ),
      ),
      backgroundColor: t.bg,
    );
  }
}

/// Today tab: a horizontal date strip plus that date's fixtures.
class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(selected);
    final query = FixturesQuery(tab: 'today', date: dateStr);
    final fixtures = ref.watch(fixturesProvider(query));

    return Column(
      children: [
        _DateStrip(selected: selected),
        Expanded(
          child: RefreshIndicator(
            color: context.terrace.brand,
            onRefresh: () => ref.refresh(fixturesProvider(query).future),
            child: AsyncView(
              value: fixtures,
              loading: const ListSkeleton(),
              onRetry: () => ref.invalidate(fixturesProvider(query)),
              data: (list) => _FixtureList(
                fixtures: list,
                emptyTitle: 'No matches on this day',
                emptyMessage: 'Try another date from the strip above.',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateStrip extends ConsumerWidget {
  final DateTime selected;
  const _DateStrip({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.terrace;
    final today = DateTime.now();
    final days = List.generate(11, (i) => DateUtils.dateOnly(today).add(Duration(days: i - 5)));
    final sel = DateUtils.dateOnly(selected);

    return Container(
      height: 76,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final d = days[i];
          final isSel = d == sel;
          final isToday = d == DateUtils.dateOnly(today);
          return GestureDetector(
            onTap: () => ref.read(selectedDateProvider.notifier).state = d,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSel ? t.brand : t.surface,
                borderRadius: BorderRadius.circular(TerraceRadii.md),
                border: Border.all(color: isSel ? t.brand : t.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'TODAY' : DateFormat('EEE').format(d).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isSel ? t.textOnBrand : t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(d),
                    style: TerraceTextStyles.tableNum(
                      context,
                      size: 18,
                      weight: FontWeight.w700,
                      color: isSel ? t.textOnBrand : t.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FixturesTab extends ConsumerWidget {
  final String tab;
  final String emptyTitle;
  final bool live;
  const _FixturesTab({required this.tab, required this.emptyTitle, this.live = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = FixturesQuery(tab: tab);
    final fixtures = ref.watch(fixturesProvider(query));
    return RefreshIndicator(
      color: context.terrace.brand,
      onRefresh: () => ref.refresh(fixturesProvider(query).future),
      child: AsyncView(
        value: fixtures,
        loading: const ListSkeleton(),
        onRetry: () => ref.invalidate(fixturesProvider(query)),
        data: (list) => _FixtureList(
          fixtures: list,
          emptyTitle: emptyTitle,
          emptyMessage: live
              ? 'When matches kick off, they will appear here in real time.'
              : 'Pull to refresh or check back soon.',
          emptyIcon: live ? LucideIcons.radio : LucideIcons.calendar,
        ),
      ),
    );
  }
}

/// Renders fixtures grouped under league headers, sorted with live first.
class _FixtureList extends StatelessWidget {
  final List<Fixture> fixtures;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;

  const _FixtureList({
    required this.fixtures,
    required this.emptyTitle,
    required this.emptyMessage,
    this.emptyIcon = LucideIcons.calendar,
  });

  @override
  Widget build(BuildContext context) {
    if (fixtures.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
          EmptyState(icon: emptyIcon, title: emptyTitle, message: emptyMessage),
        ],
      );
    }

    // Group by league preserving order; live matches float to the top group.
    final groups = <String, List<Fixture>>{};
    for (final f in fixtures) {
      final key = f.league?.name ?? 'Other matches';
      groups.putIfAbsent(key, () => []).add(f);
    }
    final entries = groups.entries.toList();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        final anyLive = e.value.any((f) => f.isLive);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeagueHeader(name: e.key, live: anyLive),
            for (final f in e.value)
              MatchCard(
                fixture: f,
                onTap: () => context.push('/match/${f.id}'),
              ),
          ],
        );
      },
    );
  }
}

class _LeagueHeader extends StatelessWidget {
  final String name;
  final bool live;
  const _LeagueHeader({required this.name, required this.live});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Icon(LucideIcons.trophy, size: 15, color: t.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name.toUpperCase(),
              style: TerraceTextStyles.overline(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (live) const LiveDot(size: 7),
        ],
      ),
    );
  }
}
