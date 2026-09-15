import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/widgets/discover_action_button.dart';
import 'package:dating_app/screens/shared/profile_detail_view.dart';

/// Discover's profile detail. Uses the shared [ProfileDetailView] for the
/// layout and only supplies the pass / chat / like action bar plus the
/// swipe-off dismiss animation.
class ProfileDetailScreen extends StatefulWidget {
  final DiscoverProfile profile;
  final Map<String, String> interestIcons;
  final Future<void> Function()? onSwipeLeft;
  final Future<void> Function()? onSwipeRight;
  final Future<void> Function()? onChat;
  final int? likesRemaining;
  final int? chatsRemaining;
  final bool isPremium;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
    this.interestIcons = const {},
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onChat,
    this.likesRemaining,
    this.chatsRemaining,
    this.isPremium = false,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _dismissController;
  late Animation<Offset> _dismissAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dismissAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, 0)).animate(
          CurvedAnimation(parent: _dismissController, curve: Curves.easeIn),
        );
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  void _startDismissAnimation(int direction) {
    _dismissAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: Offset(direction * 1.5, 0),
        ).animate(
          CurvedAnimation(parent: _dismissController, curve: Curves.easeIn),
        );
    _isAnimating = true;
    _dismissController.reset();
    _dismissController.forward().then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  void _snapBack() {
    _dismissController.stop();
    _dismissController.reset();
    _dismissAnimation =
        Tween<Offset>(begin: _dismissAnimation.value, end: Offset.zero).animate(
          CurvedAnimation(parent: _dismissController, curve: Curves.elasticOut),
        );
    _dismissController.forward().then((_) {
      if (mounted) _isAnimating = false;
    });
  }

  Future<void> _runAction(
    Future<void> Function()? action,
    int direction,
  ) async {
    if (_isAnimating) return;
    _isAnimating = true;
    _startDismissAnimation(direction);
    try {
      await action?.call();
    } catch (e) {
      _snapBack();
      if (!mounted) return;
    } finally {
      if (mounted) _isAnimating = false;
    }
  }

  Future<void> _onSwipeLeft() => _runAction(widget.onSwipeLeft, -1);
  Future<void> _onSwipeRight() => _runAction(widget.onSwipeRight, 1);
  Future<void> _onChat() => _runAction(widget.onChat, 1);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _dismissController,
      builder: (context, child) => Transform.translate(
        offset: _dismissAnimation.value * width,
        child: child,
      ),
      child: ProfileDetailView(
        profile: widget.profile,
        interestIcons: widget.interestIcons,
        showBlockOption: false,
        bottomBar: _buildBottomActionBar(context),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final isDark = context.isDarkMode;
    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DiscoverActionButton(
            icon: Icons.close_rounded,
            gradient: AppTheme.rejectGradient(isDark: isDark),
            size: 56,
            onPressed: _isAnimating ? null : _onSwipeLeft,
          ),
          const SizedBox(width: 24),
          DiscoverActionButton(
            icon: Icons.chat_bubble_rounded,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            iconColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            borderColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            size: 64,
            badgeCount: widget.isPremium ? null : widget.chatsRemaining,
            onPressed: _isAnimating ? null : _onChat,
          ),
          const SizedBox(width: 24),
          DiscoverActionButton(
            icon: Icons.favorite_rounded,
            gradient: AppTheme.likeGradient(isDark: isDark),
            size: 56,
            badgeCount: widget.isPremium ? null : widget.likesRemaining,
            onPressed: _isAnimating ? null : _onSwipeRight,
          ),
        ],
      ),
    );
  }
}
