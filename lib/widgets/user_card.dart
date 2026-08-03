import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/widgets/shimmer_avatar.dart';

class UserCard extends StatefulWidget {
  final DiscoverProfile profile;
  final Map<String, String> interestIcons;
  final double scale;
  final bool isTop;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const UserCard({
    super.key,
    required this.profile,
    this.interestIcons = const {},
    this.scale = 1.0,
    this.isTop = false,
    this.onTap,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _dx = 0;
  double _dy = 0;
  double _rotation = 0;
  bool _isDismissed = false;
  String? _swipeLabel;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
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

  void _animateDismiss(int direction) {
    _isDismissed = true;
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
        if (direction > 0) {
          widget.onSwipeRight?.call();
        } else {
          widget.onSwipeLeft?.call();
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
      }
    });

    _controller.forward();
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
                top: 40,
                left: _swipeLabel == 'LIKE' ? 24 : null,
                right: _swipeLabel == 'NOPE' ? 24 : null,
                child: Transform.rotate(
                  angle: _swipeLabel == 'LIKE' ? -0.2 : 0.2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _swipeLabel == 'LIKE'
                            ? (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary)
                            : (isDark ? AppTheme.darkError : AppTheme.lightError),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _swipeLabel!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
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
              top: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profile.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkError : AppTheme.lightError,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text('Premium',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, size: 14, color: Colors.white),
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
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
              top: 12,
              left: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profile.isOnline)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (profile.isOnline) const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 12, color: Colors.white70),
                        SizedBox(width: 4),
                        Text('Tap for more',
                            style: TextStyle(
                                fontSize: 10,
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
