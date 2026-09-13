import 'json.dart';
import 'team.dart';

/// Score Challenge models — the free, points-only fan game where you call the
/// final scoreline of each gameweek's fixtures and climb leaderboards.
/// No money in or out, points only (see COMPLIANCE.md).

/// A lightweight fixture summary used inside a challenge round. Reuses the
/// existing [Team] model for crests and names.
class FixtureBrief {
  final int id;
  final DateTime? kickoffAt;
  final Team? homeTeam;
  final Team? awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String? leagueName;
  final bool isFinished;

  const FixtureBrief({
    required this.id,
    this.kickoffAt,
    this.homeTeam,
    this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.leagueName,
    this.isFinished = false,
  });

  bool get hasScore => homeScore != null && awayScore != null;

  factory FixtureBrief.fromJson(Map<String, dynamic> j) {
    final league = asMap(j['league']);
    return FixtureBrief(
      id: asInt(j['id']),
      kickoffAt: asDate(j['kickoff_at']),
      homeTeam: asMap(j['home_team']) == null ? null : Team.fromJson(asMap(j['home_team'])!),
      awayTeam: asMap(j['away_team']) == null ? null : Team.fromJson(asMap(j['away_team'])!),
      homeScore: asIntOrNull(j['home_score']),
      awayScore: asIntOrNull(j['away_score']),
      leagueName: league == null ? asStringOrNull(j['league']) : asStringOrNull(league['name']),
      isFinished: asBool(j['is_finished']),
    );
  }
}

/// A score the fan has called for a fixture.
class Call {
  final int homeScore;
  final int awayScore;
  const Call(this.homeScore, this.awayScore);

  factory Call.fromJson(Map<String, dynamic> j) =>
      Call(asInt(j['home_score']), asInt(j['away_score']));

  Map<String, dynamic> toEntry(int fixtureId) => {
        'fixture_id': fixtureId,
        'home_score': homeScore,
        'away_score': awayScore,
      };
}

/// One fixture inside a gameweek, with the fan's call + earned points.
class RoundFixtureCall {
  final FixtureBrief fixture;
  final bool kickedOff;
  final Call? myCall;
  final int? points;
  final bool settled;

  const RoundFixtureCall({
    required this.fixture,
    this.kickedOff = false,
    this.myCall,
    this.points,
    this.settled = false,
  });

  /// Whether the fan can still edit this call (only before kickoff).
  bool get isLocked => kickedOff;

  factory RoundFixtureCall.fromJson(Map<String, dynamic> j) {
    final call = asMap(j['my_call']);
    return RoundFixtureCall(
      fixture: FixtureBrief.fromJson(asMap(j['fixture']) ?? const {}),
      kickedOff: asBool(j['kicked_off']),
      myCall: call == null ? null : Call.fromJson(call),
      points: asIntOrNull(j['points']),
      settled: asBool(j['settled']),
    );
  }
}

enum ChallengeRoundStatus {
  open,
  locked,
  settled,
  unknown;

  static ChallengeRoundStatus parse(String? raw) {
    switch (raw) {
      case 'open':
        return ChallengeRoundStatus.open;
      case 'locked':
        return ChallengeRoundStatus.locked;
      case 'settled':
        return ChallengeRoundStatus.settled;
      default:
        return ChallengeRoundStatus.unknown;
    }
  }
}

/// A gameweek of fixtures to call.
class ChallengeRound {
  final int id;
  final String name;
  final DateTime? locksAt;
  final bool isLocked;
  final ChallengeRoundStatus status;
  final List<RoundFixtureCall> fixtures;

  const ChallengeRound({
    required this.id,
    required this.name,
    this.locksAt,
    this.isLocked = false,
    this.status = ChallengeRoundStatus.unknown,
    this.fixtures = const [],
  });

  /// Fixtures the fan can still call (not yet kicked off).
  Iterable<RoundFixtureCall> get openFixtures => fixtures.where((f) => !f.kickedOff);

  factory ChallengeRound.fromJson(Map<String, dynamic> j) => ChallengeRound(
        id: asInt(j['id']),
        name: asString(j['name'], 'Gameweek'),
        locksAt: asDate(j['locks_at']),
        isLocked: asBool(j['is_locked']),
        status: ChallengeRoundStatus.parse(asStringOrNull(j['status'])),
        fixtures: asMapList(j['fixtures']).map(RoundFixtureCall.fromJson).toList(),
      );
}

