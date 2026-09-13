import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_providers.dart';
import '../data/auth_controller.dart';
import '../theme/terrace_theme.dart';

/// A star-toggle follow control backed by [followsControllerProvider].
/// Falls back to an [initialFollowing] hint (e.g. team.isFollowing) before the
/// follow set loads.
class FollowButton extends ConsumerWidget {
  final String type; // team | league | player | user
  final int id;
  final bool? initialFollowing;
  final bool compact;

  const FollowButton({
    super.key,
    required this.type,
    required this.id,
    this.initialFollowing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.terrace;
    final follows = ref.watch(followsControllerProvider);
    final following = follows.valueOrNull?[type]?.contains(id) ?? initialFollowing ?? false;

    Future<void> onPressed() async {
      if (ref.read(currentUserProvider) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to follow.')),
        );
        return;
      }
      await ref.read(followsControllerProvider.notifier).toggle(type, id);
    }

    if (compact) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(following ? LucideIcons.star : LucideIcons.star,
            color: following ? t.accent : t.textMuted),
      );
    }

    return following
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(LucideIcons.check, size: 18, color: t.brand),
            label: const Text('Following'),
            style: OutlinedButton.styleFrom(foregroundColor: t.brand, side: BorderSide(color: t.brand)),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(LucideIcons.star, size: 18),
            label: const Text('Follow'),
          );
  }
}
