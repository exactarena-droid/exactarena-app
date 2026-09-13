import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_providers.dart';
import '../../data/repositories.dart';
import '../../models/models.dart';

/// The leaderboard scope the Play screen is currently showing.
/// `null` poolId = the global board; a pool id = a mini-league board.
class BoardScope {
  final int? poolId;
  final String label;
  const BoardScope({this.poolId, required this.label});

  static const global = BoardScope(poolId: null, label: 'Global');

  @override
  bool operator ==(Object other) =>
      other is BoardScope && other.poolId == poolId && other.label == label;
  @override
  int get hashCode => Object.hash(poolId, label);
}

/// Which leaderboard scope the Play screen's Leaderboard tab is showing.
final boardScopeProvider = StateProvider<BoardScope>((ref) => BoardScope.global);

/// Submits a fan's calls for a gameweek, then refreshes the standings + boards.
/// Frames the action as a game ("locking in calls") for leaderboard points only.
class CallsController extends StateNotifier<AsyncValue<void>> {
  CallsController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  /// POST the calls for [roundId]. On success, invalidate the current round and
  /// every leaderboard so the new points/standing show up immediately.
  Future<bool> submit(int roundId, Map<int, Call> calls) async {
    if (calls.isEmpty) return false;
    state = const AsyncValue.loading();
    try {
      await _ref.read(challengeRepositoryProvider).submitCalls(roundId, calls);
      _ref.invalidate(challengeCurrentProvider);
      _ref.invalidate(challengeBoardProvider);
      _ref.invalidate(challengePoolsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final callsControllerProvider =
    StateNotifierProvider<CallsController, AsyncValue<void>>((ref) => CallsController(ref));
