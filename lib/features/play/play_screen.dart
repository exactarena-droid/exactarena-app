import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/result.dart';
import '../../data/app_providers.dart';
import '../../data/auth_controller.dart';
import '../../models/models.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';
import 'play_providers.dart';
import 'widgets/board_list.dart';
import 'widgets/call_row.dart';
import 'widgets/leagues_view.dart';
import 'widgets/play_hero.dart';

/// The Score Challenge "Play" experience — Terrace's hero tab.
///
/// A free, points-only game (COMPLIANCE.md): each gameweek you call the final
/// scorelines, earn points, and climb global + private mini-league leaderboards.
/// Three sections: Calls · Leaderboard · Leagues.
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

enum _PlaySection { calls, leaderboard, leagues }

class _PlayScreenState extends ConsumerState<PlayScreen> {
  _PlaySection _section = _PlaySection.calls;

  /// In-progress, unsaved calls keyed by fixture id (before "lock in").
  final Map<int, Call> _draft = {};

  void _setScore(int fixtureId, {int? home, int? away, required Call current}) {
    setState(() {
      final next = Call(
        (home ?? current.homeScore).clamp(0, 30),
        (away ?? current.awayScore).clamp(0, 30),
      );
      _draft[fixtureId] = next;
    });
  }

  /// The current call for a fixture: an unsaved draft if present, else the
  /// server's saved call, else a fresh 0–0.
  Call _callFor(RoundFixtureCall f) =>
      _draft[f.fixture.id] ?? f.myCall ?? const Call(0, 0);

  /// Whether the draft differs from what's saved on the server.
  bool _hasUnsaved(ChallengeRound round) {
    for (final f in round.fixtures) {
      if (f.kickedOff) continue;
      final draft = _draft[f.fixture.id];
      if (draft == null) continue;
      final saved = f.myCall;
      if (saved == null || saved.homeScore != draft.homeScore || saved.awayScore != draft.awayScore) {
        return true;
      }
    }
    return false;
  }

