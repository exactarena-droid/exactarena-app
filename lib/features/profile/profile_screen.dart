import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/result.dart';
import '../../data/app_providers.dart';
import '../../data/auth_controller.dart';
import '../../models/user.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Live chat is gated on a configured Supoora embed key (from /config).
    final hasLiveChat =
        ref.watch(appConfigProvider).valueOrNull?.hasLiveChat ?? false;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            title: const Text('Profile'),
            actions: [
              if (hasLiveChat)
                IconButton(
                  tooltip: 'Live chat',
                  icon: const Icon(LucideIcons.headset),
                  onPressed: () => context.push('/support'),
                ),
            ],
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (user != null) _UserHeader(user: user) else const _SignedOutHeader(),
            const _ThemeToggleTile(),
            if (user != null) ...[
              const _SectionLabel('Notifications'),
              const _NotificationPrefs(),
            ],
            const _SectionLabel('Terrace'),
            _LinkTile(
              icon: LucideIcons.crown,
              label: 'Premium plans',
              accent: context.terrace.accent,
              onTap: () => context.push('/plans'),
              trailing: user?.isPremium == true
                  ? const PremiumBadge(label: 'ACTIVE', compact: true)
                  : null,
            ),
            _LinkTile(
              icon: LucideIcons.trophy,
              label: 'Standings',
              onTap: () => context.push('/standings'),
            ),
            _LinkTile(
              icon: LucideIcons.star,
              label: 'Following',
              onTap: () => context.push('/following'),
            ),
            _LinkTile(
              icon: LucideIcons.users,
              label: 'Community',
              onTap: () => context.push('/community'),
            ),
            if (hasLiveChat)
              _LinkTile(
                icon: LucideIcons.headset,
                label: 'Live chat',
                onTap: () => context.push('/support'),
              ),
            _LinkTile(
              icon: LucideIcons.info,
              label: 'About Exact Arena',
              onTap: () => _showAbout(context),
            ),
            const SizedBox(height: 20),
            if (user != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.terrace.danger,
                    side: BorderSide(color: context.terrace.danger.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => _confirmDeleteAccount(context, ref),
                  child: Text('Delete account',
                      style: TextStyle(color: context.terrace.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently deletes your account and all your data — calls, leagues, posts and follows. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: ctx.terrace.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Your account has been deleted.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e is AppFailure ? e.message : 'Could not delete your account.')));
      }
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Terrace',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Live scores, statistics, news and fan community.',
    );
  }
}

class _UserHeader extends StatelessWidget {
  final User user;
  const _UserHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.brandSubtle, t.surface],
        ),
        borderRadius: BorderRadius.circular(TerraceRadii.xl2),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          InitialAvatar(imageUrl: user.avatar, initials: user.initials, size: 60, seed: user.id),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    if (user.isPremium) ...[
                      const SizedBox(width: 8),
                      const PremiumBadge(compact: true),
                    ],
                  ],
                ),
                if (user.username != null)
                  Text('@${user.username}', style: Theme.of(context).textTheme.bodyMedium),
                if (user.email != null)
                  Text(user.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutHeader extends StatelessWidget {
  const _SignedOutHeader();

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.xl2),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.brandSubtle, shape: BoxShape.circle),
            child: Icon(LucideIcons.user, color: t.brand, size: 28),
          ),
          const SizedBox(height: 14),
          Text("You're browsing as a guest", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Sign in to follow teams, react and join match threads.',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleTile extends ConsumerWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final t = context.terrace;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(TerraceRadii.lg),
          border: Border.all(color: t.border),
        ),
        child: SwitchListTile(
          value: isDark,
          onChanged: (v) => ref.read(themeModeProvider.notifier).set(v ? ThemeMode.dark : ThemeMode.light),
          secondary: Icon(isDark ? LucideIcons.moon : LucideIcons.sun, color: t.brand),
          title: const Text('Dark mode'),
          subtitle: Text(isDark ? 'Match-day dark theme' : 'Warm light theme',
              style: Theme.of(context).textTheme.bodySmall),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TerraceRadii.lg)),
        ),
      ),
    );
  }
}

/// Local notification preference toggles (persisted in shared_preferences).
class _NotificationPrefs extends ConsumerWidget {
  const _NotificationPrefs();

  static const _prefs = [
    ('notify.goals', 'Goal alerts', 'A push when a team you follow scores', LucideIcons.goal),
    ('notify.kickoff', 'Kickoff reminders', 'Before matches you follow start', LucideIcons.bell),
    ('notify.news', 'News digest', 'Editorial highlights and match reports', LucideIcons.newspaper),
    ('notify.threads', 'Thread replies', 'When someone replies to you', LucideIcons.messageCircle),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.terrace;
    final store = ref.watch(sharedPrefsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(TerraceRadii.lg),
          border: Border.all(color: t.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < _prefs.length; i++) ...[
              if (i > 0) Divider(height: 1, color: t.border),
              _PrefToggle(prefKey: _prefs[i].$1, title: _prefs[i].$2, subtitle: _prefs[i].$3, icon: _prefs[i].$4, store: store),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrefToggle extends StatefulWidget {
  final String prefKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final dynamic store;
  const _PrefToggle({
    required this.prefKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.store,
  });

  @override
  State<_PrefToggle> createState() => _PrefToggleState();
}

class _PrefToggleState extends State<_PrefToggle> {
  late bool _value = widget.store.getBool(widget.prefKey) as bool? ?? true;

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return SwitchListTile(
      value: _value,
      onChanged: (v) {
        setState(() => _value = v);
        widget.store.setBool(widget.prefKey, v);
      },
      secondary: Icon(widget.icon, color: t.textSecondary, size: 22),
      title: Text(widget.title),
      subtitle: Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;
  final Widget? trailing;
  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Material(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TerraceRadii.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TerraceRadii.lg),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: accent ?? t.textSecondary),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
                if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
                Icon(LucideIcons.chevronRight, size: 18, color: t.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text(text.toUpperCase(), style: TerraceTextStyles.overline(context)),
    );
  }
}
