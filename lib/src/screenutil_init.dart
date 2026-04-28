import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import './_flutter_widgets.dart';
import 'debug_overlay.dart';
import 'screen_util.dart';
import 'su_mixin.dart';

typedef RebuildFactor = bool Function(MediaQueryData old, MediaQueryData data);

typedef ScreenUtilInitBuilder = Widget Function(
  BuildContext context,
  Widget? child,
);

abstract class RebuildFactors {
  static bool size(MediaQueryData old, MediaQueryData data) {
    return old.size != data.size;
  }

  static bool orientation(MediaQueryData old, MediaQueryData data) {
    return old.orientation != data.orientation;
  }

  static bool sizeAndViewInsets(MediaQueryData old, MediaQueryData data) {
    return old.viewInsets != data.viewInsets;
  }

  static bool change(MediaQueryData old, MediaQueryData data) {
    return old != data;
  }

  static bool always(MediaQueryData _, MediaQueryData __) {
    return true;
  }

  static bool none(MediaQueryData _, MediaQueryData __) {
    return false;
  }

  /// Bug 3 fix default — also fires on orientation change, not just size.
  ///
  /// This prevents a square-ish tablet from missing a rebuild when it rotates
  /// but the pixel dimensions happen to be identical.
  static bool sizeOrOrientation(MediaQueryData old, MediaQueryData data) {
    return old.size != data.size || old.orientation != data.orientation;
  }
}

abstract class FontSizeResolvers {
  static double width(num fontSize, ScreenUtil instance) {
    return instance.setWidth(fontSize);
  }

  static double height(num fontSize, ScreenUtil instance) {
    return instance.setHeight(fontSize);
  }

  static double radius(num fontSize, ScreenUtil instance) {
    return instance.radius(fontSize);
  }

  static double diameter(num fontSize, ScreenUtil instance) {
    return instance.diameter(fontSize);
  }

  static double diagonal(num fontSize, ScreenUtil instance) {
    return instance.diagonal(fontSize);
  }
}

class ScreenUtilInit extends StatefulWidget {
  /// A helper widget that initialises [ScreenUtil].
  ///
  /// Place this at the root of your widget tree, wrapping [MaterialApp] (or
  /// equivalent).  All children can then use `.w`, `.h`, `.sp`, `.r`, etc.
  ///
  /// ```dart
  /// ScreenUtilInit(
  ///   designSize: const Size(390, 844),
  ///   minTextAdapt: true,
  ///   builder: (_, child) => MaterialApp(home: child),
  ///   child: const MyApp(),
  /// )
  /// ```
  const ScreenUtilInit({
    Key? key,
    this.builder,
    this.child,
    // Bug 3 fix: new default also fires on orientation change.
    this.rebuildFactor = RebuildFactors.sizeOrOrientation,
    // ── Portrait design sizes ──────────────────────────────────────────────
    this.designSize = ScreenUtil.defaultSize,
    this.tabletDesignSize,
    this.desktopDesignSize,
    // ── Landscape design sizes ─────────────────────────────────────────────
    this.landscapeDesignSize,
    this.tabletLandscapeDesignSize,
    this.desktopLandscapeDesignSize,
    // ── Text ──────────────────────────────────────────────────────────────
    this.splitScreenMode = false,
    this.minTextAdapt = false,
    // Bug 1 fix: expose both text-scale bounds to the caller.
    this.minTextScaleFactor = 0.85,
    this.maxTextScaleFactor = 1.4,
    // ── Breakpoints ────────────────────────────────────────────────────────
    this.phoneBreakpoint = 600,
    this.tabletBreakpoint = 1024,
    // ── Scale toggles ──────────────────────────────────────────────────────
    @Deprecated(
      'useInheritedMediaQuery has no effect since the rebuild-engine rewrite. '
      'Remove this parameter — ScreenUtil now always reads from the View layer.',
    )
    this.useInheritedMediaQuery = false,
    this.ensureScreenSize = false,
    this.enableScaleWH,
    this.enableScaleText,
    // ── Widget lists ──────────────────────────────────────────────────────
    this.responsiveWidgets,
    this.excludeWidgets,
    // ── Font size resolver ────────────────────────────────────────────────
    this.fontSizeResolver,
    // ── Debug ──────────────────────────────────────────────────────────────
    this.debugShowOverlay = false,
  }) : super(key: key);

