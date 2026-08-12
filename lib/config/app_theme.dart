// lib/config/app_theme.dart
import 'package:flutter/material.dart';

/// Bondi design system — "Warm Orange".
/// All visual tokens live here. Screens reference tokens, never raw values.
class AppTheme {
  // ============ FONT FAMILIES ============

  /// Latin font (en / default).
  static const String fontFamily = 'Inter';
  /// Persian font (fa locale) — Inter has no Persian glyphs.
  static const String fontFamilyFa = 'Vazirmatn';

  /// Returns the typeface for the current locale (en -> Inter, fa -> Vazirmatn).
  static String fontFor(bool isPersian) => isPersian ? fontFamilyFa : fontFamily;

  // ============ BRAND GRADIENT ============

  static const Color primaryGradientStart = Color(0xFFFF6B6B);
  static const Color primaryGradientEnd = Color(0xFFFFA751);

  /// 135° brand gradient — primary CTAs, bottom nav, sent bubbles, hero moments.
  static LinearGradient primaryGradient() {
    return const LinearGradient(
      colors: [primaryGradientStart, primaryGradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ============ ACCENTS ============

  static const Color accentLike = Color(0xFFFF4F81);
  static const Color accentLikeEnd = Color(0xFFFF7A59);
  static const Color accentSuperlike = Color(0xFFFFC93C);
  static const Color accentSuperlikeEnd = Color(0xFFE8A800);
  static const Color accentReject = Color(0xFFF1F1F1);
  static const Color accentRejectIcon = Color(0xFF4A4A4A);
  static const Color accentRejectDark = Color(0xFF322F3A);
  static const Color accentRejectIconDark = Color(0xFFE8E6EC);

  // ============ LIGHT COLORS ============

  static const Color lightBackground = Color(0xFFFFF8F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFFFF6B6B);
  static const Color lightPrimaryLight = Color(0xFFFFA751);
  static const Color lightPrimaryDark = Color(0xFFE5484D);
  static const Color lightSecondary = Color(0xFFF1F1F1);
  static const Color lightText = Color(0xFF1E1E1E);
  static const Color lightTextMuted = Color(0xFF8A8A8A);
  static const Color lightTextLight = Color(0xFFB0B0B0);
  static const Color lightBorder = Color(0xFFF0F0F0);
  static const Color lightError = Color(0xFFE5484D);
  static const Color lightSuccess = Color(0xFF4CAF7D);
  static const Color lightWarning = Color(0xFFFFC93C);
  static const Color lightShadow = Color(0x0A000000); // black @ 4%
  static const Color lightDivider = Color(0xFFF0F0F0);

  // ============ DARK COLORS ============

  static const Color darkBackground = Color(0xFF15131A);
  static const Color darkSurface = Color(0xFF24222C);
  static const Color darkPrimary = Color(0xFFFF6B6B);
  static const Color darkPrimaryLight = Color(0xFFFFA751);
  static const Color darkPrimaryDark = Color(0xFFC93F4C);
  static const Color darkSecondary = Color(0xFF322F3A);
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkTextMuted = Color(0xFF9A98A5);
  static const Color darkTextLight = Color(0xFF6E6A78);
  static const Color darkBorder = Color(0xFF332F3C);
  static const Color darkError = Color(0xFFFF6B6B);
  static const Color darkSuccess = Color(0xFF4CAF7D);
  static const Color darkWarning = Color(0xFFFFC93C);
  static const Color darkShadow = Color(0x1A000000); // black @ 10%
  static const Color darkDivider = Color(0xFF332F3C);

  /// White text/icon on full-bleed photos.
  static const Color textOnPhoto = Color(0xFFFFFFFF);

  // ============ SHAPE TOKENS ============

  /// Bento modules — sharper/geometric (replaces old 24-28px floaty radius).
  static const double radiusModule = 16;
  /// Full-pill buttons, chips, avatars.
  static const double radiusChip = 999;
  /// Text inputs.
  static const double radiusInput = 14;

  // ============ SHADOW TOKENS ============

  /// Minimal module shadow — separation is color-driven, not elevation-driven.
  static BoxShadow shadowModule({bool isDark = false}) {
    return BoxShadow(
      color: (isDark ? darkShadow : lightShadow).withValues(alpha: 0.5),
      blurRadius: 8,
      offset: const Offset(0, 2),
    );
  }

  /// Shadow for buttons floating on full-bleed photos.
  /// Color matches the button's own fill @ 25% opacity.
  static BoxShadow shadowFloatingBtn(Color fill, {double blur = 16}) {
    return BoxShadow(
      color: fill.withValues(alpha: 0.25),
      blurRadius: blur,
      offset: const Offset(0, 6),
    );
  }

  // ============ GRADIENT HELPERS (kept for compatibility) ============

  static LinearGradient rejectGradient({required bool isDark}) {
    return LinearGradient(
      colors: isDark
          ? const [accentRejectDark, Color(0xFF3A3547)]
          : const [Color(0xFFF1F1F1), Color(0xFFE4E4E4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient chatGradient({required bool isDark}) {
    return primaryGradient();
  }

  static LinearGradient likeGradient({required bool isDark}) {
    return const LinearGradient(
      colors: [accentLike, accentLikeEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient superlikeGradient() {
    return const LinearGradient(
      colors: [accentSuperlike, accentSuperlikeEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ============ MODULE (BENTO) FILLS ============

  static Color moduleFillNeutral({required bool isDark}) =>
      isDark ? darkSurface : lightSurface;

  /// Primary/accent tinted module fill — light 10%, dark 18%.
  static Color moduleFillTinted({required bool isDark, Color? accent}) {
    final base = accent ?? lightPrimary;
    return base.withValues(alpha: isDark ? 0.18 : 0.10);
  }

  // ============ TEXT STYLES — "Exaggerated Minimalism" ============

  // --- Latin (en) resolved styles ---
  static TextStyle get heroDisplay => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
      );
  static TextStyle get h1 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
  static TextStyle get h2 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );
  static TextStyle get body => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );
  static TextStyle get bodyBold => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.45,
      );
  static TextStyle get caption => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: Color(0xFF8A8A8A),
      );
  static TextStyle get overline => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: Color(0xFF8A8A8A),
      );
  static TextStyle get button => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  // --- Persian (fa) resolved styles — Vazirmatn, +15% line-height, no tracking ---
  static TextStyle get heroDisplayFa => const TextStyle(
        fontFamily: fontFamilyFa,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.25,
      );
  static TextStyle get h1Fa => const TextStyle(
        fontFamily: fontFamilyFa,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.4,
      );
  static TextStyle get h2Fa => const TextStyle(
        fontFamily: fontFamilyFa,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );
  static TextStyle get bodyFa => const TextStyle(
        fontFamily: fontFamilyFa,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.65,
      );
  static TextStyle get bodyBoldFa => const TextStyle(
        fontFamily: fontFamilyFa,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.65,
      );
  static TextStyle get captionFa => const TextStyle(
        fontFamily: fontFamilyFa,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: Color(0xFF8A8A8A),
      );
  static TextStyle get overlineFa => const TextStyle(
        fontFamily: fontFamilyFa,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8A8A8A),
      );
  static TextStyle get buttonFa => const TextStyle(
        fontFamily: fontFamilyFa,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      );

  // --- Legacy aliases (so existing call sites keep working) ---
  static TextStyle get headlineLarge => h1;
  static TextStyle get headlineMedium => h2;
  static TextStyle get headlineSmall => h2;
  static TextStyle get titleLarge => h1;
  static TextStyle get titleMedium => h2;
  static TextStyle get titleSmall => bodyBold;
  static TextStyle get bodyLarge => body;
  static TextStyle get bodyMedium => body;
  static TextStyle get bodySmall => caption;
  static TextStyle get labelLarge => button;
  static TextStyle get labelMedium => bodyBold;
  static TextStyle get labelSmall => caption;
  static TextStyle get buttonText => button;

  // ============ DECORATIONS ============

  /// Bento module decoration — flat fill, near-flat shadow, radius 16.
  static BoxDecoration moduleDecoration({required bool isDark, Color? fill}) {
    return BoxDecoration(
      color: fill ?? moduleFillNeutral(isDark: isDark),
      borderRadius: BorderRadius.circular(radiusModule),
      boxShadow: [shadowModule(isDark: isDark)],
    );
  }

  /// Legacy card decoration — kept for files not yet migrated.
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: lightSurface,
      borderRadius: BorderRadius.circular(radiusModule),
      boxShadow: [shadowModule()],
    );
  }

  static BoxDecoration get inputDecoration {
    return BoxDecoration(
      color: lightSurface,
      borderRadius: BorderRadius.circular(radiusInput),
      border: Border.all(color: lightBorder, width: 1),
    );
  }

  static BoxDecoration get inputDecorationFocused {
    return BoxDecoration(
      color: lightSurface,
      borderRadius: BorderRadius.circular(radiusInput),
      border: Border.all(color: lightPrimary, width: 1.5),
    );
  }

  static BoxDecoration get inputDecorationError {
    return BoxDecoration(
      color: lightSurface,
      borderRadius: BorderRadius.circular(radiusInput),
      border: Border.all(color: lightError, width: 1),
    );
  }

  // ============ BUTTON STYLES ============

  static ButtonStyle get primaryButton {
    return ElevatedButton.styleFrom(
      backgroundColor: lightPrimary,
      foregroundColor: textOnPhoto,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusChip)),
      ),
      elevation: 0,
      minimumSize: const Size(double.infinity, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: button,
    );
  }

  static ButtonStyle get primaryButtonSmall {
    return ElevatedButton.styleFrom(
      backgroundColor: lightPrimary,
      foregroundColor: textOnPhoto,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusChip)),
      ),
      elevation: 0,
      minimumSize: const Size(160, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: button,
    );
  }

