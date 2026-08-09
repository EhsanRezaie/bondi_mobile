import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/widgets/shimmer_avatar.dart';

class UserCard extends StatefulWidget {
  final DiscoverProfile profile;
  final Map<String, String> interestIcons;
  final double scale;
  final bool isTop;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final void Function(UserCardState)? onCardReady;

  const UserCard({
    super.key,
    required this.profile,
    this.interestIcons = const {},
    this.scale = 1.0,
    this.isTop = false,
    this.onTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onCardReady,
  });

  @override
  State<UserCard> createState() => UserCardState();
}

class UserCardState extends State<UserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _dx = 0;
  double _dy = 0;
  double _rotation = 0;
  bool _isDismissed = false;
  String? _swipeLabel;

  // Animation state tracking
  Completer<void>? _currentAnimationCompleter;
  bool _isAnimatingOut = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Notify parent that this card is ready for programmatic control
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onCardReady?.call(this);
      }
    });
  }

  @override
  void dispose() {
    _currentAnimationCompleter?.complete();
    _currentAnimationCompleter = null;
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.isTop) return;
    setState(() {
      _dx += d.delta.dx;
      _dy += d.delta.dy;
      _rotation = (_dx / 500).clamp(-0.3, 0.3);
      if (_dx > 40) {
        _swipeLabel = 'LIKE';
      } else if (_dx < -40) {
        _swipeLabel = 'NOPE';
      } else {
        _swipeLabel = null;
      }
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (!widget.isTop) return;
    final threshold = MediaQuery.of(context).size.width * 0.35;
    final velocity = d.velocity.pixelsPerSecond.dx;

    if (_dx.abs() > threshold || velocity.abs() > 800) {
      final direction = _dx > 0 || velocity > 0 ? 1 : -1;
      _animateDismiss(direction);
    } else {
      _animateSnapBack();
    }
  }

  void _animateDismiss(int direction, {bool fireCallbacks = true}) {
    _isDismissed = true;
    _isAnimatingOut = true;
    _controller.reset();

    final startX = _dx;
    final startY = _dy;
    final startR = _rotation;
    final endX = direction * 600.0;
    final endY = _dy + 100.0;
    final endR = direction * 0.3;

    void listener() {
      final t = Curves.easeIn.transform(_controller.value);
      setState(() {
        _dx = startX + (endX - startX) * t;
        _dy = startY + (endY - startY) * t;
        _rotation = startR + (endR - startR) * t;
      });
    }

    _controller.addListener(listener);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.removeListener(listener);
        _isAnimatingOut = false;
        if (fireCallbacks) {
          if (direction > 0) {
            widget.onSwipeRight?.call();
          } else {
            widget.onSwipeLeft?.call();
          }
        }
      }
    });

    _controller.forward();
  }

  void _animateSnapBack() {
    _controller.reset();
    setState(() { _swipeLabel = null; });
    final startX = _dx;
    final startY = _dy;
    final startR = _rotation;

    void listener() {
      final t = Curves.elasticOut.transform(_controller.value);
      setState(() {
        _dx = startX * (1 - t);
        _dy = startY * (1 - t);
        _rotation = startR * (1 - t);
      });
    }

    _controller.addListener(listener);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.removeListener(listener);
        _isDismissed = false;
      }
    });

    _controller.forward();
  }

  Future<void> swipeOut(int direction) {
    // If already animating out, return existing future
    if (_isAnimatingOut && _currentAnimationCompleter != null) {
      return _currentAnimationCompleter!.future;
    }

    _currentAnimationCompleter = Completer<void>();
    _isAnimatingOut = true;
    _isDismissed = true;

    setState(() {
      _swipeLabel = direction > 0 ? 'LIKE' : 'NOPE';
    });
    _controller.reset();

    final startX = _dx;
    final startY = _dy;
    final startR = _rotation;
    final endX = direction * 600.0;
    final endY = _dy + 100.0;
    final endR = direction * 0.3;

    void listener() {
      final t = Curves.easeIn.transform(_controller.value);
      setState(() {
        _dx = startX + (endX - startX) * t;
        _dy = startY + (endY - startY) * t;
        _rotation = startR + (endR - startR) * t;
      });
    }

    _controller.addListener(listener);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.removeListener(listener);
        _isAnimatingOut = false;
        _currentAnimationCompleter?.complete();
        _currentAnimationCompleter = null;
      }
    });

    _controller.forward();
    return _currentAnimationCompleter!.future;
  }

  Future<void> snapBack() {
    // If currently animating out, stop it and snap back
    _controller.stop();
    _controller.reset();
    _isAnimatingOut = false;
    _currentAnimationCompleter?.complete(); // Complete any pending swipeOut
    _currentAnimationCompleter = null;

    final completer = Completer<void>();
    setState(() { _swipeLabel = null; });
    final startX = _dx;
    final startY = _dy;
    final startR = _rotation;

    void listener() {
      final t = Curves.elasticOut.transform(_controller.value);
      setState(() {
        _dx = startX * (1 - t);
        _dy = startY * (1 - t);
        _rotation = startR * (1 - t);
      });
    }

    _controller.addListener(listener);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.removeListener(listener);
        _isDismissed = false;
        completer.complete();
      }
    });

    _controller.forward();
    return completer.future;
  }

  void _onTapCard() {
    if (_isDismissed) return;
    widget.onTap?.call();
  }

  double _getOpacity() {
    if (!widget.isTop) return 1.0;
    final dist = _dx.abs() / 300;
    return (1.0 - dist.clamp(0.0, 0.5));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    final card = Transform.translate(
      offset: Offset(_dx, _dy),
      child: Transform.rotate(
        angle: _rotation * math.pi / 180,
        child: Opacity(
          opacity: _getOpacity(),
          child: _buildCardContent(context, isDark, primaryColor),
        ),
      ),
    );

    return Transform.scale(
      scale: widget.scale,
      child: widget.isTop
          ? GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: card,
            )
          : card,
    );
  }

  Widget _buildCardContent(
      BuildContext context, bool isDark, Color primaryColor) {
    return GestureDetector(
      onTap: _onTapCard,
      child: _buildCardFront(context, isDark, primaryColor),
    );
  }

  Widget _buildCardFront(
      BuildContext context, bool isDark, Color primaryColor) {
    final profile = widget.profile;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppTheme.darkShadow
                : AppTheme.lightShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (profile.displayPhotoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: profile.displayPhotoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerAvatar(),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
                  child: Icon(Icons.person, size: 64,
                      color: isDark ? AppTheme.darkTextMuted : Colors.grey),
                ),
              )
            else
              Container(
                color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
                child: Icon(Icons.person, size: 64,
                    color: isDark ? AppTheme.darkTextMuted : Colors.grey),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
            if (_swipeLabel != null)
              Positioned(
                top: AppLayout.s(context, 40),
                left: _swipeLabel == 'LIKE' ? 24 : null,
                right: _swipeLabel == 'NOPE' ? 24 : null,
                child: Transform.rotate(
                  angle: _swipeLabel == 'LIKE' ? -0.2 : 0.2,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.s(context, 16),
                        vertical: AppLayout.s(context, 8)),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _swipeLabel == 'LIKE'
                            ? (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary)
                            : (isDark ? AppTheme.darkError : AppTheme.lightError),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(AppLayout.s(context, 8)),
                    ),
                    child: Text(
                      _swipeLabel!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: AppLayout.s(context, 32),
                        fontWeight: FontWeight.w900,
                        color: _swipeLabel == 'LIKE'
                            ? (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary)
                            : (isDark ? AppTheme.darkError : AppTheme.lightError),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: AppLayout.s(context, 12),
              right: AppLayout.s(context, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profile.isPremium)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppLayout.s(context, 8),
                          vertical: AppLayout.s(context, 4)),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkError : AppTheme.lightError,
                        borderRadius: BorderRadius.circular(AppLayout.s(context, 12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium,
                              size: AppLayout.s(context, 12), color: Colors.white),
                          SizedBox(width: AppLayout.s(context, 3)),
                          Text('Premium',
                              style: TextStyle(
                                  fontSize: AppLayout.s(context, 10),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  if (profile.isVerified) ...[
                    SizedBox(width: AppLayout.s(context, 6)),
                    Container(
                      padding: EdgeInsets.all(AppLayout.s(context, 5)),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified,
                          size: AppLayout.s(context, 14), color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${profile.age}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        profile.gender == 'male'
                            ? Icons.male
                            : Icons.female,
                        size: 18,
                        color: profile.gender == 'male'
                            ? (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary)
                            : (isDark ? AppTheme.darkError : AppTheme.lightError),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (profile.distanceKm != null)
                    Row(
                      children: [
                        Icon(Icons.near_me, size: 13,
                            color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.distanceKm!.round()} km away',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  if (profile.locationDisplay.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 14,
                              color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              profile.locationDisplay,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: AppLayout.s(context, 12),
              left: AppLayout.s(context, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profile.isOnline)
                    Container(
                      width: AppLayout.s(context, 12),
                      height: AppLayout.s(context, 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (profile.isOnline) SizedBox(width: AppLayout.s(context, 6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.s(context, 8),
                        vertical: AppLayout.s(context, 4)),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppLayout.s(context, 10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app,
                            size: AppLayout.s(context, 12), color: Colors.white70),
                        SizedBox(width: AppLayout.s(context, 4)),
                        Text('Tap for more',
                            style: TextStyle(
                                fontSize: AppLayout.s(context, 10),
                                color: Colors.white70,
                                fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
