import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';

class _OnboardPage {
  final String asset;
  final String headline;
  final String sub;
  const _OnboardPage(this.asset, this.headline, this.sub);
}

/// Five-screen first-run flow. Copy mirrors design/onboarding/manifest.json.
const _pages = <_OnboardPage>[
  _OnboardPage('assets/onboarding/welcome.svg', 'Every match. One terrace.',
      'Live scores, deep stats and a fan community in one place.'),
  _OnboardPage('assets/onboarding/live-scores.svg', 'Goals the second they happen.',
      'Real-time scores, match clock and event timelines.'),
  _OnboardPage('assets/onboarding/deep-stats.svg', 'The numbers behind the game.',
      'Tables, form, head-to-head and season-long stats.'),
  _OnboardPage('assets/onboarding/community.svg', 'Sit with fans who get it.',
      'Match-day threads, polls and reactions.'),
  _OnboardPage('assets/onboarding/follow.svg', 'Your teams. Your alerts.',
      'Follow teams and leagues, get the notifications you choose.'),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _finish() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(PrefsKeys.seenOnboarding, true);
    if (mounted) context.go('/scores');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                child: AnimatedOpacity(
                  opacity: _isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _isLast ? null : _finish,
                    child: const Text('Skip'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: SvgPicture.asset(p.asset, width: 260, height: 230),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          '0${i + 1} / 0${_pages.length}',
                          style: TerraceTextStyles.overline(context, color: t.brand),
                        ),
                        const SizedBox(height: 12),
                        Text(p.headline, style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: 12),
                        Text(
                          p.sub,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: t.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              child: Row(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _index ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _index ? t.brand : t.surfaceInset,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TerraceRadii.full),
                      ),
                    ),
                    child: Text(_isLast ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper used by the router redirect to decide whether to show onboarding.
bool hasSeenOnboarding(SharedPreferences prefs) =>
    prefs.getBool(PrefsKeys.seenOnboarding) ?? false;
