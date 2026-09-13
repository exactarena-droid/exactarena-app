import 'json.dart';

/// Public author summary attached to thread posts.
class PostAuthor {
  final int id;
  final String name;
  final String? username;
  final String? avatar;

  const PostAuthor({required this.id, required this.name, this.username, this.avatar});

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
  }

  factory PostAuthor.fromJson(Map<String, dynamic> j) => PostAuthor(
        id: asInt(j['id']),
        name: asString(j['name'], 'Fan'),
        username: asStringOrNull(j['username']),
        avatar: asStringOrNull(j['avatar']),
      );
}

enum ReactionType {
  like,
  love,
  laugh,
  fire,
  clap;

  String get apiValue => name;

  static ReactionType? parse(String? raw) {
    for (final r in ReactionType.values) {
      if (r.name == raw) return r;
    }
    return null;
  }
}

class ThreadPost {
  final int id;
  final String body;
  final String? status;
  final int? parentId;
  final int reactionsCount;
  final int repliesCount;
  final DateTime? createdAt;
  final PostAuthor user;
  final ReactionType? myReaction;
  final List<ThreadPost> replies;

  const ThreadPost({
    required this.id,
    required this.body,
    this.status,
    this.parentId,
    this.reactionsCount = 0,
    this.repliesCount = 0,
    this.createdAt,
    required this.user,
    this.myReaction,
    this.replies = const [],
  });

  ThreadPost copyWith({
    int? reactionsCount,
    Object? myReaction = _sentinel,
  }) =>
      ThreadPost(
        id: id,
        body: body,
        status: status,
        parentId: parentId,
        reactionsCount: reactionsCount ?? this.reactionsCount,
        repliesCount: repliesCount,
        createdAt: createdAt,
        user: user,
        myReaction:
            identical(myReaction, _sentinel) ? this.myReaction : myReaction as ReactionType?,
        replies: replies,
      );

  factory ThreadPost.fromJson(Map<String, dynamic> j) => ThreadPost(
        id: asInt(j['id']),
        body: asString(j['body']),
        status: asStringOrNull(j['status']),
        parentId: asIntOrNull(j['parent_id']),
        reactionsCount: asInt(j['reactions_count']),
        repliesCount: asInt(j['replies_count']),
        createdAt: asDate(j['created_at']),
        user: PostAuthor.fromJson(asMap(j['user']) ?? const {}),
        myReaction: ReactionType.parse(asStringOrNull(j['my_reaction'])),
        replies: asMapList(j['replies']).map(ThreadPost.fromJson).toList(),
      );
}

const Object _sentinel = Object();
