// lib/screens/splash_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/generated/app_localizations.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _targetProgress = 50;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _targetProgress = 50 + _random.nextInt(50);
    final targetDouble = _targetProgress / 100;

    await _animateProgress(0.0, targetDouble, duration: const Duration(milliseconds: 800));
    
    final isAuthenticated = await authProvider.initializeApp();

    if (authProvider.user != null && mounted) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      settingsProvider.loadFromUser(authProvider.user);
    }
    
    if (!authProvider.isServerHealthy && mounted) {
      final t = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = t.splash_connection_failed;
      });
      return;
    }

    await _animateProgress(_progress, 1.0, duration: const Duration(milliseconds: 300));

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _animateProgress(double from, double to, {required Duration duration}) async {
    final steps = 20;
    final stepDuration = duration ~/ steps;
    final increment = (to - from) / steps;

    for (int i = 0; i < steps; i++) {
      await Future.delayed(stepDuration);
      if (mounted) {
        setState(() {
          _progress = from + (increment * (i + 1));
          if (_progress > 1.0) _progress = 1.0;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _progress = 0.0;
      _targetProgress = 50 + _random.nextInt(50);
    });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final textMuted = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.favorite,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t.app_title,
                  style: AppTheme.headlineLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.splash_subtitle,
                  style: AppTheme.bodyLarge.copyWith(
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 60),

                if (_hasError)
                  _buildErrorWidget()
                else if (_isLoading)
                  _buildLoadingWidget()
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMuted = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    
    final displayPercent = (_progress * 100).toInt();
    
    return Column(
      children: [
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: _progress,
            child: Container(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$displayPercent%',
          style: AppTheme.labelMedium.copyWith(
            color: textMuted,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t.splash_connecting,
          style: AppTheme.bodyMedium.copyWith(
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final textMuted = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    
    return Column(
      children: [
        Icon(
          Icons.wifi_off_rounded,
          size: 48,
          color: textMuted.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: AppTheme.titleSmall.copyWith(
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.splash_check_internet,
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(
            color: textMuted,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50,
          width: 200,
          child: ElevatedButton(
            onPressed: _retry,
            style: AppTheme.primaryButtonSmall,
            child: Text(
              t.splash_retry,
              style: AppTheme.buttonText,
            ),
          ),
        ),
      ],
    );
  }
}