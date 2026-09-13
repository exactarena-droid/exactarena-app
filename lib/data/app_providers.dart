import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth_controller.dart';
import 'repositories.dart';

// ── App bootstrap config ──────────────────────────────────────────────────
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return ref.watch(configRepositoryProvider).fetch();
});

// ── Scores ────────────────────────────────────────────────────────────────

/// Currently selected date on the Today tab (defaults to now).
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class FixturesQuery {
  final String tab;
  final String? date;
  const FixturesQuery({required this.tab, this.date});

  @override
  bool operator ==(Object other) =>
      other is FixturesQuery && other.tab == tab && other.date == date;
  @override
  int get hashCode => Object.hash(tab, date);
}

final fixturesProvider =
    FutureProvider.family<List<Fixture>, FixturesQuery>((ref, q) async {
  return ref.watch(fixtureRepositoryProvider).list(tab: q.tab, date: q.date);
});

final fixtureDetailProvider = FutureProvider.family<Fixture, int>((ref, id) async {
  return ref.watch(fixtureRepositoryProvider).detail(id);
});

final fixtureThreadProvider =
    FutureProvider.family<List<ThreadPost>, int>((ref, fixtureId) async {
  return ref.watch(fixtureRepositoryProvider).thread(fixtureId);
});

/// Fan verdict + Man of the Match for a fixture (opinion only — COMPLIANCE.md).
/// The match-detail screen watches this; submitting a rating invalidates it.
final fixtureRatingsProvider =
    FutureProvider.family<FixtureRatings, int>((ref, fixtureId) async {
  return ref.watch(ratingsRepositoryProvider).get(fixtureId);
});

// ── Leagues & standings ─────────────────────────────────────────────────────
final leaguesProvider = FutureProvider<List<League>>((ref) async {
  return ref.watch(leagueRepositoryProvider).all();
});

final standingsProvider =
    FutureProvider.family<List<Standing>, int>((ref, leagueId) async {
  return ref.watch(leagueRepositoryProvider).standings(leagueId);
});

// ── Teams & players ─────────────────────────────────────────────────────────
final teamDetailProvider = FutureProvider.family<Team, int>((ref, id) async {
  return ref.watch(teamRepositoryProvider).detail(id);
});

final teamFixturesProvider = FutureProvider.family<List<Fixture>, int>((ref, id) async {
  return ref.watch(teamRepositoryProvider).fixtures(id);
});

final teamSquadProvider = FutureProvider.family<List<Player>, int>((ref, id) async {
  return ref.watch(teamRepositoryProvider).squad(id);
});

final playerDetailProvider = FutureProvider.family<Player, int>((ref, id) async {
  return ref.watch(playerRepositoryProvider).detail(id);
});

// ── News ────────────────────────────────────────────────────────────────────
final newsCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(newsRepositoryProvider).categories();
});

final newsFeedProvider =
    FutureProvider.family<List<Article>, String?>((ref, categorySlug) async {
  return ref.watch(newsRepositoryProvider).list(category: categorySlug);
});

final articleDetailProvider = FutureProvider.family<Article, String>((ref, slug) async {
  return ref.watch(newsRepositoryProvider).detail(slug);
});

// ── Plans ─────────────────────────────────────────────────────────────────
final plansProvider = FutureProvider<List<Plan>>((ref) async {
  return ref.watch(planRepositoryProvider).all();
});

// ── Score Challenge (free points game — COMPLIANCE.md) ──────────────────────

/// The current gameweek + the fan's standing. Re-fetches when auth changes so
/// the personalized `me` block and existing calls reflect the signed-in fan.
final challengeCurrentProvider = FutureProvider<ChallengeCurrent>((ref) async {
  ref.watch(currentUserProvider);
  return ref.watch(challengeRepositoryProvider).getCurrent();
});

/// A leaderboard. `null` = the global board; a pool id = a mini-league board.
final challengeBoardProvider =
    FutureProvider.family<ChallengeBoard, int?>((ref, poolId) async {
  ref.watch(currentUserProvider);
  return ref.watch(challengeRepositoryProvider).leaderboard(poolId: poolId);
});

/// The fan's private mini-leagues (signed-in only).
final challengePoolsProvider = FutureProvider<List<ChallengePool>>((ref) async {
  if (ref.watch(currentUserProvider) == null) return const <ChallengePool>[];
  return ref.watch(challengeRepositoryProvider).pools();
});

// ── Follows ─────────────────────────────────────────────────────────────────

/// Tracks which entities the signed-in user follows. Refreshes when auth changes.
class FollowsController extends StateNotifier<AsyncValue<Map<String, List<int>>>> {
  FollowsController(this._ref) : super(const AsyncValue.loading()) {
    load();
  }
  final Ref _ref;

  Future<void> load() async {
    if (_ref.read(currentUserProvider) == null) {
      state = const AsyncValue.data({'team': [], 'league': [], 'player': [], 'user': []});
      return;
    }
    state = const AsyncValue.loading();
    try {
      final data = await _ref.read(followsRepositoryProvider).all();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isFollowing(String type, int id) {
    final map = state.valueOrNull;
    return map?[type]?.contains(id) ?? false;
  }

  /// Optimiztically toggle, then reconcile with the server.
  Future<bool> toggle(String type, int id) async {
    final current = Map<String, List<int>>.from(
        state.valueOrNull ?? {'team': [], 'league': [], 'player': [], 'user': []});
    final list = List<int>.from(current[type] ?? const []);
    final wasFollowing = list.contains(id);
    if (wasFollowing) {
      list.remove(id);
    } else {
      list.add(id);
    }
    current[type] = list;
    state = AsyncValue.data(current);

    try {
      final following = await _ref.read(followsRepositoryProvider).toggle(type: type, id: id);
      // Reconcile in case the server disagreed.
      final reconciled = Map<String, List<int>>.from(state.valueOrNull ?? current);
      final reList = List<int>.from(reconciled[type] ?? const []);
      if (following && !reList.contains(id)) reList.add(id);
      if (!following && reList.contains(id)) reList.remove(id);
      reconciled[type] = reList;
      state = AsyncValue.data(reconciled);
      return following;
    } catch (_) {
      // Roll back on failure.
      final rollback = Map<String, List<int>>.from(state.valueOrNull ?? current);
      final rbList = List<int>.from(rollback[type] ?? const []);
      if (wasFollowing && !rbList.contains(id)) rbList.add(id);
      if (!wasFollowing && rbList.contains(id)) rbList.remove(id);
      rollback[type] = rbList;
      state = AsyncValue.data(rollback);
      return wasFollowing;
    }
  }
}

final followsControllerProvider =
    StateNotifierProvider<FollowsController, AsyncValue<Map<String, List<int>>>>(
        (ref) => FollowsController(ref));

/// Fixtures for teams/leagues the user follows (Following tab).
final followedFixturesProvider = FutureProvider<List<Fixture>>((ref) async {
  // Recompute when the follow set changes.
  ref.watch(followsControllerProvider);
  return ref.watch(fixtureRepositoryProvider).list(tab: 'today', followed: true);
});
