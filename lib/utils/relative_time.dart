import 'package:dating_app/generated/app_localizations.dart';

String relativeTime(DateTime? time, AppLocalizations t) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.isNegative || diff.inMinutes < 1) {
    return t.time_just_now;
  }
  if (diff.inMinutes < 60) {
    return t.time_minutes_ago(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return t.time_hours_ago(diff.inHours);
  }
  return t.time_days_ago(diff.inDays);
}