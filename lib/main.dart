import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Автоматично генерираният от Flutter локализационен пакет
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 

import 'core/providers.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'theme/terrace_theme.dart';

// Професионален Riverpod доставчик, който управлява и помни ръчно избрания език през бутона
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(Locale(_prefs.getString('selected_language') ?? 'en')) {
    // Проверяваме дали има записан избор на потребителя в паметта на телефона, ако ли не - по подразбиране е English ('en')
  }

  // Тази функция ще се извиква директно от бутона в менюто на приложението за ръчна смяна
  void changeLanguage(String languageCode) {
    if (languageCode == 'en' || languageCode == 'ar') {
      _prefs.setString('selected_language', languageCode);
      state = Locale(languageCode);
    }
  }
}

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
    // Следим в реално време кой език е избран от бутона в приложението
    final currentLocale = ref.watch(localeProvider); 

    return MaterialApp.router(
      title: 'Terrace',
      debugShowCheckedModeBanner: false,
      theme: TerraceThemeBuilder.light(),
      darkTheme: TerraceThemeBuilder.dark(),
      themeMode: themeMode,
      routerConfig: router,
      
      // ─── ВКЛЮЧВАНЕ НА ЕЗИКОВАТА СИСТЕМА И ПОДДРЪЖКАТА НА АРАБСКИ (RTL) ───
      locale: currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // ───────────────────────────────────────────────────────────────────
    );
  }
}
