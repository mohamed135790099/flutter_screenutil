/*
 * Created by 李卓原 on 2018/9/29.
 * email: zhuoyuan93@gmail.com
 */

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

import 'dart:math' show min, max;
import 'dart:ui' as ui show FlutterView;

import 'package:flutter/widgets.dart';

typedef FontSizeResolver = double Function(num fontSize, ScreenUtil instance);

// ── Device-type enum ───────────────────────────────────────────────────────

/// Device class based on logical screen width.
///
/// Breakpoints are configurable via [ScreenUtil.configure].
/// Defaults: phone < 600 ≤ tablet < 1024 ≤ desktop < 1600 ≤ tv.
enum DeviceType { phone, tablet, desktop, tv }

// ── Legacy enum (unchanged) ────────────────────────────────────────────────

/// Original platform-based device type — kept for backwards compatibility.
enum LegacyDeviceType { mobile, tablet, web, mac, windows, linux, fuchsia }

// ─────────────────────────────────────────────────────────────────────────────
// ScreenUtil
// ─────────────────────────────────────────────────────────────────────────────

class ScreenUtil {
  static const Size defaultSize = Size(360, 690);
  static ScreenUtil _instance = ScreenUtil._();

  static bool Function() _enableScaleWH = () => true;
  static bool Function() _enableScaleText = () => true;

  // ── Design sizes (portrait) ──────────────────────────────────────────────

  /// Phone portrait design frame (required).
  late Size _portraitDesignSize;

  /// Tablet portrait design frame (optional).
  Size? _tabletDesignSize;

  /// Desktop portrait design frame (optional).
  Size? _desktopDesignSize;

  // ── Design sizes (landscape) ─────────────────────────────────────────────

  /// Phone landscape design frame.  null → auto-transpose portrait frame.
  Size? _landscapeDesignSize;

  /// Tablet landscape design frame. null → auto-transpose tablet portrait.
  Size? _tabletLandscapeDesignSize;

  /// Desktop landscape design frame. null → auto-transpose desktop portrait.
  Size? _desktopLandscapeDesignSize;

  // ── Active size (resolved each configure call) ───────────────────────────
  late Size _uiSize;

  // ── Text scale ───────────────────────────────────────────────────────────

  /// Floor for the text scale factor. Text never shrinks below this ratio.
  /// Default: 0.85 (was a hardcoded 0.5 in the original).
  double _minTextScaleFactor = 0.85;

  /// Ceiling for the text scale factor. Text never grows above this ratio.
  /// Default: 1.4.
  double _maxTextScaleFactor = 1.4;

  // ── Breakpoints ──────────────────────────────────────────────────────────

  double _phoneBreakpoint = 600;
  double _tabletBreakpoint = 1024;

  /// Width at which desktop transitions to TV.  Not currently exposed as a
  /// parameter (rare in practice) but kept as a field for future flexibility.
  static const double _tvBreakpoint = 1600;

  // ── Other ────────────────────────────────────────────────────────────────

  late Orientation _orientation;
  late bool _minTextAdapt;
  late MediaQueryData _data;
  late bool _splitScreenMode;
  FontSizeResolver? fontSizeResolver;

  ScreenUtil._();

  factory ScreenUtil() => _instance;

  // ── Scale enable ─────────────────────────────────────────────────────────

  /// Enable or disable width/height and text scaling globally.
  static void enableScale({
    bool Function()? enableWH,
    bool Function()? enableText,
  }) {
    _enableScaleWH = enableWH ?? () => true;
    _enableScaleText = enableText ?? () => true;
  }

  // ── ensureScreenSize ──────────────────────────────────────────────────────

  /// Waits until the window size has been reported by the platform.
  ///
  /// Call this once in `main()` or a splash screen before reading any
  /// ScreenUtil properties.
  static Future<void> ensureScreenSize([
    ui.FlutterView? window,
    Duration duration = const Duration(milliseconds: 10),
  ]) async {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    binding.deferFirstFrame();

    await Future.doWhile(() {
      if (window == null) {
        window = binding.platformDispatcher.implicitView;
      }

      if (window == null || window!.physicalSize.isEmpty) {
        return Future.delayed(duration, () => true);
      }

      return false;
    });

    binding.allowFirstFrame();
  }

