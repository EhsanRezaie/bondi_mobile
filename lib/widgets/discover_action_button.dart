import 'package:flutter/material.dart';

class DiscoverActionButton extends StatelessWidget {
  final IconData icon;
  final LinearGradient? gradient;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final int? badgeCount;

  const DiscoverActionButton({
    super.key,
    required this.icon,
    this.gradient,
    this.onPressed,
    this.size = 56,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              gradient: backgroundColor == null ? gradient : null,
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: (gradient?.colors.first ?? backgroundColor ?? Colors.black)
                      .withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor ?? Colors.white, size: size * 0.45),
          ),
        ),
        if (badgeCount != null && badgeCount! > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFDC3545),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