  final ScreenUtilInitBuilder? builder;
  final Widget? child;

  // ── Portrait design sizes ────────────────────────────────────────────────

  /// Phone portrait design frame (required).  Equivalent to the original
  /// `designSize` parameter — accepts the same value.
  final Size designSize;

  /// Tablet portrait design frame.  When omitted, tablet falls back to
  /// [designSize].
  final Size? tabletDesignSize;

  /// Desktop portrait design frame.  When omitted, desktop falls back to
  /// [tabletDesignSize] then [designSize].
  final Size? desktopDesignSize;

  // ── Landscape design sizes ───────────────────────────────────────────────

  /// Phone landscape design frame.  When `null`, the portrait frame is
  /// automatically transposed (width ↔ height).
  final Size? landscapeDesignSize;

  /// Tablet landscape design frame.  `null` → auto-transpose tablet portrait.
  final Size? tabletLandscapeDesignSize;

  /// Desktop landscape design frame. `null` → auto-transpose desktop portrait.
  final Size? desktopLandscapeDesignSize;

  // ── Text scale ───────────────────────────────────────────────────────────

  final bool splitScreenMode;
  final bool minTextAdapt;

  /// Text-scale floor.  Defaults to `0.85` — text never shrinks below 85 % of
  /// its design size (was hardcoded `0.5` in the original).
  final double minTextScaleFactor;

  /// Text-scale ceiling.  Defaults to `1.4` — text never grows above 140 % of
  /// its design size.
  final double maxTextScaleFactor;

  // ── Breakpoints ──────────────────────────────────────────────────────────

  /// Logical width at which phone transitions to tablet.  Default: 600 dp.
  final double phoneBreakpoint;

  /// Logical width at which tablet transitions to desktop.  Default: 1024 dp.
  final double tabletBreakpoint;

  // ── Scale toggles / misc ─────────────────────────────────────────────────

  @Deprecated(
    'useInheritedMediaQuery has no effect since the rebuild-engine rewrite. '
    'Remove this parameter — ScreenUtil now always reads from the View layer.',
  )
  final bool useInheritedMediaQuery;
  final bool ensureScreenSize;
  final bool Function()? enableScaleWH;
  final bool Function()? enableScaleText;
  final RebuildFactor rebuildFactor;

  /// Custom font-size resolver.  When provided it bypasses the built-in
  /// orientation-aware clamp, preserving backwards compatibility.
  final FontSizeResolver? fontSizeResolver;

  final Iterable<String>? responsiveWidgets;
  final Iterable<String>? excludeWidgets;

  // ── Debug ─────────────────────────────────────────────────────────────────

  /// Show a live metrics HUD (screen size, scale factors, orientation, device
  /// type, dpr, and a 16 sp sanity value) during development.
  ///
  /// Automatically disable in release builds by passing `kDebugMode`:
  /// ```dart
  /// debugShowOverlay: kDebugMode,
  /// ```
  final bool debugShowOverlay;

  @override
  State<ScreenUtilInit> createState() => _ScreenUtilInitState();
}

