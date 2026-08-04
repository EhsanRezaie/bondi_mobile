import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/providers/language_provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth/sign_up_screen.dart';
import 'main_screen.dart';
import '../services/google_auth_service.dart';
import '../../widgets/action_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleAuthService _googleAuth = GoogleAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _showLanguageSelector() {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = context.read<LanguageProvider>();
    final isEnglish = languageProvider.isEnglish;
    final colors = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            width: 320.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.select_language,
                  style: AppTheme.titleMedium.copyWith(
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 16.0),
                const Divider(color: AppTheme.lightBorder),
                const SizedBox(height: 16.0),
                _LanguageOption(
                  languageCode: 'EN',
                  languageName: l10n.english,
                  flag: '🇺🇸',
                  isSelected: isEnglish,
                  onTap: () {
                    languageProvider.changeLanguage('en');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12.0),
                _LanguageOption(
                  languageCode: 'FA',
                  languageName: l10n.persian,
                  flag: '🇮🇷',
                  isSelected: !isEnglish,
                  onTap: () {
                    languageProvider.changeLanguage('fa');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.lightTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _validateEmail(String value) {
    final t = AppLocalizations.of(context)!;
    setState(() {
      if (value.isEmpty) {
        _emailError = t.login_email_required;
      } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
        _emailError = t.login_email_invalid;
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    final t = AppLocalizations.of(context)!;
    setState(() {
      if (value.isEmpty) {
        _passwordError = t.login_password_required;
      } else if (value.length < 8) {
        _passwordError = t.login_password_invalid;
      } else {
        _passwordError = null;
      }
    });
  }

  Future<void> _handleLogin() async {
    final t = AppLocalizations.of(context)!;
    _validateEmail(_emailController.text);
    _validatePassword(_passwordController.text);
    
    if (_emailError != null || _passwordError != null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoading) return;

    setState(() => _isLoading = true);

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      context: context,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      showActionToast(context, t.error_wrong_credentials, isError: true);
    }
  }

   Future<void> _handleGoogleSignIn() async {
     final t = AppLocalizations.of(context)!;
     
     final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isLoading) return;

    setState(() => _isLoading = true);
    final result = await _googleAuth.signIn();
    if (result == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;
    final success = await authProvider.googleLogin(
      idToken: result['id_token']!,
      name: result['name'],
      email: result['email'],
      picture: result['picture'],
      context: context,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (mounted) {
      showActionToast(
        context,
        authProvider.errorMessage ?? t.error_login_failed,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final languageProvider = context.watch<LanguageProvider>();
    final currentLanguage = languageProvider.currentLanguageCode.toUpperCase();
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    
    final Color bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final Color primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final Color surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final Color borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final Color textMutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final Color errorColor = AppTheme.lightError;
    final Color secondaryColor = isDark ? AppTheme.darkSecondary : AppTheme.lightSecondary;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _showLanguageSelector,
                        icon: Icon(
                          Icons.language,
                          size: 18.0,
                          color: textMutedColor,
                        ),
                        label: Text(
                          currentLanguage,
                          style: AppTheme.labelMedium.copyWith(
                            color: textMutedColor,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    t.app_title,
                    textAlign: TextAlign.center,
                    style: AppTheme.headlineLarge.copyWith(
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    t.welcome_subtitle,
                    textAlign: TextAlign.center,
                    style: AppTheme.headlineMedium.copyWith(
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      t.join_community_text,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyLarge.copyWith(
                        color: textMutedColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // Email TextField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
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
                        onEditingComplete: () {
                          FocusScope.of(context).requestFocus(_passwordFocusNode);
                        },
                        style: AppTheme.bodyLarge.copyWith(
                          color: colors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: t.enter_email_hint,
                          hintStyle: AppTheme.bodyMedium.copyWith(
                            color: textMutedColor,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 16.0,
                          ),
                          filled: true,
                          fillColor: surfaceColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide(
                              color: _emailError != null ? errorColor : borderColor,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide(
                              color: _emailError != null ? errorColor : primaryColor,
                              width: 2.0,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide(
                              color: errorColor,
                              width: 1.0,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide(
                              color: errorColor,
                              width: 2.0,
                            ),
                          ),
                          errorText: _emailError,
                          errorStyle: AppTheme.labelSmall.copyWith(
                            color: errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Password TextField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9!@#$%^&*()_+{}|:<>?~]'),
                          ),
                        ],
                        onChanged: _validatePassword,
                        onEditingComplete: _handleLogin,
                        style: AppTheme.bodyLarge.copyWith(
                          color: colors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: t.enter_password_hint,
                          hintStyle: AppTheme.bodyMedium.copyWith(
                            color: textMutedColor,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 16.0,
                          ),
                          filled: true,
                          fillColor: surfaceColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide(
                              color: _passwordError != null ? errorColor : borderColor,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide(
                              color: _passwordError != null ? errorColor : primaryColor,
                              width: 2.0,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: textMutedColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          errorText: _passwordError,
                          errorStyle: AppTheme.labelSmall.copyWith(
                            color: errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Sign in Button
                  Container(
                    height: 56.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14001F3F),
                          offset: Offset(0, 12),
                          blurRadius: 32.0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              t.sign_in_button,
                              style: AppTheme.buttonText,
                            ),
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: borderColor, thickness: 1.0)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          t.or,
                          style: AppTheme.labelMedium.copyWith(
                            color: textMutedColor,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: borderColor, thickness: 1.0)),
                    ],
                  ),
                  const SizedBox(height: 32.0),

                  // Google Button
                  SizedBox(
                    height: 56.0,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 24.0,
                        width: 24.0,
                        fit: BoxFit.contain,
                      ),
                      label: Text(
                        t.continue_with_google,
                        style: AppTheme.buttonText,
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: primaryColor,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Sign up links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.dont_have_an_account,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.0,
                          color: textMutedColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          );
                        },
                        child: Text(
                          t.sign_up,
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
                  const SizedBox(height: 16.0),

                  // Terms and Policy
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      t.terms_and_policy,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodySmall.copyWith(
                        color: textMutedColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.languageCode,
    required this.languageName,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8EDF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24.0),
            ),
            const SizedBox(width: 16.0),
            Text(
              languageName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colors.primary : AppTheme.lightTextMuted,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colors.primary,
                size: 24.0,
              ),
          ],
        ),
      ),
    );
  }
}