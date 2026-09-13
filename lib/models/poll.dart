import 'json.dart';

class PollOption {
  final int id;
  final String label;
  final int votesCount;
  final double percentage;

  const PollOption({
    required this.id,
    required this.label,
    this.votesCount = 0,
    this.percentage = 0,
  });

  factory PollOption.fromJson(Map<String, dynamic> j) => PollOption(
        id: asInt(j['id']),
        label: asString(j['label']),
        votesCount: asInt(j['votes_count']),
        percentage: asDouble(j['percentage']),
      );
}

/// Fan OPINION poll only (fan opinion only — see COMPLIANCE.md).
class Poll {
  final int id;
  final String question;
  final DateTime? closesAt;
  final bool isClosed;
  final int votesCount;
  final int? myVoteOptionId;
  final List<PollOption> options;

  const Poll({
    required this.id,
    required this.question,
    this.closesAt,
    this.isClosed = false,
    this.votesCount = 0,
    this.myVoteOptionId,
    this.options = const [],
  });

  bool get hasVoted => myVoteOptionId != null;

  factory Poll.fromJson(Map<String, dynamic> j) => Poll(
        id: asInt(j['id']),
        question: asString(j['question']),
        closesAt: asDate(j['closes_at']),
        isClosed: asBool(j['is_closed']),
        votesCount: asInt(j['votes_count']),
        myVoteOptionId: asIntOrNull(j['my_vote_option_id']),
        options: asMapList(j['options']).map(PollOption.fromJson).toList(),
      );
}
