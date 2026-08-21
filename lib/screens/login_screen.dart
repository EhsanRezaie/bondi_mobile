import 'package:flutter/material.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'auth/phone_entry_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return PhoneEntryScreen(
      title: t.welcome_message,
      subtitle: t.find_match_tagline,
      submitLabel: t.send_code,
    );
  }
}