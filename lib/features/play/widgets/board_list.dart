import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/app_providers.dart';
import '../../../models/models.dart';
import '../../../theme/terrace_theme.dart';
import '../../../theme/terrace_tokens.dart';
import '../../../widgets/widgets.dart';
import '../play_providers.dart';

/// The Leaderboard section: a scope switcher (global + the fan's pools) over a
/// ranked board. The fan's own row is pinned at the bottom and highlighted.
class BoardSection extends ConsumerWidget {
  const BoardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(boardScopeProvider);
    final boardAsync = ref.watch(challengeBoardProvider(scope.poolId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScopeSwitcher(active: scope),
        boardAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Skeleton(height: 52, radius: TerraceRadii.lg),
                SizedBox(height: 8),
                Skeleton(height: 52, radius: TerraceRadii.lg),
                SizedBox(height: 8),
                Skeleton(height: 52, radius: TerraceRadii.lg),
              ],
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: EmptyState(
              icon: LucideIcons.trophy,
              title: 'Leaderboard unavailable',
              message: 'Pull to refresh or try again shortly.',
            ),
          ),
          data: (board) => _Board(board: board),
        ),
      ],
    );
  }
}

class _ScopeSwitcher extends ConsumerWidget {
  final BoardScope active;
  const _ScopeSwitcher({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pools = ref.watch(challengePoolsProvider).valueOrNull ?? const <ChallengePool>[];
    final scopes = <BoardScope>[
      BoardScope.global,
      for (final p in pools) BoardScope(poolId: p.id, label: p.name),
    ];
    if (scopes.length == 1) return const SizedBox(height: 4);

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        itemCount: scopes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = scopes[i];
          final selected = s == active;
          return _ScopeChip(
            label: s.label,
            global: s.poolId == null,
            selected: selected,
            onTap: () => ref.read(boardScopeProvider.notifier).state = s,
          );
        },
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool global;
  final bool selected;
  final VoidCallback onTap;
  const _ScopeChip({
    required this.label,
    required this.global,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TerraceRadii.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? t.brand : t.surface,
            borderRadius: BorderRadius.circular(TerraceRadii.full),
            border: Border.all(color: selected ? t.brand : t.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                global ? LucideIcons.globe : LucideIcons.users,
                size: 13,
                color: selected ? t.textOnBrand : t.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? t.textOnBrand : t.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final ChallengeBoard board;
  const _Board({required this.board});

  @override
  Widget build(BuildContext context) {
    if (board.leaders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: EmptyState(
          icon: LucideIcons.listOrdered,
          title: 'No standings yet',
          message: 'Once calls are settled this gameweek, the leaderboard fills up here.',
        ),
      );
    }
    // Whether the fan's row already appears in the visible leaders.
    final meInList = board.me != null && board.leaders.any((r) => r.isMe);
    return Column(
      children: [
        const _BoardHeaderRow(),
        for (final row in board.leaders) LeaderTile(row: row),
        if (board.me != null && !meInList) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
            child: Row(
              children: [
                Text('YOUR RANK', style: TerraceTextStyles.overline(context)),
              ],
            ),
          ),
          LeaderTile(row: board.me!),
        ],
      ],
    );
  }
}

class _BoardHeaderRow extends StatelessWidget {
  const _BoardHeaderRow();

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    TextStyle h() => TextStyle(color: t.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 6),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: h())),
          const SizedBox(width: 42),
          Expanded(child: Text('PLAYER', style: h())),
          SizedBox(width: 44, child: Text('EXACT', style: h(), textAlign: TextAlign.center)),
          SizedBox(width: 56, child: Text('PTS', style: h(), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

/// One leaderboard row. The fan's own row is highlighted in pitch-green.
class LeaderTile extends StatelessWidget {
  final LeaderRow row;
  const LeaderTile({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final me = row.isMe;
    final topThree = row.rank >= 1 && row.rank <= 3;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 3, 16, 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: me ? t.brandSubtle : t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.lg),
        border: Border.all(color: me ? t.brand : t.border, width: me ? 1.4 : 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: topThree
                ? Icon(LucideIcons.medal, size: 18, color: _medalColor(context, row.rank))
                : Text(
                    '${row.rank}',
                    textAlign: TextAlign.center,
                    style: TerraceTextStyles.tableNum(context, size: 14, weight: FontWeight.w700, color: t.textSecondary),
                  ),
          ),
          const SizedBox(width: 12),
          InitialAvatar(
            imageUrl: row.user.avatar,
            initials: row.user.initials,
            size: 32,
            seed: row.rank,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        me ? 'You' : row.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: me ? t.brand : t.textPrimary),
                      ),
                    ),
                    if (row.streak > 1) ...[
                      const SizedBox(width: 6),
                      Icon(LucideIcons.flame, size: 13, color: t.accent),
                      Text('${row.streak}', style: TextStyle(color: t.accent, fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ],
                  ],
                ),
                if (row.user.username != null)
                  Text('@${row.user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${row.exacts}',
              textAlign: TextAlign.center,
              style: TerraceTextStyles.tableNum(context, size: 13.5, weight: FontWeight.w600, color: t.textSecondary),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '${row.points}',
              textAlign: TextAlign.right,
              style: TerraceTextStyles.tableNum(context, size: 16, weight: FontWeight.w800, color: me ? t.brand : t.accent),
            ),
          ),
        ],
      ),
    );
  }

  Color _medalColor(BuildContext context, int rank) {
    final t = context.terrace;
    switch (rank) {
      case 1:
        return t.accent;
      case 2:
        return t.textMuted;
      default:
        return TerraceColors.floodlight700;
    }
  }
}
