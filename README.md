# flutter_screenutil

[![Flutter Package](https://img.shields.io/pub/v/flutter_screenutil.svg)](https://pub.dev/packages/flutter_screenutil)
[![Pub Points](https://img.shields.io/pub/points/flutter_screenutil)](https://pub.dev/packages/flutter_screenutil/score)
[![Popularity](https://img.shields.io/pub/popularity/flutter_screenutil)](https://pub.dev/packages/flutter_screenutil/score)
[![CodeFactor](https://www.codefactor.io/repository/github/openflutter/flutter_screenutil/badge)](https://www.codefactor.io/repository/github/openflutter/flutter_screenutil)

**A Flutter plugin for adapting screen and font size. Your UI displays a reasonable layout on every screen — phone, tablet, and desktop.**

> **Fully additive.** Every existing API (`200.w`, `14.sp`, `8.r`, `ScreenUtilInit`, etc.) works exactly as before. All improvements are new parameters and new classes layered on top — no breaking changes.

---

## Table of Contents

1. [Installation](#1-installation)
2. [Quick Start](#2-quick-start)
3. [What Was Fixed](#3-what-was-fixed)
4. [ScreenUtilInit — Full Parameter Reference](#4-screenutilinit--full-parameter-reference)
5. [Core API (unchanged)](#5-core-api-unchanged)
6. [Orientation Support](#6-orientation-support)
7. [Device-Class API](#7-device-class-api)
8. [Debug HUD](#8-debug-hud)
9. [Phase 5 — Adaptive Extensions](#9-phase-5--adaptive-extensions)
   - [AdaptiveNum](#adaptivenum)
   - [num.adaptive() quick shortcut](#numadaptive-quick-shortcut)
   - [Auto-scaled shortcuts — .aw .ah .asp .ar](#auto-scaled-shortcuts)
   - [AdaptiveSize](#adaptivesize)
   - [AdaptiveEdgeInsets](#adaptiveedgeinsets)
   - [AdaptiveTextStyle](#adaptivetextstyle)
   - [AdaptiveBorderRadius](#adaptiveborderradius)
   - [AdaptiveColor](#adaptivecolor)
   - [AdaptiveDouble](#adaptivedouble)
   - [.adaptive() on existing types](#adaptive-on-existing-types)
   - [AppSpacing tokens](#appspacing-tokens)
   - [AdaptiveGridDelegate](#adaptivegriddelegate)
10. [Fallback Chain](#10-fallback-chain)
11. [Breakpoints](#11-breakpoints)
12. [Text Scale Clamp Reference](#12-text-scale-clamp-reference)
13. [Migration Cheat-Sheet](#13-migration-cheat-sheet)
14. [Full Example App](#14-full-example-app)
15. [Testing](#15-testing)

---

## 1. Installation

```yaml
dependencies:
  flutter_screenutil: ^{latest_version}
```

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
```

---

## 2. Quick Start

Wrap your app root with `ScreenUtilInit`. Place `MaterialApp` inside the `builder` so the entire widget tree rebuilds automatically when screen metrics change (orientation, window resize):

```dart
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),   // your phone Figma frame
      minTextAdapt: true,
      builder: (_, child) => MaterialApp(
        home: HomePage(),
      ),
    );
  }
}
```

That is the only setup required. All `.w`, `.h`, `.sp`, `.r` extensions work immediately everywhere in the tree.

---

## 2b. Upgrading from a Previous Version — Zero Breaking Changes

> **You do not need to change a single line of existing code.**
>
> Every parameter, getter, and method from the previous version of `flutter_screenutil` compiles and behaves exactly as before. All new features are purely additive — new optional parameters and new classes that sit alongside the original API.

### Your existing `ScreenUtilInit` still works 100 %

```dart
// ✅ This code from ANY previous version compiles and works unchanged
ScreenUtilInit(
  designSize:             const Size(360, 690),
  builder:                (_, child) => MaterialApp(home: child),
  child:                  const MyHomePage(),
  rebuildFactor:          RebuildFactors.size,
  splitScreenMode:        false,
  minTextAdapt:           false,
  ensureScreenSize:       false,
  enableScaleWH:          () => true,
  enableScaleText:        () => true,
  responsiveWidgets:      null,
  excludeWidgets:         null,
  fontSizeResolver:       FontSizeResolvers.width,
)
```

### Every `.w` `.h` `.sp` `.r` extension still works unchanged

```dart
Container(
  width:  200.w,    // ✅ still works
  height: 100.h,    // ✅ still works
)

Text(
  'Hello',
  style: TextStyle(fontSize: 14.sp),   // ✅ still works (now also clamp-safe)
)

Icon(Icons.star, size: 24.r)           // ✅ still works

SizedBox(height: 16.verticalSpace)     // ✅ still works
SizedBox(width:  16.horizontalSpace)   // ✅ still works

0.5.sw    // ✅ 50 % of screen width
1.0.sh    // ✅ full screen height
16.sm     // ✅ min(16, 16.sp) — deprecated alias for .spMin, still works
```

### Full attribute status table

| Attribute / API | Exists? | Behavior same? | Notes |
|---|---|---|---|
| `designSize` | ✅ | ✅ | Unchanged |
| `builder` | ✅ | ✅ | Unchanged |
| `child` | ✅ | ✅ | Unchanged |
| `rebuildFactor` | ✅ | ✅ | Default now also fires on rotation |
| `splitScreenMode` | ✅ | ✅ | Unchanged |
| `minTextAdapt` | ✅ | ✅ | Unchanged |
| `ensureScreenSize` | ✅ | ✅ | Unchanged |
| `enableScaleWH` | ✅ | ✅ | Unchanged |
| `enableScaleText` | ✅ | ✅ | Unchanged |
| `responsiveWidgets` | ✅ | ✅ | Unchanged |
| `excludeWidgets` | ✅ | ✅ | Unchanged |
| `fontSizeResolver` | ✅ | ✅ | Unchanged; `null` = new built-in clamped resolver |
| `FontSizeResolvers.width` | ✅ | ✅ | Still present and usable |
| `FontSizeResolvers.height` | ✅ | ✅ | Still present |
| `FontSizeResolvers.radius` | ✅ | ✅ | Still present |
| `FontSizeResolvers.diameter` | ✅ | ✅ | Still present |
| `FontSizeResolvers.diagonal` | ✅ | ✅ | Still present |
| `RebuildFactors.size` | ✅ | ✅ | Still present |
| `RebuildFactors.orientation` | ✅ | ✅ | Still present |
| `RebuildFactors.change` | ✅ | ✅ | Still present |
| `RebuildFactors.always` | ✅ | ✅ | Still present |
| `RebuildFactors.none` | ✅ | ✅ | Still present |
| `useInheritedMediaQuery` | ✅ | — | **Accepted but has no effect.** Shows a `@Deprecated` warning. Safe to remove. |
| `.w` `.h` `.r` `.sp` `.sm` | ✅ | ✅ | All present in `size_extension.dart` |
| `.sw` `.sh` | ✅ | ✅ | Screen width/height fraction |
| `.spMin` `.spMax` | ✅ | ✅ | Unchanged |
| `.dg` `.dm` | ✅ | ✅ | diagonal / diameter — unchanged |
| `.verticalSpace` | ✅ | ✅ | `SizedBox(height: …)` |
| `.horizontalSpace` | ✅ | ✅ | `SizedBox(width: …)` |
| `EdgeInsets.w` `.h` `.r` | ✅ | ✅ | All extension getters present |
| `BorderRadius.w` `.h` `.r` | ✅ | ✅ | All extension getters present |
| `BoxConstraints.w` `.h` `.r` `.hw` | ✅ | ✅ | All extension getters present |
| `ScreenUtil.init()` | ✅ | ✅ | Manual init path unchanged |
| `ScreenUtil.configure()` | ✅ | ✅ | Unchanged |
| `ScreenUtil.ensureScreenSize()` | ✅ | ✅ | Unchanged |
| `ScreenUtil().screenWidth` | ✅ | ✅ | Unchanged |
| `ScreenUtil().screenHeight` | ✅ | ✅ | Unchanged |
| `ScreenUtil().scaleWidth` | ✅ | ✅ | Unchanged |
| `ScreenUtil().scaleHeight` | ✅ | ✅ | Unchanged |
| `ScreenUtil().pixelRatio` | ✅ | ✅ | Unchanged |
| `ScreenUtil().statusBarHeight` | ✅ | ✅ | Unchanged |
| `ScreenUtil().bottomBarHeight` | ✅ | ✅ | Unchanged |
| `ScreenUtil().orientation` | ✅ | ✅ | Unchanged |
| `ScreenUtil().textScaleFactor` | ✅ | ✅ | Unchanged |

### The only deprecated item

`useInheritedMediaQuery` — this parameter is still accepted and causes **no crash**, but it has no effect since the rebuild engine was rewritten to always read from Flutter's `View` layer. You will see a `@Deprecated` IDE warning. Remove it at your convenience:

```dart
// Before
ScreenUtilInit(
  useInheritedMediaQuery: true,   // ← shows @Deprecated warning, safe to remove
  ...
)

// After — identical behavior, no warning
ScreenUtilInit(
  ...
)
```

---

## 3. What Was Fixed

Three bugs existed in the original package. All are fixed without breaking any existing API.

### Bug 1 — `setSp()` always used `scaleWidth` (text wrong in landscape)

In landscape mode, `scaleWidth` jumps because the screen is now wider than the portrait design. The original code multiplied every font by this inflated scale, making all text oversized after rotation.

**Fixed:** `setSp()` now picks `min(scaleWidth, scaleHeight)` when `minTextAdapt: true`, and clamps the result inside a user-controlled range:

```dart
// Before — broken in landscape
double setSp(num fontSize) => fontSize * scaleWidth;

// After — orientation-aware + two-sided clamp
double setSp(num fontSize) {
  final rawScale = _minTextAdapt
      ? math.min(scaleWidth, scaleHeight)
      : scaleWidth;
  return fontSize * rawScale.clamp(_minTextScaleFactor, _maxTextScaleFactor);
}
```

The `.sp` call signature is **unchanged**:

```dart
Text('Hello', style: TextStyle(fontSize: 14.sp));  // same as always
```

### Bug 2 — Design size never updated on orientation change

`_uiSize` was set once at startup and never changed. After rotation all `.w` / `.h` calculations still used the portrait design size.

**Fixed:** The correct design size is now resolved from up to six frames on every build cycle based on current device type and orientation (see [Orientation Support](#6-orientation-support)).

### Bug 3 — Rebuild heuristic failed in release mode

The v5.9.0 name-based heuristic was unreliable: class names can be minified or tree-shaken in release builds, silently breaking responsive rebuilds.

**Fixed:** The default `rebuildFactor` now also fires on **orientation change**, not just size change. Moving `MaterialApp` inside the `builder` callback (see Quick Start above) is the cleanest way to ensure the whole tree rebuilds reactively — no mixin or manual wiring needed.

---

## 4. ScreenUtilInit — Full Parameter Reference

All original parameters are unchanged. New parameters are marked `// NEW`.

```dart
ScreenUtilInit(
  // ── Design sizes — portrait ─────────────────────────────────────────
  designSize:                  const Size(390, 844),   // required, phone portrait
  tabletDesignSize:            const Size(768, 1024),  // NEW — tablet portrait
  desktopDesignSize:           const Size(1280, 900),  // NEW — desktop portrait

  // ── Design sizes — landscape (omit any → auto-transpose) ────────────
  landscapeDesignSize:         const Size(844, 390),   // NEW — phone landscape
  tabletLandscapeDesignSize:   const Size(1024, 768),  // NEW — tablet landscape
  desktopLandscapeDesignSize:  const Size(1440, 900),  // NEW — desktop landscape

  // ── Text ────────────────────────────────────────────────────────────
  minTextAdapt:        true,          // unchanged
  minTextScaleFactor:  0.85,          // NEW — scale floor   (default 0.85)
  maxTextScaleFactor:  1.4,           // NEW — scale ceiling (default 1.4)
  fontSizeResolver:    myResolver,    // unchanged

  // ── Breakpoints ─────────────────────────────────────────────────────
  phoneBreakpoint:     600,           // NEW — default 600 dp
  tabletBreakpoint:    1024,          // NEW — default 1024 dp

  // ── Scaling toggles ─────────────────────────────────────────────────
  enableScaleWH:       () => true,    // unchanged
  enableScaleText:     () => true,    // unchanged

  // ── Layout ──────────────────────────────────────────────────────────
  splitScreenMode:     false,         // unchanged

  // ── Rebuild ─────────────────────────────────────────────────────────
  rebuildFactor:       orientationOrSizeChangedRebuildFactor, // NEW default
  responsiveWidgets:   null,          // unchanged
  excludeWidgets:      null,          // unchanged

  // ── Debug ───────────────────────────────────────────────────────────
  debugShowOverlay:    kDebugMode,    // NEW — live metrics HUD

  // ── Content ─────────────────────────────────────────────────────────
  builder: (_, child) => MaterialApp(home: child),  // unchanged
  child: const HomePage(),                          // unchanged
)
```

---

## 5. Core API (unchanged)

Every original API remains identical:

```dart
200.w      // scaled to screen width
120.h      // scaled to screen height
14.sp      // orientation-aware font size (now also clamped)
8.r        // scaled to shorter axis — for radii and icon sizes
12.sm      // min(12, 12.sp)

1.sw       // full screen width
1.sh       // full screen height
0.5.sw     // 50 % of screen width

ScreenUtil().screenWidth
ScreenUtil().screenHeight
ScreenUtil().scaleWidth
ScreenUtil().scaleHeight
ScreenUtil().pixelRatio
ScreenUtil().statusBarHeight
ScreenUtil().bottomBarHeight
ScreenUtil().orientation

EdgeInsets.all(10).w          // scale EdgeInsets by width
EdgeInsets.all(10).r          // scale by shorter axis
BoxConstraints(maxWidth: 100).w
BorderRadius.all(Radius.circular(16)).w

16.verticalSpace               // SizedBox(height: 16.h)
16.horizontalSpace             // SizedBox(width: 16.w)
```

---

## 6. Orientation Support

### Per-device landscape frames

Provide separate Figma frames for each device class. Any omitted variant is **auto-transposed** (width ↔ height swapped) from the portrait frame:

```dart
// Minimal — only phone has an explicit landscape frame
ScreenUtilInit(
  designSize:          const Size(390, 844),
  landscapeDesignSize: const Size(844, 390),
)

// Full control — all six frames
ScreenUtilInit(
  designSize:                  const Size(390, 844),
  tabletDesignSize:            const Size(768, 1024),
  desktopDesignSize:           const Size(1280, 900),
  landscapeDesignSize:         const Size(844, 390),
  tabletLandscapeDesignSize:   const Size(1024, 768),
  desktopLandscapeDesignSize:  const Size(1440, 900),
)
```

Internally, the active design size is selected on every build cycle:

```
orientation?
  portrait  → phone → designSize
              tablet → tabletDesignSize ?? designSize
              desktop → desktopDesignSize ?? tabletDesignSize ?? designSize
  landscape → phone → landscapeDesignSize ?? flip(designSize)
              tablet → tabletLandscapeDesignSize ?? flip(tabletDesignSize) ?? flip(designSize)
              desktop → desktopLandscapeDesignSize ?? flip(desktopDesignSize) ?? …
```

### New getters

```dart
ScreenUtil().isLandscape   // bool
ScreenUtil().isPortrait    // bool
ScreenUtil().orientation   // Orientation (unchanged)
```

### `ScreenOrientationBuilder`

```dart
ScreenOrientationBuilder(
  portrait:  (ctx) => PortraitLayout(),
  landscape: (ctx) => LandscapeLayout(),
)
```

### `OrientationValue<T>`

```dart
final padding = OrientationValue<EdgeInsets>(
  portrait:  EdgeInsets.symmetric(horizontal: 16.w),
  landscape: EdgeInsets.symmetric(horizontal: 32.w),
);

// In build():
Padding(padding: padding.value)
```

### `SliverOrientationDelegate`

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

---

## 7. Device-Class API

### `DeviceType` enum

```dart
enum DeviceType { phone, tablet, desktop, tv }
```

Auto-detected from the logical screen width using configurable breakpoints.

### `ScreenUtil().deviceType` and convenience getters

```dart
ScreenUtil().deviceType   // → DeviceType.phone / .tablet / .desktop / .tv
ScreenUtil().isPhone      // width < 600
ScreenUtil().isTablet     // 600 ≤ width < 1024
ScreenUtil().isDesktop    // 1024 ≤ width < 1600
ScreenUtil().isTV         // width ≥ 1600
```

### `ScreenUtil().adaptive<T>()`

Returns a different value per device type with automatic fallback to the next smaller tier:

```dart
final cols = ScreenUtil().adaptive<int>(
  phone:   2,
  tablet:  3,
  desktop: 4,
);

final fontSize = ScreenUtil().adaptive<double>(
  phone:   14.sp,
  tablet:  16.sp,
  desktop: 18.sp,
);

// Omit desktop — it falls back to tablet value
final cols = ScreenUtil().adaptive(phone: 1, tablet: 2);
```

### `AdaptiveWidget`

Renders a different widget per device type:

```dart
AdaptiveWidget(
  phone:   (ctx) => BottomNavBar(),
  tablet:  (ctx) => NavigationRail(extended: false),
  desktop: (ctx) => NavigationRail(extended: true),
)
```

### `AdaptiveLayout`

Full layout switcher with separate portrait and landscape overrides:

```dart
AdaptiveLayout(
  phone:          (_) => _PhoneScaffold(),
  landscapePhone: (_) => _LandscapePhoneScaffold(),
  tablet:         (_) => _TabletScaffold(),
  desktop:        (_) => _DesktopScaffold(),
)
```

### `Breakpoints` — without `ScreenUtil`

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
    return GridView.count(crossAxisCount: cols, children: [...]);
  },
)
```

---

## 8. Debug HUD

Enable the live metrics overlay during development:

```dart
ScreenUtilInit(
  debugShowOverlay: kDebugMode,   // auto-disabled in release builds
  ...
)
```

The HUD (top-left corner) shows:
- Screen size in dp
- Scale factors (width × height)
- Text scale
- Orientation
- Device type
- Device pixel ratio
- `16.sp` resolved value (quick sanity check)

Tap to collapse to a compact `SU` badge. The overlay uses its own `Directionality` and is overflow-safe regardless of window size.

### `ScreenMetrics` — immutable snapshot

```dart
final metrics = ScreenMetrics.current();

metrics.screenWidth   // double
metrics.screenHeight  // double
metrics.scaleWidth    // double
metrics.deviceType    // DeviceType
metrics.isLandscape   // bool
metrics.sp(16)        // → same as ScreenUtil().setSp(16)
```

---

## 9. Phase 5 — Adaptive Extensions

Every dimension type now understands `phone` / `tablet` / `desktop` values. Import is automatic — everything is in `package:flutter_screenutil/flutter_screenutil.dart`.

---

### `AdaptiveNum`

The core class. Provide raw dp values per device, access any scaling axis as a getter.

```dart
AdaptiveNum({
  required num phone,
  num? tablet,    // fallback → phone
  num? desktop,   // fallback → tablet → phone
  num? tv,        // fallback → desktop → tablet → phone
})

.w    // scaled to screen width
.h    // scaled to screen height
.sp   // orientation-aware font size
.r    // scaled to shorter axis (radii, icon sizes)
.raw  // unscaled — already in logical px
.hs   // SizedBox(height: value.h)  — vertical spacer widget
.ws   // SizedBox(width: value.w)   — horizontal spacer widget
```

```dart
// Width
Container(width: AdaptiveNum(phone: 200, tablet: 320, desktop: 480).w)

// Font size
Text('Heading', style: TextStyle(
  fontSize: AdaptiveNum(phone: 20, tablet: 24, desktop: 28).sp,
))

// Icon size (square — uses shorter axis)
Icon(Icons.star, size: AdaptiveNum(phone: 24, tablet: 32, desktop: 40).r)

// Vertical spacing between widgets
Column(children: [
  MyWidget(),
  AdaptiveNum(phone: 12, tablet: 16, desktop: 24).hs,
  OtherWidget(),
])
```

---

### `num.adaptive()` quick shortcut

Seed an `AdaptiveNum` from any number using `this` as the phone base:

```dart
16.adaptive(tablet: 18, desktop: 20).sp
200.adaptive(tablet: 320, desktop: 480).w
8.adaptive(tablet: 12).r           // desktop falls back to tablet
12.adaptive(tablet: 16).hs         // vertical spacer widget
```

---

### Auto-scaled shortcuts

Four shortcut getters apply automatic multipliers so you don't have to calculate every breakpoint:

| Getter | Multipliers | Typical use |
|--------|-------------|-------------|
| `.aw`  | phone×1.0, tablet×1.3, desktop×1.6 | Widths |
| `.ah`  | phone×1.0, tablet×1.2, desktop×1.4 | Heights |
| `.asp` | phone×1.0, tablet×1.15, desktop×1.25 | Font sizes |
| `.ar`  | phone×1.0, tablet×1.2, desktop×1.3 | Radii, icon sizes |

```dart
16.asp    // ≈ AdaptiveNum(phone: 16, tablet: 18.4, desktop: 20).sp
200.aw    // ≈ AdaptiveNum(phone: 200, tablet: 260, desktop: 320).w
8.ar      // ≈ AdaptiveNum(phone: 8,  tablet: 9.6,  desktop: 10.4).r
```

> Use shortcuts for rapid prototyping. Use `AdaptiveNum` with explicit values for pixel-perfect Figma match.

---

### `AdaptiveSize`

For `Size` objects — avatar frames, image placeholders, icon boxes:

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

**Scaling getters:**

```dart
.value  // raw, unscaled
.wh     // width by scaleWidth, height by scaleHeight
.w      // both axes by scaleWidth (preserves aspect ratio)
.r      // shorter axis — for square icons
```

---

### `AdaptiveEdgeInsets`

Padding that changes per device type:

```dart
// All sides equal
AdaptiveEdgeInsets.all(phone: 12, tablet: 16, desktop: 20)

// Symmetric
AdaptiveEdgeInsets.symmetric(
  phoneH: 16,  phoneV: 12,
  tabletH: 24, tabletV: 16,
  desktopH: 40, desktopV: 20,
)

// Per-side (omitted sides fall back to phone values)
AdaptiveEdgeInsets.only(
  phoneLeft: 16, phoneTop: 8, phoneRight: 16, phoneBottom: 8,
  tabletLeft: 24, tabletTop: 12,
)
```

**Scaling getters:**

```dart
.w    // all sides scaled by scaleWidth
.wh   // horizontal sides by scaleWidth, vertical by scaleHeight
.r    // all sides by shorter axis
```

```dart
Padding(
  padding: AdaptiveEdgeInsets.symmetric(
    phoneH: 16,  phoneV: 12,
    tabletH: 24, tabletV: 16,
    desktopH: 40, desktopV: 20,
  ).wh,
)
```

---

### `AdaptiveTextStyle`

A complete per-device `TextStyle` — font size, weight, and color all adapt:

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
    desktopWeight:   FontWeight.w500,
    phoneColor:      Colors.black,
    desktopColor:    Colors.grey.shade800,
    letterSpacing:   -0.5,
  ).style,
)
```

**All parameters:**

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

.style  // → TextStyle (fully resolved + scaled)
```

---

### `AdaptiveBorderRadius`

Border radii that change per device:

```dart
// All corners equal
AdaptiveBorderRadius.circular(phone: 8, tablet: 12, desktop: 16)

// Per-corner control
AdaptiveBorderRadius.only(
  phoneTL: 8,  phoneTR: 8,
  tabletTL: 12, tabletTR: 12,
)

// Full manual
AdaptiveBorderRadius(
  phone:   BorderRadius.circular(8),
  tablet:  BorderRadius.circular(12),
  desktop: BorderRadius.circular(16),
)
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

**Scaling getters:** `.r` (shorter axis) · `.w` (width axis) · `.value` (raw)

---

### `AdaptiveColor`

When brand color contrast or tint varies per screen size:

```dart
Container(
  color: AdaptiveColor(
    phone:   Colors.blue.shade700,   // higher contrast on small screen
    tablet:  Colors.blue.shade600,
    desktop: Colors.blue.shade500,
  ).value,
)
```

---

### `AdaptiveDouble`

Raw double per device — **no ScreenUtil scaling applied**. Use for unitless values: column counts, flex ratios, opacity, animation durations.

```dart
// Column count
GridView.count(
  crossAxisCount: AdaptiveDouble(phone: 1, tablet: 2, desktop: 4).toInt,
)

// Opacity
Opacity(
  opacity: AdaptiveDouble(phone: 1.0, desktop: 0.8).value,
  child: SidePanel(),
)

// Animation duration
AnimatedContainer(
  duration: Duration(
    milliseconds: AdaptiveDouble(phone: 300, tablet: 250, desktop: 200).toInt,
  ),
)

// Flex ratios
Row(children: [
  Expanded(
    flex: AdaptiveDouble(phone: 1, tablet: 2, desktop: 3).toInt,
    child: Content(),
  ),
  Expanded(
    flex: AdaptiveDouble(phone: 0, desktop: 1).toInt,
    child: Sidebar(),
  ),
])
```

---

### `.adaptive()` on existing types

Wrap any existing Flutter value and override only the breakpoints you need:

```dart
// EdgeInsets
Padding(
  padding: EdgeInsets.all(16).adaptive(
    tablet:  EdgeInsets.all(24),
    desktop: EdgeInsets.all(40),
  ).w,
)

// Size
SizedBox.fromSize(
  size: const Size(200, 60).adaptive(
    tablet:  const Size(280, 72),
    desktop: const Size(360, 80),
  ).wh,
)

// Color
Icon(
  Icons.favorite,
  color: Colors.red.shade600.adaptive(
    tablet:  Colors.red.shade500,
    desktop: Colors.red.shade400,
  ).value,
)

// BorderRadius
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

A semantic spacing enum following a T-shirt size scale:

| Token   | Phone | Tablet | Desktop |
|---------|-------|--------|---------|
| `xxs`   | 2 dp  | 4 dp   | 6 dp    |
| `xs`    | 4 dp  | 6 dp   | 8 dp    |
| `sm`    | 8 dp  | 10 dp  | 12 dp   |
| `md`    | 12 dp | 16 dp  | 20 dp   |
| `lg`    | 16 dp | 20 dp  | 24 dp   |
| `xl`    | 24 dp | 32 dp  | 40 dp   |
| `xxl`   | 32 dp | 48 dp  | 64 dp   |
| `xxxl`  | 48 dp | 64 dp  | 96 dp   |

```dart
// As a raw scaled value
AppSpacing.md.w    // 12 dp → 16 dp → 20 dp (scaled by scaleWidth)
AppSpacing.lg.h    // scaled by scaleHeight

// As a spacer widget (most common)
AppSpacing.lg.hs   // SizedBox(height: ...)
AppSpacing.md.ws   // SizedBox(width: ...)
```

```dart
Column(
  children: [
    ProfileHeader(),
    AppSpacing.lg.hs,
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

A `SliverGridDelegate` with adaptive cross-axis column counts:

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
  padding: EdgeInsets.all(AppSpacing.md.w),
  gridDelegate: AdaptiveGridDelegate(
    phone:            2,
    tablet:           3,
    desktop:          4,
    spacing:          AdaptiveNum(phone: 8, tablet: 12, desktop: 16).w,
    childAspectRatio: AdaptiveDouble(
      phone: 0.75, tablet: 0.80, desktop: 0.85,
    ).value,
  ),
  itemCount: products.length,
  itemBuilder: (_, i) => ProductCard(products[i]),
)
```

---

## 10. Fallback Chain

All `Adaptive*` classes use the same chain when a tier is not provided:

```
tv  →  desktop  →  tablet  →  phone (required)
```

```dart
// Only phone + tablet provided
AdaptiveNum(phone: 12, tablet: 16)
// phone   → 12
// tablet  → 16
// desktop → 16  (fallback to tablet)
// tv      → 16  (fallback → desktop → tablet)

// Only phone provided — all devices use phone value, scaled by their own axis
AdaptiveNum(phone: 12)
```

---

## 11. Breakpoints

Default values (configurable in `ScreenUtilInit`):

| Device    | Condition                    |
|-----------|------------------------------|
| `phone`   | `width < 600 dp`             |
| `tablet`  | `600 dp ≤ width < 1024 dp`   |
| `desktop` | `1024 dp ≤ width < 1600 dp`  |
| `tv`      | `width ≥ 1600 dp`            |

Detection uses **logical screen width** — correctly handles split-screen and desktop window resizing.

```dart
ScreenUtilInit(
  phoneBreakpoint:  600,    // customize per project
  tabletBreakpoint: 1024,
)
```

---

## 12. Text Scale Clamp Reference

| Scenario | `minTextScaleFactor` | `maxTextScaleFactor` | Result |
|---|---|---|---|
| **Default** (most apps) | `0.85` | `1.4` | Safe, accessible range |
| Information-dense | `0.80` | `1.2` | Tighter, smaller allowed |
| Accessibility-first | `1.0` | `2.0` | Text only ever grows |
| Fixed UI (no adaption) | `1.0` | `1.0` | Always exactly design size |

```dart
// Default (no override needed)
ScreenUtilInit(
  designSize: const Size(390, 844),
  minTextAdapt: true,
  // minTextScaleFactor defaults to 0.85
  // maxTextScaleFactor defaults to 1.4
  builder: (_, child) => MaterialApp(home: child),
)

// Accessibility-first
ScreenUtilInit(
  minTextScaleFactor: 1.0,
  maxTextScaleFactor: 2.0,
  ...
)

// Completely fixed
ScreenUtilInit(
  minTextScaleFactor: 1.0,
  maxTextScaleFactor: 1.0,
  ...
)
```

> **Why 0.85 as the default floor?** The old hardcoded floor was `0.5` — text could shrink to half its design size on small screens, which is unreadable. `0.85` is the accessibility-safe lower bound recommended by Material Design.

---

## 13. Migration Cheat-Sheet

You don't need to change anything. All existing code compiles as-is. The table below shows how to upgrade specific patterns:

| Before (still works) | After (more per-device control) |
|---|---|
| `200.w` | `AdaptiveNum(phone: 200, tablet: 280, desktop: 360).w` |
| `14.sp` | `AdaptiveNum(phone: 14, tablet: 15, desktop: 16).sp` |
| `8.r` | `AdaptiveNum(phone: 8, tablet: 10, desktop: 12).r` |
| `200.w` (quick) | `200.aw` (auto-scaled tiers) |
| `14.sp` (quick) | `14.asp` |
| `EdgeInsets.all(16).w` | `AdaptiveEdgeInsets.all(phone: 16, tablet: 24, desktop: 32).w` |
| `BorderRadius.circular(8).r` | `AdaptiveBorderRadius.circular(phone: 8, tablet: 12, desktop: 16).r` |
| Manual `if (screenWidth > 600)` | `AdaptiveDouble(phone: 1, tablet: 2, desktop: 3).toInt` |
| `GridView.count(crossAxisCount: 2)` | `AdaptiveGridDelegate(phone: 2, tablet: 3, desktop: 4)` |
| `SizedBox(height: 16.h)` | `AppSpacing.lg.hs` |
| Single `landscapeDesignSize` | `landscapeDesignSize` + `tabletLandscapeDesignSize` + `desktopLandscapeDesignSize` |

---

## 14. Full Example App

A complete, copy-paste example demonstrating every feature. Run with:

```bash
flutter run -t lib/main_adaptive.dart
```

```dart
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Per-device portrait frames
      designSize:                const Size(390, 844),
      tabletDesignSize:          const Size(768, 1024),
      desktopDesignSize:         const Size(1280, 900),

      // Per-device landscape frames (null = auto-transpose)
      landscapeDesignSize:       const Size(844, 390),
      tabletLandscapeDesignSize: const Size(1024, 768),

      // Text scale — both bounds user-controlled
      minTextAdapt:       true,
      minTextScaleFactor: 0.85,
      maxTextScaleFactor: 1.4,

      // Breakpoints
      phoneBreakpoint:  600,
      tabletBreakpoint: 1024,

      // Live debug HUD — auto-off in release
      debugShowOverlay: kDebugMode,

      builder: (_, child) => MaterialApp(
        title: 'Adaptive ScreenUtil Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: HomePage(),
      ),
    );
  }
}

// Phase 3 — full layout switcher with orientation variants
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      phone:          (_) => const _PhoneScaffold(),
      landscapePhone: (_) => const _LandscapePhoneScaffold(),
      tablet:         (_) => const _TabletScaffold(),
      desktop:        (_) => const _DesktopScaffold(),
    );
  }
}

// Phone — bottom navigation bar
class _PhoneScaffold extends StatelessWidget {
  const _PhoneScaffold();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Demo')),
      body: Column(
        children: [
          _DeviceBanner(),
          Expanded(child: ProductGrid(products: _kProducts)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Phone landscape — NavigationRail
class _LandscapePhoneScaffold extends StatelessWidget {
  const _LandscapePhoneScaffold();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Demo — Landscape')),
      body: Row(
        children: [
          NavigationRail(
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.search), label: Text('Search')),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
          Expanded(child: ProductGrid(products: _kProducts)),
        ],
      ),
    );
  }
}

// Tablet — NavigationDrawer side panel
class _TabletScaffold extends StatelessWidget {
  const _TabletScaffold();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            children: [
              DrawerHeader(child: Text('Adaptive Demo')),
              const ListTile(leading: Icon(Icons.home),   title: Text('Home')),
              const ListTile(leading: Icon(Icons.search), title: Text('Search')),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                _DeviceBanner(),
                Expanded(child: ProductGrid(products: _kProducts)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Desktop — extended NavigationRail with adaptive width
class _DesktopScaffold extends StatelessWidget {
  const _DesktopScaffold();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: AdaptiveNum(phone: 160, desktop: 200).w,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home),     label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.search),   label: Text('Search')),
              NavigationRailDestination(icon: Icon(Icons.person),   label: Text('Profile')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            leading: Padding(
              padding: AdaptiveEdgeInsets.symmetric(
                phoneH: 16, phoneV: 24,
                desktopH: 24, desktopV: 32,
              ).w,
              child: Text(
                'Adaptive Demo',
                style: AdaptiveTextStyle(
                  phoneFontSize: 18,
                  desktopFontSize: 22,
                  phoneWeight: FontWeight.bold,
                ).style,
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                _DeviceBanner(),
                Expanded(child: ProductGrid(products: _kProducts)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Live device info banner — every Phase 5 API at a glance
class _DeviceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final su = ScreenUtil();
    final metrics = ScreenMetrics.current();
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: AdaptiveEdgeInsets.symmetric(
        phoneH: 16, phoneV: 10,
        desktopH: 24, desktopV: 14,
      ).w,
      child: Wrap(
        spacing: AppSpacing.md.w,
        runSpacing: AppSpacing.xs.h,
        children: [
          Chip(label: Text('${metrics.screenWidth.toStringAsFixed(0)}'
              '×${metrics.screenHeight.toStringAsFixed(0)} dp')),
          Chip(label: Text(su.deviceType.name)),
          Chip(label: Text(su.isLandscape ? 'landscape' : 'portrait')),
          Chip(label: Text('16.sp = ${su.setSp(16).toStringAsFixed(1)}')),
          Chip(label: Text('scaleW = ${su.scaleWidth.toStringAsFixed(3)}')),
        ],
      ),
    );
  }
}

// ProductCard — showcases Phase 5 Adaptive* classes
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.title,
    required this.price,
    required this.emoji,
  });
  final String title;
  final double price;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AdaptiveBorderRadius.circular(
          phone: 8, tablet: 12, desktop: 16,
        ).r,
      ),
      child: Padding(
        padding: AdaptiveEdgeInsets.all(
          phone: 12, tablet: 16, desktop: 20,
        ).w,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emoji,
                style: TextStyle(
                  fontSize: AdaptiveNum(phone: 32, tablet: 40, desktop: 48).r,
                ),
              ),
              AppSpacing.sm.hs,
              Text(
                title,
                style: AdaptiveTextStyle(
                  phoneFontSize: 14,
                  tabletFontSize: 16,
                  desktopFontSize: 18,
                  phoneWeight: FontWeight.w600,
                ).style,
              ),
              AppSpacing.xs.hs,
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: AdaptiveTextStyle(
                  phoneFontSize: 13,
                  tabletFontSize: 14,
                  desktopFontSize: 15,
                  phoneColor: Colors.green.shade700,
                  tabletColor: Colors.green.shade600,
                  desktopColor: Colors.green.shade500,
                ).style,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ProductGrid — AdaptiveGridDelegate
class ProductGrid extends StatelessWidget {
  const ProductGrid({required this.products});
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.md.w),
      gridDelegate: AdaptiveGridDelegate(
        phone:            2,
        tablet:           3,
        desktop:          4,
        spacing:          AdaptiveNum(phone: 8, tablet: 12, desktop: 16).w,
        childAspectRatio: AdaptiveDouble(
          phone: 0.75, tablet: 0.80, desktop: 0.85,
        ).value,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(
        title: products[i]['title'] as String,
        price: (products[i]['price'] as num).toDouble(),
        emoji: products[i]['emoji'] as String,
      ),
    );
  }
}

const _kProducts = [
  {'title': 'Wireless Headphones', 'price': 79.99,  'emoji': '🎧'},
  {'title': 'Mechanical Keyboard', 'price': 129.99, 'emoji': '⌨️'},
  {'title': 'Gaming Mouse',        'price': 59.99,  'emoji': '🖱️'},
  {'title': 'USB-C Hub',           'price': 39.99,  'emoji': '🔌'},
];
```

---

## 15. Testing

```bash
flutter test test/adaptive_test.dart
```

Widget tests — initialize `ScreenUtil` before assertions:

```dart
testWidgets('cards render on phone', (tester) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => const MaterialApp(home: Scaffold(body: ProductCard(...))),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byType(ProductCard), findsOneWidget);
});
```

Use `ScreenMetrics.current()` to assert exact scale values in unit tests:

```dart
test('sp is clamped on wide screen', () {
  ScreenUtil.configure(
    data: MediaQueryData(size: const Size(2000, 1000)),
    designSize: const Size(390, 844),
    maxTextScaleFactor: 1.4,
  );
  final metrics = ScreenMetrics.current();
  expect(metrics.sp(16), closeTo(16 * 1.4, 0.5));
});
```

---

[Update log](https://github.com/OpenFlutter/flutter_screenutil/blob/master/CHANGELOG.md) · [中文文档](https://github.com/OpenFlutter/flutter_screenutil/blob/master/README_CN.md) · [GitHub](https://github.com/OpenFlutter/flutter_screenutil)
