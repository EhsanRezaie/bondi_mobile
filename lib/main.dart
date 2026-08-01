// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'generated/app_localizations.dart';
import 'config/app_theme.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/language_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load();

  await ApiService.init();

  // Load saved language before running app
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('selected_language') ?? 'en';
  
  runApp(
    MyApp(
      initialLanguage: savedLanguage,
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialLanguage;
  
  const MyApp({
    super.key,
    required this.initialLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider()..setLanguage(initialLanguage),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer2<LanguageProvider, SettingsProvider>(
        builder: (context, langProv, settingsProv, _) {
          return MaterialApp(
            title: 'AURA',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProv.darkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            locale: langProv.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}