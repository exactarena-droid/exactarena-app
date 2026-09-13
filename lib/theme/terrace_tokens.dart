// AUTO-GENERATED from design/tokens/tokens.json — DO NOT EDIT BY HAND.
// Run `node design/tokens/build.mjs` after editing tokens.json.
import 'package:flutter/widgets.dart';

/// Raw palette. Prefer [TerracePalette] semantic roles in widgets.
abstract final class TerraceColors {
  static const Color stone50 = Color(0xFFFAF9F6);
  static const Color stone100 = Color(0xFFF4F2EA);
  static const Color stone200 = Color(0xFFE7E4D8);
  static const Color stone300 = Color(0xFFD5D0C0);
  static const Color stone400 = Color(0xFFADA690);
  static const Color stone500 = Color(0xFF837C66);
  static const Color stone600 = Color(0xFF615B49);
  static const Color stone700 = Color(0xFF46422F);
  static const Color stone800 = Color(0xFF2B2820);
  static const Color stone900 = Color(0xFF1A1813);
  static const Color stone950 = Color(0xFF0F0E0A);
  static const Color pitch50 = Color(0xFFECF8F0);
  static const Color pitch100 = Color(0xFFD0EFDB);
  static const Color pitch200 = Color(0xFFA2DFBA);
  static const Color pitch300 = Color(0xFF6BCB93);
  static const Color pitch400 = Color(0xFF3BAF6E);
  static const Color pitch500 = Color(0xFF1F9156);
  static const Color pitch600 = Color(0xFF147447);
  static const Color pitch700 = Color(0xFF125C3A);
  static const Color pitch800 = Color(0xFF11492F);
  static const Color pitch900 = Color(0xFF0E3B28);
  static const Color pitch950 = Color(0xFF06231A);
  static const Color floodlight50 = Color(0xFFFEF7EC);
  static const Color floodlight100 = Color(0xFFFBE9C7);
  static const Color floodlight200 = Color(0xFFF7D28C);
  static const Color floodlight300 = Color(0xFFF3B954);
  static const Color floodlight400 = Color(0xFFF0A431);
  static const Color floodlight500 = Color(0xFFE08A1E);
  static const Color floodlight600 = Color(0xFFBC6A15);
  static const Color floodlight700 = Color(0xFF964F16);
  static const Color floodlight800 = Color(0xFF7B4018);
  static const Color floodlight900 = Color(0xFF683717);
  static const Color live400 = Color(0xFFF2585B);
  static const Color live500 = Color(0xFFE5484D);
  static const Color live600 = Color(0xFFD13438);
  static const Color live700 = Color(0xFFB42C30);
  static const Color info400 = Color(0xFF5B8DD4);
  static const Color info500 = Color(0xFF3B6FB0);
  static const Color info600 = Color(0xFF2E588C);
  static const Color rose400 = Color(0xFFE06B7E);
  static const Color rose500 = Color(0xFFC84A60);
  static const Color rose600 = Color(0xFFA6394C);
}

/// Semantic colour roles, resolved per brightness. Read these in widgets:
/// `context.terrace.brand`, `context.terrace.surface`, etc.
@immutable
class TerracePalette {
  final Color bg;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceInset;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnBrand;
  final Color brand;
  final Color brandHover;
  final Color brandSubtle;
  final Color accent;
  final Color live;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Brightness brightness;
  const TerracePalette({
    required this.bg,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceInset,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnBrand,
    required this.brand,
    required this.brandHover,
    required this.brandSubtle,
    required this.accent,
    required this.live,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.brightness,
  });

  factory TerracePalette.light() => TerracePalette(
    bg: const Color(0xFFFAF9F6),
    surface: const Color(0xFFFFFFFF),
    surfaceMuted: const Color(0xFFF4F2EA),
    surfaceInset: const Color(0xFFE7E4D8),
    border: const Color(0xFFE7E4D8),
    borderStrong: const Color(0xFFD5D0C0),
    textPrimary: const Color(0xFF1A1813),
    textSecondary: const Color(0xFF615B49),
    textMuted: const Color(0xFF837C66),
    textOnBrand: const Color(0xFFFFFFFF),
    brand: const Color(0xFF147447),
    brandHover: const Color(0xFF125C3A),
    brandSubtle: const Color(0xFFECF8F0),
    accent: const Color(0xFFE08A1E),
    live: const Color(0xFFE5484D),
    success: const Color(0xFF147447),
    warning: const Color(0xFFE08A1E),
    danger: const Color(0xFFC84A60),
    info: const Color(0xFF3B6FB0),
    brightness: Brightness.light,
  );

  factory TerracePalette.dark() => TerracePalette(
    bg: const Color(0xFF0F0E0A),
    surface: const Color(0xFF16150F),
    surfaceMuted: const Color(0xFF1A1813),
    surfaceInset: const Color(0xFF2B2820),
    border: const Color(0xFF2B2820),
    borderStrong: const Color(0xFF3A362A),
    textPrimary: const Color(0xFFFAF9F6),
    textSecondary: const Color(0xFFD5D0C0),
    textMuted: const Color(0xFFADA690),
    textOnBrand: const Color(0xFF06231A),
    brand: const Color(0xFF3BAF6E),
    brandHover: const Color(0xFF6BCB93),
    brandSubtle: const Color(0xFF10271D),
    accent: const Color(0xFFF0A431),
    live: const Color(0xFFF2585B),
    success: const Color(0xFF3BAF6E),
    warning: const Color(0xFFF0A431),
    danger: const Color(0xFFE06B7E),
    info: const Color(0xFF5B8DD4),
    brightness: Brightness.dark,
  );

}

/// Font families (added to pubspec via google_fonts).
abstract final class TerraceFonts {
  static const String display = 'Bricolage Grotesque';
  static const String sans = 'Plus Jakarta Sans';
  static const String serif = 'Fraunces';
  static const String mono = 'IBM Plex Mono';
}

/// Corner radii.
abstract final class TerraceRadii {
  static const double none = 0;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xl2 = 28;
  static const double xl3 = 40;
  static const double full = 999;
}

/// 4px spacing grid.
abstract final class TerraceSpace {
  static const double s0 = 0;
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 28;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
  static const double s20 = 80;
  static const double s24 = 96;
  static const double s32 = 128;
}
