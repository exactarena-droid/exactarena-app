import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_providers.dart';
import '../../models/league.dart';
import '../../models/standing.dart';
import '../../theme/terrace_theme.dart';
import '../../widgets/widgets.dart';

class StandingsScreen extends ConsumerStatefulWidget {
  final int? initialLeagueId;
  const StandingsScreen({super.key, this.initialLeagueId});

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen> {
  int? _leagueId;

  @override
  void initState() {
    super.initState();
    _leagueId = widget.initialLeagueId;
  }

  @override
  Widget build(BuildContext context) {
    final leagues = ref.watch(leaguesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Standings')),
      body: AsyncView(
        value: leagues,
        loading: const ListSkeleton(count: 4),
        onRetry: () => ref.invalidate(leaguesProvider),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(title: 'No leagues yet', message: 'Tables will appear once leagues are available.');
          }
          final selected = list.firstWhere(
            (l) => l.id == _leagueId,
            orElse: () => list.first,
          );
          return Column(
            children: [
              _LeagueChips(
                leagues: list,
                selectedId: selected.id,
                onSelect: (id) => setState(() => _leagueId = id),
              ),
              Expanded(child: _StandingsTable(league: selected)),
            ],
          );
        },
      ),
    );
  }
}

class _LeagueChips extends StatelessWidget {
  final List<League> leagues;
  final int selectedId;
  final ValueChanged<int> onSelect;
  const _LeagueChips({required this.leagues, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      height: 60,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: leagues.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final l = leagues[i];
          final sel = l.id == selectedId;
          return ChoiceChip(
            label: Text(l.name),
            selected: sel,
            onSelected: (_) => onSelect(l.id),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: sel ? t.textOnBrand : t.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            backgroundColor: t.surfaceMuted,
            selectedColor: t.brand,
            side: BorderSide(color: sel ? t.brand : t.border),
          );
        },
      ),
    );
  }
}

class _StandingsTable extends ConsumerWidget {
  final League league;
  const _StandingsTable({required this.league});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(standingsProvider(league.id));
    return RefreshIndicator(
      color: context.terrace.brand,
      onRefresh: () => ref.refresh(standingsProvider(league.id).future),
      child: AsyncView(
        value: standings,
        loading: const ListSkeleton(count: 8),
        onRetry: () => ref.invalidate(standingsProvider(league.id)),
        data: (rows) {
          if (rows.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 80),
              EmptyState(title: 'No table yet', message: 'Standings for this league are not available.'),
            ]);
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const _TableHeader(),
              for (var i = 0; i < rows.length; i++)
                _StandingRow(standing: rows[i], stripe: i.isOdd),
              const SizedBox(height: 12),
              const _Legend(),
            ],
          );
        },
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final style = TerraceTextStyles.overline(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: t.surfaceMuted,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text('#', style: style)),
          const SizedBox(width: 8),
          Expanded(child: Text('TEAM', style: style)),
          _num('P', style),
          _num('W', style),
          _num('D', style),
          _num('L', style),
          _num('GD', style),
          _num('PTS', style),
        ],
      ),
    );
  }

  Widget _num(String s, TextStyle style) =>
      SizedBox(width: 30, child: Text(s, textAlign: TextAlign.center, style: style));
}

class _StandingRow extends StatelessWidget {
  final Standing standing;
  final bool stripe;
  const _StandingRow({required this.standing, required this.stripe});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final s = standing;
    return Material(
      color: stripe ? t.surfaceMuted.withValues(alpha: 0.4) : t.surface,
      child: InkWell(
        onTap: () => context.push('/team/${s.team.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${s.rank}',
                      style: TerraceTextStyles.tableNum(context, size: 13, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TeamCrest(team: s.team, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.team.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                  ),
                  _cell(context, '${s.played}'),
                  _cell(context, '${s.won}'),
                  _cell(context, '${s.drawn}'),
                  _cell(context, '${s.lost}'),
                  _cell(context, s.goalDiff > 0 ? '+${s.goalDiff}' : '${s.goalDiff}'),
                  _cell(context, '${s.points}', bold: true, color: t.brand),
                ],
              ),
              if (s.form.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 32),
                    FormRow(form: s.form, size: 18),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, String value, {bool bold = false, Color? color}) {
    return SizedBox(
      width: 30,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TerraceTextStyles.tableNum(
          context,
          size: 13,
          weight: bold ? FontWeight.w800 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'P played · W won · D drawn · L lost · GD goal difference · PTS points',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
