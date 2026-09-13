import 'json.dart';
import 'team.dart';

class Standing {
  final int rank;
  final Team team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDiff;
  final int points;
  final List<String> form;

  const Standing({
    required this.rank,
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDiff,
    required this.points,
    this.form = const [],
  });

  factory Standing.fromJson(Map<String, dynamic> j) => Standing(
        rank: asInt(j['rank']),
        team: Team.fromJson(asMap(j['team']) ?? const {}),
        played: asInt(j['played']),
        won: asInt(j['won']),
        drawn: asInt(j['drawn']),
        lost: asInt(j['lost']),
        goalsFor: asInt(j['goals_for']),
        goalsAgainst: asInt(j['goals_against']),
        goalDiff: asInt(j['goal_diff']),
        points: asInt(j['points']),
        form: asStringList(j['form']),
      );
}
