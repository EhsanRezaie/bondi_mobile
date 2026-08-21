// lib/screens/auth/phone_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../config/app_theme.dart';
import '../../generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/action_toast.dart';
import '../../widgets/phone_input_field.dart';
import '../legal/terms_screen.dart';
import '../legal/privacy_screen.dart';
import 'verify_code_screen.dart';

class PhoneEntryScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String submitLabel;

  const PhoneEntryScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.submitLabel,
  });

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  CountryCode _countryCode = CountryCode.fromCountryCode('IR');
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _validatePhone(String value) {
    final t = AppLocalizations.of(context)!;
    setState(() {
      if (value.isEmpty) {
        _phoneError = t.phone_error_required;
      } else if (value.length < 8) {
        _phoneError = t.phone_error_invalid;
      } else {
        _phoneError = null;
      }
    });
  }

  String _fullPhone() {
    final digits = _phoneController.text.trim();
    final dial = _countryCode.dialCode ?? '+98';
    return '$dial$digits';
  }

  Future<void> _handleContinue() async {
    final t = AppLocalizations.of(context)!;
    _validatePhone(_phoneController.text);
    if (_phoneError != null || _phoneController.text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoading) return;

    if (mounted) setState(() {});
    final success = await authProvider.requestCode(_fullPhone(), context);

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(phone: _fullPhone()),
        ),
      );
    } else {
      showActionToast(
        context,
        authProvider.errorMessage ?? t.error_something_wrong,
        isError: true,
      );
    }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          backgroundColor: colors.surface,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            width: 320.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.select_language,
                  style: AppTheme.titleMedium.copyWith(color: colors.primary),
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

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  }

  void _openPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = context.watch<LanguageProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;
    final currentLanguage = languageProvider.currentLanguageCode.toUpperCase();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: t.settings_dark_mode,
          icon: Icon(
            settingsProvider.darkMode ? Icons.light_mode : Icons.dark_mode,
            color: onSurfaceColor,
          ),
          onPressed: () {
            settingsProvider.toggleDarkMode(!settingsProvider.darkMode);
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: t.select_language,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageProvider.isEnglish ? '🇺🇸' : '🇮🇷',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 2),
                Text(
                  currentLanguage,
                  style: AppTheme.labelMedium.copyWith(color: onSurfaceColor),
                ),
              ],
            ),
            onPressed: _showLanguageSelector,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height - 120,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t.app_title,
                      style: AppTheme.headlineLarge.copyWith(color: primaryColor),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTheme.headlineMedium.copyWith(color: onSurfaceColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyLarge.copyWith(color: textMutedColor),
                    ),
                    const SizedBox(height: 40),
                    PhoneInputField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      hintText: t.phone_hint,
                      errorText: _phoneError,
                      onChanged: _validatePhone,
                      onSubmitted: _handleContinue,
                      onCountryChanged: (code) {
                        setState(() {
                          _countryCode = code;
                          _phoneError = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(widget.submitLabel, style: AppTheme.buttonText),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _TermsFooter(
                      onTermsTap: _openTerms,
                      onPrivacyTap: _openPrivacy,
                    ),
                    const SizedBox(height: 16),
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

class _TermsFooter extends StatelessWidget {
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const _TermsFooter({
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final textMutedColor = context.isDarkMode
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final primaryColor = context.isDarkMode
        ? AppTheme.darkPrimary
        : AppTheme.lightPrimary;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final linkStyle = TextStyle(
      fontFamily: AppTheme.fontFor(isPersian),
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: primaryColor,
      decoration: TextDecoration.underline,
      decorationColor: primaryColor,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: AppTheme.fontFor(isPersian),
            fontSize: 11,
            height: 1.4,
            color: textMutedColor,
          ),
          children: [
            TextSpan(text: '${t.terms_and_policy_agreement} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: onTermsTap,
                child: Text(t.terms_of_service, style: linkStyle),
              ),
            ),
            TextSpan(text: ' ${t.and} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: onPrivacyTap,
                child: Text(t.privacy_policy, style: linkStyle),
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
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
          color: isSelected
              ? AppTheme.moduleFillTinted(
                  isDark: colors.brightness == Brightness.dark,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24.0)),
            const SizedBox(width: 16.0),
            Text(
              languageName,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(
                  !Localizations.localeOf(context).languageCode.contains('en'),
                ),
                fontSize: 16.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colors.primary : AppTheme.lightTextMuted,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: colors.primary, size: 24.0),
          ],
        ),
      ),
    );
  }
}