// lib/screens/splash_screen.dart
import 'dart:math';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dating_app/generated/app_localizations.dart';
import '../config/app_constants.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/settings_provider.dart';
import '../services/system_service.dart';
import '../widgets/action_toast.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'onboarding/basic_info_screen.dart';
import 'onboarding/interests_screen.dart';
import 'onboarding/photo_upload_screen.dart';
import 'onboarding/profile_details_screen.dart';
import 'onboarding/prompts_screen.dart';

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
  String? _noticeType; // 'maintenance' | 'force_update' | 'update'
  String? _noticeMessage;
  String? _noticeUrl;
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

    await _checkVersionAndGate();
    if (_noticeType != null || !mounted) return;

    await _continueInit(authProvider);
  }

  /// Calls /system/version-check and shows maintenance / update gates.
  Future<void> _checkVersionAndGate() async {
    final platform = defaultTargetPlatform == TargetPlatform.android
        ? 'android'
        : 'ios';
    final result = await SystemService.checkVersion(
      platform: platform,
      version: AppConstants.appVersion,
    );
    if (!mounted || result == null) return; // fail-open on outage
    if (result.isMaintenance) {
      setState(() {
        _noticeType = 'maintenance';
        _noticeMessage = result.message;
      });
    } else if (result.isUpdateRequired) {
      setState(() {
        _noticeType = result.forceUpdate ? 'force_update' : 'update';
        _noticeMessage = result.message;
        _noticeUrl = result.updateUrl;
      });
    }
  }

  Future<void> _continueInit(AuthProvider authProvider) async {
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
      final user = authProvider.user;
      final onboarding = Provider.of<OnboardingProvider>(
        context,
        listen: false,
      );
      if (user != null) {
        await onboarding.attachUser(user.id);
      }
      if (!mounted) return;

      Widget home;
      final bool profileComplete = user?.isProfileComplete ?? false;
      if (profileComplete) {
        // The profile is authoritative. Drop any stale/partial onboarding
        // state so a completed user never gets sent back into the flow.
        onboarding.clear();
        home = const MainScreen();
      } else if (onboarding.flowComplete) {
        home = const MainScreen();
      } else if (onboarding.hasSavedState) {
        home = _resumeScreen(onboarding.stepIndex, onboarding.selfieStage);
      } else {
        home = const BasicInfoScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => home),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _dismissNotice() {
    setState(() {
      _noticeType = null;
      _noticeMessage = null;
      _noticeUrl = null;
    });
  }

  Future<void> _openUpdateUrl() async {
    final url = _noticeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      showActionToast(context, AppLocalizations.of(context)!.error_something_wrong, isError: true);
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _noticeType = null;
      _noticeMessage = null;
      _noticeUrl = null;
      _targetProgress = 50 + _random.nextInt(50);
    });
    _progressController.value = 0.0;
    _initializeApp();
  }

  Widget _resumeScreen(int step, bool selfieStage) {
    if (step >= 4 || selfieStage) return const PhotoUploadScreen();
    switch (step) {
      case 0:
        return const BasicInfoScreen();
      case 1:
        return const ProfileDetailsScreen();
      case 2:
        return const InterestsScreen();
      case 3:
        return const PromptsScreen();
      default:
        return const BasicInfoScreen();
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

                  if (_noticeType != null)
                    _buildNoticeWidget()
                  else if (isError)
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
                  style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold)
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

  Widget _buildNoticeWidget() {
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    final isMaintenance = _noticeType == 'maintenance';
    final title = isMaintenance
        ? t.system_maintenance_title
        : t.system_update_required_title;
    final message = (_noticeMessage?.isNotEmpty ?? false)
        ? _noticeMessage!
        : (isMaintenance
            ? t.system_maintenance_body
            : t.system_update_required_body);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMaintenance ? Icons.engineering : Icons.system_update_alt,
          size: 48,
          color: AppTheme.textOnPhoto.withValues(alpha: 0.9),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold).copyWith(
            color: AppTheme.textOnPhoto,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: (isPersian ? AppTheme.bodyFa : AppTheme.body).copyWith(
            color: AppTheme.textOnPhoto.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 32),
        if (!isMaintenance)
          SizedBox(
            height: 50,
            width: 200,
            child: ElevatedButton(
              onPressed: _openUpdateUrl,
              style: AppTheme.primaryButtonSmall.copyWith(
                backgroundColor: WidgetStatePropertyAll(AppTheme.textOnPhoto),
                foregroundColor: WidgetStatePropertyAll(
                  AppTheme.primaryGradientStart,
                ),
              ),
              child: Text(
                t.system_update_now,
                style: (isPersian ? AppTheme.buttonFa : AppTheme.button),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          width: 200,
          child: OutlinedButton(
            onPressed: () {
              if (isMaintenance) {
                _retry();
              } else if (_noticeType == 'update') {
                _dismissNotice();
                _continueInit(
                  Provider.of<AuthProvider>(context, listen: false),
                );
              } else {
                _retry();
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.textOnPhoto.withValues(alpha: 0.7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isMaintenance
                  ? t.splash_retry
                  : (_noticeType == 'update' ? t.system_update_later : t.splash_retry),
              style: (isPersian ? AppTheme.buttonFa : AppTheme.button).copyWith(
                color: AppTheme.textOnPhoto,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
