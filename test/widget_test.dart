// Smoke test: the app boots and renders the onboarding flow on first run.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:terrace/core/providers.dart';
import 'package:terrace/main.dart';

void main() {
  testWidgets('App boots into onboarding on first run', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const TerraceApp(),
      ),
    );
    await tester.pump();

    // The first onboarding headline should be visible.
    expect(find.text('Every match. One terrace.'), findsOneWidget);
  });
}
