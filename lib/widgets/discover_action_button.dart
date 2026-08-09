import 'package:flutter/material.dart';
import '../utils/responsive.dart';

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
    // Scale the whole button (and its badge) modestly on larger screens.
    final effectiveSize = AppLayout.s(context, size);
    final effectiveIcon = effectiveSize * 0.45;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: effectiveSize,
            height: effectiveSize,
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
                  blurRadius: AppLayout.s(context, 16),
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon,
                color: iconColor ?? Colors.white, size: effectiveIcon),
          ),
        ),
        if (badgeCount != null && badgeCount! > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: BoxConstraints(
                  minWidth: AppLayout.s(context, 20),
                  minHeight: AppLayout.s(context, 20)),
              padding: EdgeInsets.symmetric(horizontal: AppLayout.s(context, 5)),
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: AppLayout.s(context, 10),
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
