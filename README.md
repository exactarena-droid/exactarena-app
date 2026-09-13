# Terrace — Flutter app

The mobile client for **Terrace**, a sports scores, statistics, news and fan-community product. It talks to
the included Laravel REST API and shares one reskinnable design system with the admin and web dashboard.
For the full stack (backend, admin, web) see the [project README](../README.md).

## Features

- **Live scores, standings, match centre** and team/player pages.
- **Score Challenge** — a free, points-only game of skill: call the final scoreline of upcoming fixtures for
  leaderboard points, with a global board and private mini-leagues. No money in, no money out, no gambling.
- **Sport news** feed with source attribution.
- **Email OTP** sign-up and password reset (no verification links); **delete account** built in.
- **Firebase Cloud Messaging** push notifications and **house ads** for free users (removed for Premium).
- Light/dark theming from shared design tokens; premium purchased on the web (no in-app purchase).

## Tech

Flutter (iOS + Android) · Riverpod · Dio · go_router · google_fonts · Lucide · flutter_secure_storage ·
firebase_core / firebase_messaging. The Sanctum bearer token is kept in OS secure storage (Keychain /
Keystore), never in plain preferences.

## Project structure

```
lib/
├── main.dart            App entry (Firebase init, ProviderScope, router)
├── router.dart          go_router routes + the bottom-nav shell
├── core/                api client, config, providers, result types
├── data/                controllers + repositories (auth, challenge, app data)
├── models/              JSON models
├── features/            screens by feature (scores, play, news, profile, auth, ads, …)
├── theme/               terrace_theme + generated terrace_tokens.dart
└── widgets/             shared UI
```

## Getting started

```bash
flutter pub get
flutter run
```

By default the app points at the hosted demo API. Override the base URL at build/run time:

```bash
flutter run --dart-define=API_BASE=https://your-domain.com/api/v1
```

Requires a current stable Flutter SDK (Dart `>=3.8.0 <4.0.0`, i.e. Flutter 3.32 or newer).

### Push notifications (optional)

Firebase is initialised defensively — the app runs without it. To enable push, run
`flutterfire configure` to generate your own `lib/firebase_options.dart` and native config, then rebuild.

### Reskinning

Colors, type and radii come from `../design/tokens/tokens.json`. Running the backend's `npm run build`
regenerates `lib/theme/terrace_tokens.dart` (and the web/admin tokens) so every surface re-themes together.

## Demo login

Point the app at the live demo API and sign in with `jordan@terrace.test` (free) or `sam@terrace.test`
(premium). Ask your admin for the current demo password, or create an account with email OTP.
