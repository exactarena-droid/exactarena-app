import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/result.dart';
import '../../../data/app_providers.dart';
import '../../../data/repositories.dart';
import '../../../models/models.dart';
import '../../../theme/terrace_theme.dart';
import '../../../theme/terrace_tokens.dart';
import '../../../widgets/widgets.dart';
import '../play_screen.dart';

/// The Leagues section: the fan's private mini-leagues, plus actions to create
/// a new one or join with an invite code. Signed-out fans see a sign-in gate.
class LeaguesView extends ConsumerWidget {
  const LeaguesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isSignedIn(ref)) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: SignInToPlay(
          message: 'Sign in to start a mini-league and play against your mates.',
        ),
      );
    }

    final poolsAsync = ref.watch(challengePoolsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LeagueActions(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: Text('YOUR MINI-LEAGUES', style: TerraceTextStyles.overline(context)),
        ),
        poolsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Skeleton(height: 86, radius: TerraceRadii.xl),
                SizedBox(height: 10),
                Skeleton(height: 86, radius: TerraceRadii.xl),
              ],
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: EmptyState(
              icon: LucideIcons.users,
              title: 'Could not load your leagues',
              message: 'Pull to refresh or try again shortly.',
            ),
          ),
          data: (pools) {
            if (pools.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 8),
                child: EmptyState(
                  icon: LucideIcons.users,
                  title: 'No mini-leagues yet',
                  message: 'Create a private league and share the invite code, or join one with a friend’s code.',
                ),
              );
            }
            return Column(
              children: [for (final p in pools) _PoolCard(pool: p)],
            );
          },
        ),
      ],
    );
  }
}

class _LeagueActions extends StatelessWidget {
  const _LeagueActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _showCreate(context),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Create a league'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showJoin(context),
              icon: const Icon(LucideIcons.userPlus, size: 18),
              label: const Text('Join'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreate(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateLeagueSheet(),
    );
  }

  void _showJoin(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _JoinLeagueSheet(),
    );
  }
}

class _PoolCard extends StatelessWidget {
  final ChallengePool pool;
  const _PoolCard({required this.pool});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.xl),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        pool.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (pool.isOwner) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.brandSubtle,
                          borderRadius: BorderRadius.circular(TerraceRadii.full),
                        ),
                        child: Text('OWNER',
                            style: TextStyle(color: t.brand, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PoolStat(value: _ordinal(pool.myRank), label: 'Your rank', accent: true),
              _PoolStatDivider(),
              _PoolStat(value: '${pool.myPoints}', label: 'Points'),
              _PoolStatDivider(),
              _PoolStat(value: '${pool.membersCount}', label: pool.membersCount == 1 ? 'Member' : 'Members'),
            ],
          ),
          const SizedBox(height: 14),
          _InviteCodeBar(code: pool.code),
        ],
      ),
    );
  }

  static String _ordinal(int n) {
    if (n <= 0) return '—';
    final mod100 = n % 100;
    final mod10 = n % 10;
    String suffix;
    if (mod100 >= 11 && mod100 <= 13) {
      suffix = 'th';
    } else {
      suffix = switch (mod10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
    }
    return '$n$suffix';
  }
}

class _PoolStat extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;
  const _PoolStat({required this.value, required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TerraceTextStyles.scoreboard(context, size: 24)
                .copyWith(color: accent ? t.brand : t.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: TextStyle(color: t.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

class _PoolStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(width: 1, height: 30, margin: const EdgeInsets.symmetric(horizontal: 12), color: t.border);
  }
}

/// An invite code with a copy affordance.
class _InviteCodeBar extends StatelessWidget {
  final String code;
  const _InviteCodeBar({required this.code});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => copyInviteCode(context, code),
        borderRadius: BorderRadius.circular(TerraceRadii.md),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: t.surfaceMuted,
            borderRadius: BorderRadius.circular(TerraceRadii.md),
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.hash, size: 15, color: t.textMuted),
              const SizedBox(width: 8),
              Text('Invite code', style: TextStyle(color: t.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  code,
                  style: TerraceTextStyles.mono(context, size: 13.5, weight: FontWeight.w700, color: t.textPrimary),
                ),
              ),
              TextButton.icon(
                onPressed: () => copyInviteCode(context, code),
                icon: const Icon(LucideIcons.copy, size: 15),
                label: const Text('Copy'),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet: create a league (name → shows the new invite code).
class _CreateLeagueSheet extends ConsumerStatefulWidget {
  const _CreateLeagueSheet();

  @override
  ConsumerState<_CreateLeagueSheet> createState() => _CreateLeagueSheetState();
}

class _CreateLeagueSheetState extends ConsumerState<_CreateLeagueSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;
  ChallengePool? _created;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give your league a name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pool = await ref.read(challengeRepositoryProvider).createPool(name);
      ref.invalidate(challengePoolsProvider);
      if (!mounted) return;
      setState(() {
        _created = pool;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is AppFailure ? e.message : 'Could not create the league.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    return _SheetShell(
      title: created == null ? 'Create a league' : 'League created',
      child: created == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Name your private mini-league, then share the invite code with your mates.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  maxLength: 40,
                  decoration: InputDecoration(
                    hintText: 'e.g. Sunday League Lads',
                    prefixIcon: const Icon(LucideIcons.trophy, size: 18),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create league'),
                  ),
                ),
              ],
            )
          : _CreatedConfirmation(pool: created),
    );
  }
}

class _CreatedConfirmation extends StatelessWidget {
  final ChallengePool pool;
  const _CreatedConfirmation({required this.pool});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(LucideIcons.circleCheck, color: t.brand, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(pool.name, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Share this invite code so friends can join your league.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.brandSubtle,
            borderRadius: BorderRadius.circular(TerraceRadii.lg),
            border: Border.all(color: t.brand.withValues(alpha: 0.4)),
          ),
          child: Text(
            pool.code,
            style: TerraceTextStyles.mono(context, size: 26, weight: FontWeight.w800, color: t.brand),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => copyInviteCode(context, pool.code),
                icon: const Icon(LucideIcons.copy, size: 18),
                label: const Text('Copy code'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bottom sheet: join a league with an invite code.
class _JoinLeagueSheet extends ConsumerStatefulWidget {
  const _JoinLeagueSheet();

  @override
  ConsumerState<_JoinLeagueSheet> createState() => _JoinLeagueSheetState();
}

class _JoinLeagueSheetState extends ConsumerState<_JoinLeagueSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter an invite code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pool = await ref.read(challengeRepositoryProvider).joinPool(code);
      ref.invalidate(challengePoolsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${pool.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is AppFailure ? e.message : 'Could not join that league.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Join a league',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter the invite code a friend shared with you.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _submit(),
            maxLength: 16,
            decoration: InputDecoration(
              hintText: 'Invite code',
              prefixIcon: const Icon(LucideIcons.hash, size: 18),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Join league'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared sheet scaffold: title + content, padded above the keyboard.
class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 4, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
