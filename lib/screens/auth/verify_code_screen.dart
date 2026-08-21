import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/generated/app_localizations.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../utils/responsive.dart';
import '../onboarding/basic_info_screen.dart';
import '../main_screen.dart';
import '../../widgets/action_toast.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String phone;
  final String? referralCode;

  const VerifyCodeScreen({
    super.key,
    required this.phone,
    this.referralCode,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  String? _errorMessage;

  // Timer variables
  int _resendTimerSeconds = 300;
  bool _isTimerRunning = true;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Focus on first field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _isTimerRunning = true;
    _resendTimerSeconds = 300;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_resendTimerSeconds > 0) {
            _resendTimerSeconds--;
          } else {
            _isTimerRunning = false;
            _resendTimer?.cancel();
            _resendTimer = null;
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _codeFocusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    _isTimerRunning = false;
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    // Auto-advance to next field
    if (value.length == 1 && index < 5) {
      _codeFocusNodes[index + 1].requestFocus();
    }
    // Auto-backspace to previous field
    if (value.isEmpty && index > 0) {
      _codeFocusNodes[index - 1].requestFocus();
    }
    setState(() {
      _errorMessage = null;
    });
  }

  String _getFullCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  Future<void> _handleVerify() async {
    final t = AppLocalizations.of(context)!;
    final code = _getFullCode();
    if (code.length != 6) {
      setState(() {
        _errorMessage = t.verify_code_required;
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _setLoading(true);

    final success = await authProvider.verifyCode(
      code: code,
      context: context,
    );

    _setLoading(false);

    if (success) {
      if (mounted) {
        final onboardingProvider = Provider.of<OnboardingProvider>(
          context,
          listen: false,
        );
        onboardingProvider.setPhone(widget.phone);

        if (authProvider.isNewUser) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BasicInfoScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage =
              authProvider.errorMessage ?? t.error_verification_failed;
        });
        for (var controller in _codeControllers) {
          controller.clear();
        }
        _codeFocusNodes[0].requestFocus();
      }
    }
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  Future<void> _resendCode() async {
    if (_isTimerRunning || _isLoading) {
      return;
    }

    final t = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _setLoading(true);

    final success = await authProvider.requestCode(widget.phone, context);

    _setLoading(false);

    if (success && mounted) {
      _startResendTimer();
      showActionToast(context, t.verify_resend_success);
      for (var controller in _codeControllers) {
        controller.clear();
      }
      _codeFocusNodes[0].requestFocus();
    } else if (mounted) {
      showActionToast(
        context,
        authProvider.errorMessage ?? t.verify_resend_failed,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;
    final errorColor = AppTheme.lightError;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurfaceColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              child: AppLayout.box(
                context: context,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      t.verify_title,
                      style: AppTheme.headlineMedium.copyWith(
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.verify_subtitle,
                      style: AppTheme.bodyLarge.copyWith(color: textMutedColor),
                    ),
                    Text(
                      widget.phone,
                      style: AppTheme.bodyLarge.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 48),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: errorColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                  fontSize: 14,
                                  color: errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 24),

                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return Expanded(
                            child: SizedBox(
                              height: 56,
                              child: TextFormField(
                                controller: _codeControllers[index],
                                focusNode: _codeFocusNodes[index],
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.ltr,
                                maxLength: 1,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                  fontSize: AppLayout.s(context, 20),
                                  fontWeight: FontWeight.w600,
                                  color: onSurfaceColor,
                                ),
                                onChanged: (value) =>
                                    _onCodeChanged(index, value),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '—',
                                  hintStyle: TextStyle(
                                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                    fontSize: AppLayout.s(context, 20),
                                    fontWeight: FontWeight.w600,
                                    color: textMutedColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: surfaceColor,
                                  contentPadding: const EdgeInsets.all(0),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isTimerRunning || _isLoading
                            ? null
                            : _resendCode,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isTimerRunning
                              ? textMutedColor
                              : primaryColor,
                          disabledForegroundColor: textMutedColor,
                          side: BorderSide(
                            color: _isTimerRunning
                                ? borderColor
                                : primaryColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isTimerRunning
                              ? '${t.verify_resend} (${_formatTime(_resendTimerSeconds)})'
                              : t.verify_resend,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(t.verify_button, style: AppTheme.buttonText),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}