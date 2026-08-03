// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/discover_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/profile_provider.dart';
import '../services/photo_service.dart';
import 'auth/sign_up_screen.dart';
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
          MaterialPageRoute(builder: (_) => const SignUpScreen()),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}