class _ScreenUtilInitState extends State<ScreenUtilInit>
    with WidgetsBindingObserver {
  final _canMarkedToBuild = HashSet<String>();
  final _excludedWidgets = HashSet<String>();
  MediaQueryData? _mediaQueryData;
  final _binding = WidgetsBinding.instance;
  final _screenSizeCompleter = Completer<void>();

  @override
  void initState() {
    if (widget.responsiveWidgets != null) {
      _canMarkedToBuild.addAll(widget.responsiveWidgets!);
    }
    if (widget.excludeWidgets != null) {
      _excludedWidgets.addAll(widget.excludeWidgets!);
    }

    ScreenUtil.enableScale(
      enableWH: widget.enableScaleWH,
      enableText: widget.enableScaleText,
    );

    _validateSize().then(_screenSizeCompleter.complete);

    super.initState();
    _binding.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _revalidate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _revalidate();
  }

  MediaQueryData? _newData() {
    final mq = MediaQuery.maybeOf(context);
    if (mq != null) return mq;

    final view = View.maybeOf(context);
    if (view != null) return MediaQueryData.fromView(view);
    return null;
  }

  Future<void> _validateSize() async {
    if (widget.ensureScreenSize) return ScreenUtil.ensureScreenSize();
  }

  // ── Bug 3 fix: explicit SU mixin check replaces name-heuristic ───────────

  void _markNeedsBuildIfAllowed(Element el) {
    final w = el.widget;
    // Explicit opt-out: skip widgets that implement SuExclude.
    if (w is SuExclude) return;
    final widgetName = w.runtimeType.toString();
    if (_excludedWidgets.contains(widgetName)) return;

    // Explicit opt-in: rebuild widgets marked with the SU mixin.
    final suOptIn = w is SU;

    // Legacy name-based heuristic retained as secondary path for widgets
    // that haven't been migrated to SU yet.
    final nameBasedAllow = _canMarkedToBuild.contains(widgetName) ||
        !(widgetName.startsWith('_') || flutterWidgets.contains(widgetName));

    if (suOptIn || nameBasedAllow) el.markNeedsBuild();
  }

  void _updateTree(Element el) {
    _markNeedsBuildIfAllowed(el);
    el.visitChildren(_updateTree);
  }

  void _revalidate([void Function()? callback]) {
    final oldData = _mediaQueryData;
    final newData = _newData();

    if (newData == null) return;

    if (oldData == null || widget.rebuildFactor(oldData, newData)) {
      setState(() {
        _mediaQueryData = newData;
        callback?.call();
      });
      // Walk the element tree *after* setState so we never call
      // markNeedsBuild() while a build is already scheduled for this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateTree(context as Element);
      });
    }
  }

  // ── Shared configure call ─────────────────────────────────────────────────

  void _configureScreenUtil(MediaQueryData mq) {
    ScreenUtil.configure(
      data: mq,
      // Portrait
      designSize: widget.designSize,
      tabletDesignSize: widget.tabletDesignSize,
      desktopDesignSize: widget.desktopDesignSize,
      // Landscape
      landscapeDesignSize: widget.landscapeDesignSize,
      tabletLandscapeDesignSize: widget.tabletLandscapeDesignSize,
      desktopLandscapeDesignSize: widget.desktopLandscapeDesignSize,
      // Flags
      splitScreenMode: widget.splitScreenMode,
      minTextAdapt: widget.minTextAdapt,
      // Text scale
      minTextScaleFactor: widget.minTextScaleFactor,
      maxTextScaleFactor: widget.maxTextScaleFactor,
      // Breakpoints
      phoneBreakpoint: widget.phoneBreakpoint,
      tabletBreakpoint: widget.tabletBreakpoint,
      // Resolver
      fontSizeResolver: widget.fontSizeResolver,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = _mediaQueryData;

    if (mq == null) return const SizedBox.shrink();

    if (!widget.ensureScreenSize) {
      _configureScreenUtil(mq);
      final content =
          widget.builder?.call(context, widget.child) ?? widget.child!;
      return ScreenUtilDebugOverlay(
        enabled: widget.debugShowOverlay,
        child: content,
      );
    }

    return FutureBuilder<void>(
      future: _screenSizeCompleter.future,
      builder: (_, snapshot) {
        _configureScreenUtil(mq);

        if (snapshot.connectionState == ConnectionState.done) {
          final content =
              widget.builder?.call(context, widget.child) ?? widget.child!;
          return ScreenUtilDebugOverlay(
            enabled: widget.debugShowOverlay,
            child: content,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    _binding.removeObserver(this);
    super.dispose();
  }
}
