// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/discover_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/profile_provider.dart';
import '../services/photo_service.dart';

import 'login_screen.dart';
import 'onboarding/basic_info_screen.dart';
import 'onboarding/photo_upload_screen.dart';
import 'profile/profile_screen.dart';
import 'discover/discover_screen.dart';
import 'search/search_screen.dart';
import '../providers/search_provider.dart';
import 'chats/chats_screen.dart';

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
      }
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
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
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusModule),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? active : inactive, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? active : inactive,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5,
              height: 5,
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