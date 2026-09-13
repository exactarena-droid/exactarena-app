import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/app_providers.dart';
import '../../data/auth_controller.dart';
import '../../theme/terrace_theme.dart';
import '../../widgets/widgets.dart';

/// Following tab: fixtures for the teams and leagues the user follows.
class FollowingScreen extends ConsumerWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          const SliverAppBar(pinned: true, floating: true, title: Text('Following')),
        ],
        body: user == null
            ? _SignedOut()
            : _FollowedFixtures(),
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      assetPath: 'assets/onboarding/follow.svg',
      title: 'Follow your teams',
      message: 'Sign in to follow teams and leagues and see their fixtures here.',
      action: FilledButton(
        onPressed: () => context.push('/login'),
        child: const Text('Sign in'),
      ),
    );
  }
}

class _FollowedFixtures extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixtures = ref.watch(followedFixturesProvider);
    return RefreshIndicator(
      color: context.terrace.brand,
      onRefresh: () => ref.refresh(followedFixturesProvider.future),
      child: AsyncView(
        value: fixtures,
        loading: const ListSkeleton(),
        onRetry: () => ref.invalidate(followedFixturesProvider),
        data: (list) {
          if (list.isEmpty) {
            return ListView(children: [
              const SizedBox(height: 40),
              EmptyState(
                assetPath: 'assets/onboarding/empty-following.svg',
                title: 'Nothing followed yet',
                message: 'Follow teams from their profile to see their matches here.',
                action: FilledButton.icon(
                  onPressed: () => context.go('/scores'),
                  icon: const Icon(LucideIcons.activity, size: 18),
                  label: const Text('Browse scores'),
                ),
              ),
            ]);
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, i) => MatchCard(
              fixture: list[i],
              showLeague: true,
              onTap: () => context.push('/match/${list[i].id}'),
            ),
          );
        },
      ),
    );
  }
}
