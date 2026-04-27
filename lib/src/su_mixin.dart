/// Phase 4 — Explicit opt-in / opt-out rebuild system.
///
/// Replaces the broken widget-name heuristic with a reliable mixin-based
/// approach that works in all build modes including release (where class names
/// can be tree-shaken or mangled).
library flutter_screenutil.su_mixin;

import 'package:flutter/widgets.dart';

// ── SU mixin ──────────────────────────────────────────────────────────────

/// Opt-in mixin: mark a widget to be rebuilt whenever [ScreenUtil] detects a
/// screen-size or orientation change.
///
/// Apply [SU] to `StatelessWidget` or the *widget* class of a
/// `StatefulWidget` (not the `State`):
///
/// ```dart
/// // StatelessWidget
/// class ProductCard extends StatelessWidget with SU {
///   @override
///   Widget build(BuildContext context) {
///     return Container(
///       width:  120.w,
///       height: 80.h,
///       child:  Text('Item', style: TextStyle(fontSize: 12.sp)),
///     );
///   }
/// }
///
/// // StatefulWidget — apply only to the widget class
/// class MyWidget extends StatefulWidget with SU { ... }
/// class _MyWidgetState extends State<MyWidget> { ... }
/// ```
mixin SU on Widget {}

// ── SuExclude ─────────────────────────────────────────────────────────────

/// Opt-out marker: a widget class implementing [SuExclude] is **never**
/// rebuilt by [ScreenUtil], regardless of the name-heuristic.
///
/// Use on heavy widgets that never read [ScreenUtil] values to prevent
/// unnecessary rebuilds:
///
/// ```dart
/// class HeroImage extends StatelessWidget implements SuExclude {
///   @override
///   Widget build(BuildContext context) => Image.asset('assets/hero.png');
/// }
/// ```
/// An intentionally empty marker class. Classes that [implement] [SuExclude]
/// are never scheduled for rebuild by [ScreenUtil]'s rebuild engine.
abstract class SuExclude {}

// ── SuResponsiveWrapper ───────────────────────────────────────────────────

/// Wraps a third-party widget so it participates in [ScreenUtil]-triggered
/// rebuilds without requiring modification of the original widget class.
///
/// ```dart
/// SuResponsiveWrapper(
///   child: ThirdPartyCard(width: 200.w, fontSize: 14.sp),
/// )
/// ```
///
/// [SuResponsiveWrapper] carries the [SU] mixin, so [ScreenUtil] will always
/// include it in rebuild cycles.
class SuResponsiveWrapper extends StatelessWidget with SU {
  /// Creates a [SuResponsiveWrapper] around [child].
  const SuResponsiveWrapper({super.key, required this.child});

  /// The widget to wrap.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
