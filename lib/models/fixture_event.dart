import 'json.dart';

/// A lightweight {id, name} reference used for players inside events.
class PlayerRef {
  final int id;
  final String name;
  const PlayerRef({required this.id, required this.name});

  factory PlayerRef.fromJson(Map<String, dynamic> j) =>
      PlayerRef(id: asInt(j['id']), name: asString(j['name']));
}

enum FixtureEventType {
  goal,
  ownGoal,
  penalty,
  missedPenalty,
  yellow,
  red,
  substitution,
  varReview,
  unknown;

  static FixtureEventType parse(String? raw) {
    switch (raw) {
      case 'goal':
        return FixtureEventType.goal;
      case 'own_goal':
        return FixtureEventType.ownGoal;
      case 'penalty':
        return FixtureEventType.penalty;
      case 'missed_penalty':
        return FixtureEventType.missedPenalty;
      case 'yellow':
        return FixtureEventType.yellow;
      case 'red':
        return FixtureEventType.red;
      case 'substitution':
        return FixtureEventType.substitution;
      case 'var':
        return FixtureEventType.varReview;
      default:
        return FixtureEventType.unknown;
    }
  }

  bool get isGoal =>
      this == FixtureEventType.goal ||
      this == FixtureEventType.penalty ||
      this == FixtureEventType.ownGoal;
}

class FixtureEvent {
  final int id;
  final int minute;
  final int? addedTime;
  final FixtureEventType type;
  final String? detail;
  final int? teamId;
  final PlayerRef? player;
  final PlayerRef? relatedPlayer;

  const FixtureEvent({
    required this.id,
    required this.minute,
    this.addedTime,
    required this.type,
    this.detail,
    this.teamId,
    this.player,
    this.relatedPlayer,
  });

  /// e.g. "67'" or "45+2'".
  String get minuteLabel {
    if (addedTime != null && addedTime! > 0) return "$minute+$addedTime'";
    return "$minute'";
  }

  factory FixtureEvent.fromJson(Map<String, dynamic> j) => FixtureEvent(
        id: asInt(j['id']),
        minute: asInt(j['minute']),
        addedTime: asIntOrNull(j['added_time']),
        type: FixtureEventType.parse(asStringOrNull(j['type'])),
        detail: asStringOrNull(j['detail']),
        teamId: asIntOrNull(j['team_id']),
        player: asMap(j['player']) == null ? null : PlayerRef.fromJson(asMap(j['player'])!),
        relatedPlayer: asMap(j['related_player']) == null
            ? null
            : PlayerRef.fromJson(asMap(j['related_player'])!),
      );
}
