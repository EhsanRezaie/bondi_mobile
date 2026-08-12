import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../utils/responsive.dart';

class DiscoverActionButton extends StatefulWidget {
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
  State<DiscoverActionButton> createState() => _DiscoverActionButtonState();
}

class _DiscoverActionButtonState extends State<DiscoverActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Scale the whole button (and its badge) modestly on larger screens.
    final effectiveSize = AppLayout.s(context, widget.size);
    final effectiveIcon = effectiveSize * 0.45;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final font = AppTheme.fontFor(isPersian);
    return AnimatedScale(
      scale: _pressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 90),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTapDown: widget.onPressed == null
                ? null
                : (_) => setState(() => _pressed = true),
            onTapUp: widget.onPressed == null
                ? null
                : (_) => setState(() => _pressed = false),
            onTapCancel: widget.onPressed == null
                ? null
                : () => setState(() => _pressed = false),
            onTap: widget.onPressed,
            child: Container(
              width: effectiveSize,
              height: effectiveSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.backgroundColor,
                gradient: widget.backgroundColor == null
                    ? widget.gradient
                    : null,
                border: widget.borderColor != null
                    ? Border.all(color: widget.borderColor!, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.gradient?.colors.first ??
                                widget.backgroundColor ??
                                Colors.black)
                            .withValues(alpha: 0.35),
                    blurRadius: AppLayout.s(context, 16),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor ?? Colors.white,
                size: effectiveIcon,
              ),
            ),
          ),
          if (widget.badgeCount != null && widget.badgeCount! > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: AppLayout.s(context, 20),
                  minHeight: AppLayout.s(context, 20),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.s(context, 5),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkError
                      : AppTheme.lightError,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${widget.badgeCount}',
                    style: TextStyle(
                      fontFamily: font,
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
      ),
    );
  }
}
