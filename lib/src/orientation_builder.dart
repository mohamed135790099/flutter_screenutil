/// Phase 2 — Orientation-aware layout helpers.
///
/// Provides [ScreenOrientationBuilder], [OrientationValue], and
/// [SliverOrientationDelegate] — all driven by [ScreenUtil]'s current
/// orientation so they stay in sync with the package's design-size selection.
library flutter_screenutil.orientation_builder;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'screen_util.dart';

// ── ScreenOrientationBuilder ──────────────────────────────────────────────

/// Builds a different widget tree depending on the current orientation as
/// tracked by [ScreenUtil].
///
/// Prefer this over Flutter's built-in [OrientationBuilder] when you also use
/// `flutter_screenutil`, because [ScreenOrientationBuilder] reads orientation
/// from [ScreenUtil] — the same source that drives `.w`, `.h`, and `.sp` —
/// ensuring perfect consistency between layout switching and scaling.
///
/// ```dart
/// ScreenOrientationBuilder(
///   portrait:  (ctx) => PortraitLayout(),
///   landscape: (ctx) => LandscapeLayout(),
/// )
/// ```
class ScreenOrientationBuilder extends StatelessWidget {
  /// Creates an orientation-aware builder.
  ///
  /// [portrait] is used when [ScreenUtil().isPortrait] is `true`.
  /// [landscape] is used when [ScreenUtil().isLandscape] is `true`.
  const ScreenOrientationBuilder({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  /// Widget builder used in portrait orientation.
  final WidgetBuilder portrait;

  /// Widget builder used in landscape orientation.
  final WidgetBuilder landscape;

  @override
  Widget build(BuildContext context) {
    return ScreenUtil().isLandscape
        ? landscape(context)
        : portrait(context);
  }
}

// ── OrientationValue<T> ───────────────────────────────────────────────────

/// Holds two values of type [T] — one per orientation — and resolves the
/// correct one automatically based on [ScreenUtil]'s current orientation.
///
/// ```dart
/// final padding = OrientationValue<EdgeInsets>(
///   portrait:  EdgeInsets.symmetric(horizontal: 16.w),
///   landscape: EdgeInsets.symmetric(horizontal: 32.w),
/// );
///
/// // Inside build():
/// Padding(padding: padding.value)
/// ```
class OrientationValue<T> {
  /// Creates an [OrientationValue] with a [portrait] and a [landscape] value.
  const OrientationValue({
    required this.portrait,
    required this.landscape,
  });

  /// Value used in portrait orientation.
  final T portrait;

  /// Value used in landscape orientation.
  final T landscape;

  /// The value appropriate for the current [ScreenUtil] orientation.
  T get value => ScreenUtil().isLandscape ? landscape : portrait;
}

// ── SliverOrientationDelegate ─────────────────────────────────────────────

/// A [SliverGridDelegate] that uses a different cross-axis count depending on
/// the current [ScreenUtil] orientation.
///
/// ```dart
/// GridView.builder(
///   gridDelegate: SliverOrientationDelegate(
///     portraitCrossAxisCount:  2,
///     landscapeCrossAxisCount: 4,
///     childAspectRatio: 1.0,
///   ),
///   itemBuilder: (_, i) => ProductCard(products[i]),
/// )
/// ```
class SliverOrientationDelegate extends SliverGridDelegate {
  /// Creates a [SliverOrientationDelegate].
  ///
  /// [portraitCrossAxisCount] and [landscapeCrossAxisCount] must both be ≥ 1.
  const SliverOrientationDelegate({
    required this.portraitCrossAxisCount,
    required this.landscapeCrossAxisCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.childAspectRatio = 1.0,
  })  : assert(portraitCrossAxisCount >= 1),
        assert(landscapeCrossAxisCount >= 1),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        assert(childAspectRatio > 0);

  /// Number of columns in portrait orientation.
  final int portraitCrossAxisCount;

  /// Number of columns in landscape orientation.
  final int landscapeCrossAxisCount;

  /// Space between rows.
  final double mainAxisSpacing;

  /// Space between columns.
  final double crossAxisSpacing;

  /// Width-to-height ratio of each cell.
  final double childAspectRatio;

  int get _crossAxisCount =>
      ScreenUtil().isLandscape ? landscapeCrossAxisCount : portraitCrossAxisCount;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final count = _crossAxisCount;
    final usableWidth = constraints.crossAxisExtent -
        crossAxisSpacing * (count - 1);
    final cellWidth = usableWidth / count;
    final cellHeight = cellWidth / childAspectRatio;

    return SliverGridRegularTileLayout(
      crossAxisCount: count,
      mainAxisStride: cellHeight + mainAxisSpacing,
      crossAxisStride: cellWidth + crossAxisSpacing,
      childMainAxisExtent: cellHeight,
      childCrossAxisExtent: cellWidth,
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) {
    if (oldDelegate is! SliverOrientationDelegate) return true;
    return oldDelegate.portraitCrossAxisCount != portraitCrossAxisCount ||
        oldDelegate.landscapeCrossAxisCount != landscapeCrossAxisCount ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.childAspectRatio != childAspectRatio;
  }
}
