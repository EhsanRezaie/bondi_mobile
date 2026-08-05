import 'package:intl/intl.dart';

/// Formats a distance in km into a short label.
///
/// Mirrors the previous inline logic in `discover_screen.dart`:
/// null or >= 500 -> '500+ km', otherwise rounded to whole km.
String formatDistanceKm(double? distanceKm) {
  if (distanceKm == null || distanceKm >= 500) return '500+ km';
  return '${distanceKm.round()} km';
}

/// Formats a `lastSeen` timestamp into a relative label.
///
/// Mirrors the previous inline logic in `online_indicator.dart`. The `now`
/// parameter is injectable for deterministic tests.
String formatLastSeen(DateTime lastSeen, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final diff = ref.difference(lastSeen);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(lastSeen);
}
