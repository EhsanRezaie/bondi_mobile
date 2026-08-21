// lib/screens/legal/legal_page.dart
import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';

class LegalSection {
  final String title;
  final String body;

  const LegalSection({required this.title, required this.body});
}

class LegalPage extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  const LegalPage({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: AppTheme.h2.copyWith(color: textColor),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lastUpdated,
                style: AppTheme.caption.copyWith(color: mutedColor),
              ),
              const SizedBox(height: 24),
              for (final section in sections) ...[
                Text(
                  section.title,
                  style: AppTheme.bodyBold.copyWith(
                    color: primaryColor,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.body,
                  style: AppTheme.body.copyWith(color: textColor),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}