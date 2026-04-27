/// Phase 3 — Device-class API: [AdaptiveWidget], [AdaptiveLayout],
/// [Breakpoints].
///
/// [DeviceType] and [ScreenUtil.adaptive] are defined in `screen_util.dart`
/// and re-exported via the barrel.  This file adds the widget-level helpers
/// that build on top of those primitives.
library flutter_screenutil.device_type;

import 'package:flutter/widgets.dart';

import 'screen_util.dart';

// ── AdaptiveWidget ────────────────────────────────────────────────────────

/// Renders a different widget subtree based on the current [DeviceType].
///
/// The fallback chain follows: [desktop] → [tablet] → [phone].
/// Omit any tier to inherit from the next smaller one.
///
/// ```dart
/// AdaptiveWidget(
///   phone:   (ctx) => BottomNavBar(),
///   tablet:  (ctx) => SideRail(),
///   desktop: (ctx) => FullDrawer(),
/// )
/// ```
class AdaptiveWidget extends StatelessWidget {
  /// Creates an [AdaptiveWidget].
  ///
  /// [phone] is the only required builder; [tablet], [desktop], and [tv] are
  /// optional and fall back to the next smaller device's builder when omitted.
  const AdaptiveWidget({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
    this.tv,
  });

  /// Builder for [DeviceType.phone].
  final WidgetBuilder phone;

  /// Builder for [DeviceType.tablet].  Falls back to [phone] when `null`.
  final WidgetBuilder? tablet;

  /// Builder for [DeviceType.desktop].  Falls back to [tablet] → [phone].
  final WidgetBuilder? desktop;

  /// Builder for [DeviceType.tv].  Falls back to [desktop] → [tablet] → [phone].
  final WidgetBuilder? tv;

  @override
  Widget build(BuildContext context) {
    final builder = ScreenUtil().adaptive<WidgetBuilder>(
      phone: phone,
      tablet: tablet,
      desktop: desktop,
      tv: tv,
    );
    return builder(context);
  }
}

// ── AdaptiveLayout ────────────────────────────────────────────────────────

/// Full layout switcher with per-device-type **and** per-orientation guards.
///
/// Landscape-specific builders ([landscapePhone], [landscapeTablet],
/// [landscapeDesktop]) take precedence over their portrait counterparts when
/// the device is in landscape orientation.  If a landscape builder is omitted
/// the portrait builder for that device class is used as fallback.
///
/// ```dart
/// AdaptiveLayout(
///   phone:          (_) => MobileHome(),
///   landscapePhone: (_) => HorizontalVideoPlayer(),
///   tablet:         (_) => TabletHome(),
///   landscapeTablet: (_) => TabletLandscapeHome(),
///   desktop:        (_) => DesktopDashboard(),
/// )
/// ```
class AdaptiveLayout extends StatelessWidget {
  /// Creates an [AdaptiveLayout].
  ///
  /// [phone] is required.  All other parameters are optional; omitted
  /// landscape builders fall back to the corresponding portrait builder.
  const AdaptiveLayout({
    super.key,
    required this.phone,
    this.landscapePhone,
    this.tablet,
    this.landscapeTablet,
    this.desktop,
    this.landscapeDesktop,
    this.tv,
    this.landscapeTv,
  });

  final WidgetBuilder phone;
  final WidgetBuilder? landscapePhone;
  final WidgetBuilder? tablet;
  final WidgetBuilder? landscapeTablet;
  final WidgetBuilder? desktop;
  final WidgetBuilder? landscapeDesktop;
  final WidgetBuilder? tv;
  final WidgetBuilder? landscapeTv;