/// The signed-in fan's personal standing in the current round.
class ChallengeMe {
  final int rank;
  final int points;
  final int played;
  final int exacts;
  final int streak;
  final int called;
  final int fixtures;

  const ChallengeMe({
    this.rank = 0,
    this.points = 0,
    this.played = 0,
    this.exacts = 0,
    this.streak = 0,
    this.called = 0,
    this.fixtures = 0,
  });

  factory ChallengeMe.fromJson(Map<String, dynamic> j) => ChallengeMe(
        rank: asInt(j['rank']),
        points: asInt(j['points']),
        played: asInt(j['played']),
        exacts: asInt(j['exacts']),
        streak: asInt(j['streak']),
        called: asInt(j['called']),
        fixtures: asInt(j['fixtures']),
      );
}

/// The current gameweek bundled with the fan's standing (null when signed out).
class ChallengeCurrent {
  final ChallengeRound round;
  final ChallengeMe? me;

  const ChallengeCurrent({required this.round, this.me});

  factory ChallengeCurrent.fromJson(Map<String, dynamic> j) => ChallengeCurrent(
        round: ChallengeRound.fromJson(asMap(j['round']) ?? const {}),
        me: asMap(j['me']) == null ? null : ChallengeMe.fromJson(asMap(j['me'])!),
      );
}

/// A single entry in a leaderboard.
class LeaderRow {
  final int rank;
  final int points;
  final int played;
  final int exacts;
  final int streak;
  final bool isMe;
  final LeaderUser user;

  const LeaderRow({
    required this.rank,
    required this.points,
    required this.played,
    required this.exacts,
    required this.streak,
    required this.isMe,
    required this.user,
  });

  factory LeaderRow.fromJson(Map<String, dynamic> j) => LeaderRow(
        rank: asInt(j['rank']),
        points: asInt(j['points']),
        played: asInt(j['played']),
        exacts: asInt(j['exacts']),
        streak: asInt(j['streak']),
        isMe: asBool(j['is_me']),
        user: LeaderUser.fromJson(asMap(j['user']) ?? const {}),
      );
}

/// A trimmed user shown on a leaderboard row.
class LeaderUser {
  final String name;
  final String? username;
  final String? avatar;

  const LeaderUser({required this.name, this.username, this.avatar});

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
  }

  factory LeaderUser.fromJson(Map<String, dynamic> j) => LeaderUser(
        name: asString(j['name'], 'Fan'),
        username: asStringOrNull(j['username']),
        avatar: asStringOrNull(j['avatar']),
      );
}

/// A leaderboard for a scope (global, or a private mini-league).
class ChallengeBoard {
  final String scope;
  final List<LeaderRow> leaders;
  final LeaderRow? me;

  const ChallengeBoard({
    this.scope = 'global',
    this.leaders = const [],
    this.me,
  });

  factory ChallengeBoard.fromJson(Map<String, dynamic> j) => ChallengeBoard(
        scope: asString(j['scope'], 'global'),
        leaders: asMapList(j['leaders']).map(LeaderRow.fromJson).toList(),
        me: asMap(j['me']) == null ? null : LeaderRow.fromJson(asMap(j['me'])!),
      );
}

/// A private mini-league the fan owns or has joined.
class ChallengePool {
  final int id;
  final String name;
  final String code;
  final bool isPublic;
  final bool isOwner;
  final int membersCount;
  final int myRank;
  final int myPoints;

  const ChallengePool({
    required this.id,
    required this.name,
    required this.code,
    this.isPublic = false,
    this.isOwner = false,
    this.membersCount = 0,
    this.myRank = 0,
    this.myPoints = 0,
  });

  factory ChallengePool.fromJson(Map<String, dynamic> j) => ChallengePool(
        id: asInt(j['id']),
        name: asString(j['name'], 'Mini-league'),
        code: asString(j['code']),
        isPublic: asBool(j['is_public']),
        isOwner: asBool(j['is_owner']),
        membersCount: asInt(j['members_count']),
        myRank: asInt(j['my_rank']),
        myPoints: asInt(j['my_points']),
      );
}