  Set<Element>? _elementsToRebuild;

  /// ### Experimental
  /// Register current page and all its descendants to rebuild.
  /// Helpful when building for web and desktop.
  static void registerToBuild(
    BuildContext context, [
    bool withDescendants = false,
  ]) {
    (_instance._elementsToRebuild ??= {}).add(context as Element);

    if (withDescendants) {
      context.visitChildren((element) {
        registerToBuild(element, true);
      });
    }
  }

  // ── configure ─────────────────────────────────────────────────────────────

  /// Update ScreenUtil state.
  ///
  /// All parameters are optional — only provided values are updated.
  static void configure({
    MediaQueryData? data,
    // Portrait design sizes
    Size? designSize,
    Size? tabletDesignSize,
    Size? desktopDesignSize,
    // Landscape design sizes
    Size? landscapeDesignSize,
    Size? tabletLandscapeDesignSize,
    Size? desktopLandscapeDesignSize,
    // Flags
    bool? splitScreenMode,
    bool? minTextAdapt,
    // Text scale clamp
    double? minTextScaleFactor,
    double? maxTextScaleFactor,
    // Breakpoints
    double? phoneBreakpoint,
    double? tabletBreakpoint,
    // Custom resolver
    FontSizeResolver? fontSizeResolver,
  }) {
    try {
      if (data != null) {
        _instance._data = data;
      } else {
        data = _instance._data;
      }

      if (designSize != null) {
        _instance._portraitDesignSize = designSize;
      } else {
        designSize = _instance._portraitDesignSize;
      }
    } catch (_) {
      throw Exception(
        'You must either use ScreenUtil.init or ScreenUtilInit first',
      );
    }

    final MediaQueryData? deviceData = data.nonEmptySizeOrNull();
    final Size deviceSize = deviceData?.size ?? designSize;

    final orientation = deviceData?.orientation ??
        (deviceSize.width > deviceSize.height
            ? Orientation.landscape
            : Orientation.portrait);

    _instance
      ..fontSizeResolver = fontSizeResolver ?? _instance.fontSizeResolver
      .._minTextAdapt = minTextAdapt ?? _instance._minTextAdapt
      .._splitScreenMode = splitScreenMode ?? _instance._splitScreenMode
      .._orientation = orientation
      // Optional design sizes
      .._tabletDesignSize = tabletDesignSize ?? _instance._tabletDesignSize
      .._desktopDesignSize = desktopDesignSize ?? _instance._desktopDesignSize
      .._landscapeDesignSize =
          landscapeDesignSize ?? _instance._landscapeDesignSize
      .._tabletLandscapeDesignSize =
          tabletLandscapeDesignSize ?? _instance._tabletLandscapeDesignSize
      .._desktopLandscapeDesignSize =
          desktopLandscapeDesignSize ?? _instance._desktopLandscapeDesignSize
      // Text scale bounds
      .._minTextScaleFactor =
          minTextScaleFactor ?? _instance._minTextScaleFactor
      .._maxTextScaleFactor =
          maxTextScaleFactor ?? _instance._maxTextScaleFactor
      // Breakpoints
      .._phoneBreakpoint = phoneBreakpoint ?? _instance._phoneBreakpoint
      .._tabletBreakpoint = tabletBreakpoint ?? _instance._tabletBreakpoint;

    // Bug 2 fix: resolve the correct design size for this orientation +
    // device-type on every configure call, not just once at startup.
    _instance._uiSize = _instance._resolveDesignSize();

    _instance._elementsToRebuild?.forEach((el) => el.markNeedsBuild());
  }

  // ── init ─────────────────────────────────────────────────────────────────

