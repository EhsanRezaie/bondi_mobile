import 'package:flutter/material.dart';

/// Root navigator key used for context-free navigation and overlays (e.g. the
/// notification toast triggered from WS/FCM callbacks that have no widget tree).
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();