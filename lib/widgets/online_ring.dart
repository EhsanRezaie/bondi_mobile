import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';

class OnlineRing extends StatelessWidget {
  final bool isOnline;
  final double size;
  final double borderWidth;

  const OnlineRing({
    super.key,
    required this.isOnline,
    this.size = 12,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = isOnline
        ? (isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess)
        : Colors.white.withValues(alpha: 0.75);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: borderWidth),
      ),
    );
  }
}