  /// Initialise ScreenUtil inside a widget tree.
  ///
  /// Prefer using [ScreenUtilInit] at the root; call this only if you need
  /// manual control.
  static void init(
    BuildContext context, {
    Size designSize = defaultSize,
    Size? tabletDesignSize,
    Size? desktopDesignSize,
    Size? landscapeDesignSize,
    Size? tabletLandscapeDesignSize,
    Size? desktopLandscapeDesignSize,
    bool splitScreenMode = false,
    bool minTextAdapt = false,
    double minTextScaleFactor = 0.85,
    double maxTextScaleFactor = 1.4,
    double phoneBreakpoint = 600,
    double tabletBreakpoint = 1024,
    FontSizeResolver? fontSizeResolver,
  }) {
    final mq = MediaQuery.maybeOf(context);
    final view = View.maybeOf(context);
    configure(
      data: mq ?? (view != null ? MediaQueryData.fromView(view) : null),
      designSize: designSize,
      tabletDesignSize: tabletDesignSize,
      desktopDesignSize: desktopDesignSize,
      landscapeDesignSize: landscapeDesignSize,
      tabletLandscapeDesignSize: tabletLandscapeDesignSize,
      desktopLandscapeDesignSize: desktopLandscapeDesignSize,
      splitScreenMode: splitScreenMode,
      minTextAdapt: minTextAdapt,
      minTextScaleFactor: minTextScaleFactor,
      maxTextScaleFactor: maxTextScaleFactor,
      phoneBreakpoint: phoneBreakpoint,
      tabletBreakpoint: tabletBreakpoint,
      fontSizeResolver: fontSizeResolver,
    );
  }

  static Future<void> ensureScreenSizeAndInit(
    BuildContext context, {
    Size designSize = defaultSize,
    Size? tabletDesignSize,
    Size? desktopDesignSize,
    Size? landscapeDesignSize,
    Size? tabletLandscapeDesignSize,
    Size? desktopLandscapeDesignSize,
    bool splitScreenMode = false,
    bool minTextAdapt = false,
    double minTextScaleFactor = 0.85,
    double maxTextScaleFactor = 1.4,
    double phoneBreakpoint = 600,
    double tabletBreakpoint = 1024,
    FontSizeResolver? fontSizeResolver,
  }) {
    return ScreenUtil.ensureScreenSize().then((_) {
      init(
        context,
        designSize: designSize,
        tabletDesignSize: tabletDesignSize,
        desktopDesignSize: desktopDesignSize,
        landscapeDesignSize: landscapeDesignSize,
        tabletLandscapeDesignSize: tabletLandscapeDesignSize,
        desktopLandscapeDesignSize: desktopLandscapeDesignSize,
        minTextAdapt: minTextAdapt,
        splitScreenMode: splitScreenMode,
        minTextScaleFactor: minTextScaleFactor,
        maxTextScaleFactor: maxTextScaleFactor,
        phoneBreakpoint: phoneBreakpoint,
        tabletBreakpoint: tabletBreakpoint,
        fontSizeResolver: fontSizeResolver,
      );
    });
  }

  // ── Internal: design-size resolution ─────────────────────────────────────

  /// Bug 2 fix — selects the correct design frame from up to 6 registered
  /// sizes based on the current orientation and device type.
  ///
  /// Falls back gracefully when optional sizes are absent:
  /// * Landscape with no landscape frame → auto-transpose the portrait frame.
  /// * Tablet/desktop with no specific frame → falls back to the next
  ///   smaller device class.
  Size _resolveDesignSize() {
    final isLandscapeNow = _orientation == Orientation.landscape;
    final dt = _currentDeviceType();

    if (isLandscapeNow) {
      if (dt == DeviceType.desktop) {
        return _desktopLandscapeDesignSize ??
            _flipIfNotNull(_desktopDesignSize) ??
            _flipIfNotNull(_tabletDesignSize) ??
            Size(_portraitDesignSize.height, _portraitDesignSize.width);
      } else if (dt == DeviceType.tablet) {
        return _tabletLandscapeDesignSize ??
            _flipIfNotNull(_tabletDesignSize) ??
            Size(_portraitDesignSize.height, _portraitDesignSize.width);
      } else {
        return _landscapeDesignSize ??
            Size(_portraitDesignSize.height, _portraitDesignSize.width);
      }
    }

    if (dt == DeviceType.desktop) {
      return _desktopDesignSize ?? _tabletDesignSize ?? _portraitDesignSize;
    } else if (dt == DeviceType.tablet) {
      return _tabletDesignSize ?? _portraitDesignSize;
    }
    return _portraitDesignSize;
  }

