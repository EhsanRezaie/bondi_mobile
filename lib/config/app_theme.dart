// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ============ COLORS ============
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFBF9F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF001F3F);
  static const Color lightPrimaryLight = Color(0xFF1A3A5C);
  static const Color lightPrimaryDark = Color(0xFF000A1A);
  static const Color lightSecondary = Color.fromARGB(255, 224, 229, 231);
  static const Color lightText = Color(0xFF001F3F);
  static const Color lightTextMuted = Color(0xFF707070);
  static const Color lightTextLight = Color(0xFF9E9E9E);
  static const Color lightBorder = Color(0xFFE0E5EB);
  static const Color lightError = Color(0xFFDC3545);
  static const Color lightSuccess = Color(0xFF28A745);
  static const Color lightWarning = Color(0xFFFFC107);
  static const Color lightShadow = Color(0x14001F3F);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFF4A7CF7);
  static const Color darkPrimaryLight = Color(0xFF6B96F9);
  static const Color darkPrimaryDark = Color(0xFF1A3A7A);
  static const Color darkSecondary = Color(0xFF2D2D2D);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextMuted = Color(0xFF9E9E9E);
  static const Color darkTextLight = Color(0xFF6B6B6B);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkSuccess = Color(0xFF81C784);
  static const Color darkWarning = Color(0xFFFFD54F);
  static const Color darkShadow = Color(0x4A000000);

  // ============ GRADIENT DEFINITIONS (Discover) ============

  static LinearGradient rejectGradient({required bool isDark}) {
    final base = isDark ? darkError : lightError;
    return LinearGradient(
      colors: [base, base.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient chatGradient({required bool isDark}) {
    final base = isDark ? darkPrimary : lightPrimary;
    return LinearGradient(
      colors: [base, base.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient likeGradient({required bool isDark}) {
    final base = isDark ? darkPrimary : lightPrimary;
    return LinearGradient(
      colors: [base, base.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ============ TEXT STYLES ============
  
  static const String fontFamily = 'Inter';
  
  static TextStyle get headlineLarge {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
    );
  }
  
  static TextStyle get headlineMedium {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.28,
    );
  }
  
  static TextStyle get headlineSmall {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.24,
    );
  }
  
  static TextStyle get titleLarge {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );
  }
  
  static TextStyle get titleMedium {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle get titleSmall {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle get bodyLarge {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    );
  }
  
  static TextStyle get bodyMedium {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    );
  }
  
  static TextStyle get bodySmall {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
  }
  
  static TextStyle get labelLarge {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle get labelMedium {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
  }
  
  static TextStyle get labelSmall {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
  }
  
  static TextStyle get buttonText {
    return const TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }

  // ============ DECORATIONS ============
  
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: lightSurface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: lightShadow,
          offset: Offset(0, 8),
          blurRadius: 24,
        ),
      ],
    );
  }
  
  static BoxDecoration get inputDecoration {
    return BoxDecoration(
      color: lightBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: lightBorder,
        width: 1,
      ),
    );
  }
  
  static BoxDecoration get inputDecorationFocused {
    return BoxDecoration(
      color: lightBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: lightPrimary,
        width: 2,
      ),
    );
  }
  
  static BoxDecoration get inputDecorationError {
    return BoxDecoration(
      color: lightBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: lightError,
        width: 1,
      ),
    );
  }

  // ============ BUTTON STYLES ============
  
  static ButtonStyle get primaryButton {
    return ElevatedButton.styleFrom(
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      minimumSize: const Size(double.infinity, 56),
      textStyle: buttonText,
    );
  }
  
  static ButtonStyle get primaryButtonSmall {
    return ElevatedButton.styleFrom(
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      minimumSize: const Size(200, 50),
      textStyle: buttonText,
    );
  }
  
  static ButtonStyle get outlineButton {
    return OutlinedButton.styleFrom(
      backgroundColor: lightSecondary,
      foregroundColor: lightPrimary,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      minimumSize: const Size(double.infinity, 56),
      textStyle: buttonText,
    );
  }

  // ============ THEME DATA ============
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightPrimaryLight,
        surface: lightSurface,
        error: lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightText,
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: lightBackground,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightPrimary,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightError, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: lightTextMuted,
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: lightTextMuted,
        ),
        errorStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: lightError,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButton,
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: outlineButton,
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.28,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkPrimaryLight,
        surface: darkSurface,
        error: darkError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkText,
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: darkBackground,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkError, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: darkTextMuted,
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: darkTextMuted,
        ),
        errorStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: darkError,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          textStyle: buttonText,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: darkSecondary,
          foregroundColor: darkText,
          side: const BorderSide(color: darkBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(double.infinity, 56),
          textStyle: buttonText,
        ),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.28,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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