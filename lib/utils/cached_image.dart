// lib/utils/cached_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/widgets/shimmer_avatar.dart';

/// Shared image-resolution + caching config for network photos.
///
/// The app is photo-heavy (swipe cards, profile grids, message photos), so
/// decoding every network image at full source resolution is the #1 jank
/// suspect flagged in `PLAN_WARM_ORANGE_REDESIGN.md` (§P0). This helper computes
/// `memCacheWidth`/`memCacheHeight` from the *rendered* size × device pixel
/// ratio and forwards them to `CachedNetworkImage` / `CachedNetworkImageProvider`,
/// so photos are decoded once at display resolution and reused across rebuilds.
class CachedImage {
  CachedImage._();

  /// A network image widget with a shimmer placeholder and a fallback icon on
  /// error.
  ///
  /// `width`/`height` should be the *display* size (in logical px); the helper
  /// derives the in-memory cache dimensions and the on-disk tile size from them.
  static Widget widget(
    String? imageUrl, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    VoidCallback? onTap,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _fallback(width, height, errorWidget);
    }

    final pxW = _pixel(width);
    final pxH = _pixel(height);

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: pxW,
      memCacheHeight: pxH,
      maxWidthDiskCache: pxW,
      maxHeightDiskCache: pxH,
      placeholder: (context, url) => SizedBox(
        width: width,
        height: height,
        child: placeholder ?? const ShimmerAvatar(),
      ),
      errorWidget: (context, url, error) => SizedBox(
        width: width,
        height: height,
        child: errorWidget ??
            const Icon(Icons.broken_image, size: 32, color: Colors.grey),
      ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius, child: image);
    }

    if (onTap == null) return image;
    return GestureDetector(onTap: onTap, child: image);
  }

  /// Resolves a [CachedNetworkImageProvider] sized to `maxWidth`×`maxHeight`
  /// in *pixels*. Use this for `CircleAvatar.backgroundImage` / avatar tiles
  /// where the rendered diameter is known.
  static CachedNetworkImageProvider provider(
    String imageUrl, {
    required double diameter,
  }) {
    final px = _pixel(diameter);
    return CachedNetworkImageProvider(
      imageUrl,
      maxWidth: px,
      maxHeight: px,
    );
  }

  /// Resolves a cached provider for rectangular avatars (non-square leading
  /// thumbs) where width/height differ.
  static CachedNetworkImageProvider providerRect(
    String imageUrl, {
    required double width,
    required double height,
  }) {
    return CachedNetworkImageProvider(
      imageUrl,
      maxWidth: _pixel(width),
      maxHeight: _pixel(height),
    );
  }

  static Widget _fallback(
    double width,
    double height,
    Widget? errorWidget,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: errorWidget ??
          const Icon(Icons.broken_image, size: 32, color: Colors.grey),
    );
  }

  static int _pixel(double logical) =>
      (logical * _devicePixelRatio).ceil();

  static double get _devicePixelRatio {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    return views.isEmpty ? 1.0 : views.first.devicePixelRatio;
  }
}
