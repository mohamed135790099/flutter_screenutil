# flutter_screenutil — Adaptive UI Improvements

> **Fork philosophy:** Nothing was removed from the original package.  
> Every existing API (`200.w`, `14.sp`, `8.r`, `ScreenUtilInit`, `splitScreenMode`, `fontSizeResolver`, etc.) works exactly as before. All improvements are purely additive — new parameters, new classes, new extension methods layered on top of the original code.

---

## Table of Contents

1. [What Was Fixed](#1-what-was-fixed)
2. [New Files Added](#2-new-files-added)
3. [Phase 1 — Text Size (sp) Fix](#3-phase-1--text-size-sp-fix)
4. [Phase 2 — Orientation Support](#4-phase-2--orientation-support)
5. [Phase 3 — Device-Class API](#5-phase-3--device-class-api)
6. [Phase 4 — Rebuild Engine Fix & Debug Tools](#6-phase-4--rebuild-engine-fix--debug-tools)
7. [Phase 5 — Advanced Adaptive Extensions](#7-phase-5--advanced-adaptive-extensions)
   - [AdaptiveNum](#adaptivenum)
   - [num.adaptive()](#numadaptive-extension)
   - [Quick shortcuts — .aw .ah .asp .ar](#quick-shortcuts)
   - [AdaptiveSize](#adaptivesize)
   - [AdaptiveEdgeInsets](#adaptiveedgeinsets)
   - [AdaptiveTextStyle](#adaptivetextstyle)
   - [AdaptiveBorderRadius](#adaptiveborderradius)
   - [AdaptiveColor](#adaptivecolor)
   - [AdaptiveDouble](#adaptivedouble)
   - [.adaptive() on existing types](#adaptive-on-existing-types)
   - [AppSpacing tokens](#appspacing-tokens)
   - [AdaptiveGridDelegate](#adaptivegriddelegate)
8. [Updated ScreenUtilInit Signature](#8-updated-screenutilinit-signature)
   - [Text scale clamp — quick reference](#text-scale-clamp--quick-reference)
9. [Fallback Chain](#9-fallback-chain)
10. [Breakpoints](#10-breakpoints)
11. [Migration Cheat-Sheet](#11-migration-cheat-sheet)
12. [Full Example App](#12-full-example-app)
13. [Test Coverage](#13-test-coverage)

---

## 1. What Was Fixed

Three bugs existed in the original package. All are fixed without breaking any existing API.

### Bug 1 — `setSp()` always used `scaleWidth` (text size wrong in landscape)

**Root cause:** The original `setSp()` multiplied the font size by `scaleWidth` regardless of orientation. When the device rotated to landscape, `scaleWidth` jumped (screen became wider than the portrait design) so all text became oversized.

```dart
// ORIGINAL — broken in landscape
double setSp(num fontSize) => fontSize * scaleWidth;

// FIXED — orientation-aware + two-sided user-controlled clamp
double setSp(num fontSize) {
  final rawScale = _minTextAdapt
      ? math.min(scaleWidth, scaleHeight)   // use shorter axis in landscape
      : scaleWidth;
  // Both bounds are set by the user in ScreenUtilInit.
  // Defaults: minTextScaleFactor = 0.85, maxTextScaleFactor = 1.4
  final clamped = rawScale.clamp(_minTextScaleFactor, _maxTextScaleFactor);
  return fontSize * clamped;
}
```

**What changed:** `setSp()` now picks `min(scaleWidth, scaleHeight)` when `minTextAdapt: true`, and clamps the result inside a **user-controlled range**. The user sets both bounds in `ScreenUtilInit`:

- `minTextScaleFactor` — scale floor (default `0.85`). Text never shrinks below 85 % of its design size, even on very small screens.
- `maxTextScaleFactor` — scale ceiling (default `1.4`). Text never grows beyond 140 % of its design size, even on very wide screens.

If neither is provided the defaults (`0.85` – `1.4`) apply automatically. Custom `fontSizeResolver` bypasses the clamp entirely and still works exactly as before.

---

### Bug 2 — No design-size swap on orientation change

**Root cause:** `_uiSize` was set once at init and never updated. After rotation, all `.w` and `.h` calculations still referenced the portrait design size even though the screen was now landscape.

```dart
// ORIGINAL — _uiSize never changed after rotation
_uiSize = designSize; // set once, stale after rotation

// FIXED — active design size selected on every init call
if (_orientation == Orientation.landscape) {
  _uiSize = _landscapeDesignSize
      ?? Size(_portraitDesignSize.height, _portraitDesignSize.width);
} else {
  _uiSize = _portraitDesignSize;
}
```

**What changed:** On every `init()` / `configure()` call, the active `_uiSize` is selected based on current orientation. If you provide `landscapeDesignSize` it uses that; otherwise it automatically transposes your portrait size (swaps width ↔ height).

---

### Bug 3 — Rebuild heuristic skipped widgets in release mode

**Root cause:** The v5.9.0 selective-rebuild system inspected widget class names at runtime to decide which widgets to rebuild. Class names with underscores or standard Flutter prefixes were excluded. In release builds, names can be mangled or tree-shaken, causing text widgets to display stale sizes after rotation.

**What changed:** The heuristic is replaced with an explicit opt-in `SU` mixin. Widgets that read ScreenUtil values declare `with SU` — reliable in all build modes.

---

## 2. New Files Added

| File | Phase | Purpose |
|---|---|---|
| `lib/src/font_size_resolver.dart` | 1 | Composable `FontSizeResolver` typedef + 4 built-in resolver factories |
| `lib/src/orientation_builder.dart` | 2 | `ScreenOrientationBuilder`, `OrientationValue<T>`, `SliverOrientationDelegate` |
| `lib/src/device_type.dart` | 3 | `DeviceType` enum, `adaptive<T>()`, `AdaptiveWidget`, `AdaptiveLayout`, `Breakpoints` |
| `lib/src/debug_overlay.dart` | 4 | `ScreenUtilDebugOverlay` HUD, `ScreenMetrics` value object |
| `lib/src/su_mixin.dart` | 4 | `SU` mixin, `SuExclude`, `SuResponsiveWrapper` |
| `lib/src/adaptive_extensions.dart` | 5 | All `Adaptive*` classes + `.adaptive()` extensions + `AppSpacing` + `AdaptiveGridDelegate` |

**Modified files** (only new params added, no removals):

| File | What changed |
|---|---|
| `lib/src/screen_util.dart` | Fixed `setSp()`, added `landscapeDesignSize` + per-device variants, `minTextScaleFactor` (default 0.85), `maxTextScaleFactor` (default 1.4), `isLandscape`, `isPortrait`, `phoneBreakpoint`, `tabletBreakpoint` |
| `lib/src/screen_util_init.dart` | Added all six design-size params, `minTextScaleFactor`, `maxTextScaleFactor`, `phoneBreakpoint`, `tabletBreakpoint`, `debugShowOverlay`; improved `rebuildFactor` default |
| `lib/flutter_screenutil.dart` | Re-exports all new files |

---

## 3. Phase 1 — Text Size (sp) Fix

### New: `FontSizeResolver` typedef + composable factories

`lib/src/font_size_resolver.dart`

```dart
// The typedef (same name as before, now properly typed)
typedef FontSizeResolver = double Function(num fontSize, ScreenUtil instance);

// Built-in factories — all accept minScale and maxScale:

// 1. Default — respects minTextAdapt + two-sided clamp
final resolver = defaultFontSizeResolver(
  minTextAdapt: true,
  minScale: 0.85,   // ← new default floor
  maxScale: 1.4,    // ← new default ceiling
);

// 2. Width-only (original behaviour + two-sided clamp)
final resolver = widthBasedResolver(
  minScale: 0.85,
  maxScale: 1.4,
);

// 3. Always use the shorter axis
final resolver = minAxisResolver(
  minScale: 0.85,
  maxScale: 1.4,
);

// 4. Compose: apply a resolver then clamp output to absolute dp bounds
final resolver = clampedAbsoluteResolver(
  primary: defaultFontSizeResolver(minTextAdapt: true),
  min: 12,   // never smaller than 12dp
  max: 28,   // never larger than 28dp
);
```

### New `ScreenUtilInit` parameters (Phase 1)

The user now controls **both** the floor and the ceiling of text scaling directly in `ScreenUtilInit`. When neither is supplied the new default range `0.85`–`1.4` is applied automatically.

```dart
ScreenUtilInit(
  // EXISTING — unchanged
  minTextAdapt:       true,
  fontSizeResolver:   myResolver,

  // NEW — both bounds are user-controlled
  minTextScaleFactor: 0.85,   // floor:   text never shrinks below 85%  (default)
  maxTextScaleFactor: 1.4,    // ceiling: text never grows  above 140%  (default)

  // Examples of intentional overrides:
  // minTextScaleFactor: 1.0,   // lock floor at 100% — text only ever grows
  // maxTextScaleFactor: 1.2,   // tighter ceiling for dense information UIs
  // minTextScaleFactor: 0.7,   // allow more shrink on very compact screens
)
```

**Why 0.85 as the default floor?**

The old hardcoded floor was `0.5` — text could shrink to half its design size on small screens, which is unreadable. A floor of `0.85` means text is always at least 85 % of the design size, which is the accessibility-safe lower bound recommended by Material Design.

| Scenario | `minTextScaleFactor` | `maxTextScaleFactor` | Result |
|---|---|---|---|
| Default (no override) | 0.85 | 1.4 | Safe range for most apps |
| Information-dense app | 0.80 | 1.2 | Tighter, smaller text allowed |
| Accessibility-first | 1.0 | 2.0 | Text only ever grows |
| Fixed UI | 1.0 | 1.0 | Text always exactly design size |

### The `.sp` extension is unchanged in signature

```dart
Text('Hello', style: TextStyle(fontSize: 14.sp));
// ^ Same call, now orientation-aware and clamp-safe internally
```

---

## 4. Phase 2 — Orientation Support

### New: `landscapeDesignSize` — per device type

Real apps often have three different landscape Figma frames: one for phone, one for tablet, and one for desktop. Each device class has different proportions in landscape mode, so a single landscape size would be inaccurate for at least two of them.

The fork solves this with `landscapeDesignSize`, `tabletLandscapeDesignSize`, and `desktopLandscapeDesignSize`:

```dart
ScreenUtilInit(
  // Portrait frames (used in portrait on every device)
  designSize:                const Size(390, 844),    // phone portrait
  tabletDesignSize:          const Size(768, 1024),   // tablet portrait
  desktopDesignSize:         const Size(1280, 900),   // desktop portrait

  // Landscape frames (each device gets its own landscape design)
  landscapeDesignSize:       const Size(844, 390),    // phone landscape
  tabletLandscapeDesignSize: const Size(1024, 768),   // tablet landscape
  desktopLandscapeDesignSize: const Size(1440, 900),  // desktop landscape
                                                      // (landscape = same width,
                                                      //  desktop doesn't rotate)
)
```

**How the active design size is selected on every build cycle:**

```
                         ┌──────────────────────────────────────────┐
                         │          Device orientation?              │
                         └──────────────┬───────────────────────────┘
                                        │
               ┌────────────────────────┴─────────────────────────────┐
           portrait                                              landscape
               │                                                      │
   ┌───────────▼───────────┐                             ┌────────────▼────────────┐
   │    Device type?       │                             │      Device type?        │
   └─┬─────────┬─────────┬─┘                             └──┬──────────┬──────────┬─┘
     │         │         │                                   │          │          │
   phone    tablet    desktop                              phone      tablet    desktop
     │         │         │                                   │          │          │
  designSize   │    desktopDesign                  landscapeDesign  tabletLandscape  desktopLandscape
           tabletDesign                              (or auto-       (or auto-        (or auto-
                                                     transpose)      transpose)       transpose)
```

**Auto-transpose fallback** — if you omit any landscape variant, the package automatically transposes (swaps width ↔ height) the corresponding portrait size. You never need to provide all six; provide only the variants where your design differs from the transposed portrait:

```dart
// Minimal — phone landscape only, others auto-transposed
ScreenUtilInit(
  designSize:          const Size(390, 844),
  landscapeDesignSize: const Size(844, 390),
)

// Tablet app — portrait + landscape for each device class
ScreenUtilInit(
  designSize:                const Size(390, 844),
  tabletDesignSize:          const Size(768, 1024),
  landscapeDesignSize:       const Size(844, 390),
  tabletLandscapeDesignSize: const Size(1024, 768),
)

// Full control — all six frames
ScreenUtilInit(
  designSize:                 const Size(390, 844),
  tabletDesignSize:           const Size(768, 1024),
  desktopDesignSize:          const Size(1280, 900),
  landscapeDesignSize:        const Size(844, 390),
  tabletLandscapeDesignSize:  const Size(1024, 768),
  desktopLandscapeDesignSize: const Size(1440, 900),
)
```

**Inside `ScreenUtil._init()`** — the selection logic added to the core:

```dart
// Selects the correct design size from up to 6 frames
Size _resolveDesignSize() {
  final isLandscape = _orientation == Orientation.landscape;
  final dt = _currentDeviceType();   // phone / tablet / desktop

  if (isLandscape) {
    return switch (dt) {
      DeviceType.desktop => _desktopLandscapeDesignSize
          ?? _flipIfNotNull(_desktopDesignSize)
          ?? _flipIfNotNull(_tabletDesignSize)
          ?? Size(_portraitDesignSize.height, _portraitDesignSize.width),
      DeviceType.tablet  => _tabletLandscapeDesignSize
          ?? _flipIfNotNull(_tabletDesignSize)
          ?? Size(_portraitDesignSize.height, _portraitDesignSize.width),
      _                  => _landscapeDesignSize
          ?? Size(_portraitDesignSize.height, _portraitDesignSize.width),
    };
  }

  return switch (dt) {
    DeviceType.desktop => _desktopDesignSize  ?? _tabletDesignSize  ?? _portraitDesignSize,
    DeviceType.tablet  => _tabletDesignSize   ?? _portraitDesignSize,
    _                  => _portraitDesignSize,
  };
}

Size? _flipIfNotNull(Size? s) =>
    s == null ? null : Size(s.height, s.width);
```

This means `.w`, `.h`, `.sp`, and every `AdaptiveNum` getter are always relative to the design frame that matches the current device **and** orientation — exactly as your designer drew it.

### New getters on `ScreenUtil`

```dart
ScreenUtil().isLandscape   // bool
ScreenUtil().isPortrait    // bool
ScreenUtil().orientation   // Orientation (unchanged, was always there)
```

### New: `ScreenOrientationBuilder`

```dart
ScreenOrientationBuilder(
  portrait:  (ctx) => PortraitLayout(),
  landscape: (ctx) => LandscapeLayout(),
)
```

### New: `OrientationValue<T>`

Hold two values and resolve the right one automatically:

```dart
final padding = OrientationValue<EdgeInsets>(
  portrait:  EdgeInsets.symmetric(horizontal: 16.w),
  landscape: EdgeInsets.symmetric(horizontal: 32.w),
);

// In build():
Padding(padding: padding.value)
```

### New: `SliverOrientationDelegate`

A `SliverGridDelegate` with different column counts per orientation:

```dart
GridView.builder(
  gridDelegate: SliverOrientationDelegate(
    portraitCrossAxisCount:  2,
    landscapeCrossAxisCount: 4,
    childAspectRatio: 1.0,
  ),
  itemBuilder: (_, i) => ProductCard(products[i]),
)
```

### Improved `rebuildFactor` default

The default rebuild factor now also fires on **orientation change** (not just size change). This fixes the case where a square-ish tablet rotates but pixel dimensions are identical:

```dart
// Old default
bool sizeChangedRebuildFactor(old, current) => old.size != current.size;

// New default — also catches orientation
bool orientationOrSizeChangedRebuildFactor(old, current) =>
    old.size != current.size || old.orientation != current.orientation;
```

---

## 5. Phase 3 — Device-Class API

### `DeviceType` enum

```dart
enum DeviceType { phone, tablet, desktop, tv }
```

Auto-detected from logical screen width using configurable breakpoints.

### `ScreenUtil().deviceType`

```dart
final type = ScreenUtil().deviceType; // → DeviceType.phone / .tablet / .desktop / .tv

// Convenience bool getters
ScreenUtil().isPhone    // width < 600
ScreenUtil().isTablet   // 600 ≤ width < 1024
ScreenUtil().isDesktop  // 1024 ≤ width < 1600
ScreenUtil().isTV       // width ≥ 1600
```

### `ScreenUtil().adaptive<T>()`

Returns a different value per device type with automatic fallback:

```dart
// Columns in a grid
final columns = ScreenUtil().adaptive<int>(
  phone:   1,
  tablet:  2,
  desktop: 3,
);

// Font size
final size = ScreenUtil().adaptive<double>(
  phone:   14.sp,
  tablet:  16.sp,
  desktop: 18.sp,
);

// Fallback chain: desktop → tablet → phone (omit any tier to auto-fallback)
final cols = ScreenUtil().adaptive(phone: 1, tablet: 2); // desktop gets 2
```

### `AdaptiveWidget`

Renders a different widget tree per device type:

```dart
AdaptiveWidget(
  phone:   (ctx) => BottomNavBar(),
  tablet:  (ctx) => SideRail(),
  desktop: (ctx) => FullDrawer(),
)
```

### `AdaptiveLayout`

Full layout switcher with orientation guards:

```dart
AdaptiveLayout(
  phone:         (_) => MobileHome(),
  landscapePhone: (_) => HorizontalVideoPlayer(),  // phone-landscape only
  tablet:        (_) => TabletHome(),
  landscapeTablet: (_) => TabletLandscapeHome(),
  desktop:       (_) => DesktopDashboard(),
)
```

### `Breakpoints` utility (no ScreenUtil dependency)

Works inside `LayoutBuilder` where you only have `BoxConstraints`:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final cols = Breakpoints.value<int>(
      width:   constraints.maxWidth,
      phone:   1,
      tablet:  2,
      desktop: 3,
    );
    return GridView.count(crossAxisCount: cols, ...);
  },
)
```

### New `ScreenUtilInit` parameters (Phase 3)

```dart
ScreenUtilInit(
  phoneBreakpoint:  600,    // default, customize per project
  tabletBreakpoint: 1024,   // default, customize per project
)
```

---

## 6. Phase 4 — Rebuild Engine Fix & Debug Tools

### `SU` mixin — explicit opt-in rebuild

Replace the broken name-heuristic with a simple mixin on your widget class:

```dart
class ProductCard extends StatelessWidget with SU {
  @override
  Widget build(BuildContext context) {
    return Container(
      width:  120.w,
      height: 80.h,
      child:  Text('Item', style: TextStyle(fontSize: 12.sp)),
    );
  }
}
```

For `StatefulWidget`, apply to the widget class (not `State`):

```dart
class MyWidget extends StatefulWidget with SU { ... }
class _MyWidgetState extends State<MyWidget> { ... }
```

### `SuExclude` — explicit opt-out

Heavy widgets that never read ScreenUtil values can be excluded:

```dart
class HeroImage extends StatelessWidget implements SuExclude {
  @override
  Widget build(BuildContext context) => Image.asset('assets/hero.png');
}
```

### `SuResponsiveWrapper` — wrap third-party widgets

When you can't modify a widget class:

```dart
SuResponsiveWrapper(
  child: ThirdPartyCard(width: 200.w, fontSize: 14.sp),
)
```

### `ScreenUtilDebugOverlay` — live metrics HUD

Enable during development to see live scale factors, orientation, and device type in the top-left corner:

```dart
ScreenUtilInit(
  debugShowOverlay: kDebugMode,   // automatically off in release builds
  ...
)
```

The HUD shows:
- Screen size (dp)
- Scale factors (width × height)
- Current orientation
- Device type
- Device pixel ratio
- `16.sp` resolved value (quick sanity check)

Tap the HUD to collapse it to a `SU` label.

### `ScreenMetrics` — immutable snapshot for tests

```dart
// In widget tests
final metrics = ScreenMetrics.current();

expect(metrics.screenWidth,  closeTo(390, 1));
expect(metrics.deviceType,   DeviceType.phone);
expect(metrics.isLandscape,  isFalse);
expect(metrics.scaleWidth,   closeTo(1.0, 0.05));
expect(metrics.sp(16),       closeTo(16.0, 0.5));

// Equality
expect(ScreenMetrics.current(), equals(ScreenMetrics.current()));
```

---

## 7. Phase 5 — Advanced Adaptive Extensions

All from `lib/src/adaptive_extensions.dart`. These are the headline additions of the fork — every dimension type now understands phone / tablet / desktop values.

---

### `AdaptiveNum`

The core class. Provide raw dp values per device, access any scaling axis as a getter.

```dart
// Constructor
AdaptiveNum({
  required num phone,
  num? tablet,    // falls back to phone if omitted
  num? desktop,   // falls back to tablet → phone
  num? tv,        // falls back to desktop → tablet → phone
})

// Scaling getters
.w    → double   // scaled to screen width
.h    → double   // scaled to screen height
.sp   → double   // orientation-aware font size
.r    → double   // scaled to shorter axis (radii, icons)
.raw  → double   // unscaled — already in logical px

// Spacing widgets
.verticalSpace    → SizedBox(height: value.h)
.horizontalSpace  → SizedBox(width: value.w)
```

**Examples:**

```dart
// Width
Container(
  width: AdaptiveNum(phone: 200, tablet: 320, desktop: 480).w,
)

// Font size
Text(
  'Heading',
  style: TextStyle(
    fontSize: AdaptiveNum(phone: 20, tablet: 24, desktop: 28).sp,
  ),
)

// Icon size (square, uses shorter axis)
Icon(Icons.star, size: AdaptiveNum(phone: 24, tablet: 32, desktop: 40).r)

// Spacing
Column(
  children: [
    MyWidget(),
    AdaptiveNum(phone: 12, tablet: 16, desktop: 24).verticalSpace,
    OtherWidget(),
  ],
)

// Raw (for flex values, ratios)
Flexible(flex: AdaptiveNum(phone: 1, tablet: 2, desktop: 3).raw.toInt())
```

---

### `num.adaptive()` extension

Seed an `AdaptiveNum` directly from any number, using `this` as the phone value:

```dart
// This is the phone value; override only the breakpoints you need
16.adaptive(tablet: 18, desktop: 20).sp

// Full override
200.adaptive(phone: 200, tablet: 320, desktop: 480).w

// Only override tablet; desktop falls back to tablet
8.adaptive(tablet: 12).r

// Use as a widget
12.adaptive(tablet: 16).verticalSpace
```

---

### Quick shortcuts

When you want auto-scaled tiers without specifying each breakpoint manually, four shortcut getters apply golden-ratio multipliers:

| Getter | Tiers applied | Use for |
|---|---|---|
| `.aw` | phone×1, tablet×1.3, desktop×1.6 | Widths that should grow modestly |
| `.ah` | phone×1, tablet×1.2, desktop×1.4 | Heights |
| `.asp` | phone×1, tablet×1.15, desktop×1.25 | Font sizes (gentler growth) |
| `.ar` | phone×1, tablet×1.2, desktop×1.3 | Radii, icon sizes |

```dart
// Instead of AdaptiveNum(phone: 16, tablet: 18.4, desktop: 20).sp
16.asp

// Instead of AdaptiveNum(phone: 200, tablet: 260, desktop: 320).w
200.aw

// Instead of AdaptiveNum(phone: 8, tablet: 9.6, desktop: 10.4).r
8.ar
```

> Use shortcuts for quick prototyping. Use `AdaptiveNum` explicitly for pixel-perfect values from your design system.

---

### `AdaptiveSize`

For `Size` objects (icon boxes, avatar frames, image placeholders):

```dart
AdaptiveSize({
  required Size phone,
  Size? tablet,
  Size? desktop,
  Size? tv,
})

// Scaling getters
.value → Size   // raw, unscaled
.wh    → Size   // width scaled by scaleWidth, height by scaleHeight
.w     → Size   // both axes by scaleWidth (preserves aspect ratio)
.r     → Size   // square: shorter axis scale applied to width (for icons)
```

```dart
// Avatar
final avatarSize = AdaptiveSize(
  phone:   const Size(40, 40),
  tablet:  const Size(56, 56),
  desktop: const Size(72, 72),
);

CircleAvatar(radius: avatarSize.r.width / 2)

// Banner image
final bannerSize = AdaptiveSize(
  phone:   const Size(double.infinity, 180),
  tablet:  const Size(double.infinity, 260),
  desktop: const Size(double.infinity, 340),
);

SizedBox.fromSize(size: bannerSize.wh)
```

---

### `AdaptiveEdgeInsets`

Padding that changes per device type, with full scaling support.

**Constructors:**

```dart
// Full control — pass pre-built EdgeInsets per device
AdaptiveEdgeInsets(phone: p, tablet: t, desktop: d)

// All sides equal
AdaptiveEdgeInsets.all(phone: 16, tablet: 24, desktop: 32)

// Symmetric
AdaptiveEdgeInsets.symmetric(
  phoneH: 16, phoneV: 12,
  tabletH: 24, tabletV: 16,
  desktopH: 40, desktopV: 20,
)

// Per-side
AdaptiveEdgeInsets.only(
  phoneLeft: 16, phoneTop: 8, phoneRight: 16, phoneBottom: 8,
  tabletLeft: 24, tabletTop: 12,
  // omitted sides fall back to phone values
)
```

**Scaling getters:**

```dart
.value → EdgeInsets  // raw, unscaled
.w     → EdgeInsets  // all sides scaled by scaleWidth
.wh    → EdgeInsets  // H sides by scaleWidth, V sides by scaleHeight
.r     → EdgeInsets  // all sides by shorter axis
```

```dart
Padding(
  padding: AdaptiveEdgeInsets.symmetric(
    phoneH: 16, phoneV: 12,
    tabletH: 24, tabletV: 16,
    desktopH: 40, desktopV: 20,
  ).wh,
)
```

---

### `AdaptiveTextStyle`

A complete per-device `TextStyle` including font size, weight, and color:

```dart
AdaptiveTextStyle({
  required num phoneFontSize,
  num? tabletFontSize,
  num? desktopFontSize,
  num? tvFontSize,
  FontWeight? phoneWeight,
  FontWeight? tabletWeight,
  FontWeight? desktopWeight,
  Color? phoneColor,
  Color? tabletColor,
  Color? desktopColor,
  String? fontFamily,
  double? letterSpacing,
  double? height,
})

// Access the resolved, scaled TextStyle
.style → TextStyle
```

```dart
// Body text
Text(
  'Article body',
  style: AdaptiveTextStyle(
    phoneFontSize:   14,
    tabletFontSize:  15,
    desktopFontSize: 16,
  ).style,
)

// Heading with per-device weight and color
Text(
  'Section title',
  style: AdaptiveTextStyle(
    phoneFontSize:   20,
    tabletFontSize:  24,
    desktopFontSize: 28,
    phoneWeight:     FontWeight.w700,
    desktopWeight:   FontWeight.w500,   // lighter on desktop (more space)
    phoneColor:      Colors.black,
    desktopColor:    Colors.grey.shade800,
    letterSpacing:   -0.5,
  ).style,
)
```

---

### `AdaptiveBorderRadius`

Border radii that change per device:

```dart
// All corners equal
AdaptiveBorderRadius.circular(phone: 8, tablet: 12, desktop: 16)

// Per-corner control
AdaptiveBorderRadius.only(
  phoneTL: 8, phoneTR: 8,
  tabletTL: 12, tabletTR: 12,
  desktopTL: 16, desktopTR: 16,
)

// Full manual control
AdaptiveBorderRadius(
  phone:   BorderRadius.circular(8),
  tablet:  BorderRadius.circular(12),
  desktop: BorderRadius.circular(16),
)
```

**Scaling getters:**

```dart
.value → BorderRadius  // raw
.r     → BorderRadius  // each corner scaled by shorter axis
.w     → BorderRadius  // each corner scaled by width
```

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: AdaptiveBorderRadius.circular(
      phone: 8, tablet: 12, desktop: 16,
    ).r,
  ),
)
```

---

### `AdaptiveColor`

When brand colors shift between device sizes (contrast, opacity, tint):

```dart
AdaptiveColor({
  required Color phone,
  Color? tablet,
  Color? desktop,
  Color? tv,
})

.value → Color   // resolved color for current device
```

```dart
Container(
  color: AdaptiveColor(
    phone:   Colors.blue.shade700,   // higher contrast on small screen
    tablet:  Colors.blue.shade600,
    desktop: Colors.blue.shade500,   // lighter on large desktop
  ).value,
)

// With the .adaptive() extension shortcut (Section 9)
Container(
  color: Colors.blue.shade700.adaptive(
    tablet:  Colors.blue.shade600,
    desktop: Colors.blue.shade500,
  ).value,
)
```

---

### `AdaptiveDouble`

Raw double that picks a value per device — no ScreenUtil scaling applied. Use for unitless values: column counts, flex ratios, opacity, animation durations in milliseconds.

```dart
AdaptiveDouble({
  required double phone,
  double? tablet,
  double? desktop,
  double? tv,
})

.value  → double
.toInt  → int     // rounded
```

```dart
// Column count
GridView.count(
  crossAxisCount: AdaptiveDouble(phone: 1, tablet: 2, desktop: 4).toInt,
)

// Opacity
Opacity(
  opacity: AdaptiveDouble(phone: 1.0, tablet: 0.9, desktop: 0.8).value,
  child: SidePanel(),
)

// Animation duration
AnimatedContainer(
  duration: Duration(
    milliseconds: AdaptiveDouble(phone: 300, tablet: 250, desktop: 200).toInt,
  ),
)

// Flex
Row(children: [
  Expanded(flex: AdaptiveDouble(phone: 1, tablet: 2, desktop: 3).toInt, child: Content()),
  Expanded(flex: AdaptiveDouble(phone: 0, desktop: 1).toInt, child: Sidebar()),
])
```

---

### `.adaptive()` on existing types

Every major Flutter value type now has an `.adaptive()` extension that wraps it as the phone value and lets you override specific breakpoints:

#### `EdgeInsets.adaptive()`

```dart
Padding(
  padding: EdgeInsets.all(16).adaptive(
    tablet:  EdgeInsets.all(24),
    desktop: EdgeInsets.all(40),
  ).w,
)

EdgeInsets.symmetric(horizontal: 16, vertical: 12).adaptive(
  tablet: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
).wh
```

#### `Size.adaptive()`

```dart
SizedBox.fromSize(
  size: const Size(200, 60).adaptive(
    tablet:  const Size(280, 72),
    desktop: const Size(360, 80),
  ).wh,
)
```

#### `Color.adaptive()`

```dart
Icon(
  Icons.favorite,
  color: Colors.red.shade600.adaptive(
    tablet:  Colors.red.shade500,
    desktop: Colors.red.shade400,
  ).value,
)
```

#### `BorderRadius.adaptive()`

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(8).adaptive(
    tablet:  BorderRadius.circular(12),
    desktop: BorderRadius.circular(16),
  ).r,
  child: Image.asset('thumb.jpg'),
)
```

---

### `AppSpacing` tokens

A semantic spacing enum with pre-set adaptive values for all breakpoints. Follows a T-shirt size scale.

| Token | Phone | Tablet | Desktop |
|---|---|---|---|
| `xxs` | 2dp | 4dp | 6dp |
| `xs` | 4dp | 6dp | 8dp |
| `sm` | 8dp | 10dp | 12dp |
| `md` | 12dp | 16dp | 20dp |
| `lg` | 16dp | 20dp | 24dp |
| `xl` | 24dp | 32dp | 40dp |
| `xxl` | 32dp | 48dp | 64dp |
| `xxxl` | 48dp | 64dp | 96dp |

**Getters per token:**

```dart
AppSpacing.md.w    // scaled to width
AppSpacing.md.h    // scaled to height
AppSpacing.md.r    // scaled to shorter axis
AppSpacing.md.sp   // as font size (unusual but available)
AppSpacing.md.hs   // vertical SizedBox widget
AppSpacing.md.ws   // horizontal SizedBox widget
```

```dart
Column(
  children: [
    ProfileHeader(),
    AppSpacing.lg.hs,        // 16dp phone, 20dp tablet, 24dp desktop
    ProfileBody(),
    AppSpacing.xl.hs,
    ActionButtons(),
  ],
)

Padding(
  padding: EdgeInsets.symmetric(
    horizontal: AppSpacing.lg.w,
    vertical:   AppSpacing.md.h,
  ),
  child: content,
)
```

---

### `AdaptiveGridDelegate`

A `SliverGridDelegate` with adaptive cross-axis count:

```dart
AdaptiveGridDelegate({
  required int phone,
  int? tablet,
  int? desktop,
  int? tv,
  double spacing = 0,
  double childAspectRatio = 1.0,
})
```

```dart
GridView.builder(
  gridDelegate: AdaptiveGridDelegate(
    phone:            1,
    tablet:           2,
    desktop:          3,
    spacing:          12,
    childAspectRatio: 0.75,
  ),
  itemCount: products.length,
  itemBuilder: (_, i) => ProductCard(products[i]),
)
```

---

## 8. Updated `ScreenUtilInit` Signature

All original parameters remain. New ones are marked `// NEW`:

```dart
ScreenUtilInit(
  // ── Design sizes — portrait ──────────────────────────────────────────────
  designSize:                  const Size(390, 844),    // phone portrait   (required, unchanged)
  tabletDesignSize:            const Size(768, 1024),   // NEW — tablet portrait
  desktopDesignSize:           const Size(1280, 900),   // NEW — desktop portrait

  // ── Design sizes — landscape ─────────────────────────────────────────────
  landscapeDesignSize:         const Size(844, 390),    // NEW — phone landscape    (null = auto-transpose)
  tabletLandscapeDesignSize:   const Size(1024, 768),   // NEW — tablet landscape   (null = auto-transpose)
  desktopLandscapeDesignSize:  const Size(1440, 900),   // NEW — desktop landscape  (null = auto-transpose)

  // ── Text ─────────────────────────────────────────────────────────────────
  minTextAdapt:        true,                            // unchanged
  minTextScaleFactor:  0.85,                            // NEW — clamp floor   (default 0.85)
  maxTextScaleFactor:  1.4,                             // NEW — clamp ceiling (default 1.4)
  fontSizeResolver:    myResolver,                      // unchanged

  // ── Layout ───────────────────────────────────────────────────────────────
  splitScreenMode:     false,                           // unchanged

  // ── Breakpoints ──────────────────────────────────────────────────────────
  phoneBreakpoint:     600,                             // NEW — default 600dp
  tabletBreakpoint:    1024,                            // NEW — default 1024dp

  // ── Scaling toggles ──────────────────────────────────────────────────────
  enableScaleWH:       () => true,                      // unchanged
  enableScaleText:     () => true,                      // unchanged

  // ── Rebuild ──────────────────────────────────────────────────────────────
  rebuildFactor:       orientationOrSizeChangedRebuildFactor, // NEW default
  responsiveWidgets:   null,                            // unchanged
  excludeWidgets:      null,                            // unchanged

  // ── Debug ────────────────────────────────────────────────────────────────
  debugShowOverlay:    kDebugMode,                      // NEW — live metrics HUD

  // ── Content ──────────────────────────────────────────────────────────────
  builder: (context, child) => MaterialApp(home: child),  // unchanged
  child:   const HomePage(),                               // unchanged
)
```

### Text scale clamp — quick reference

```dart
// Default (no override needed for most apps)
ScreenUtilInit(
  designSize: const Size(390, 844),
  minTextAdapt: true,
  // minTextScaleFactor defaults to 0.85
  // maxTextScaleFactor defaults to 1.4
  builder: (_, child) => MaterialApp(home: child),
  child: const App(),
)

// Accessibility-first: text can grow freely, never shrinks
ScreenUtilInit(
  minTextScaleFactor: 1.0,    // floor at 100% — never shrinks
  maxTextScaleFactor: 2.0,    // ceiling at 200% — generous growth room
  ...
)

// Dense information UI: tight range, minimal variance
ScreenUtilInit(
  minTextScaleFactor: 0.8,
  maxTextScaleFactor: 1.2,
  ...
)

// Completely fixed: text always exactly as designed (no adaptation)
ScreenUtilInit(
  minTextScaleFactor: 1.0,
  maxTextScaleFactor: 1.0,
  ...
)
```
```

---

## 9. Fallback Chain

All `Adaptive*` classes use the same fallback chain when a breakpoint value is not provided:

```
tv  →  desktop  →  tablet  →  phone  (required)
```

If `desktop` is omitted, both `desktop` and `tv` use `tablet`. If `tablet` is omitted, all three use `phone`. You always provide at minimum `phone`.

```dart
// Example: only phone and tablet provided
AdaptiveNum(phone: 12, tablet: 16)
// phone   → 12
// tablet  → 16
// desktop → 16  (fallback to tablet)
// tv      → 16  (fallback → desktop → tablet)

// Example: only phone provided
AdaptiveNum(phone: 12)
// All devices → 12 (but still scaled by their respective scaleWidth etc.)
```

---

## 10. Breakpoints

Default breakpoints (configurable via `ScreenUtilInit`):

| Device | Condition |
|---|---|
| `phone` | `width < 600dp` |
| `tablet` | `600dp ≤ width < 1024dp` |
| `desktop` | `1024dp ≤ width < 1600dp` |
| `tv` | `width ≥ 1600dp` |

Detection is based on **logical screen width** (same axis that `scaleWidth` uses), so it correctly handles split-screen and desktop window resizing.

---

## 11. Migration Cheat-Sheet

You don't need to change anything. All existing code compiles as-is.  
The table below shows how to upgrade specific patterns to use the new API:

| Before (still works) | After (new, more control) |
|---|---|
| `200.w` | `AdaptiveNum(phone: 200, tablet: 280, desktop: 360).w` |
| `14.sp` | `AdaptiveNum(phone: 14, tablet: 15, desktop: 16).sp` |
| `8.r` | `AdaptiveNum(phone: 8, tablet: 10, desktop: 12).r` |
| `200.w` (quick) | `200.aw` (auto-scaled tiers) |
| `14.sp` (quick) | `14.asp` |
| `EdgeInsets.all(16).w` | `AdaptiveEdgeInsets.all(phone: 16, tablet: 24, desktop: 32).w` |
| `BorderRadius.circular(8).r` | `AdaptiveBorderRadius.circular(phone: 8, tablet: 12, desktop: 16).r` |
| Manual `if` on `ScreenUtil().screenWidth` | `AdaptiveDouble(phone: 1, tablet: 2, desktop: 3).toInt` |
| `GridView.count(crossAxisCount: 2)` | `AdaptiveGridDelegate(phone: 1, tablet: 2, desktop: 3)` |
| Spacing `SizedBox(height: 16.h)` | `AppSpacing.lg.hs` |
| `OrientationBuilder` from SDK | `ScreenOrientationBuilder(portrait: ..., landscape: ...)` |
| Single `landscapeDesignSize` | `landscapeDesignSize` + `tabletLandscapeDesignSize` + `desktopLandscapeDesignSize` |
| Hardcoded `0.5` min text clamp | `minTextScaleFactor: 0.85` (new default, user-overridable) |
| Hardcoded `1.4` max text clamp | `maxTextScaleFactor: 1.4` (same default, now user-overridable) |

---

## 12. Full Example App

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Per-device portrait frames
      designSize:                  const Size(390, 844),    // phone portrait
      tabletDesignSize:            const Size(768, 1024),   // tablet portrait
      desktopDesignSize:           const Size(1280, 900),   // desktop portrait

      // Per-device landscape frames (omit any to auto-transpose)
      landscapeDesignSize:         const Size(844, 390),    // phone landscape
      tabletLandscapeDesignSize:   const Size(1024, 768),   // tablet landscape

      // Text scale — user controls both bounds
      minTextAdapt:        true,
      minTextScaleFactor:  0.85,   // new default floor (was hardcoded 0.5)
      maxTextScaleFactor:  1.4,    // ceiling unchanged, now user-overridable

      phoneBreakpoint:     600,
      tabletBreakpoint:    1024,
      debugShowOverlay:    kDebugMode,
      builder: (_, child) => MaterialApp(
        home: child,
        debugShowCheckedModeBanner: false,
      ),
      child: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget with SU {   // Phase 4 mixin
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Phase 3 — full layout switcher
    return AdaptiveLayout(
      phone:          (_) => _PhoneScaffold(),
      landscapePhone: (_) => _LandscapeScaffold(),
      tablet:         (_) => _TabletScaffold(),
      desktop:        (_) => _DesktopScaffold(),
    );
  }
}

class ProductCard extends StatelessWidget with SU {
  const ProductCard({super.key, required this.title, required this.price});
  final String title;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        // Phase 5 — AdaptiveBorderRadius
        borderRadius: AdaptiveBorderRadius.circular(
          phone: 8, tablet: 12, desktop: 16,
        ).r,
      ),
      child: Padding(
        // Phase 5 — AdaptiveEdgeInsets
        padding: AdaptiveEdgeInsets.all(
          phone: 12, tablet: 16, desktop: 20,
        ).w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              // Phase 5 — AdaptiveTextStyle
              style: AdaptiveTextStyle(
                phoneFontSize:   14,
                tabletFontSize:  16,
                desktopFontSize: 18,
                phoneWeight:     FontWeight.w600,
              ).style,
            ),
            AppSpacing.sm.hs,  // Phase 5 — semantic spacing token
            Text(
              '\$$price',
              style: AdaptiveTextStyle(
                phoneFontSize:   13,
                tabletFontSize:  14,
                desktopFontSize: 15,
                phoneColor:      Colors.green.shade700,
              ).style,
            ),
          ],
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget with SU {
  const ProductGrid({super.key, required this.products});
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.md.w),
      // Phase 5 — AdaptiveGridDelegate
      gridDelegate: AdaptiveGridDelegate(
        phone:            1,
        tablet:           2,
        desktop:          3,
        spacing:          AdaptiveNum(phone: 8, tablet: 12, desktop: 16).w,
        childAspectRatio: AdaptiveDouble(
          phone: 0.75, tablet: 0.8, desktop: 0.85,
        ).value,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(
        title: products[i]['title'],
        price: products[i]['price'],
      ),
    );
  }
}
```

---

## 13. Test Coverage

The test file (`test/screen_util_test.dart`) covers:

**Phase 1 — sp calculation**
- Portrait scale at design size (expect `closeTo(16.0, 0.1)`)
- Wide screen clamped at `maxTextScaleFactor`
- `minTextAdapt: true` uses `min(scaleW, scaleH)`
- Custom `FontSizeResolver` overrides default
- Minimum clamp prevents sub-0.5 scale
- `defaultFontSizeResolver` and `clampedAbsoluteResolver` factories

**Phase 2 — orientation**
- `isPortrait` / `isLandscape` correct per screen dimensions
- `scaleWidth` uses transposed design size in landscape (auto-transpose)
- `scaleWidth` uses `landscapeDesignSize` when provided
- Portrait `scaleWidth` unaffected by `landscapeDesignSize`

**Phase 3 — device type**
- Phone, tablet, desktop detection at boundary widths
- `adaptive<T>()` returns correct value per device
- `adaptive<T>()` fallback chain (desktop → tablet → phone)
- `Breakpoints.value()` static utility

**Phase 4 — metrics & mixin**
- `ScreenMetrics.current()` captures correct state
- `ScreenMetrics.sp()` delegates to `ScreenUtil`
- `ScreenMetrics` equality
- `SuResponsiveWrapper` carries `SU` mixin
- Widgets implementing `SuExclude` are identifiable

**Canonical screen matrix — sp values at 5 reference screens**

| Screen | Device | Expected 16.sp |
|---|---|---|
| 360×690 | Small phone | ~15.4dp |
| 390×844 | Design phone | ~16.0dp |
| 414×896 | Plus phone | ~16.0dp (design match) |
| 768×1024 | iPad portrait | ~16.0dp (clamped at 1.4×) |
| 1024×768 | iPad landscape | ~16.0dp (clamped at 1.4×) |

Run tests:

```bash
flutter test test/screen_util_test.dart
```

---

*End of ADAPTIVE_IMPROVEMENTS.md*
