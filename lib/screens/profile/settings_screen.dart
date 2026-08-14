import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import 'package:dating_app/providers/language_provider.dart';
import 'package:dating_app/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      settingsProvider.loadFromUser(authProvider.user);
    });
  }

  void _showLogoutDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.settings_logout,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        content: Text(
          t.settings_logout_confirm,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t.cancel,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            },
            child: Text(
              t.settings_logout,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkError : AppTheme.lightError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = ctx.isDarkMode;
        final isPersian = !Localizations.localeOf(
          ctx,
        ).languageCode.contains('en');
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.select_language,
                  style: (isPersian ? AppTheme.h2Fa : AppTheme.h2).copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                label: t.english,
                isSelected: context.read<SettingsProvider>().language == 'en',
                onTap: () {
                  context.read<SettingsProvider>().changeLanguage('en');
                  context.read<LanguageProvider>().changeLanguage('en');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: t.persian,
                isSelected: context.read<SettingsProvider>().language == 'fa',
                onTap: () {
                  context.read<SettingsProvider>().changeLanguage('fa');
                  context.read<LanguageProvider>().changeLanguage('fa');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final textMutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: onSurfaceColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.settings_title,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: onSurfaceColor,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPremiumModule(t, isDark, onSurfaceColor, textMutedColor),
              const SizedBox(height: 28),
              _buildSectionHeader(t.settings_appearance, isDark, onSurfaceColor),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  _buildSwitchTile(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    title: t.settings_dark_mode,
                    subtitle: t.settings_dark_mode_desc,
                    value: isDark,
                    onChanged: (val) {
                      context.read<SettingsProvider>().toggleDarkMode(val);
                    },
                    isDark: isDark,
                    onSurfaceColor: onSurfaceColor,
                    textMutedColor: textMutedColor,
                    borderColor: borderColor,
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                  ),
                ],
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                borderRadius: 16,
              ),
              const SizedBox(height: 28),
              _buildSectionHeader(t.settings_privacy, isDark, onSurfaceColor),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  _buildSwitchTile(
                    icon: Icons.visibility_off_outlined,
                    title: t.settings_hide_last_seen,
                    subtitle: t.settings_hide_last_seen_desc,
                    value: context.watch<SettingsProvider>().hideLastSeen,
                    onChanged: (val) {
                      context.read<SettingsProvider>().toggleHideLastSeen(val);
                    },
                    isDark: isDark,
                    onSurfaceColor: onSurfaceColor,
                    textMutedColor: textMutedColor,
                    borderColor: borderColor,
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                  ),
                  _buildDivider(isDark),
                  _buildSwitchTile(
                    icon: Icons.power_outlined,
                    title: t.settings_hide_online_status,
                    subtitle: t.settings_hide_online_status_desc,
                    value: context.watch<SettingsProvider>().hideOnlineStatus,
                    onChanged: (val) {
                      context.read<SettingsProvider>().toggleHideOnlineStatus(val);
                    },
                    isDark: isDark,
                    onSurfaceColor: onSurfaceColor,
                    textMutedColor: textMutedColor,
                    borderColor: borderColor,
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                  ),
                ],
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                borderRadius: 16,
              ),
              const SizedBox(height: 28),
              _buildSectionHeader(t.settings_notifications, isDark, onSurfaceColor),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_outlined,
                    title: t.settings_push_notifications,
                    subtitle: t.settings_push_notifications_desc,
                    value: context.watch<SettingsProvider>().pushEnabled,
                    onChanged: (val) {
                      context.read<SettingsProvider>().togglePushEnabled(val);
                    },
                    isDark: isDark,
                    onSurfaceColor: onSurfaceColor,
                    textMutedColor: textMutedColor,
                    borderColor: borderColor,
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                  ),
                  _buildDivider(isDark),
                  _buildSwitchTile(
                    icon: Icons.favorite_outline,
                    title: t.settings_like_notifications,
                    subtitle: t.settings_like_notifications_desc,
                    value: context.watch<SettingsProvider>().likeNotifications,
                    onChanged: (val) {
                      context.read<SettingsProvider>().toggleLikeNotifications(val);
                    },
                    isDark: isDark,
                    onSurfaceColor: onSurfaceColor,
                    textMutedColor: textMutedColor,
                    borderColor: borderColor,
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                  ),
                  _buildDivider(isDark),
                  _buildSwitchTile(
                    icon: Icons.favorite,
                    title: t.settings_match_notifications,
                    subtitle: t.settings_match_notifications_desc,
                    value: context.watch<SettingsProvider>().matchNotifications,
                    onChanged: (val) {
                      context.read<SettingsProvider>().toggleMatchNotifications(val);
                    },
                    isDark: isDark,
                    onSurfaceColor: onSurfaceColor,
                    textMutedColor: textMutedColor,
                    borderColor: borderColor,
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                  ),
                  _buildDivider(isDark),
                  _buildSwitchTile(
                    icon: Icons.message_outlined,
                    title: t.settings_message_notifications,
                    subtitle: t.settings_message_notifications_desc,
                    value: context.watch<SettingsProvider>().messageNotifications,
                    onChanged: (val) {
                      context.read<SettingsProvider>().toggleMessageNotifications(val);
                    },
                    isDark: isDark,
                    onSurfaceColor: onSurfaceColor,
                    textMutedColor: textMutedColor,
                    borderColor: borderColor,
                    surfaceColor: surfaceColor,
                    primaryColor: primaryColor,
                  ),
                ],
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                borderRadius: 16,
              ),
              const SizedBox(height: 28),
              _buildSectionHeader(t.settings_language, isDark, onSurfaceColor),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  InkWell(
                    onTap: _showLanguagePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.moduleFillTinted(
                                isDark: isDark,
                                accent: primaryColor,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.language,
                              color: primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.settings_language,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: onSurfaceColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.settings_language_desc,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                    fontSize: 13,
                                    color: textMutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            context.watch<SettingsProvider>().language == 'fa'
                                ? t.persian
                                : t.english,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: textMutedColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                borderRadius: 16,
              ),
              const SizedBox(height: 28),
              _buildSectionHeader(t.settings_account, isDark, onSurfaceColor),
              const SizedBox(height: 12),
              _buildSettingsCard(
                children: [
                  InkWell(
                    onTap: () => _showLogoutDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkError.withValues(alpha: 0.1)
                                  : AppTheme.lightError.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.logout,
                              color: isDark ? AppTheme.darkError : AppTheme.lightError,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.settings_logout,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppTheme.darkError : AppTheme.lightError,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.settings_logout_desc,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                    fontSize: 13,
                                    color: textMutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: textMutedColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                borderRadius: 16,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumModule(
    AppLocalizations t,
    bool isDark,
    Color onSurfaceColor,
    Color textMutedColor,
  ) {
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.moduleFillTinted(
          isDark: isDark,
          accent: AppTheme.accentLike,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusModule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.likeGradient(isDark: isDark),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.settings_premium_title,
                      style: (isPersian ? AppTheme.h2Fa : AppTheme.h2).copyWith(
                        color: onSurfaceColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      t.settings_premium_subtitle,
                      style: (isPersian ? AppTheme.captionFa : AppTheme.caption)
                          .copyWith(color: textMutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPerkPill(
                icon: Icons.favorite,
                label: t.settings_premium_perk_likes,
                isDark: isDark,
                onSurfaceColor: onSurfaceColor,
              ),
              _buildPerkPill(
                icon: Icons.chat_bubble,
                label: t.settings_premium_perk_chats,
                isDark: isDark,
                onSurfaceColor: onSurfaceColor,
              ),
              _buildPerkPill(
                icon: Icons.rocket_launch,
                label: t.settings_premium_perk_boost,
                isDark: isDark,
                onSurfaceColor: onSurfaceColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTheme.gradientButton(
            onPressed: () {},
            height: 48,
            child: Text(
              t.settings_premium_cta,
              style: (isPersian ? AppTheme.buttonFa : AppTheme.button).copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerkPill({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color onSurfaceColor,
  }) {
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.accentLike),
          const SizedBox(width: 5),
          Text(
            label,
            style: (isPersian ? AppTheme.captionFa : AppTheme.caption).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, Color onSurfaceColor) {
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: (isPersian ? AppTheme.overlineFa : AppTheme.overline).copyWith(
          color: mutedColor,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required List<Widget> children,
    required Color surfaceColor,
    required Color borderColor,
    required double borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color onSurfaceColor,
    required Color textMutedColor,
    required Color borderColor,
    required Color surfaceColor,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.moduleFillTinted(
                isDark: isDark,
                accent: primaryColor,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: onSurfaceColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 12,
                    color: textMutedColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.18 : 0.10)
              : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold)
                    .copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? primaryColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 22),
          ],
        ),
      ),
    );
  }
}
