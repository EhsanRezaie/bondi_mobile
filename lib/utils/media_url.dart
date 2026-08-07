import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Rewrites backend hostname URLs so media works on emulators/devices dev.
/// `localhost` (or a plain host without scheme) is mapped to the Android
/// emulator loopback `10.0.2.2` so `CachedNetworkImage` can reach the dev API.
String mediaUrlForDisplay(String? url, {bool? isAndroidOverride}) {
  if (url == null || url.isEmpty) return url ?? '';
  if (kIsWeb) return url;
  final isAndroid = isAndroidOverride ?? (!kIsWeb && Platform.isAndroid);
  if (!isAndroid) return url;
  if (url.startsWith('localhost')) {
    return '10.0.2.2${url.substring('localhost'.length)}';
  }
  if (url.startsWith('127.0.0.1')) {
    return '10.0.2.2${url.substring('127.0.0.1'.length)}';
  }
  return url;
}