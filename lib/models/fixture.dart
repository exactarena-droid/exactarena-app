import 'fixture_event.dart';
import 'json.dart';
import 'league.dart';
import 'team.dart';

enum FixtureStatus {
  scheduled,
  live,
  halftime,
  finished,
  postponed,
  canceled,
  unknown;

  static FixtureStatus parse(String? raw) {
    switch (raw) {
      case 'scheduled':
        return FixtureStatus.scheduled;
      case 'live':
        return FixtureStatus.live;
      case 'halftime':
        return FixtureStatus.halftime;
      case 'finished':
        return FixtureStatus.finished;
      case 'postponed':
        return FixtureStatus.postponed;
      case 'canceled':
        return FixtureStatus.canceled;
      default:
        return FixtureStatus.unknown;
    }
  }
}

class Fixture {
  final int id;
  final DateTime? kickoffAt;
  final FixtureStatus status;
  final String? statusDetail;
  final int? minute;
  final bool isLive;
  final bool isFinished;
  final Team? homeTeam;
  final Team? awayTeam;
  final int? homeScore;
  final int? awayScore;
  final League? league;
  final String? round;
  final String? season;
  final String? venue;
  final List<FixtureEvent> events;
  final bool hasThread;

  const Fixture({
    required this.id,
    this.kickoffAt,
    required this.status,
    this.statusDetail,
    this.minute,
    this.isLive = false,
    this.isFinished = false,
    this.homeTeam,
    this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.league,
    this.round,
    this.season,
    this.venue,
    this.events = const [],
    this.hasThread = false,
  });

  bool get isHalftime => status == FixtureStatus.halftime;
  bool get hasScore => homeScore != null && awayScore != null;

  factory Fixture.fromJson(Map<String, dynamic> j) => Fixture(
        id: asInt(j['id']),
        kickoffAt: asDate(j['kickoff_at']),
        status: FixtureStatus.parse(asStringOrNull(j['status'])),
        statusDetail: asStringOrNull(j['status_detail']),
        minute: asIntOrNull(j['minute']),
        isLive: asBool(j['is_live']),
        isFinished: asBool(j['is_finished']),
        homeTeam: asMap(j['home_team']) == null ? null : Team.fromJson(asMap(j['home_team'])!),
        awayTeam: asMap(j['away_team']) == null ? null : Team.fromJson(asMap(j['away_team'])!),
        homeScore: asIntOrNull(j['home_score']),
        awayScore: asIntOrNull(j['away_score']),
        league: asMap(j['league']) == null ? null : League.fromJson(asMap(j['league'])!),
        round: asStringOrNull(j['round']),
        season: asStringOrNull(j['season']),
        venue: asStringOrNull(j['venue']),
        events: asMapList(j['events']).map(FixtureEvent.fromJson).toList(),
        hasThread: asBool(j['has_thread']),
      );
}
