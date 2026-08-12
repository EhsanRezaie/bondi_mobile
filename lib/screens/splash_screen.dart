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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _targetProgress = 50;

  final Random _random = Random();

  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initializeApp();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _targetProgress = 50 + _random.nextInt(50);
    final targetDouble = _targetProgress / 100;

    await _animateProgress(
      0.0,
      targetDouble,
      duration: const Duration(milliseconds: 800),
    );

    final isAuthenticated = await authProvider.initializeApp();

    if (authProvider.user != null && mounted) {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
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

    await _animateProgress(
      _progressController.value,
      1.0,
      duration: const Duration(milliseconds: 300),
    );

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

  Future<void> _animateProgress(
    double from,
    double to, {
    required Duration duration,
  }) async {
    _progressController
      ..duration = duration
      ..value = from;
    await _progressController.animateTo(
      to,
      duration: duration,
      curve: Curves.easeOut,
    );
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _targetProgress = 50 + _random.nextInt(50);
    });
    _progressController.value = 0.0;
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    // Mode A: full-gradient background, white wordmark, no modules.
    final isError = _hasError;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient()),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 20.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite,
                        size: 48,
                        color: AppTheme.textOnPhoto,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.app_title,
                    textAlign: TextAlign.center,
                    style:
                        (isPersian
                                ? AppTheme.heroDisplayFa
                                : AppTheme.heroDisplay)
                            .copyWith(color: AppTheme.textOnPhoto),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.splash_subtitle,
                    textAlign: TextAlign.center,
                    style: (isPersian ? AppTheme.bodyFa : AppTheme.body)
                        .copyWith(
                          color: AppTheme.textOnPhoto.withValues(alpha: 0.85),
                        ),
                  ),
                  const SizedBox(height: 60),

                  if (isError)
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
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    return Column(
      children: [
        AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            final progress = _progressController.value;
            final displayPercent = (progress * 100).toInt();
            return Column(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.textOnPhoto.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.textOnPhoto,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$displayPercent%',
                  style: (isPersian
                          ? AppTheme.bodyBoldFa
                          : AppTheme.bodyBold)
                      .copyWith(
                    color: AppTheme.textOnPhoto.withValues(alpha: 0.9),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          t.splash_connecting,
          style: (isPersian ? AppTheme.bodyFa : AppTheme.body).copyWith(
            color: AppTheme.textOnPhoto.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    return Column(
      children: [
        Icon(
          Icons.wifi_off_rounded,
          size: 48,
          color: AppTheme.textOnPhoto.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold).copyWith(
            color: AppTheme.textOnPhoto,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.splash_check_internet,
          textAlign: TextAlign.center,
          style: (isPersian ? AppTheme.bodyFa : AppTheme.body).copyWith(
            color: AppTheme.textOnPhoto.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50,
          width: 200,
          child: ElevatedButton(
            onPressed: _retry,
            style: AppTheme.primaryButtonSmall.copyWith(
              backgroundColor: WidgetStatePropertyAll(AppTheme.textOnPhoto),
              foregroundColor: WidgetStatePropertyAll(
                AppTheme.primaryGradientStart,
              ),
            ),
            child: Text(
              t.splash_retry,
              style: (isPersian ? AppTheme.buttonFa : AppTheme.button),
            ),
          ),
        ),
      ],
    );
  }
}
