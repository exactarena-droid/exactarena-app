import 'json.dart';

/// A rated player's identity within a fixture-ratings payload. This is a slim
/// projection of the API's player object (id, name, position, photo, shirt
/// number, team) used by the fan-verdict surface.
class RatedPlayer {
  final int id;
  final String name;
  final String? position;
  final String? photo;
  final int? shirtNumber;
  final int? teamId;

  const RatedPlayer({
    required this.id,
    required this.name,
    this.position,
    this.photo,
    this.shirtNumber,
    this.teamId,
  });

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
  }

  factory RatedPlayer.fromJson(Map<String, dynamic> j) => RatedPlayer(
        id: asInt(j['id']),
        name: asString(j['name']),
        position: asStringOrNull(j['position']),
        photo: asStringOrNull(j['photo']),
        shirtNumber: asIntOrNull(j['shirt_number']),
        teamId: asIntOrNull(j['team_id']),
      );
}

/// The Man-of-the-Match verdict: the top-rated player by fan average.
/// Pure opinion on a past performance — see COMPLIANCE.md.
class PlayerVerdict {
  final RatedPlayer player;
  final double avg;
  final int votes;

  const PlayerVerdict({required this.player, required this.avg, required this.votes});

  factory PlayerVerdict.fromJson(Map<String, dynamic> j) => PlayerVerdict(
        player: RatedPlayer.fromJson(asMap(j['player']) ?? const {}),
        avg: asDouble(j['avg']),
        votes: asInt(j['votes']),
      );
}

/// One row in the fan-ratings list: a player, their side, the running fan
/// average + vote count, and the signed-in user's own rating (if any).
class PlayerRatingRow {
  final RatedPlayer player;
  final String side; // 'home' | 'away'
  final double avg;
  final int votes;
  final int? myRating;

  const PlayerRatingRow({
    required this.player,
    required this.side,
    required this.avg,
    required this.votes,
    this.myRating,
  });

  bool get isHome => side == 'home';

  factory PlayerRatingRow.fromJson(Map<String, dynamic> j) => PlayerRatingRow(
        player: RatedPlayer.fromJson(asMap(j['player']) ?? const {}),
        side: asString(j['side'], 'home'),
        avg: asDouble(j['avg']),
        votes: asInt(j['votes']),
        myRating: asIntOrNull(j['my_rating']),
      );
}

/// The full fan-verdict payload for a fixture: whether rating is open, the
/// total number of fan verdicts cast, the Man of the Match, and the per-player
/// rows. Opinion on what happened on the pitch — never a forecast.
class FixtureRatings {
  final bool canRate;
  final int totalVotes;
  final PlayerVerdict? motm;
  final List<PlayerRatingRow> players;

  const FixtureRatings({
    required this.canRate,
    required this.totalVotes,
    this.motm,
    this.players = const [],
  });

  factory FixtureRatings.fromJson(Map<String, dynamic> j) => FixtureRatings(
        canRate: asBool(j['can_rate']),
        totalVotes: asInt(j['total_votes']),
        motm: asMap(j['motm']) == null ? null : PlayerVerdict.fromJson(asMap(j['motm'])!),
        players: asMapList(j['players']).map(PlayerRatingRow.fromJson).toList(),
      );
}
