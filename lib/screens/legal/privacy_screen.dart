// lib/screens/legal/privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'legal_page.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return LegalPage(
      title: t.privacy_title,
      lastUpdated: t.privacy_last_updated,
      sections: [
        LegalSection(
          title: t.privacy_sec_1_title,
          body: t.privacy_sec_1_body,
        ),
        LegalSection(
          title: t.privacy_sec_2_title,
          body: t.privacy_sec_2_body,
        ),
        LegalSection(
          title: t.privacy_sec_3_title,
          body: t.privacy_sec_3_body,
        ),
        LegalSection(
          title: t.privacy_sec_4_title,
          body: t.privacy_sec_4_body,
        ),
        LegalSection(
          title: t.privacy_sec_5_title,
          body: t.privacy_sec_5_body,
        ),
        LegalSection(
          title: t.privacy_sec_6_title,
          body: t.privacy_sec_6_body,
        ),
        LegalSection(
          title: t.privacy_sec_7_title,
          body: t.privacy_sec_7_body,
        ),
      ],
    );
  }
}