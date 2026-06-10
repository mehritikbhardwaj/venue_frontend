import 'package:flutter/material.dart';

/// Single source of truth for the app's visual identity.
///
/// "Energetic sporty" direction: a vibrant green/lime brand, gradient headers,
/// large rounded cards with soft shadows, and a punchy amber accent. All design
/// tokens (color, spacing, radius, shadow) live here so screens stay declarative.
class AppTheme {
  // ---- Brand palette ----------------------------------------------------
  static const seed = Color(0xFF16A34A); // emerald-600
  static const brand = Color(0xFF16A34A);
  static const brandBright = Color(0xFF22C55E); // green-500
  static const brandDark = Color(0xFF15803D); // green-700
  static const accent = Color(0xFFF59E0B); // amber-500 — energy pop
  static const danger = Color(0xFFEF4444); // red-500

  // Neutral surfaces — a barely-tinted off-white keeps cards crisp & "lifted".
  static const canvas = Color(0xFFF4F7F4);
  static const card = Colors.white;
  static const ink = Color(0xFF0F1B12); // near-black with a green undertone
  static const inkMuted = Color(0xFF5B6B5F);

  // ---- Gradients --------------------------------------------------------
  /// Primary brand gradient used on hero headers and CTAs.
  static const brandGradient = LinearGradient(
    colors: [brandBright, brandDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle gradient used for sport avatars / accent chips.
  static const limeGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const amberGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---- Shape & spacing tokens ------------------------------------------
  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 32;

  static const double gap = 16;

  /// Soft, diffuse shadow for "floating" cards.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: brandDark.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// Tighter shadow for interactive tiles.
  static List<BoxShadow> get tileShadow => [
        BoxShadow(
          color: brandDark.withValues(alpha: 0.10),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  // ---- ThemeData --------------------------------------------------------
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: card,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      error: danger,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: const TextStyle(color: inkMuted),
        labelStyle: const TextStyle(color: inkMuted, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: brand, fontWeight: FontWeight.w600),
        enabledBorder: _border(scheme.outlineVariant),
        border: _border(scheme.outlineVariant),
        focusedBorder: _border(brand, width: 2),
        errorBorder: _border(danger),
        focusedErrorBorder: _border(danger, width: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brand.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandDark,
          side: const BorderSide(color: brand, width: 1.5),
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandDark,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: const TextStyle(
          color: ink,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(color: inkMuted, fontSize: 15, height: 1.4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: brandDark.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1.5}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );

  static TextTheme _textTheme(TextTheme base) => base.copyWith(
        displaySmall: base.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: ink,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: ink,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: ink,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyMedium: base.bodyMedium?.copyWith(color: inkMuted, height: 1.4),
        labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      );
}