  @override
  Widget build(BuildContext context) {
    final su = ScreenUtil();
    final isLandscape = su.isLandscape;

    // Portrait builders per device class (with fallback chain).
    final portraitPhone = phone;
    final portraitTablet = tablet ?? phone;
    final portraitDesktop = desktop ?? tablet ?? phone;
    final portraitTv = tv ?? desktop ?? tablet ?? phone;

    // Active portrait builder for this device.
    final portraitBuilder = su.adaptive<WidgetBuilder>(
      phone: portraitPhone,
      tablet: portraitTablet,
      desktop: portraitDesktop,
      tv: portraitTv,
    );

    if (!isLandscape) return portraitBuilder(context);

    // Pick landscape builder; fall back to portrait for this device.
    final landscapeBuilder = su.adaptive<WidgetBuilder>(
      phone: landscapePhone ?? portraitPhone,
      tablet: landscapeTablet ?? portraitTablet,
      desktop: landscapeDesktop ?? portraitDesktop,
      tv: landscapeTv ?? portraitTv,
    );

    return landscapeBuilder(context);
  }
}

// ── Breakpoints ───────────────────────────────────────────────────────────

/// Static utility that resolves per-device values from an explicit [width]
/// value.
///
/// Unlike [ScreenUtil.adaptive], [Breakpoints] has **no dependency on
/// [ScreenUtil]** — it works anywhere you have a width constraint, including
/// inside `LayoutBuilder` callbacks.
///
/// Default breakpoints match [ScreenUtil]'s defaults:
/// `phone < 600 ≤ tablet < 1024 ≤ desktop < 1600 ≤ tv`.
///
/// ```dart
/// LayoutBuilder(
///   builder: (context, constraints) {
///     final cols = Breakpoints.value<int>(
///       width:   constraints.maxWidth,
///       phone:   1,
///       tablet:  2,
///       desktop: 3,
///     );
///     return GridView.count(crossAxisCount: cols, ...);
///   },
/// )
/// ```
abstract class Breakpoints {
  // Private constructor — utilities only.
  Breakpoints._();

  /// Default phone → tablet boundary in logical pixels.
  static const double defaultPhoneBreakpoint = 600;

  /// Default tablet → desktop boundary in logical pixels.
  static const double defaultTabletBreakpoint = 1024;

  /// Default desktop → TV boundary in logical pixels.
  static const double defaultTvBreakpoint = 1600;

  /// Returns the [DeviceType] for the given [width].
  ///
  /// Breakpoints default to [defaultPhoneBreakpoint], [defaultTabletBreakpoint],
  /// and [defaultTvBreakpoint]; pass custom values to override per call-site.
  static DeviceType deviceTypeFor(
    double width, {
    double phoneBreakpoint = defaultPhoneBreakpoint,
    double tabletBreakpoint = defaultTabletBreakpoint,
    double tvBreakpoint = defaultTvBreakpoint,
  }) {
    if (width >= tvBreakpoint) return DeviceType.tv;
    if (width >= tabletBreakpoint) return DeviceType.desktop;
    if (width >= phoneBreakpoint) return DeviceType.tablet;
    return DeviceType.phone;
  }

  /// Returns an appropriate value for the [DeviceType] inferred from [width].
  ///
  /// Fallback chain: tv → desktop → tablet → phone (required).
  ///
  /// ```dart
  /// final cols = Breakpoints.value<int>(
  ///   width:   constraints.maxWidth,
  ///   phone:   1,
  ///   tablet:  2,
  ///   desktop: 3,
  /// );
  /// ```
  static T value<T>({
    required double width,
    required T phone,
    T? tablet,
    T? desktop,
    T? tv,
    double phoneBreakpoint = defaultPhoneBreakpoint,
    double tabletBreakpoint = defaultTabletBreakpoint,
    double tvBreakpoint = defaultTvBreakpoint,
  }) {
    final dt = deviceTypeFor(
      width,
      phoneBreakpoint: phoneBreakpoint,
      tabletBreakpoint: tabletBreakpoint,
      tvBreakpoint: tvBreakpoint,
    );
    if (dt == DeviceType.tv) return tv ?? desktop ?? tablet ?? phone;
    if (dt == DeviceType.desktop) return desktop ?? tablet ?? phone;
    if (dt == DeviceType.tablet) return tablet ?? phone;
    return phone;
  }
}