  /// Swaps width and height of [s] if [s] is non-null; returns null otherwise.
  Size? _flipIfNotNull(Size? s) =>
      s == null ? null : Size(s.height, s.width);

  /// Determines device type from logical screen width and configured
  /// breakpoints.  Safe to call before [_data] is initialised (returns phone).
  DeviceType _currentDeviceType() {
    double w;
    try {
      w = screenWidth;
    } catch (_) {
      // _data not yet initialised — treat as phone.
      return DeviceType.phone;
    }
    if (w >= _tvBreakpoint) return DeviceType.tv;
    if (w >= _tabletBreakpoint) return DeviceType.desktop;
    if (w >= _phoneBreakpoint) return DeviceType.tablet;
    return DeviceType.phone;
  }

  // ── Public getters ────────────────────────────────────────────────────────

  /// Current screen orientation.
  Orientation get orientation => _orientation;

  /// `true` when the device is in landscape orientation.
  bool get isLandscape => _orientation == Orientation.landscape;

  /// `true` when the device is in portrait orientation.
  bool get isPortrait => _orientation == Orientation.portrait;

  /// Device class inferred from logical screen width.
  DeviceType get deviceType => _currentDeviceType();

  /// `true` when [screenWidth] < [_phoneBreakpoint].
  bool get isPhone => _currentDeviceType() == DeviceType.phone;

  /// `true` when [_phoneBreakpoint] ≤ [screenWidth] < [_tabletBreakpoint].
  bool get isTablet => _currentDeviceType() == DeviceType.tablet;

  /// `true` when [_tabletBreakpoint] ≤ [screenWidth] < 1600.
  bool get isDesktop => _currentDeviceType() == DeviceType.desktop;

  /// `true` when [screenWidth] ≥ 1600.
  bool get isTV => _currentDeviceType() == DeviceType.tv;

  /// The number of font pixels for each logical pixel.
  // ignore: deprecated_member_use
  double get textScaleFactor => _data.textScaleFactor;

  /// Device pixel ratio.
  double? get pixelRatio => _data.devicePixelRatio;

  /// Current device logical width (dp).
  double get screenWidth => _data.size.width;

  /// Current device logical height (dp).
  double get screenHeight => _data.size.height;

  /// Status-bar height (dp).
  double get statusBarHeight => _data.padding.top;

  /// Bottom safe-area height (dp).
  double get bottomBarHeight => _data.padding.bottom;

  /// Ratio of actual width to the active design width.
  double get scaleWidth =>
      !_enableScaleWH() ? 1 : screenWidth / _uiSize.width;

  /// Ratio of actual height to the active design height.
  double get scaleHeight => !_enableScaleWH()
      ? 1
      : (_splitScreenMode ? max(screenHeight, 700) : screenHeight) /
          _uiSize.height;

  /// Bug 1 fix — orientation-aware text scale with two-sided user clamp.
  ///
  /// When [_minTextAdapt] is `true`, picks the smaller of [scaleWidth] and
  /// [scaleHeight] (prevents landscape overscaling).  The result is then
  /// clamped to [`_minTextScaleFactor`, `_maxTextScaleFactor`].
  double get scaleText {
    if (!_enableScaleText()) return 1;
    final rawScale =
        _minTextAdapt ? min(scaleWidth, scaleHeight) : scaleWidth;
    return rawScale.clamp(_minTextScaleFactor, _maxTextScaleFactor);
  }

  // ── Adaptive value selector ───────────────────────────────────────────────

