import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReporting {
  CrashReporting._();

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  static Future<void> init() async {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    await analytics.setAnalyticsCollectionEnabled(true);
    FirebaseCrashlytics.instance
        .setCustomKey('build_mode', kDebugMode ? 'debug' : 'release');
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } catch (_) {}
  }

  static void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) {
    try {
      FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: fatal, reason: reason);
    } catch (_) {}
  }

  static void log(String message) {
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  static void setUserId(String? userId) {
    try {
      FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
      analytics.setUserId(id: userId);
    } catch (_) {}
  }

  static Future<void> logEvent(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }
}