  static ButtonStyle get outlineButton {
    return OutlinedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: lightPrimary,
      side: const BorderSide(color: lightPrimary, width: 1.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusChip)),
      ),
      minimumSize: const Size(double.infinity, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: button,
    );
  }

  /// Gradient-filled primary CTA pill.
  static Widget gradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    bool enabled = true,
    double height = 52,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(radiusChip),
          child: Ink(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              gradient: primaryGradient(),
              borderRadius: BorderRadius.circular(radiusChip),
              boxShadow: [shadowFloatingBtn(primaryGradientStart, blur: 12)],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  // ============ THEME DATA ============

  static ThemeData get lightTheme => _buildTheme(Brightness.light, false, fontFamily);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark, false, fontFamily);

  /// Theme with the family for the active locale (used by MaterialApp).
  static ThemeData themeFor({required Brightness brightness, required bool isPersian}) {
    return _buildTheme(brightness, isPersian, fontFor(isPersian));
  }

  static ThemeData _buildTheme(Brightness brightness, bool isPersian, String family) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurface : lightSurface;
    final primary = isDark ? darkPrimary : lightPrimary;
    final primaryLight = isDark ? darkPrimaryLight : lightPrimaryLight;
    final text = isDark ? darkText : lightText;
    final textMuted = isDark ? darkTextMuted : lightTextMuted;
    final border = isDark ? darkBorder : lightBorder;
    final error = isDark ? darkError : lightError;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: family,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: textOnPhoto,
        secondary: primaryLight,
        onSecondary: textOnPhoto,
        error: error,
        onError: textOnPhoto,
        surface: surface,
        onSurface: text,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? darkDivider : lightDivider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          fontFamily: family,
          fontSize: 15,
          color: textMuted,
        ),
        labelStyle: TextStyle(
          fontFamily: family,
          fontSize: 15,
          color: textMuted,
        ),
        errorStyle: TextStyle(
          fontFamily: family,
          fontSize: 12,
          color: error,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: isDark ? _darkPrimaryButton(family) : primaryButton,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: isDark ? _darkOutlineButton(family) : outlineButton,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: TextTheme(
        displayLarge: isPersian ? h1Fa : h1,
        displayMedium: isPersian ? h1Fa : h1,
        displaySmall: isPersian ? h2Fa : h2,
        headlineLarge: isPersian ? h2Fa : h2,
        headlineMedium: isPersian ? h2Fa : h2,
        headlineSmall: isPersian ? bodyBoldFa : bodyBold,
        bodyLarge: isPersian ? bodyFa : body,
        bodyMedium: isPersian ? bodyFa : body,
        bodySmall: isPersian ? captionFa : caption,
        labelLarge: isPersian ? buttonFa : button,
        labelMedium: isPersian ? bodyBoldFa : bodyBold,
        labelSmall: isPersian ? captionFa : caption,
      ),
    );
  }

  static ButtonStyle _darkPrimaryButton(String family) {
    return ElevatedButton.styleFrom(
      backgroundColor: darkPrimary,
      foregroundColor: textOnPhoto,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusChip)),
      ),
      elevation: 0,
      minimumSize: const Size(double.infinity, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  static ButtonStyle _darkOutlineButton(String family) {
    return OutlinedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: darkText,
      side: BorderSide(color: darkBorder, width: 1.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusChip)),
      ),
      minimumSize: const Size(double.infinity, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ============ EXTENSION FOR EASY ACCESS ============

extension ThemeColors on BuildContext {
  ThemeData get theme => Theme.of(this);

  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get errorColor => Theme.of(this).colorScheme.error;
  Color get onPrimaryColor => Theme.of(this).colorScheme.onPrimary;
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurface;
  Color get onBackgroundColor => Theme.of(this).colorScheme.onSurface;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