  Future<void> _lockIn(ChallengeRound round) async {
    // Send every open fixture's current call (draft or already-saved), so the
    // backend has a complete set. Kicked-off fixtures are excluded.
    final toSend = <int, Call>{};
    for (final f in round.fixtures) {
      if (f.kickedOff) continue;
      toSend[f.fixture.id] = _callFor(f);
    }
    final ok = await ref.read(callsControllerProvider.notifier).submit(round.id, toSend);
    if (!mounted) return;
    if (ok) {
      _draft.clear();
      _section = _PlaySection.calls;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calls locked in. Good luck this gameweek.')),
      );
    } else {
      final err = ref.read(callsControllerProvider).error;
      final msg = err is AppFailure ? err.message : 'Could not lock in your calls.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final currentAsync = ref.watch(challengeCurrentProvider);
    final submitting = ref.watch(callsControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: AsyncView(
                value: currentAsync,
                loading: const _PlayLoading(),
                onRetry: () => ref.invalidate(challengeCurrentProvider),
                data: (current) => _buildLoaded(context, current, submitting),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, ChallengeCurrent current, bool submitting) {
    final round = current.round;
    final signedIn = isSignedIn(ref);
    final hasOpen = round.openFixtures.isNotEmpty && !round.isLocked;
    final showBar = _section == _PlaySection.calls && hasOpen;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: context.terrace.brand,
            onRefresh: () async => ref.invalidate(challengeCurrentProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PlayHero(round: round, me: current.me),
                ),
                SliverToBoxAdapter(
                  child: _SectionSwitcher(
                    section: _section,
                    onChanged: (s) => setState(() => _section = s),
                  ),
                ),
                ..._sectionSlivers(current, signedIn),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ),
        ),
        if (showBar && signedIn)
          _LockBar(
            round: round,
            hasUnsaved: _hasUnsaved(round),
            submitting: submitting,
            onLockIn: () => _lockIn(round),
          )
        else if (showBar && !signedIn)
          const _SignInBar(),
      ],
    );
  }

  List<Widget> _sectionSlivers(ChallengeCurrent current, bool signedIn) {
    switch (_section) {
      case _PlaySection.calls:
        return _callsSlivers(current.round, signedIn);
      case _PlaySection.leaderboard:
        return const [SliverToBoxAdapter(child: BoardSection())];
      case _PlaySection.leagues:
        return const [SliverToBoxAdapter(child: LeaguesView())];
    }
  }

  List<Widget> _callsSlivers(ChallengeRound round, bool signedIn) {
    if (round.fixtures.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(
              icon: LucideIcons.gamepad2,
              title: 'No fixtures to call yet',
              message: 'The next gameweek opens soon. Check back to call the scores.',
            ),
          ),
        ),
      ];
    }
    return [
      if (!signedIn)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 12),
            child: SignInToPlay(),
          ),
        ),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: _CallsIntro(),
        ),
      ),
      SliverList.builder(
        itemCount: round.fixtures.length,
        itemBuilder: (context, i) {
          final f = round.fixtures[i];
          return CallRow(
            fixture: f,
            call: _callFor(f),
            onHome: (v) => _setScore(f.fixture.id, home: v, current: _callFor(f)),
            onAway: (v) => _setScore(f.fixture.id, away: v, current: _callFor(f)),
          );
        },
      ),
    ];
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
      child: Row(
        children: [
          Icon(LucideIcons.gamepad2, size: 22, color: t.brand),
          const SizedBox(width: 10),
          Text('Score Challenge', style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          IconButton(
            tooltip: 'How to play',
            icon: Icon(LucideIcons.circleHelp, color: t.textSecondary),
            onPressed: () => _showHowToPlay(context),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    final t = context.terrace;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to play', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'A free game of bragging rights. Each gameweek, call the final score of '
              'every fixture before kickoff, then climb the leaderboard with your mates.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            _ScoreRule(points: '5', label: 'Exact score', detail: 'You nailed it', color: t.brand),
            _ScoreRule(points: '3', label: 'Right result + goal difference', detail: 'Close call', color: t.accent),
            _ScoreRule(points: '2', label: 'Right result', detail: 'Win, draw or loss', color: t.textSecondary),
            _ScoreRule(points: '0', label: 'Miss', detail: 'Better luck next week', color: t.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ScoreRule extends StatelessWidget {
  final String points;
  final String label;
  final String detail;
  final Color color;
  const _ScoreRule({
    required this.points,
    required this.label,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TerraceRadii.md),
            ),
            child: Text(
              points,
              style: TerraceTextStyles.tableNum(context, size: 18, weight: FontWeight.w800, color: color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text('pts', style: TextStyle(color: t.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CallsIntro extends StatelessWidget {
  const _CallsIntro();

  @override
  Widget build(BuildContext context) {
    return Text('THIS WEEK', style: TerraceTextStyles.overline(context));
  }
}

/// Segmented control: Calls · Leaderboard · Leagues.
class _SectionSwitcher extends StatelessWidget {
  final _PlaySection section;
  final ValueChanged<_PlaySection> onChanged;
  const _SectionSwitcher({required this.section, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    const items = [
      (_PlaySection.calls, 'Calls', LucideIcons.target),
      (_PlaySection.leaderboard, 'Leaderboard', LucideIcons.trophy),
      (_PlaySection.leagues, 'Leagues', LucideIcons.users),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: t.surfaceMuted,
          borderRadius: BorderRadius.circular(TerraceRadii.full),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: _SegButton(
                  label: item.$2,
                  icon: item.$3,
                  selected: section == item.$1,
                  onTap: () => onChanged(item.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SegButton({
    required this.label,
    required this.icon,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? t.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(TerraceRadii.full),
            border: Border.all(color: selected ? t.border : Colors.transparent),
            boxShadow: selected ? t.softShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? t.brand : t.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? t.textPrimary : t.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticky bottom bar for guests: a prompt to sign in before locking in calls.
class _SignInBar extends StatelessWidget {
  const _SignInBar();

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sign in to lock in your calls and play.',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(LucideIcons.gamepad2, size: 18),
            label: const Text('Sign in to play'),
          ),
        ],
      ),
    );
  }
}

/// Sticky bottom bar: "Lock in my calls".
class _LockBar extends StatelessWidget {
  final ChallengeRound round;
  final bool hasUnsaved;
  final bool submitting;
  final VoidCallback onLockIn;
  const _LockBar({
    required this.round,
    required this.hasUnsaved,
    required this.submitting,
    required this.onLockIn,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final openCount = round.openFixtures.length;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$openCount ${openCount == 1 ? "fixture" : "fixtures"} open',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  hasUnsaved ? 'Unsaved calls' : 'All calls saved',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: submitting ? null : onLockIn,
            icon: submitting
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.lockKeyhole, size: 18),
            label: Text(submitting ? 'Locking in...' : 'Lock in my calls'),
          ),
        ],
      ),
    );
  }
}

class _PlayLoading extends StatelessWidget {
  const _PlayLoading();

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: t.surfaceMuted,
            borderRadius: BorderRadius.circular(TerraceRadii.xl2),
          ),
        ),
        const SizedBox(height: 16),
        const Skeleton(height: 44, radius: TerraceRadii.full),
        const SizedBox(height: 20),
        for (var i = 0; i < 5; i++) ...[
          const Skeleton(height: 72, radius: TerraceRadii.xl),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Helper used by mini-league widgets to copy an invite code to the clipboard.
Future<void> copyInviteCode(BuildContext context, String code) async {
  await Clipboard.setData(ClipboardData(text: code));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Invite code $code copied')),
  );
}

/// A tasteful sign-in gate shown where a game action needs an account.
class SignInToPlay extends ConsumerWidget {
  final String message;
  const SignInToPlay({super.key, this.message = 'Sign in to play the Score Challenge.'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.terrace;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.brandSubtle, t.surface],
        ),
        borderRadius: BorderRadius.circular(TerraceRadii.xl2),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.surface, shape: BoxShape.circle, border: Border.all(color: t.border)),
            child: Icon(LucideIcons.gamepad2, color: t.brand, size: 26),
          ),
          const SizedBox(height: 14),
          Text('Join the game', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Convenience: is the fan signed in right now?
bool isSignedIn(WidgetRef ref) => ref.watch(currentUserProvider) != null;

/// Re-export so widget files share one timer-formatting helper.
String formatCountdown(DateTime? locksAt) {
  if (locksAt == null) return '';
  final diff = locksAt.difference(DateTime.now());
  if (diff.isNegative) return 'Locked';
  if (diff.inDays >= 1) return 'locks in ${diff.inDays}d ${diff.inHours % 24}h';
  if (diff.inHours >= 1) return 'locks in ${diff.inHours}h ${diff.inMinutes % 60}m';
  if (diff.inMinutes >= 1) return 'locks in ${diff.inMinutes}m';
  return 'locks in <1m';
}

/// A small periodic ticker so the lock countdown stays live without a network call.
class CountdownText extends StatefulWidget {
  final DateTime? locksAt;
  final TextStyle? style;
  const CountdownText({super.key, required this.locksAt, this.style});

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(formatCountdown(widget.locksAt), style: widget.style);
  }
}
