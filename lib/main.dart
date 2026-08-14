// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'providers/notifications_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/global_navigator.dart';
import 'widgets/action_toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  FlutterError.onError = (details) {
    debugPrint('========== DIAGNOSTIC: FlutterError ==========');
    debugPrint('exception: ${details.exception}');
    debugPrint('stack:\n${details.stack}');
    final info = <DiagnosticsNode>[];
    details.informationCollector?.call() ?? info;
    if (info.isNotEmpty) {
      debugPrint('widget tree:\n${info.join('\n')}');
    }
    debugPrint('========== END DIAGNOSTIC ==========');
    FlutterError.presentError(details);
  };
  
  await dotenv.load();

  await ApiService.init();

  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('selected_language') ?? 'en';

  runApp(
    MyApp(
      initialLanguage: savedLanguage,
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final alreadyShown =
          prefs.getBool('screenshot_notice_shown') ?? false;
      if (!alreadyShown) {
        await prefs.setBool('screenshot_notice_shown', true);
        final context = appNavigatorKey.currentContext;
        if (context != null && context.mounted) {
          showActionToast(
            context,
            AppLocalizations.of(context)!.screenshot_disabled_notice,
          );
        }
      }
    }
  });
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
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final langProv = context.watch<LanguageProvider>();
    final settingsProv = context.watch<SettingsProvider>();

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'AURA',
      theme: AppTheme.themeFor(
        brightness: Brightness.light,
        isPersian: !langProv.isEnglish,
      ),
      darkTheme: AppTheme.themeFor(
        brightness: Brightness.dark,
        isPersian: !langProv.isEnglish,
      ),
      themeMode: settingsProv.darkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      locale: langProv.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        // Clamp the system text scale so very large accessibility fonts
        // (2x+) can't overflow our fixed-height layouts. Default scale is
        // untouched.
        final userScale = media.textScaler.scale(1.0);
        final clamped = userScale.clamp(1.0, 1.3);
        return MediaQuery(
          data: media.copyWith(
            textScaler: clamped == userScale
                ? media.textScaler
                : TextScaler.linear(clamped),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
