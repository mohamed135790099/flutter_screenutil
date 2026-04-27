/// Phase 4 — Live metrics HUD and [ScreenMetrics] snapshot.
///
/// [ScreenUtilDebugOverlay] is wired into [ScreenUtilInit] via the
/// `debugShowOverlay` parameter.  [ScreenMetrics] provides an immutable
/// snapshot of the current [ScreenUtil] state, useful in widget tests.
library flutter_screenutil.debug_overlay;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'screen_util.dart';

// ── ScreenMetrics ─────────────────────────────────────────────────────────

/// Immutable snapshot of [ScreenUtil]'s current state.
///
/// Capture a snapshot anywhere in the widget tree:
///
/// ```dart
/// final metrics = ScreenMetrics.current();
///
/// // Use in widget tests:
/// expect(metrics.screenWidth,  closeTo(390, 1));
/// expect(metrics.deviceType,   DeviceType.phone);
/// expect(metrics.isLandscape,  isFalse);
/// expect(metrics.scaleWidth,   closeTo(1.0, 0.05));
/// expect(metrics.sp(16),       closeTo(16.0, 0.5));
///
/// // Equality (same values → equal)
/// expect(ScreenMetrics.current(), equals(ScreenMetrics.current()));
/// ```
class ScreenMetrics {
  /// Creates a [ScreenMetrics] snapshot.
  const ScreenMetrics({
    required this.screenWidth,
    required this.screenHeight,
    required this.scaleWidth,
    required this.scaleHeight,
    required this.scaleText,
    required this.pixelRatio,
    required this.isLandscape,
    required this.deviceType,
  });

  /// Captures the current [ScreenUtil] state as an immutable [ScreenMetrics].
  factory ScreenMetrics.current() {
    final su = ScreenUtil();
    return ScreenMetrics(
      screenWidth: su.screenWidth,
      screenHeight: su.screenHeight,
      scaleWidth: su.scaleWidth,
      scaleHeight: su.scaleHeight,
      scaleText: su.scaleText,
      pixelRatio: su.pixelRatio ?? 1.0,
      isLandscape: su.isLandscape,
      deviceType: su.deviceType,
    );
  }

  final double screenWidth;
  final double screenHeight;
  final double scaleWidth;
  final double scaleHeight;
  final double scaleText;
  final double pixelRatio;
  final bool isLandscape;
  final DeviceType deviceType;

  /// Returns the scaled font size for [fontSize] using the captured [scaleText].
  ///
  /// Mirrors [ScreenUtil.setSp] at the moment of snapshot capture.
  double sp(num fontSize) => fontSize * scaleText;

  /// `true` when the captured state was in portrait orientation.
  bool get isPortrait => !isLandscape;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenMetrics &&
        other.screenWidth == screenWidth &&
        other.screenHeight == screenHeight &&
        other.scaleWidth == scaleWidth &&
        other.scaleHeight == scaleHeight &&
        other.scaleText == scaleText &&
        other.pixelRatio == pixelRatio &&
        other.isLandscape == isLandscape &&
        other.deviceType == deviceType;
  }

  @override
  int get hashCode => Object.hash(
        screenWidth,
        screenHeight,
        scaleWidth,
        scaleHeight,
        scaleText,
        pixelRatio,
        isLandscape,
        deviceType,
      );

  @override
  String toString() => 'ScreenMetrics('
      'size: ${screenWidth.toStringAsFixed(0)}×${screenHeight.toStringAsFixed(0)}, '
      'scale: ${scaleWidth.toStringAsFixed(2)}w×${scaleHeight.toStringAsFixed(2)}h, '
      'text: ${scaleText.toStringAsFixed(2)}, '
      'dpr: ${pixelRatio.toStringAsFixed(1)}, '
      '${isLandscape ? "landscape" : "portrait"}, '
      '$deviceType'
      ')';
}

// ── ScreenUtilDebugOverlay ────────────────────────────────────────────────

/// Live metrics HUD displayed in the top-left corner of the screen during
/// development.
///
/// Enable via [ScreenUtilInit.debugShowOverlay]:
///
/// ```dart
/// ScreenUtilInit(
///   debugShowOverlay: kDebugMode,   // automatically off in release builds
///   ...
/// )
/// ```
///
/// The HUD displays:
/// - Screen size (dp)
/// - Scale factors (width × height)
/// - Text scale
/// - Current orientation
/// - [DeviceType]
/// - Device pixel ratio
/// - `16.sp` resolved value (quick sanity check)
///
/// Tap the HUD to collapse it to a compact `SU` label.
class ScreenUtilDebugOverlay extends StatefulWidget {
  /// Creates a [ScreenUtilDebugOverlay].
  ///
  /// [child] is the widget tree to overlay.  Pass `enabled: false` (or keep
  /// the default) to disable in production — the overlay is a no-op and
  /// simply returns [child] when disabled.
  const ScreenUtilDebugOverlay({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  /// The widget to display beneath the HUD.
  final Widget child;

  /// Whether the HUD is shown.  Defaults to [kDebugMode].
  ///
  /// Set to `false` to disable entirely; the overlay is then a transparent
  /// passthrough that returns [child] with zero overhead.
  final bool enabled;

  @override
  State<ScreenUtilDebugOverlay> createState() => _ScreenUtilDebugOverlayState();
}

class _ScreenUtilDebugOverlayState extends State<ScreenUtilDebugOverlay> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        widget.child,
        Directionality(
          textDirection: TextDirection.ltr,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => setState(() => _collapsed = !_collapsed),
              child: _collapsed
                  ? _CollapsedHud(key: const ValueKey('su_hud_collapsed'))
                  : _ExpandedHud(key: const ValueKey('su_hud_expanded')),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Collapsed HUD ─────────────────────────────────────────────────────────

class _CollapsedHud extends StatelessWidget {
  const _CollapsedHud({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'SU',
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

// ── Expanded HUD ──────────────────────────────────────────────────────────

class _ExpandedHud extends StatelessWidget {
  const _ExpandedHud({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = ScreenMetrics.current();

    final rows = <MapEntry<String, String>>[
      MapEntry('Size', '${metrics.screenWidth.toStringAsFixed(0)}'
          ' × ${metrics.screenHeight.toStringAsFixed(0)} dp'),
      MapEntry('Scale W×H', '${metrics.scaleWidth.toStringAsFixed(3)}'
          ' × ${metrics.scaleHeight.toStringAsFixed(3)}'),
      MapEntry('Text scale', metrics.scaleText.toStringAsFixed(3)),
      MapEntry('Orientation', metrics.isLandscape ? 'landscape' : 'portrait'),
      MapEntry('Device', metrics.deviceType.name),
      MapEntry('DPR', metrics.pixelRatio.toStringAsFixed(2)),
      MapEntry('16.sp', ScreenUtil().setSp(16).toStringAsFixed(2)),
    ];

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontFamily: 'monospace',
          decoration: TextDecoration.none,
          height: 1.6,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ScreenUtil',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            for (final row in rows)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(
                      '${row.key}:',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  Text(row.value),
                ],
              ),
            const SizedBox(height: 4),
            const Text(
              'tap to collapse',
              style: TextStyle(color: Colors.grey, fontSize: 9),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
