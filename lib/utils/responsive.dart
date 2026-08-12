// lib/utils/responsive.dart
import 'package:flutter/widgets.dart';

/// Layout width breakpoints (logical pixels).
class Breakpoints {
  Breakpoints._();

  /// Devices at or above this width are treated as tablets (phones < 600dp).
  static const double tablet = 600;

  /// Large tablets / foldables unfolded (>= 840dp).
  static const double largeTablet = 840;
}

/// Lightweight responsive helpers used across the whole app.
///
/// Design sizes are authored for a ~440dp phone baseline. `s()` scales a value
/// to the current screen width, clamped so small phones shrink slightly and
/// large tablets grow modestly instead of exploding. `box()`/`contentWidth()`
/// keep long-form content centered at a comfortable width on wide screens.
class AppLayout {
  AppLayout._();

  /// The design baseline width that spread values are authored against.
  static const double designWidth = 440;

  /// Smallest allowed scale factor (used on very narrow phones).
  static const double minScale = 0.95;

  /// Largest allowed scale factor (used on large tablets).
  static const double maxScale = 1.15;

  /// Scale factor for [width]. Never exceeds [maxScale] on giant tablets.
  static double scaleForWidth(double width) {
    return (width / designWidth).clamp(minScale, maxScale);
  }

  /// Scale factor for the current screen width.
  static double scaleOf(BuildContext context) {
    return scaleForWidth(MediaQuery.sizeOf(context).width);
  }

  /// Scales a "design" size to the current screen width.
  static double s(BuildContext context, double px) {
    return px * scaleOf(context);
  }

  /// True when the current screen is at least phone-tablet width.
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
  }

  /// True when the current screen is a large tablet (>= 840dp).
  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= Breakpoints.largeTablet;
  }

  /// Vertical clearance (in logical px) that content needs at the bottom of the
  /// main tab screens so the floating pill nav bar never covers it.
  static const double floatingNavClearance = 100;

  /// Bottom offset (in logical px) for the Discover action row so it hugs the
  /// top of the floating pill nav bar instead of floating high above it.
  static const double discoverActionRowBottom = 64;

  /// Bottom offset (in logical px) for the Discover card text block (tap hint,
  /// name/age, distance, location) so it always sits ABOVE the floating action
  /// buttons: action row bottom (64) + row height (~94: 12 pad + 62 button +
  /// 20 pad) + a small gap.
  static const double discoverCardTextBottom = 170;

  /// A comfortable max width for single-column forms/lists. Below 600dp the
  /// full device width is used so phones are not affected.
  static double contentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < Breakpoints.tablet ? width : 600.0;
  }

  /// Wraps [child] in a centered box constrained to a comfortable reading
  /// width on tablets (no-op on phones).
  static Widget box({
    required BuildContext context,
    required Widget child,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentWidth(context)),
        child: child,
      ),
    );
  }
}