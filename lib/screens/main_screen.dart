// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/discover_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/search_provider.dart';
import '../services/photo_service.dart';
import '../services/push_service.dart';

import 'login_screen.dart';
import 'onboarding/basic_info_screen.dart';
import 'onboarding/photo_upload_screen.dart';
import 'profile/profile_screen.dart';
import 'discover/discover_screen.dart';
import 'search/search_screen.dart';
import 'chats/chats_screen.dart';
import 'chats/chat_detail_screen.dart';
import 'chats/user_notification_profile_screen.dart';
import '../generated/app_localizations.dart';
import '../utils/global_navigator.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  bool _isChecking = false;

  late final List<Widget> _screens;

  void _initScreens() {
    _screens = [
      ChangeNotifierProvider(
        create: (_) => SearchProvider(),
        child: const SearchScreen(),
      ),
      ChangeNotifierProvider(
        create: (_) => DiscoverProvider(),
        child: DiscoverScreen(
          onSwitchToChats: () => _switchToTab(2),
        ),
      ),
      const ChatsScreen(),
      ChangeNotifierProvider(
        create: (_) => ProfileProvider(),
        child: const ProfileScreen(),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initScreens();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingStatus();
    });
  }

  Future<void> _checkOnboardingStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      final user = authProvider.user;
      
      if (user != null && !user.isProfileComplete) {
        if (mounted) {
          if (onboardingProvider.email == null ||
              onboardingProvider.email!.isEmpty) {
            onboardingProvider.setEmailAndPassword(user.email, '');
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const BasicInfoScreen(),
            ),
          );
        }
        setState(() => _isChecking = false);
        return;
      }

      if (user != null && user.isProfileComplete) {
        await _checkUserPhotos();
      }

      if (mounted) {
        Provider.of<ChatProvider>(context, listen: false)
            .connectSessionSocket();
        
        // Initialize FCM push service
        Provider.of<NotificationsProvider>(context, listen: false)
            .attachSocket(Provider.of<ChatProvider>(context, listen: false));
        Provider.of<NotificationsProvider>(context, listen: false)
            .refreshUnreadCounts();
        PushService().initPush(
          onNotificationTap: _handleNotificationTap,
          onTokenRefreshed: () {},
        );
      }
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  /// Routes a tapped background/terminated push notification to its screen.
  void _handleNotificationTap(String route, Map<String, dynamic> data) {
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

    switch (route) {
      case 'user_profile':
        final userId = data['user_id'] as String?;
        if (userId != null && userId.isNotEmpty) {
          Navigator.of(navContext).push(
            MaterialPageRoute(
              builder: (_) => UserNotificationProfileScreen(
                userId: userId,
                fallback: SwipeStubProfile(
                  id: userId,
                  name: data['title'] as String? ?? '',
                  age: 0,
                ),
              ),
            ),
          );
        }
        break;
      case 'chat':
        final chatId = data['chat_id'] as String?;
        if (chatId != null && chatId.isNotEmpty) {
          Navigator.of(navContext).push(
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                identifier: chatId,
                userName: data['title'] as String? ?? '',
                avatarUrl: null,
              ),
            ),
          );
        }
        break;
      case 'announcement':
        _showAnnouncementDialog(
          navContext,
          title: data['title'] as String? ?? '',
          body: data['body'] as String? ?? '',
        );
        break;
    }
  }

  void _showAnnouncementDialog(BuildContext context, {required String title, required String body}) {
    final t = AppLocalizations.of(context);
    final isDark = context.isDarkMode;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModule),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(isDark),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t?.notifications_close ?? 'Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkUserPhotos() async {
    try {
      final photos = await PhotoService.getMyPhotos();
      
      if (mounted) {
        final allPhotos = photos.where((p) => p.status == 'pending' || p.status == 'approved').toList();
        
        if (allPhotos.length < 3) {
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (currentRoute != '/photo-upload') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const PhotoUploadScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const PhotoUploadScreen(),
          ),
        );
      }
    }
  }

  void _switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    if (authProvider.isLoading || _isChecking) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _GradientNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 2) {
            final chatProvider =
                Provider.of<ChatProvider>(context, listen: false);
            chatProvider.loadConversations();
            chatProvider.loadPendingIncoming();
            chatProvider.refreshLimits();
          }
        },
      ),
    );
  }
}

/// Full-width gradient bottom nav per the Warm Orange spec:
/// primaryGradient background, top corners radiusModule, white icons at 60%
/// opacity (inactive) / 100% + small dot (active). No card/pill shell.
class _GradientNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GradientNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _labels = ['Search', 'Discover', 'Chats', 'Profile'];
  static const _icons = [
    Icons.search_outlined,
    Icons.explore_outlined,
    Icons.chat_outlined,
    Icons.person_outline,
  ];
  static const _activeIcons = [
    Icons.search,
    Icons.explore,
    Icons.chat,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double horizMargin = constraints.maxWidth < 360 ? 8.0 : 16.0;
        return SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 12),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: horizMargin),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient(),
              borderRadius: BorderRadius.all(
                Radius.circular(AppTheme.radiusChip),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_labels.length, (i) {
                  final selected = i == currentIndex;
                  return _NavItem(
                    label: _labels[i],
                    icon: selected ? _activeIcons[i] : _icons[i],
                    selected: selected,
                    onTap: () => onTap(i),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const active = Colors.white;
    final inactive = Colors.white.withValues(alpha: 0.60);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? active : inactive, size: 22),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? active : inactive,
              ),
            ),
            const SizedBox(height: 1),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: selected ? active : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}