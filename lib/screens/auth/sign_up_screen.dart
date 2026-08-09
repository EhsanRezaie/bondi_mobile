import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/generated/app_localizations.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../utils/responsive.dart';
import '../login_screen.dart';
import 'verify_code_screen.dart';
import '../../widgets/action_toast.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    final t = AppLocalizations.of(context)!;
    setState(() {
      if (value.isEmpty) {
        _emailError = t.signup_email_required;
      } else if (!RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(value)) {
        _emailError = t.signup_email_invalid;
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    final t = AppLocalizations.of(context)!;
    setState(() {
      if (value.isEmpty) {
        _passwordError = t.signup_password_required;
      } else if (value.length < 8) {
        _passwordError = t.signup_password_min_length;
      } else {
        _passwordError = null;
      }
    });
    if (_confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword(_confirmPasswordController.text);
    }
  }

  void _validateConfirmPassword(String value) {
    final t = AppLocalizations.of(context)!;
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError = t.signup_confirm_password_required;
      } else if (value != _passwordController.text) {
        _confirmPasswordError = t.signup_passwords_do_not_match;
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  Future<void> _handleSignUp() async {
    final t = AppLocalizations.of(context)!;
    _validateEmail(_emailController.text);
    _validatePassword(_passwordController.text);
    _validateConfirmPassword(_confirmPasswordController.text);

    if (_emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await authProvider.registerInit(email, context);

    if (success) {
      if (mounted) {
        final onboardingProvider = Provider.of<OnboardingProvider>(
          context,
          listen: false,
        );
        onboardingProvider.setEmailAndPassword(email, password);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyCodeScreen(email: email, password: password),
          ),
        );
      }
    } else {
      if (mounted) {
        showActionToast(
          context,
          authProvider.errorMessage ?? t.error_something_wrong,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;

    final Color bgColor = isDark
        ? AppTheme.darkBackground
        : AppTheme.lightBackground;
    final Color primaryColor = isDark
        ? AppTheme.darkPrimary
        : AppTheme.lightPrimary;
    final Color surfaceColor = isDark
        ? AppTheme.darkSurface
        : AppTheme.lightSurface;
    final Color borderColor = isDark
        ? AppTheme.darkBorder
        : AppTheme.lightBorder;
    final Color textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final Color errorColor = AppTheme.lightError;
    final Color onSurfaceColor = colors.onSurface;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurfaceColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: AppLayout.box(
                  context: context,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        t.signup_title,
                        style: AppTheme.headlineMedium.copyWith(
                          color: onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.signup_subtitle,
                        style: AppTheme.bodyLarge.copyWith(
                          color: textMutedColor,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9@._%+-]'),
                          ),
                        ],
                        onChanged: _validateEmail,
                        style: AppTheme.bodyLarge.copyWith(
                          color: onSurfaceColor,
                        ),
                        decoration: InputDecoration(
                          hintText: t.signup_email_hint,
                          hintStyle: AppTheme.bodyMedium.copyWith(
                            color: textMutedColor,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: textMutedColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _emailError != null
                                  ? errorColor
                                  : borderColor,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _emailError != null
                                  ? errorColor
                                  : primaryColor,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: errorColor, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: errorColor, width: 2),
                          ),
                          filled: true,
                          fillColor: surfaceColor,
                          errorText: _emailError,
                          errorStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: errorColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9!@#$%^&*()_+{}|:<>?~]'),
                          ),
                        ],
                        onChanged: _validatePassword,
                        style: AppTheme.bodyLarge.copyWith(
                          color: onSurfaceColor,
                        ),
                        decoration: InputDecoration(
                          hintText: t.signup_password_hint,
                          hintStyle: AppTheme.bodyMedium.copyWith(
                            color: textMutedColor,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: textMutedColor,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: textMutedColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _passwordError != null
                                  ? errorColor
                                  : borderColor,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _passwordError != null
                                  ? errorColor
                                  : primaryColor,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: errorColor, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: errorColor, width: 2),
                          ),
                          filled: true,
                          fillColor: surfaceColor,
                          errorText: _passwordError,
                          errorStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: errorColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        obscureText: !_isConfirmPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onChanged: _validateConfirmPassword,
                        onFieldSubmitted: (_) => _handleSignUp(),
                        style: AppTheme.bodyLarge.copyWith(
                          color: onSurfaceColor,
                        ),
                        decoration: InputDecoration(
                          hintText: t.signup_confirm_password_hint,
                          hintStyle: AppTheme.bodyMedium.copyWith(
                            color: textMutedColor,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: textMutedColor,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: textMutedColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _confirmPasswordError != null
                                  ? errorColor
                                  : borderColor,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _confirmPasswordError != null
                                  ? errorColor
                                  : primaryColor,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: errorColor, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: errorColor, width: 2),
                          ),
                          filled: true,
                          fillColor: surfaceColor,
                          errorText: _confirmPasswordError,
                          errorStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: errorColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: authProvider.isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  t.signup_button,
                                  style: AppTheme.buttonText,
                                ),
                        ),
                      ),

                      const SizedBox(height: 16.0),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              t.signup_already_have_account,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.0,
                                color: textMutedColor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              t.sign_in,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
