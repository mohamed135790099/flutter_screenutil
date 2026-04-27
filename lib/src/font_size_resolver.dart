/// Composable [FontSizeResolver] factories for [ScreenUtil].
///
/// The [FontSizeResolver] typedef is defined in `screen_util.dart`.
/// Import that file (or the barrel `flutter_screenutil.dart`) to use these.
library flutter_screenutil.font_size_resolver;

import 'dart:math' show min;

import 'screen_util.dart';

// ── Built-in resolver factories ───────────────────────────────────────────

/// Default resolver — respects [ScreenUtil]'s `minTextAdapt` flag and applies
/// a two-sided scale clamp.
///
/// This is **equivalent to the built-in `setSp()` logic** when no custom
/// resolver is provided.  Expose it as a named resolver so it can be composed
/// with [clampedAbsoluteResolver].
///
/// ```dart
/// fontSizeResolver: defaultFontSizeResolver(
///   minTextAdapt: true,
///   minScale: 0.85,
///   maxScale: 1.4,
/// ),
/// ```
FontSizeResolver defaultFontSizeResolver({
  bool minTextAdapt = true,
  double minScale = 0.85,
  double maxScale = 1.4,
}) {
  return (num fontSize, ScreenUtil instance) {
    final rawScale = minTextAdapt
        ? min(instance.scaleWidth, instance.scaleHeight)
        : instance.scaleWidth;
    final clamped = rawScale.clamp(minScale, maxScale);
    return fontSize * clamped;
  };
}

/// Width-only resolver — always scales by [ScreenUtil.scaleWidth] + clamp.
///
/// Equivalent to the original (pre-fix) `setSp()` behaviour, but with a
/// two-sided clamp added.  Useful when you want the old scaling axis.
///
/// ```dart
/// fontSizeResolver: widthBasedResolver(minScale: 0.85, maxScale: 1.4),
/// ```
FontSizeResolver widthBasedResolver({
  double minScale = 0.85,
  double maxScale = 1.4,
}) {
  return (num fontSize, ScreenUtil instance) {
    final clamped = instance.scaleWidth.clamp(minScale, maxScale);
    return fontSize * clamped;
  };
}

/// Shorter-axis resolver — always scales by the _smaller_ of width/height
/// scale, then clamps.
///
/// Equivalent to setting `minTextAdapt: true` on the default resolver.
/// Useful as a named resolver for composition.
///
/// ```dart
/// fontSizeResolver: minAxisResolver(minScale: 0.85, maxScale: 1.2),
/// ```
FontSizeResolver minAxisResolver({
  double minScale = 0.85,
  double maxScale = 1.4,
}) {
  return (num fontSize, ScreenUtil instance) {
    final rawScale = min(instance.scaleWidth, instance.scaleHeight);
    final clamped = rawScale.clamp(minScale, maxScale);
    return fontSize * clamped;
  };
}

/// Absolute-dp clamp resolver — applies [primary] first, then clamps the
/// **result in logical pixels** (dp) to [[min], [max]].
///
/// Use this when you need hard pixel bounds regardless of scale:
///
/// ```dart
/// fontSizeResolver: clampedAbsoluteResolver(
///   primary: defaultFontSizeResolver(minTextAdapt: true),
///   minDp: 12,   // never smaller than 12 dp
///   maxDp: 28,   // never larger than 28 dp
/// ),
/// ```
FontSizeResolver clampedAbsoluteResolver({
  required FontSizeResolver primary,
  /// Minimum output in logical pixels (dp). The resolved font size is never
  /// smaller than this value regardless of scale.
  required double minDp,
  /// Maximum output in logical pixels (dp). The resolved font size is never
  /// larger than this value regardless of scale.
  required double maxDp,
}) {
  return (num fontSize, ScreenUtil instance) {
    final scaled = primary(fontSize, instance);
    return scaled.clamp(minDp, maxDp);
  };
}
