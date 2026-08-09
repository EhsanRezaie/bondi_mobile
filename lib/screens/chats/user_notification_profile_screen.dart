import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/screens/search/search_profile_detail.dart';
import 'package:dating_app/services/chat_service.dart';
import 'package:dating_app/services/search_service.dart';

class UserNotificationProfileScreen extends StatefulWidget {
  final String userId;
  final SwipeStubProfile fallback;

  const UserNotificationProfileScreen({
    super.key,
    required this.userId,
    required this.fallback,
  });

  @override
  State<UserNotificationProfileScreen> createState() =>
      _UserNotificationProfileScreenState();
}

class SwipeStubProfile {
  final String id;
  final String name;
  final int age;
  final String? mainPhotoUrl;
  final bool isPremium;
  final bool isVerified;
  final double? distanceKm;

  const SwipeStubProfile({
    required this.id,
    required this.name,
    required this.age,
    this.mainPhotoUrl,
    this.isPremium = false,
    this.isVerified = false,
    this.distanceKm,
  });

  DiscoverProfile toDiscoverProfile() => DiscoverProfile(
    id: id,
    name: name,
    age: age,
    gender: '',
    mainPhotoUrl: mainPhotoUrl,
    photos: mainPhotoUrl != null ? [mainPhotoUrl!] : const [],
    isPremium: isPremium,
    isVerified: isVerified,
    distanceKm: distanceKm,
  );
}

class _UserNotificationProfileScreenState
    extends State<UserNotificationProfileScreen> {
  DiscoverProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().refreshLimits();
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ChatService.getPublicProfile(widget.userId);
      if (response.statusCode == 200 && response.data != null) {
        final profile = DiscoverProfile.fromJson(
          response.data as Map<String, dynamic>,
        );
        if (mounted) {
          setState(() {
            _profile = profile;
            _isLoading = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _error = 'not_found';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _refreshAfterAction() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.loadConversations();
    chatProvider.refreshLimits();
  }

  Future<Map<String, dynamic>?> _handleLike(DiscoverProfile profile) async {
    try {
      final response = await SearchService.swipeUser(profile.id, 'like');
      if (response.statusCode != 200) return null;
      _refreshAfterAction();
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _handleChat(
    DiscoverProfile profile, {
    String? message,
  }) async {
    try {
      final response = await ChatService.createChat(profile.id, message ?? '');
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }
      _refreshAfterAction();
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            t.error_something_wrong,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
          ),
        ),
      );
    }

    final profile = _profile ?? widget.fallback.toDiscoverProfile();
    final chatProvider = context.watch<ChatProvider>();

    return SearchProfileDetail(
      profile: profile,
      isPremium: chatProvider.isPremium,
      likesRemaining: chatProvider.likesRemaining,
      chatsRemaining: chatProvider.chatsRemaining,
      onLike: _handleLike,
      onChat: _handleChat,
    );
  }
}
