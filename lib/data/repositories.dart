import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/result.dart';
import '../models/models.dart';

/// Runs an API call and normalises failures to [AppFailure].
Future<T> _guard<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on DioException catch (e) {
    throw AppFailure.fromDio(e);
  }
}

class ConfigRepository {
  ConfigRepository(this._api);
  final ApiClient _api;

  Future<AppConfig> fetch() =>
      _guard(() async => _api.mapData(await _api.get('/config'), AppConfig.fromJson));
}

class LeagueRepository {
  LeagueRepository(this._api);
  final ApiClient _api;

  Future<List<League>> all() =>
      _guard(() async => _api.mapList(await _api.get('/leagues'), League.fromJson));

  Future<List<Standing>> standings(int leagueId, {String? season}) => _guard(() async {
        final res = await _api.get('/leagues/$leagueId/standings', query: {'season': season});
        return _api.mapList(res, Standing.fromJson);
      });
}

class FixtureRepository {
  FixtureRepository(this._api);
  final ApiClient _api;

  Future<List<Fixture>> list({
    String tab = 'today',
    String? date,
    int? league,
    int? team,
    bool followed = false,
    int? perPage,
  }) =>
      _guard(() async {
        final res = await _api.get('/fixtures', query: {
          'tab': tab,
          'date': date,
          'league': league,
          'team': team,
          if (followed) 'followed': 1,
          'per_page': perPage,
        });
        return _api.mapList(res, Fixture.fromJson);
      });

  Future<Fixture> detail(int id) =>
      _guard(() async => _api.mapData(await _api.get('/fixtures/$id'), Fixture.fromJson));

  Future<List<ThreadPost>> thread(int fixtureId, {int? perPage}) => _guard(() async {
        final res = await _api.get('/fixtures/$fixtureId/thread', query: {'per_page': perPage});
        return _api.mapList(res, ThreadPost.fromJson);
      });
}

class RatingsRepository {
  RatingsRepository(this._api);
  final ApiClient _api;

  /// Fan verdict + Man of the Match for a fixture. Opinion only (COMPLIANCE.md).
  Future<FixtureRatings> get(int fixtureId) => _guard(() async =>
      _api.mapData(await _api.get('/fixtures/$fixtureId/ratings'), FixtureRatings.fromJson));

  /// Rate a player's performance 1–10 (like a Man-of-the-Match vote). Returns
  /// the refreshed verdict payload.
  Future<FixtureRatings> rate(int fixtureId, int playerId, int rating) => _guard(() async {
        final res = await _api.post(
          '/fixtures/$fixtureId/players/$playerId/rate',
          body: {'rating': rating},
        );
        return _api.mapData(res, FixtureRatings.fromJson);
      });
}

class TeamRepository {
  TeamRepository(this._api);
  final ApiClient _api;

  Future<Team> detail(int id) =>
      _guard(() async => _api.mapData(await _api.get('/teams/$id'), Team.fromJson));

  Future<List<Fixture>> fixtures(int id) =>
      _guard(() async => _api.mapList(await _api.get('/teams/$id/fixtures'), Fixture.fromJson));

  Future<List<Player>> squad(int id) =>
      _guard(() async => _api.mapList(await _api.get('/teams/$id/squad'), Player.fromJson));
}

class PlayerRepository {
  PlayerRepository(this._api);
  final ApiClient _api;

  Future<Player> detail(int id) =>
      _guard(() async => _api.mapData(await _api.get('/players/$id'), Player.fromJson));
}

class NewsRepository {
  NewsRepository(this._api);
  final ApiClient _api;

  Future<List<Article>> list({
    String? category,
    String? query,
    bool premiumOnly = false,
    bool sponsoredOnly = false,
    int? perPage,
  }) =>
      _guard(() async {
        final res = await _api.get('/news', query: {
          'category': category,
          'q': query,
          if (premiumOnly) 'premium': 1,
          if (sponsoredOnly) 'sponsored': 1,
          'per_page': perPage,
        });
        return _api.mapList(res, Article.fromJson);
      });

  Future<List<Category>> categories() =>
      _guard(() async => _api.mapList(await _api.get('/news/categories'), Category.fromJson));

  Future<Article> detail(String slug) =>
      _guard(() async => _api.mapData(await _api.get('/news/$slug'), Article.fromJson));
}

class CommunityRepository {
  CommunityRepository(this._api);
  final ApiClient _api;

  Future<ThreadPost> reply(int threadId, {required String body, int? parentId}) =>
      _guard(() async {
        final res = await _api.post('/threads/$threadId/posts', body: {
          'body': body,
          'parent_id': ?parentId,
        });
        return _api.mapData(res, ThreadPost.fromJson);
      });

  /// Toggle a reaction; re-sending the same type removes it. Returns the raw map.
  Future<Map<String, dynamic>> react(int postId, ReactionType type) => _guard(() async {
        final res = await _api.post('/posts/$postId/react', body: {'type': type.apiValue});
        final data = res.data;
        return (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      });
}

class PollRepository {
  PollRepository(this._api);
  final ApiClient _api;

