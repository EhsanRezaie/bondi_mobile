import 'package:flutter/material.dart';
import '../config/app_theme.dart';

void showActionToast(BuildContext context, String message, {bool isError = false}) {
  final isDark = context.isDarkMode;
  final color = isError
      ? (isDark ? AppTheme.darkError : AppTheme.lightError)
      : (isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess);

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}
