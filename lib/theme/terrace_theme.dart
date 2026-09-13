// Terrace theme — builds light + dark ThemeData from the generated tokens.
// Widgets read semantic colors via context.terrace.<role>; never hard-code hex.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'terrace_tokens.dart';

/// ThemeExtension exposing Terrace's semantic palette + a couple of brand fonts.
@immutable
class TerraceTheme extends ThemeExtension<TerraceTheme> {
  final TerracePalette palette;
  const TerraceTheme(this.palette);

  // Convenience getters so widgets read context.terrace.brand etc.
  Color get bg => palette.bg;
  Color get surface => palette.surface;
  Color get surfaceMuted => palette.surfaceMuted;
  Color get surfaceInset => palette.surfaceInset;
  Color get border => palette.border;
  Color get borderStrong => palette.borderStrong;
  Color get textPrimary => palette.textPrimary;
  Color get textSecondary => palette.textSecondary;
  Color get textMuted => palette.textMuted;
  Color get textOnBrand => palette.textOnBrand;
  Color get brand => palette.brand;
  Color get brandHover => palette.brandHover;
  Color get brandSubtle => palette.brandSubtle;
  Color get accent => palette.accent;
  Color get live => palette.live;
  Color get success => palette.success;
  Color get warning => palette.warning;
  Color get danger => palette.danger;
  Color get info => palette.info;
  Brightness get brightness => palette.brightness;

  /// Soft, warm-tinted, layered elevation used sparingly (menus, sheets, FAB).
  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF1A1813).withValues(alpha: brightness == Brightness.dark ? 0.40 : 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFF1A1813).withValues(alpha: brightness == Brightness.dark ? 0.30 : 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  @override
  TerraceTheme copyWith({TerracePalette? palette}) =>
      TerraceTheme(palette ?? this.palette);

  @override
  TerraceTheme lerp(ThemeExtension<TerraceTheme>? other, double t) {
    // Palette is discrete per brightness; no need to interpolate roles.
    return this;
  }
}

/// Read the Terrace palette from any BuildContext.
extension TerraceThemeX on BuildContext {
  TerraceTheme get terrace =>
      Theme.of(this).extension<TerraceTheme>() ?? TerraceTheme(TerracePalette.light());
}

abstract final class TerraceThemeBuilder {
  static ThemeData light() => _build(TerracePalette.light());
  static ThemeData dark() => _build(TerracePalette.dark());

  static ThemeData _build(TerracePalette p) {
    final isDark = p.brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.brand,
      onPrimary: p.textOnBrand,
      secondary: p.accent,
      onSecondary: isDark ? TerraceColors.stone950 : TerraceColors.stone50,
      error: p.danger,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.surfaceMuted,
      outline: p.border,
      outlineVariant: p.borderStrong,
    );

    // Plus Jakarta Sans is the UI/body family. Bricolage = display/scores.
    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    TextStyle display(double size, {double weight = 700, double tracking = -0.5, double? height}) =>
        GoogleFonts.bricolageGrotesque(
          fontSize: size,
          fontWeight: FontWeight.values[(weight ~/ 100) - 1],
          letterSpacing: tracking,
          height: height,
          color: p.textPrimary,
        );

    final textTheme = baseText
        .copyWith(
          displayLarge: display(40, weight: 700, height: 1.04),
          displayMedium: display(34, weight: 700, height: 1.06),
          displaySmall: display(28, weight: 700, height: 1.08),
          headlineLarge: display(26, weight: 700, height: 1.1),
          headlineMedium: display(22, weight: 700, tracking: -0.3, height: 1.12),
          headlineSmall: display(19, weight: 600, tracking: -0.2, height: 1.16),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 17, fontWeight: FontWeight.w700, color: p.textPrimary, letterSpacing: -0.2),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w600, color: p.textPrimary),
          titleSmall: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: p.textSecondary),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w400, color: p.textPrimary, height: 1.45),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w400, color: p.textSecondary, height: 1.45),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12.5, fontWeight: FontWeight.w400, color: p.textMuted, height: 1.4),
          labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary, letterSpacing: 0.1),
          labelMedium: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w600, color: p.textSecondary, letterSpacing: 0.2),
          labelSmall: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w700, color: p.textMuted, letterSpacing: 0.8),
        )
        .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      extensions: [TerraceTheme(p)],
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.textSecondary, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          fontSize: 22, fontWeight: FontWeight.w700, color: p.textPrimary, letterSpacing: -0.4),
        iconTheme: IconThemeData(color: p.textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TerraceRadii.xl),
          side: BorderSide(color: p.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceMuted,
        selectedColor: p.brand,
        side: BorderSide(color: p.border),
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(color: p.textOnBrand),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TerraceRadii.full)),
        padding: const EdgeInsets.symmetric(horizontal: TerraceSpace.s3, vertical: TerraceSpace.s2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.textOnBrand,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TerraceRadii.lg)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.textOnBrand,
          elevation: 0,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TerraceRadii.lg)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 52),
          side: BorderSide(color: p.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TerraceRadii.lg)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brand,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: textTheme.bodyMedium!.copyWith(color: p.textMuted),
        labelStyle: textTheme.labelMedium,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: TerraceSpace.s4, vertical: TerraceSpace.s4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TerraceRadii.lg),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TerraceRadii.lg),
          borderSide: BorderSide(color: p.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TerraceRadii.lg),
          borderSide: BorderSide(color: p.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TerraceRadii.lg),
          borderSide: BorderSide(color: p.danger, width: 1.6),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.brand,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall!.copyWith(letterSpacing: 0.2),
        unselectedLabelStyle: textTheme.labelSmall!.copyWith(letterSpacing: 0.2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.brandSubtle,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall!.copyWith(
            color: selected ? p.brand : p.textMuted,
            letterSpacing: 0.2,
            fontWeight: FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? p.brand : p.textMuted, size: 22);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.brand,
        unselectedLabelColor: p.textMuted,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: p.brand,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.textPrimary,
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: p.bg),
        actionTextColor: p.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TerraceRadii.md)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TerraceRadii.xl2)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brand,
        linearTrackColor: p.surfaceInset,
        circularTrackColor: p.surfaceInset,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.textOnBrand : p.surface),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.brand : p.surfaceInset),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.brand : p.borderStrong),
      ),
    );
  }
}

/// Bricolage-based score / numeral style helpers (tabular figures for alignment).
abstract final class TerraceTextStyles {
  static const FontFeature _tabular = FontFeature.tabularFigures();

  static TextStyle scoreboard(BuildContext context, {double size = 34}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1,
        color: context.terrace.textPrimary,
        fontFeatures: const [_tabular],
      );

  static TextStyle mono(BuildContext context,
          {double size = 13, FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? context.terrace.textSecondary,
        fontFeatures: const [_tabular],
        letterSpacing: 0,
      );

  static TextStyle tableNum(BuildContext context,
          {double size = 13, FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? context.terrace.textPrimary,
        fontFeatures: const [_tabular],
      );

  static TextStyle serifBody(BuildContext context, {double size = 18}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: context.terrace.textPrimary,
      );

  static TextStyle serifLead(BuildContext context, {double size = 21}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: context.terrace.textPrimary,
      );

  static TextStyle overline(BuildContext context, {Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: color ?? context.terrace.textMuted,
      );
}
