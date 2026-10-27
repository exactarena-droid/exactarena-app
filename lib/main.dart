import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'theme/terrace_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional — the app runs fine without it (e.g. before push is configured on a platform).
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Missing / incomplete Firebase config for this platform — carry on without push.
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const TerraceApp(),
    ),
  );
}

class TerraceApp extends ConsumerWidget {
  const TerraceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Terrace',
      debugShowCheckedModeBanner: false,
      theme: TerraceThemeBuilder.light(),
      darkTheme: TerraceThemeBuilder.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
