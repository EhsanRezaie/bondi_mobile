// lib/screens/legal/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'legal_page.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return LegalPage(
      title: t.terms_title,
      lastUpdated: t.terms_last_updated,
      sections: [
        LegalSection(
          title: t.terms_sec_1_title,
          body: t.terms_sec_1_body,
        ),
        LegalSection(
          title: t.terms_sec_2_title,
          body: t.terms_sec_2_body,
        ),
        LegalSection(
          title: t.terms_sec_3_title,
          body: t.terms_sec_3_body,
        ),
        LegalSection(
          title: t.terms_sec_4_title,
          body: t.terms_sec_4_body,
        ),
        LegalSection(
          title: t.terms_sec_5_title,
          body: t.terms_sec_5_body,
        ),
        LegalSection(
          title: t.terms_sec_6_title,
          body: t.terms_sec_6_body,
        ),
        LegalSection(
          title: t.terms_sec_7_title,
          body: t.terms_sec_7_body,
        ),
        LegalSection(
          title: t.terms_sec_8_title,
          body: t.terms_sec_8_body,
        ),
      ],
    );
  }
}