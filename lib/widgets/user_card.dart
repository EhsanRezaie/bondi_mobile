import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/utils/cached_image.dart';
import 'package:dating_app/widgets/online_ring.dart';

class UserCard extends StatefulWidget {
  final DiscoverProfile profile;
  final Map<String, String> interestIcons;
  final double scale;
  final bool isTop;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final void Function(UserCardState)? onCardReady;
  final void Function(bool isRight)? onSwipeStarted;

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
    this.onSwipeStarted,
  });

  @override
  State<UserCard> createState() => UserCardState();
}

class UserCardState extends State<UserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// Notifies the [AnimatedBuilder] when a drag moves the card, so only the
  /// transform wrapper rebuilds per pan frame — not the whole card subtree.
  final ValueNotifier<int> _dragNotifier = ValueNotifier<int>(0);
  late final Listenable _transformListenable;

  double _dx = 0;
  double _rotation = 0;

  /// Max card tilt (radians) reached at a full-screen-width drag.
  static const double _maxRotation = 20.0 * math.pi / 180;

  bool _isDismissed = false;
  String? _swipeLabel;

  // Animation state tracking
  Completer<void>? _currentAnimationCompleter;
  bool _isAnimatingOut = false;

  // Controller-driven transform animation (no per-frame setState).
  bool _animatingTransform = false;
  double _startX = 0, _startR = 0;
  double _endX = 0, _endR = 0;
  Curve _animCurve = Curves.easeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _transformListenable = Listenable.merge([_controller, _dragNotifier]);
    // Notify parent that this card is ready for programmatic control
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onCardReady?.call(this);
      }
    });
  }

  @override
  void didUpdateWidget(UserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When this card is promoted from the back of the deck to the top, the
    // parent must point its programmatic controls at it (initState won't run
    // again because the State survives the widget update).
    if (widget.isTop && !oldWidget.isTop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onCardReady?.call(this);
        }
      });
    }
  }

  @override
  void dispose() {
    _currentAnimationCompleter?.complete();
    _currentAnimationCompleter = null;
    _dragNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.isTop || _isDismissed || _isAnimatingOut) return;
    
    // Only horizontal drag affects the card - vertical is ignored for pivot rotation
    _dx += d.delta.dx;
    
    // Pivot-based rotation around bottom-center
    // Max rotation: 20° at full screen width drag
    final screenWidth = MediaQuery.of(context).size.width;
    _rotation = (_dx / screenWidth * _maxRotation).clamp(-_maxRotation, _maxRotation);
    
    final label = _dx > 40 ? 'LIKE' : (_dx < -40 ? 'NOPE' : null);
    if (label != _swipeLabel) {
      setState(() {
        _swipeLabel = label;
      });
    }
    _dragNotifier.value++;
  }

  void _onPanEnd(DragEndDetails d) {
    if (!widget.isTop || _isDismissed || _isAnimatingOut) return;
    final threshold = MediaQuery.of(context).size.width * 0.35;
    final velocity = d.velocity.pixelsPerSecond.dx;

    if (_dx.abs() > threshold || velocity.abs() > 800) {
      final direction = _dx > 0 || velocity > 0 ? 1 : -1;
      widget.onSwipeStarted?.call(direction > 0);
      _animateDismiss(direction);
    } else {
      _animateSnapBack();
    }
  }

  void _animateDismiss(int direction, {bool fireCallbacks = true}) {
    _isDismissed = true;
    _isAnimatingOut = true;
    _controller.reset();

    _startX = _dx;
    _startR = _rotation;
    _endX = direction * 600.0;
    _endR = direction * _maxRotation;
    _animCurve = Curves.easeOut;
    _animatingTransform = true;

    void onDone(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _controller.removeStatusListener(onDone);
        _animatingTransform = false;
        _isAnimatingOut = false;
        _dx = _endX;
        _rotation = _endR;
        if (fireCallbacks) {
          if (direction > 0) {
            widget.onSwipeRight?.call();
          } else {
            widget.onSwipeLeft?.call();
          }
        }
      }
    }

    _controller.addStatusListener(onDone);
    _controller.forward();
  }

  void _animateSnapBack() {
    _controller.reset();
    setState(() {
      _swipeLabel = null;
    });

    _startX = _dx;
    _startR = _rotation;
    _endX = 0;
    _endR = 0;
    _animCurve = Curves.elasticOut;
    _animatingTransform = true;

    void onDone(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _controller.removeStatusListener(onDone);
        _animatingTransform = false;
        _isDismissed = false;
        _dx = 0;
        _rotation = 0;
        _dragNotifier.value++;
      }
    }

    _controller.addStatusListener(onDone);
    _controller.forward();
  }

  Future<void> swipeOut(int direction) {
    if (!mounted) return Future.value();
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

    _startX = _dx;
    _startR = _rotation;
    _endX = direction * 600.0;
    _endR = direction * _maxRotation;
    _animCurve = Curves.easeOut;
    _animatingTransform = true;

    void onDone(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _controller.removeStatusListener(onDone);
        _animatingTransform = false;
        _isAnimatingOut = false;
        _dx = _endX;
        _rotation = _endR;
        _currentAnimationCompleter?.complete();
        _currentAnimationCompleter = null;
      }
    }

    _controller.addStatusListener(onDone);
    _controller.forward();
    return _currentAnimationCompleter!.future;
  }

  Future<void> snapBack() {
    if (!mounted) return Future.value();
    _controller.stop();
    _controller.reset();
    _isAnimatingOut = false;
    _currentAnimationCompleter?.complete();
    _currentAnimationCompleter = null;

    final completer = Completer<void>();
    setState(() {
      _swipeLabel = null;
    });

    _startX = _dx;
    _startR = _rotation;
    _endX = 0;
    _endR = 0;
    _animCurve = Curves.elasticOut;
    _animatingTransform = true;

    void onDone(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _controller.removeStatusListener(onDone);
        _animatingTransform = false;
        _isDismissed = false;
        _dx = 0;
        _rotation = 0;
        _dragNotifier.value++;
        completer.complete();
      }
    }

    _controller.addStatusListener(onDone);
    _controller.forward();
    return completer.future;
  }

  void _onTapCard() {
    if (_isDismissed || _isAnimatingOut) return;
    widget.onTap?.call();
  }

  double _getOpacity(double dx) {
    if (!widget.isTop) return 1.0;
    final dist = dx.abs() / 300;
    return (1.0 - dist.clamp(0.0, 0.5));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    // Only the transform wrapper rebuilds per drag frame / animation tick —
    // the card content subtree is passed as a cached `child`.
    final card = AnimatedBuilder(
      animation: _transformListenable,
      child: _buildCardContent(context, isDark, primaryColor),
      builder: (context, child) {
        var dx = _dx;
        var rot = _rotation;
        if (_animatingTransform) {
          final t = _animCurve.transform(_controller.value);
          dx = _startX + (_endX - _startX) * t;
          rot = _startR + (_endR - _startR) * t;
        }
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..translateByDouble(dx, 0.0, 0.0, 1.0)
            ..rotateZ(rot),
          child: Opacity(
            opacity: _getOpacity(dx),
            child: child,
          ),
        );
      },
    );

    return RepaintBoundary(
      child: Transform.scale(
        scale: widget.scale,
        child: widget.isTop
            ? GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: card,
              )
            : card,
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return GestureDetector(
      onTap: _onTapCard,
      child: _buildCardFront(context, isDark, primaryColor),
    );
  }

  Widget _buildCardFront(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    final profile = widget.profile;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final font = AppTheme.fontFor(isPersian);

    // Mode A: photo flush to screen edges — no card shell, no radius, no shadow.
    final screenSize = MediaQuery.of(context).size;
    final placeholderColor = isDark
        ? AppTheme.darkSecondary
        : Colors.grey.shade200;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (profile.displayPhotoUrl.isNotEmpty)
          CachedImage.widget(
            profile.displayPhotoUrl,
            width: screenSize.width,
            height: screenSize.height,
            fit: BoxFit.cover,
            placeholder: Container(
              color: placeholderColor,
              child: const Icon(
                Icons.person,
                size: 64,
                color: Colors.grey,
              ),
            ),
            errorWidget: Container(
              color: placeholderColor,
              child: const Icon(
                Icons.person,
                size: 64,
                color: Colors.grey,
              ),
            ),
          )
        else
          Container(
            color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
            child: Icon(
              Icons.person,
              size: 64,
              color: isDark ? AppTheme.darkTextMuted : Colors.grey,
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0.0, 0.2, 0.45, 1.0],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.0, 0.55, 0.78, 1.0],
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
                  vertical: AppLayout.s(context, 8),
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _swipeLabel == 'LIKE'
                        ? (isDark
                              ? AppTheme.darkPrimary
                              : AppTheme.lightPrimary)
                        : (isDark ? AppTheme.darkError : AppTheme.lightError),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(AppLayout.s(context, 8)),
                ),
                child: Text(
                  _swipeLabel!,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: AppLayout.s(context, 32),
                    fontWeight: FontWeight.w900,
                    color: _swipeLabel == 'LIKE'
                        ? (isDark
                              ? AppTheme.darkPrimary
                              : AppTheme.lightPrimary)
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
                      horizontal: AppLayout.s(context, 10),
                      vertical: AppLayout.s(context, 4),
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.likeGradient(isDark: isDark),
                      borderRadius: BorderRadius.circular(
                        AppLayout.s(context, 12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          size: AppLayout.s(context, 12),
                          color: Colors.white,
                        ),
                        SizedBox(width: AppLayout.s(context, 3)),
                        Text(
                          'Premium',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: AppLayout.s(context, 10),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: AppLayout.discoverCardTextBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap for more',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      fontFamily: font,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${profile.age}',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (profile.distanceKm != null)
                Row(
                  children: [
                    Icon(
                      Icons.near_me,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${profile.distanceKm!.round()} km away',
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified,
                        size: AppLayout.s(context, 14),
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 4),
              if (profile.isVerified && profile.distanceKm == null)
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      size: AppLayout.s(context, 14),
                      color: Colors.white,
                    ),
                  ],
                ),
              if (profile.locationDisplay.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          profile.locationDisplay,
                          style: TextStyle(
                            fontFamily: font,
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
          top: 0,
          left: AppLayout.s(context, 16),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: AppLayout.s(context, 64)),
              child: OnlineRing(
                isOnline: profile.isOnline,
                size: AppLayout.s(context, 14),
                borderWidth: AppLayout.s(context, 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
