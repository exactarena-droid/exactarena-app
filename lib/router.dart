import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/community/community_screen.dart';
import 'features/community/thread_screen.dart';
import 'features/following/following_screen.dart';
import 'features/news/article_detail_screen.dart';
import 'features/news/news_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/play/play_screen.dart';
import 'features/player/player_profile_screen.dart';
import 'features/profile/plans_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/support_screen.dart';
import 'features/scores/match_detail_screen.dart';
import 'features/scores/scores_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/standings/standings_screen.dart';
import 'features/team/team_profile_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _playKey = GlobalKey<NavigatorState>(debugLabel: 'play');
final _scoresKey = GlobalKey<NavigatorState>(debugLabel: 'scores');
final _newsKey = GlobalKey<NavigatorState>(debugLabel: 'news');
final _profileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

int _intParam(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '') ?? 0;

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/play',
    redirect: (context, state) {
      final seen = hasSeenOnboarding(prefs);
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!seen && !atOnboarding) return '/onboarding';
      if (seen && atOnboarding) return '/play';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Auth (full-screen, above the shell).
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Detail routes shared across tabs (pushed onto the root navigator).
      GoRoute(
        path: '/match/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => MatchDetailScreen(fixtureId: _intParam(state, 'id')),
      ),
      GoRoute(
        path: '/team/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => TeamProfileScreen(teamId: _intParam(state, 'id')),
      ),
      GoRoute(
        path: '/player/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => PlayerProfileScreen(playerId: _intParam(state, 'id')),
      ),
      GoRoute(
        path: '/article/:slug',
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            ArticleDetailScreen(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        path: '/thread/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ThreadScreen(fixtureId: _intParam(state, 'id')),
      ),
      GoRoute(
        path: '/standings',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final raw = state.uri.queryParameters['league'];
          return StandingsScreen(initialLeagueId: raw == null ? null : int.tryParse(raw));
        },
      ),
      GoRoute(
        path: '/plans',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const PlansScreen(),
      ),
      GoRoute(
        path: '/support',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SupportScreen(),
      ),
      // Secondary destinations — off the bottom bar, opened full-screen from Profile.
      GoRoute(
        path: '/community',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const CommunityScreen(),
      ),
      GoRoute(
        path: '/following',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const FollowingScreen(),
      ),
      // Bottom-nav shell with four branches.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _playKey,
            routes: [GoRoute(path: '/play', builder: (context, state) => const PlayScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _scoresKey,
            routes: [GoRoute(path: '/scores', builder: (context, state) => const ScoresScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _newsKey,
            routes: [GoRoute(path: '/news', builder: (context, state) => const NewsScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _profileKey,
            routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});

/// Helper for main(): read whether onboarding was seen.
bool seenOnboarding(SharedPreferences prefs) => hasSeenOnboarding(prefs);
