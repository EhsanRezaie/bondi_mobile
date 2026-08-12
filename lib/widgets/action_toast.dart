import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../utils/responsive.dart';

OverlayEntry? _currentEntry;

void showActionToast(BuildContext context, String message, {bool isError = false}) {
  final isDark = context.isDarkMode;
  final color = isError
      ? (isDark ? AppTheme.darkError : AppTheme.lightError)
      : (isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess);

  final overlay = Navigator.of(context, rootNavigator: false).overlay;
  if (overlay == null) return;

  removeActionToast();

  final entry = OverlayEntry(
    builder: (context) => _ActionToast(
      message: message,
      color: color,
    ),
  );

  _currentEntry = entry;
  overlay.insert(entry);
}

void removeActionToast() {
  _currentEntry?.remove();
  _currentEntry = null;
}

class _ActionToast extends StatefulWidget {
  final String message;
  final Color color;

  const _ActionToast({
    required this.message,
    required this.color,
  });

  @override
  State<_ActionToast> createState() => _ActionToastState();
}

class _ActionToastState extends State<_ActionToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          removeActionToast();
        });
      }
    });
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isError =
        widget.color == (isDark ? AppTheme.darkError : AppTheme.lightError);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final value = _progress.value;
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -(1 - value) * 40),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isError
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: Colors.white,
                            size: AppLayout.s(context, 16),
                          ),
                          SizedBox(width: AppLayout.s(context, 6)),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: AppLayout.s(context, 260),
                            ),
                            child: Text(
                              widget.message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