  /// Returns a different value per device type with automatic fallback.
  ///
  /// Fallback chain: tv → desktop → tablet → phone (required).
  ///
  /// ```dart
  /// final cols = ScreenUtil().adaptive<int>(phone: 1, tablet: 2, desktop: 3);
  /// final size = ScreenUtil().adaptive<double>(phone: 14.sp, desktop: 18.sp);
  /// ```
  T adaptive<T>({
    required T phone,
    T? tablet,
    T? desktop,
    T? tv,
  }) {
    final dt = _currentDeviceType();
    if (dt == DeviceType.tv) return tv ?? desktop ?? tablet ?? phone;
    if (dt == DeviceType.desktop) return desktop ?? tablet ?? phone;
    if (dt == DeviceType.tablet) return tablet ?? phone;
    return phone;
  }

  // ── Dimension helpers ─────────────────────────────────────────────────────

  /// Adapts [width] to the device width using [scaleWidth].
  double setWidth(num width) => width * scaleWidth;

  /// Adapts [height] to the device height using [scaleHeight].
  double setHeight(num height) => height * scaleHeight;

  /// Adapts [r] to the shorter of width / height (for radii and icons).
  double radius(num r) => r * min(scaleWidth, scaleHeight);

  /// Adapts [d] diagonally (scaleWidth × scaleHeight).
  double diagonal(num d) => d * scaleHeight * scaleWidth;

  /// Adapts [d] to the maximum of [scaleWidth] / [scaleHeight].
  double diameter(num d) => d * max(scaleWidth, scaleHeight);

  /// Bug 1 fix — orientation-aware font-size adaptation with two-sided clamp.
  ///
  /// If a custom [fontSizeResolver] is provided it is used directly (bypassing
  /// the clamp), preserving backwards compatibility.
  double setSp(num fontSize) =>
      fontSizeResolver?.call(fontSize, _instance) ?? fontSize * scaleText;

  // ── Spacing helpers ───────────────────────────────────────────────────────

  SizedBox setVerticalSpacing(num height) =>
      SizedBox(height: setHeight(height));

  SizedBox setVerticalSpacingFromWidth(num height) =>
      SizedBox(height: setWidth(height));

  SizedBox setHorizontalSpacing(num width) => SizedBox(width: setWidth(width));

  SizedBox setHorizontalSpacingRadius(num width) =>
      SizedBox(width: radius(width));

  SizedBox setVerticalSpacingRadius(num height) =>
      SizedBox(height: radius(height));

  SizedBox setHorizontalSpacingDiameter(num width) =>
      SizedBox(width: diameter(width));

  SizedBox setVerticalSpacingDiameter(num height) =>
      SizedBox(height: diameter(height));

  SizedBox setHorizontalSpacingDiagonal(num width) =>
      SizedBox(width: diagonal(width));

  SizedBox setVerticalSpacingDiagonal(num height) =>
      SizedBox(height: diagonal(height));

  // ── Legacy platform-based deviceType ─────────────────────────────────────

  /// Original platform-based device-type detection — kept for backwards
  /// compatibility.  Prefer [deviceType] (the new width-based enum).
  LegacyDeviceType legacyDeviceType(BuildContext context) {
    var type = LegacyDeviceType.web;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final o = MediaQuery.of(context).orientation;

    if (kIsWeb) {
      type = LegacyDeviceType.web;
    } else {
      final isMobile = defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android;
      final isTabletSize =
          (o == Orientation.portrait && w >= 600) ||
              (o == Orientation.landscape && h >= 600);

      if (isMobile) {
        type = isTabletSize ? LegacyDeviceType.tablet : LegacyDeviceType.mobile;
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        type = LegacyDeviceType.linux;
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        type = LegacyDeviceType.mac;
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        type = LegacyDeviceType.windows;
      } else if (defaultTargetPlatform == TargetPlatform.fuchsia) {
        type = LegacyDeviceType.fuchsia;
      } else {
        type = LegacyDeviceType.web;
      }
    }

    return type;
  }
}

// ── Private extension ─────────────────────────────────────────────────────

extension on MediaQueryData? {
  MediaQueryData? nonEmptySizeOrNull() {
    if (this?.size.isEmpty ?? true) {
      return null;
    }
    return this;
  }
}