  Future<Poll> vote(int pollId, int optionId) => _guard(() async {
        final res = await _api.post('/polls/$pollId/vote', body: {'option_id': optionId});
        return _api.mapData(res, Poll.fromJson);
      });
}

class FollowsRepository {
  FollowsRepository(this._api);
  final ApiClient _api;

  Future<Map<String, List<int>>> all() => _guard(() async {
        final res = await _api.get('/follows');
        final body = res.data;
        final data = (body is Map && body['data'] is Map) ? body['data'] as Map : const {};
        Map<String, List<int>> pick() {
          final out = <String, List<int>>{};
          for (final key in ['team', 'league', 'player', 'user']) {
            final list = data[key];
            out[key] = (list is List)
                ? list.map((e) => int.tryParse(e.toString()) ?? -1).where((e) => e >= 0).toList()
                : <int>[];
          }
          return out;
        }

        return pick();
      });

  Future<bool> toggle({required String type, required int id}) => _guard(() async {
        final res = await _api.post('/follows/toggle', body: {'type': type, 'id': id});
        final data = res.data;
        if (data is Map && data['following'] != null) return data['following'] == true;
        return false;
      });
}

class PlanRepository {
  PlanRepository(this._api);
  final ApiClient _api;

  Future<List<Plan>> all() =>
      _guard(() async => _api.mapList(await _api.get('/plans'), Plan.fromJson));
}

/// Score Challenge — the free, points-only fan game (COMPLIANCE.md): call the
/// scorelines for a gameweek, earn leaderboard points, run private mini-leagues.
class ChallengeRepository {
  ChallengeRepository(this._api);
  final ApiClient _api;

  /// The current gameweek + the fan's standing (personalized when authed).
  Future<ChallengeCurrent> getCurrent() => _guard(() async =>
      _api.mapData(await _api.get('/challenge/current'), ChallengeCurrent.fromJson));

  /// Submit (or update) the fan's calls for a gameweek. Each fixture locks at
  /// its own kickoff, so already-kicked-off fixtures are dropped server-side.
  Future<ChallengeCurrent> submitCalls(int roundId, Map<int, Call> calls) =>
      _guard(() async {
        final entries = calls.entries.map((e) => e.value.toEntry(e.key)).toList();
        final res = await _api.post(
          '/challenge/rounds/$roundId/entries',
          body: {'entries': entries},
        );
        return _api.mapData(res, ChallengeCurrent.fromJson);
      });

  /// Global leaderboard, or a private mini-league's board when [poolId] is set.
  Future<ChallengeBoard> leaderboard({int? poolId}) => _guard(() async {
        final res = await _api.get('/challenge/leaderboard', query: {'pool': poolId});
        return _api.mapData(res, ChallengeBoard.fromJson);
      });

  /// The fan's private mini-leagues.
  Future<List<ChallengePool>> pools() =>
      _guard(() async => _api.mapList(await _api.get('/challenge/pools'), ChallengePool.fromJson));

  /// Create a private mini-league; returns it with its invite [code].
  Future<ChallengePool> createPool(String name) => _guard(() async {
        final res = await _api.post('/challenge/pools', body: {'name': name});
        return _api.mapData(res, ChallengePool.fromJson);
      });

  /// Join a mini-league with an invite code.
  Future<ChallengePool> joinPool(String code) => _guard(() async {
        final res = await _api.post('/challenge/pools/join', body: {'code': code});
        return _api.mapData(res, ChallengePool.fromJson);
      });
}

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<User> updateProfile({String? name, String? username, String? bio, String? country}) =>
      _guard(() async {
        final res = await _api.put('/auth/profile', body: {
          'name': ?name,
          'username': ?username,
          'bio': ?bio,
          'country': ?country,
        });
        return _api.mapData(res, User.fromJson);
      });
}

// ── Repository providers ──────────────────────────────────────────────────

final configRepositoryProvider = Provider((ref) => ConfigRepository(ref.watch(apiClientProvider)));
final leagueRepositoryProvider = Provider((ref) => LeagueRepository(ref.watch(apiClientProvider)));
final fixtureRepositoryProvider = Provider((ref) => FixtureRepository(ref.watch(apiClientProvider)));
final ratingsRepositoryProvider = Provider((ref) => RatingsRepository(ref.watch(apiClientProvider)));
final teamRepositoryProvider = Provider((ref) => TeamRepository(ref.watch(apiClientProvider)));
final playerRepositoryProvider = Provider((ref) => PlayerRepository(ref.watch(apiClientProvider)));
final newsRepositoryProvider = Provider((ref) => NewsRepository(ref.watch(apiClientProvider)));
final communityRepositoryProvider =
    Provider((ref) => CommunityRepository(ref.watch(apiClientProvider)));
final pollRepositoryProvider = Provider((ref) => PollRepository(ref.watch(apiClientProvider)));
final followsRepositoryProvider =
    Provider((ref) => FollowsRepository(ref.watch(apiClientProvider)));
final planRepositoryProvider = Provider((ref) => PlanRepository(ref.watch(apiClientProvider)));
final challengeRepositoryProvider =
    Provider((ref) => ChallengeRepository(ref.watch(apiClientProvider)));
final profileRepositoryProvider =
    Provider((ref) => ProfileRepository(ref.watch(apiClientProvider)));
