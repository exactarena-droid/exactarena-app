import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/auth_controller.dart';
import '../../data/repositories.dart';
import '../../models/thread_post.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/team_crest.dart';

IconData reactionIcon(ReactionType type) => switch (type) {
      ReactionType.like => LucideIcons.thumbsUp,
      ReactionType.love => LucideIcons.heart,
      ReactionType.laugh => LucideIcons.laugh,
      ReactionType.fire => LucideIcons.flame,
      ReactionType.clap => LucideIcons.partyPopper,
    };

/// A single thread post with author, body, relative time and a reaction action.
class PostTile extends ConsumerStatefulWidget {
  final ThreadPost post;
  final bool isReply;
  const PostTile({super.key, required this.post, this.isReply = false});

  @override
  ConsumerState<PostTile> createState() => _PostTileState();
}

class _PostTileState extends ConsumerState<PostTile> {
  late ThreadPost _post = widget.post;
  bool _busy = false;

  Future<void> _react(ReactionType type) async {
    if (_busy) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to react.')),
      );
      return;
    }
    // Optimiztic toggle.
    final wasSame = _post.myReaction == type;
    setState(() {
      _busy = true;
      _post = _post.copyWith(
        myReaction: wasSame ? null : type,
        reactionsCount: _post.reactionsCount + (wasSame ? -1 : (_post.myReaction == null ? 1 : 0)),
      );
    });
    try {
      await ref.read(communityRepositoryProvider).react(_post.id, type);
    } catch (_) {
      if (mounted) setState(() => _post = widget.post);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openReactions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final r in ReactionType.values)
                IconButton(
                  iconSize: 26,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _react(r);
                  },
                  icon: Icon(reactionIcon(r)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final p = _post;
    final reacted = p.myReaction != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(widget.isReply ? 44 : 16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialAvatar(
            imageUrl: p.user.avatar,
            initials: p.user.initials,
            size: widget.isReply ? 28 : 34,
            seed: p.user.id,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                    if (p.user.username != null) ...[
                      const SizedBox(width: 6),
                      Text('@${p.user.username}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(width: 6),
                    Text('· ${_relative(p.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(p.body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: t.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ActionChip(
                      icon: reacted ? reactionIcon(p.myReaction!) : LucideIcons.heart,
                      label: '${p.reactionsCount}',
                      active: reacted,
                      onTap: () => _react(p.myReaction ?? ReactionType.like),
                      onLongPress: _openReactions,
                    ),
                    const SizedBox(width: 14),
                    _ActionChip(
                      icon: LucideIcons.messageCircle,
                      label: '${p.repliesCount}',
                      active: false,
                      onTap: () {},
                    ),
                  ],
                ),
                for (final reply in p.replies) PostTile(post: reply, isReply: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _relative(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM').format(dt.toLocal());
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final color = active ? t.brand : t.textMuted;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(TerraceRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
