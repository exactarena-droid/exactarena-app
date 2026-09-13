import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/app_providers.dart';
import '../../models/player.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';

class PlayerProfileScreen extends ConsumerWidget {
  final int playerId;
  const PlayerProfileScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerDetailProvider(playerId));
    return Scaffold(
      appBar: AppBar(title: const Text('Player')),
      body: AsyncView(
        value: player,
        loading: const Center(child: CircularProgressIndicator()),
        onRetry: () => ref.invalidate(playerDetailProvider(playerId)),
        data: (p) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _PlayerHeader(player: p),
            if (p.stats.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text('SEASON STATS', style: TerraceTextStyles.overline(context)),
              ),
              _SeasonSelector(player: p),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  final Player player;
  const _PlayerHeader({required this.player});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final p = player;
    final facts = <(IconData, String)>[
      if (p.position != null) (LucideIcons.shield, p.position!),
      if (p.shirtNumber != null) (LucideIcons.hash, '#${p.shirtNumber}'),
      if (p.age != null) (LucideIcons.cake, '${p.age} yrs'),
      if (p.nationality != null) (LucideIcons.flag, p.nationality!),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
          InitialAvatar(imageUrl: p.photo, initials: p.initials, size: 88, seed: p.id),
          const SizedBox(height: 14),
          Text(p.name, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          if (p.team != null) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => context.push('/team/${p.team!.id}'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TeamCrest(team: p.team, size: 20),
                  const SizedBox(width: 8),
                  Text(p.team!.displayName,
                      style: TextStyle(color: t.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final f in facts)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.$1, size: 14, color: t.textMuted),
                      const SizedBox(width: 6),
                      Text(f.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeasonSelector extends StatefulWidget {
  final Player player;
  const _SeasonSelector({required this.player});

  @override
  State<_SeasonSelector> createState() => _SeasonSelectorState();
}

class _SeasonSelectorState extends State<_SeasonSelector> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final stats = widget.player.stats;
    final stat = stats[_index.clamp(0, stats.length - 1)];

    return Column(
      children: [
        if (stats.length > 1)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: stats.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final sel = i == _index;
                return ChoiceChip(
                  label: Text(stats[i].season),
                  selected: sel,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _index = i),
                  labelStyle: TextStyle(
                    color: sel ? t.textOnBrand : t.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  selectedColor: t.brand,
                  backgroundColor: t.surfaceMuted,
                  side: BorderSide(color: sel ? t.brand : t.border),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              _StatTile(label: 'Apps', value: '${stat.appearances}', icon: LucideIcons.shirt),
              _StatTile(label: 'Goals', value: '${stat.goals}', icon: LucideIcons.circleDot),
              _StatTile(label: 'Assists', value: '${stat.assists}', icon: LucideIcons.helpingHand),
              _StatTile(label: 'Yellow', value: '${stat.yellowCards}', icon: LucideIcons.square, accent: t.warning),
              _StatTile(label: 'Red', value: '${stat.redCards}', icon: LucideIcons.square, accent: t.danger),
              _StatTile(label: 'Minutes', value: '${stat.minutes}', icon: LucideIcons.clock),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
  const _StatTile({required this.label, required this.value, required this.icon, this.accent});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final color = accent ?? t.brand;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.lg),
        border: Border.all(color: t.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(value, style: TerraceTextStyles.scoreboard(context, size: 24)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: TerraceTextStyles.overline(context)),
        ],
      ),
    );
  }
}
