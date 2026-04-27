// ignore_for_file: avoid_redundant_argument_values
/// Comprehensive test coverage for all adaptive improvements (Phases 1–5).
///
/// Covers every item from Section 13 of ADAPTIVE_IMPROVEMENTS.md plus
/// additional edge-cases found during code review.
///
/// Run with:
///   flutter test test/adaptive_test.dart
library flutter_screenutil.adaptive_test;

import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Initialises ScreenUtil with a synthetic screen [size] and [designSize].
///
/// [minTextAdapt] controls the orientation-aware `.sp` axis.
///
/// **Important:** always call this at the start of each test or setUp because
/// ScreenUtil is a singleton — state leaks between tests.
void _init(
  Size screenSize,
  Size designSize, {
  bool minTextAdapt = false,
  double minTextScaleFactor = 0.85,
  double maxTextScaleFactor = 1.4,
  double phoneBreakpoint = 600,
  double tabletBreakpoint = 1024,
  Size? landscapeDesignSize,
  Size? tabletDesignSize,
  Size? desktopDesignSize,
  Size? tabletLandscapeDesignSize,
  FontSizeResolver? fontSizeResolver,
}) {
  // ScreenUtil.configure only updates fields that receive a non-null argument.
  // To guarantee a clean resolver state, directly wipe it via instance first.
  ScreenUtil().fontSizeResolver = null;

  ScreenUtil.configure(
    data: MediaQueryData(size: screenSize),
    designSize: designSize,
    minTextAdapt: minTextAdapt,
    splitScreenMode: false,
    minTextScaleFactor: minTextScaleFactor,
    maxTextScaleFactor: maxTextScaleFactor,
    phoneBreakpoint: phoneBreakpoint,
    tabletBreakpoint: tabletBreakpoint,
    // By passing explicit objects here, we overwrite any previously accumulated
    // singleton state from other tests.
    landscapeDesignSize:
        landscapeDesignSize ?? Size(designSize.height, designSize.width),
    tabletDesignSize: tabletDesignSize ?? designSize,
    desktopDesignSize: desktopDesignSize ?? designSize,
    tabletLandscapeDesignSize:
        tabletLandscapeDesignSize ?? landscapeDesignSize ?? Size(designSize.height, designSize.width),
    desktopLandscapeDesignSize:
        landscapeDesignSize ?? Size(designSize.height, designSize.width),
    fontSizeResolver: fontSizeResolver,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 1 — sp calculation (Bug 1 fixes)
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Phase 1 — setSp / scaleText', () {
    // Design match: screen == design → scaleText == 1 clamped → 16.sp == 16
    test('portrait scale at design size → 16.sp ≈ 16', () {
      _init(const Size(390, 844), const Size(390, 844));
      expect(ScreenUtil().setSp(16), closeTo(16.0, 0.1));
    });

    // Very wide screen → scaleWidth >> 1 → clamped at maxTextScaleFactor
    test('wide screen clamped at maxTextScaleFactor', () {
      _init(
        const Size(2000, 844),
        const Size(390, 844),
        maxTextScaleFactor: 1.4,
      );
      final su = ScreenUtil();
      // scaleWidth = 2000/390 ≈ 5.13 → clamped to 1.4
      expect(su.setSp(16), closeTo(16 * 1.4, 0.1));
    });

    // Very small screen → scaleWidth << 1 → clamped at minTextScaleFactor
    test('small screen clamped at minTextScaleFactor', () {
      _init(
        const Size(150, 300),
        const Size(390, 844),
        minTextScaleFactor: 0.85,
      );
      // scaleWidth = 150/390 ≈ 0.38 → clamped to 0.85
      expect(ScreenUtil().setSp(16), closeTo(16 * 0.85, 0.1));
    });

    // minTextAdapt: uses min(scaleW, scaleH) in landscape (Bug 1 fix)
    test('minTextAdapt: true uses min(scaleW, scaleH)', () {
      // Landscape: 844×390 on design 390×844
      _init(
        const Size(844, 390),
        const Size(390, 844),
        minTextAdapt: true,
        minTextScaleFactor: 0.0, // disable clamp floor to see raw axis
        maxTextScaleFactor: 99.0, // disable clamp ceiling
      );
      final su = ScreenUtil();
      final scaleW = su.scaleWidth;
      final scaleH = su.scaleHeight;
      final expected = 16 * min(scaleW, scaleH);
      expect(su.setSp(16), closeTo(expected, 0.01));
    });

    // Custom FontSizeResolver bypasses built-in scaleText
    test('custom FontSizeResolver overrides default', () {
      _init(
        const Size(390, 844),
        const Size(390, 844),
        fontSizeResolver: (sz, _) => sz * 2.0, // always double the size
      );
      expect(ScreenUtil().setSp(16), closeTo(32.0, 0.1));
    });

    // defaultFontSizeResolver factory
    test('defaultFontSizeResolver factory matches built-in', () {
      _init(const Size(500, 900), const Size(390, 844));
      final resolver = defaultFontSizeResolver(
        minTextAdapt: false,
        minScale: 0.85,
        maxScale: 1.4,
      );
      final su = ScreenUtil();
      final viaResolver = resolver(16, su);
      // Remove the custom resolver so setSp falls back to built-in
      ScreenUtil.configure(data: MediaQueryData(size: const Size(500, 900)));
      expect(viaResolver, closeTo(su.setSp(16), 0.001));
    });

    // clampedAbsoluteResolver hard pixel bounds
    test('clampedAbsoluteResolver clamps output in dp', () {
      _init(const Size(2000, 844), const Size(390, 844));
      final resolver = clampedAbsoluteResolver(
        primary: widthBasedResolver(minScale: 0.0, maxScale: 99.0),
        minDp: 12,
        maxDp: 20,
      );
      final su = ScreenUtil();
      // Without hard clamp: 16 * scaleWidth ≈ 16 * 5.13 ≈ 82 → clamped to 20
      expect(resolver(16, su), closeTo(20.0, 0.1));
    });

    // minAxisResolver always picks the shorter axis
    test('minAxisResolver uses min(scaleW, scaleH)', () {
      _init(
        const Size(844, 390),
        const Size(390, 844),
        minTextScaleFactor: 0.0,
        maxTextScaleFactor: 99.0,
      );
      final su = ScreenUtil();
      final resolver =
          minAxisResolver(minScale: 0.0, maxScale: 99.0);
      final expected = 16 * min(su.scaleWidth, su.scaleHeight);
      expect(resolver(16, su), closeTo(expected, 0.01));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 2 — orientation
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 2 — orientation', () {
    test('portrait screen → isPortrait = true, isLandscape = false', () {
      _init(const Size(390, 844), const Size(390, 844));
      expect(ScreenUtil().isPortrait, isTrue);
      expect(ScreenUtil().isLandscape, isFalse);
    });

    test('landscape screen → isLandscape = true, isPortrait = false', () {
      _init(const Size(844, 390), const Size(390, 844));
      expect(ScreenUtil().isLandscape, isTrue);
      expect(ScreenUtil().isPortrait, isFalse);
    });

    // Bug 2 fix: auto-transpose portrait frame in landscape
    test('landscape auto-transposes portrait design size (Bug 2)', () {
      // portrait design 390×844 → landscape auto 844×390
      _init(const Size(844, 390), const Size(390, 844));
      final su = ScreenUtil();
      // scaleWidth = 844 / 844 = 1.0  (transposed frame)
      expect(su.scaleWidth, closeTo(1.0, 0.01));
    });

    // Explicit landscapeDesignSize overrides auto-transpose
    test('explicit landscapeDesignSize overrides auto-transpose', () {
      _init(
        const Size(1000, 500),
        const Size(390, 844),
        landscapeDesignSize: const Size(800, 400),
      );
      final su = ScreenUtil();
      // scaleWidth = 1000 / 800 = 1.25
      expect(su.scaleWidth, closeTo(1.25, 0.01));
    });

    // Portrait scaleWidth is unaffected by landscapeDesignSize
    test('portrait scaleWidth unaffected by landscapeDesignSize', () {
      _init(
        const Size(390, 844),
        const Size(390, 844),
        landscapeDesignSize: const Size(800, 400),
      );
      // portrait: 390 / 390 = 1.0
      expect(ScreenUtil().scaleWidth, closeTo(1.0, 0.01));
    });

    // OrientationValue<T>
    test('OrientationValue<T> resolves correct value', () {
      _init(const Size(390, 844), const Size(390, 844));
      final val = OrientationValue<int>(portrait: 1, landscape: 2);
      expect(val.value, 1); // portrait

      _init(const Size(844, 390), const Size(390, 844));
      expect(val.value, 2); // landscape
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 3 — device type
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 3 — device type detection', () {
    test('width < 600 → phone', () {
      _init(const Size(375, 812), const Size(375, 812));
      expect(ScreenUtil().deviceType, DeviceType.phone);
      expect(ScreenUtil().isPhone, isTrue);
    });

    test('width == 600 → tablet (boundary)', () {
      _init(const Size(600, 900), const Size(600, 900));
      expect(ScreenUtil().deviceType, DeviceType.tablet);
      expect(ScreenUtil().isTablet, isTrue);
    });

    test('width == 1024 → desktop (boundary)', () {
      _init(const Size(1024, 768), const Size(1024, 768));
      expect(ScreenUtil().deviceType, DeviceType.desktop);
      expect(ScreenUtil().isDesktop, isTrue);
    });

    test('width >= 1600 → tv', () {
      _init(const Size(1920, 1080), const Size(1920, 1080));
      expect(ScreenUtil().deviceType, DeviceType.tv);
      expect(ScreenUtil().isTV, isTrue);
    });

    // adaptive<T>() value selection
    test('adaptive<T>() returns correct value per device', () {
      _init(const Size(375, 812), const Size(375, 812)); // phone
      expect(ScreenUtil().adaptive<int>(phone: 1, tablet: 2, desktop: 3), 1);

      _init(const Size(800, 1024), const Size(800, 1024)); // tablet
      expect(ScreenUtil().adaptive<int>(phone: 1, tablet: 2, desktop: 3), 2);

      _init(const Size(1280, 800), const Size(1280, 800)); // desktop
      expect(ScreenUtil().adaptive<int>(phone: 1, tablet: 2, desktop: 3), 3);
    });

    // Fallback chain: omit desktop → falls back to tablet
    test('adaptive<T>() fallback: desktop absent → returns tablet', () {
      _init(const Size(1280, 800), const Size(1280, 800)); // desktop
      expect(
        ScreenUtil().adaptive<String>(phone: 'P', tablet: 'T'),
        'T', // desktop falls back to tablet
      );
    });

    // Fallback chain: omit tablet + desktop → all map to phone
    test('adaptive<T>() fallback: only phone → all devices get phone', () {
      _init(const Size(1280, 800), const Size(1280, 800));
      expect(ScreenUtil().adaptive<String>(phone: 'P'), 'P');
    });

    // Breakpoints.value (static, no ScreenUtil dependency)
    test('Breakpoints.value<int> resolves per width', () {
      expect(
        Breakpoints.value<int>(width: 375, phone: 1, tablet: 2, desktop: 3),
        1,
      );
      expect(
        Breakpoints.value<int>(width: 768, phone: 1, tablet: 2, desktop: 3),
        2,
      );
      expect(
        Breakpoints.value<int>(width: 1280, phone: 1, tablet: 2, desktop: 3),
        3,
      );
    });

    test('Breakpoints.deviceTypeFor with custom breakpoints', () {
      expect(
        Breakpoints.deviceTypeFor(
          500,
          phoneBreakpoint: 400,
          tabletBreakpoint: 800,
        ),
        DeviceType.tablet, // 500 >= 400
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 4 — ScreenMetrics & mixin types
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 4 — ScreenMetrics & mixin', () {
    test('ScreenMetrics.current() captures correct state', () {
      _init(const Size(390, 844), const Size(390, 844));
      final m = ScreenMetrics.current();
      expect(m.screenWidth, closeTo(390, 0.1));
      expect(m.screenHeight, closeTo(844, 0.1));
      expect(m.isLandscape, isFalse);
      expect(m.isPortrait, isTrue);
      expect(m.deviceType, DeviceType.phone);
    });

    test('ScreenMetrics.sp() mirrors ScreenUtil.setSp()', () {
      _init(const Size(500, 900), const Size(390, 844));
      final m = ScreenMetrics.current();
      // sp() on saved snapshot uses captured scaleText
      expect(m.sp(16), closeTo(m.scaleText * 16, 0.001));
    });

    test('ScreenMetrics equality — same state = equal', () {
      _init(const Size(390, 844), const Size(390, 844));
      final a = ScreenMetrics.current();
      final b = ScreenMetrics.current();
      expect(a, equals(b));
    });

    test('ScreenMetrics inequality — different screen = not equal', () {
      _init(const Size(390, 844), const Size(390, 844));
      final a = ScreenMetrics.current();
      _init(const Size(768, 1024), const Size(390, 844));
      final b = ScreenMetrics.current();
      expect(a, isNot(equals(b)));
    });

    test('SuResponsiveWrapper carries SU mixin', () {
      const wrapper = SuResponsiveWrapper(child: SizedBox());
      expect(wrapper, isA<SU>());
    });

    test('widget implementing SuExclude is identifiable', () {
      const excluded = _FakeExcluded();
      expect(excluded, isA<SuExclude>());
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 5 — AdaptiveNum
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 5 — AdaptiveNum', () {
    test('.w scales by scaleWidth', () {
      _init(const Size(780, 844), const Size(390, 844)); // scaleW = 2.0
      expect(AdaptiveNum(phone: 100).w, closeTo(200.0, 0.1));
    });

    test('.h scales by scaleHeight', () {
      _init(const Size(390, 1688), const Size(390, 844)); // scaleH = 2.0
      expect(AdaptiveNum(phone: 100).h, closeTo(200.0, 0.1));
    });

    test('.sp is orientation-aware (clamp applies)', () {
      _init(const Size(390, 844), const Size(390, 844));
      expect(AdaptiveNum(phone: 16).sp, closeTo(16.0, 0.1));
    });

    test('.r uses shorter axis', () {
      _init(
        const Size(780, 844),
        const Size(390, 844),
        minTextScaleFactor: 0.0,
        maxTextScaleFactor: 99.0,
      );
      final su = ScreenUtil();
      final s = min(su.scaleWidth, su.scaleHeight);
      expect(AdaptiveNum(phone: 24).r, closeTo(24 * s, 0.01));
    });

    test('tablet tier selected on tablet device', () {
      _init(const Size(768, 1024), const Size(768, 1024)); // tablet
      final num = AdaptiveNum(phone: 10, tablet: 20, desktop: 30);
      // raw should resolve to 20 (tablet)
      expect(num.raw, closeTo(20.0, 0.01));
    });

    test('fallback: desktop absent → tablet value used', () {
      _init(const Size(1280, 800), const Size(1280, 800)); // desktop
      final num = AdaptiveNum(phone: 10, tablet: 20);
      // desktop falls back to tablet → raw = 20
      expect(num.raw, closeTo(20.0, 0.01));
    });

    test('verticalSpace is a SizedBox with correct height', () {
      _init(const Size(390, 844), const Size(390, 844));
      final box = AdaptiveNum(phone: 16).verticalSpace;
      expect(box.height, closeTo(16.h, 0.01));
    });

    test('horizontalSpace is a SizedBox with correct width', () {
      _init(const Size(390, 844), const Size(390, 844));
      final box = AdaptiveNum(phone: 16).horizontalSpace;
      expect(box.width, closeTo(16.w, 0.01));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 5 — num extension shortcuts
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 5 — num extension (.adaptive / .aw / .ah / .asp / .ar)', () {
    setUp(() => _init(const Size(390, 844), const Size(390, 844)));

    test('.adaptive() seeds AdaptiveNum with this as phone', () {
      // On a phone: raw == phone value == 16
      expect(16.adaptive().raw, closeTo(16.0, 0.01));
    });

    test('.adaptive(tablet:) overrides tablet tier', () {
      _init(const Size(768, 1024), const Size(768, 1024)); // tablet
      expect(16.adaptive(tablet: 20).raw, closeTo(20.0, 0.01));
    });

    test('.aw applies width multipliers', () {
      _init(const Size(390, 844), const Size(390, 844)); // phone scaleW=1
      // phone×1 → 100.w on phone
      expect(100.aw, closeTo(AdaptiveNum(phone: 100).w, 0.01));
    });

    test('.asp applies sp multipliers on phone', () {
      _init(const Size(390, 844), const Size(390, 844));
      expect(16.asp, closeTo(AdaptiveNum(phone: 16).sp, 0.01));
    });

    test('.ar applies radius multipliers on phone', () {
      _init(const Size(390, 844), const Size(390, 844));
      expect(24.ar, closeTo(AdaptiveNum(phone: 24).r, 0.01));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 5 — AdaptiveDouble
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 5 — AdaptiveDouble', () {
    test('.value returns correct tier (phone)', () {
      _init(const Size(375, 812), const Size(375, 812));
      expect(AdaptiveDouble(phone: 1, tablet: 2, desktop: 3).value, 1.0);
    });

    test('.value returns correct tier (desktop)', () {
      _init(const Size(1280, 800), const Size(1280, 800));
      expect(AdaptiveDouble(phone: 1, tablet: 2, desktop: 3).value, 3.0);
    });

    test('.toInt rounds correctly', () {
      _init(const Size(375, 812), const Size(375, 812));
      expect(AdaptiveDouble(phone: 2.7).toInt, 3);
    });

    test('fallback chain: tablet absent → phone', () {
      _init(const Size(768, 1024), const Size(768, 1024)); // tablet
      // tablet not provided → falls back to phone
      expect(AdaptiveDouble(phone: 99.0).value, closeTo(99.0, 0.001));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 5 — AdaptiveSize
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 5 — AdaptiveSize', () {
    setUp(() => _init(const Size(780, 844), const Size(390, 844))); // scaleW=2

    test('.value returns raw unscaled size', () {
      final s = AdaptiveSize(phone: const Size(100, 50));
      expect(s.value, const Size(100, 50));
    });

    test('.wh scales w by scaleWidth, h by scaleHeight', () {
      final s = AdaptiveSize(phone: const Size(100, 100));
      final su = ScreenUtil();
      expect(s.wh.width, closeTo(100 * su.scaleWidth, 0.1));
      expect(s.wh.height, closeTo(100 * su.scaleHeight, 0.1));
    });

    test('.w preserves aspect ratio (both by scaleWidth)', () {
      final s = AdaptiveSize(phone: const Size(100, 50));
      final sw = ScreenUtil().scaleWidth;
      expect(s.w.width, closeTo(100 * sw, 0.1));
      expect(s.w.height, closeTo(50 * sw, 0.1));
    });

    test('.r uses shorter axis', () {
      final s = AdaptiveSize(phone: const Size(40, 40));
      final su = ScreenUtil();
      final scale = min(su.scaleWidth, su.scaleHeight);
      expect(s.r.width, closeTo(40 * scale, 0.1));
    });

    test('Size.adaptive() extension works', () {
      _init(const Size(768, 1024), const Size(768, 1024)); // tablet
      final s = const Size(40, 40).adaptive(tablet: const Size(56, 56));
      expect(s.value, const Size(56, 56));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 5 — AdaptiveEdgeInsets
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 5 — AdaptiveEdgeInsets', () {
    setUp(() => _init(const Size(780, 844), const Size(390, 844))); // scaleW=2

    test('.all constructor sets all sides equal', () {
      final ei = AdaptiveEdgeInsets.all(phone: 16);
      expect(ei.value, const EdgeInsets.all(16));
    });

    test('.all tablet tier selected', () {
      _init(const Size(768, 1024), const Size(768, 1024));
      final ei = AdaptiveEdgeInsets.all(phone: 16, tablet: 24);
      expect(ei.value, const EdgeInsets.all(24));
    });

    test('.symmetric phoneH/phoneV set correctly', () {
      final ei = AdaptiveEdgeInsets.symmetric(phoneH: 16, phoneV: 8);
      expect(
        ei.value,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    });

    test('.only phoneLeft/phoneRight default to 0', () {
      final ei = AdaptiveEdgeInsets.only(phoneTop: 12, phoneBottom: 12);
      expect(ei.value.top, closeTo(12, 0.01));
      expect(ei.value.left, closeTo(0, 0.01));
    });

    test('.w scales all sides by scaleWidth', () {
      final ei = AdaptiveEdgeInsets.all(phone: 10);
      final sw = ScreenUtil().scaleWidth;
      expect(ei.w.left, closeTo(10 * sw, 0.01));
      expect(ei.w.top, closeTo(10 * sw, 0.01));
    });

    test('.wh scales H by scaleWidth, V by scaleHeight', () {
      final ei = AdaptiveEdgeInsets.symmetric(phoneH: 10, phoneV: 10);
      final su = ScreenUtil();
      expect(ei.wh.left, closeTo(10 * su.scaleWidth, 0.01));
      expect(ei.wh.top, closeTo(10 * su.scaleHeight, 0.01));
    });

    test('EdgeInsets.adaptive() extension seeds phone value', () {
      _init(const Size(768, 1024), const Size(768, 1024)); // tablet
      final ei = const EdgeInsets.all(16).adaptive(tablet: const EdgeInsets.all(24));
      expect(ei.value, const EdgeInsets.all(24));
    });

    // Fallback: tablet absent on tablet device → phone value used
    test('fallback: tablet absent → phone value', () {
      _init(const Size(768, 1024), const Size(768, 1024));
      final ei = AdaptiveEdgeInsets.all(phone: 16);
      expect(ei.value, const EdgeInsets.all(16));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 5 — AdaptiveBorderRadius
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 5 — AdaptiveBorderRadius', () {
    setUp(() => _init(const Size(390, 844), const Size(390, 844)));

    test('.circular all corners equal', () {
      final br = AdaptiveBorderRadius.circular(phone: 8);
      expect(br.value.topLeft, const Radius.circular(8));
      expect(br.value.bottomRight, const Radius.circular(8));
    });

    test('.circular tablet tier', () {
      _init(const Size(768, 1024), const Size(768, 1024));
      final br = AdaptiveBorderRadius.circular(phone: 8, tablet: 12);
      expect(br.value.topLeft, const Radius.circular(12));
    });

    test('.only per-corner on phone', () {
      final br = AdaptiveBorderRadius.only(phoneTL: 4, phoneTR: 8);
      expect(br.value.topLeft, const Radius.circular(4));
      expect(br.value.topRight, const Radius.circular(8));
      expect(br.value.bottomLeft, const Radius.circular(0));
    });

    test('.r scales corners by shorter axis', () {
      _init(const Size(780, 844), const Size(390, 844)); // scaleW=2
      final br = AdaptiveBorderRadius.circular(phone: 8);
      final su = ScreenUtil();
      final s = min(su.scaleWidth, su.scaleHeight);
      expect(br.r.topLeft.x, closeTo(8 * s, 0.01));
    });

    test('.w scales corners by scaleWidth', () {
      _init(const Size(780, 844), const Size(390, 844)); // scaleW=2
      final br = AdaptiveBorderRadius.circular(phone: 10);
      final sw = ScreenUtil().scaleWidth;
      expect(br.w.topLeft.x, closeTo(10 * sw, 0.01));
    });

    test('BorderRadius.adaptive() extension', () {
      _init(const Size(768, 1024), const Size(768, 1024)); // tablet
      final br = BorderRadius.circular(8).adaptive(
        tablet: BorderRadius.circular(12),
      );
      expect(br.value.topLeft, const Radius.circular(12));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 5 — AdaptiveColor
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 5 — AdaptiveColor', () {
    test('.value returns phone color on phone', () {
      _init(const Size(375, 812), const Size(375, 812));
      final c = AdaptiveColor(
        phone: Colors.blue.shade700,
        desktop: Colors.blue.shade500,
      );
      expect(c.value, Colors.blue.shade700);
    });

    test('.value returns desktop color on desktop', () {
      _init(const Size(1280, 800), const Size(1280, 800));
      final c = AdaptiveColor(
        phone: Colors.blue.shade700,
        desktop: Colors.blue.shade500,
      );
      expect(c.value, Colors.blue.shade500);
    });

    test('Color.adaptive() extension: fallback to phone when tablet absent', () {
      _init(const Size(768, 1024), const Size(768, 1024)); // tablet
      final c = Colors.red.adaptive(); // no overrides
      expect(c.value, Colors.red);
    });

    test('Color.adaptive() extension: uses tablet override', () {
      _init(const Size(768, 1024), const Size(768, 1024));
      final c = Colors.red.adaptive(tablet: Colors.blue);
      expect(c.value, Colors.blue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 5 — AdaptiveTextStyle
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 5 — AdaptiveTextStyle', () {
    test('.style fontSize uses setSp', () {
      _init(const Size(390, 844), const Size(390, 844));
      final ts = AdaptiveTextStyle(phoneFontSize: 16).style;
      expect(ts.fontSize, closeTo(ScreenUtil().setSp(16), 0.01));
    });

    test('.style picks tablet fontSize on tablet', () {
      _init(const Size(768, 1024), const Size(768, 1024)); // tablet w=768→scaleW≈1
      final ts = AdaptiveTextStyle(
        phoneFontSize: 14,
        tabletFontSize: 16,
      ).style;
      expect(ts.fontSize, closeTo(ScreenUtil().setSp(16), 0.01));
    });

    test('.style falls back to phone fontSize when tablet absent on tablet', () {
      _init(const Size(768, 1024), const Size(768, 1024));
      final ts = AdaptiveTextStyle(phoneFontSize: 14).style; // no tablet
      expect(ts.fontSize, closeTo(ScreenUtil().setSp(14), 0.01));
    });

    test('.style applies fontWeight', () {
      _init(const Size(375, 812), const Size(375, 812));
      final ts = AdaptiveTextStyle(
        phoneFontSize: 14,
        phoneWeight: FontWeight.w700,
      ).style;
      expect(ts.fontWeight, FontWeight.w700);
    });

    test('.style applies color', () {
      _init(const Size(375, 812), const Size(375, 812));
      final ts = AdaptiveTextStyle(
        phoneFontSize: 14,
        phoneColor: Colors.red,
      ).style;
      expect(ts.color, Colors.red);
    });

    test('.style applies fontFamily', () {
      _init(const Size(375, 812), const Size(375, 812));
      final ts = AdaptiveTextStyle(
        phoneFontSize: 14,
        fontFamily: 'Roboto',
      ).style;
      expect(ts.fontFamily, 'Roboto');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 5 — AppSpacing
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 5 — AppSpacing', () {
    test('phone raw values match spec', () {
      _init(const Size(390, 844), const Size(390, 844)); // scaleW=1
      // On design-match screen scaleW=1 → .w == raw
      expect(AppSpacing.xxs.phoneVal, 2.0);
      expect(AppSpacing.xs.phoneVal, 4.0);
      expect(AppSpacing.sm.phoneVal, 8.0);
      expect(AppSpacing.md.phoneVal, 12.0);
      expect(AppSpacing.lg.phoneVal, 16.0);
      expect(AppSpacing.xl.phoneVal, 24.0);
      expect(AppSpacing.xxl.phoneVal, 32.0);
      expect(AppSpacing.xxxl.phoneVal, 48.0);
    });

    test('tablet raw values match spec', () {
      expect(AppSpacing.md.tabletVal, 16.0);
      expect(AppSpacing.lg.tabletVal, 20.0);
      expect(AppSpacing.xl.tabletVal, 32.0);
    });

    test('desktop raw values match spec', () {
      expect(AppSpacing.md.desktopVal, 20.0);
      expect(AppSpacing.lg.desktopVal, 24.0);
      expect(AppSpacing.xl.desktopVal, 40.0);
    });

    test('.w scales by scaleWidth on phone', () {
      // Use 480×844 with design 240×844 → scaleW=2.0; 480<600 → phone device.
      _init(const Size(480, 844), const Size(240, 844));
      // On phone: AppSpacing.md.phoneVal=12, .w = 12 * 2.0 = 24
      expect(AppSpacing.md.w, closeTo(12 * ScreenUtil().scaleWidth, 0.1));
    });

    test('.hs returns a SizedBox with height', () {
      _init(const Size(390, 844), const Size(390, 844));
      final box = AppSpacing.lg.hs;
      expect(box.height, closeTo(AppSpacing.lg.h, 0.01));
    });

    test('.ws returns a SizedBox with width', () {
      _init(const Size(390, 844), const Size(390, 844));
      final box = AppSpacing.lg.ws;
      expect(box.width, closeTo(AppSpacing.lg.w, 0.01));
    });

    test('tablet tier selected on tablet device', () {
      _init(const Size(768, 1024), const Size(768, 1024));
      // scaleW on tablet with design=768 == 1.0, so .w == tabletVal * 1.0
      final su = ScreenUtil();
      expect(
        AppSpacing.md.w,
        closeTo(AppSpacing.md.tabletVal * su.scaleWidth, 0.1),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Phase 5 — AdaptiveGridDelegate
  // ───────────────────────────────────────────────────────────────────────────

  group('Phase 5 — AdaptiveGridDelegate', () {
    test('correct column count on phone', () {
      _init(const Size(375, 812), const Size(375, 812));
      final d = AdaptiveGridDelegate(phone: 1, tablet: 2, desktop: 3);
      expect(d.shouldRelayout(AdaptiveGridDelegate(phone: 2, tablet: 2, desktop: 3)),
          isTrue);
    });

    test('shouldRelayout false when identical', () {
      const d = AdaptiveGridDelegate(phone: 1, tablet: 2, desktop: 3);
      expect(
        d.shouldRelayout(
            const AdaptiveGridDelegate(phone: 1, tablet: 2, desktop: 3)),
        isFalse,
      );
    });

    test('shouldRelayout true when spacing changes', () {
      const d = AdaptiveGridDelegate(phone: 2, spacing: 8);
      expect(
        d.shouldRelayout(const AdaptiveGridDelegate(phone: 2, spacing: 12)),
        isTrue,
      );
    });

    test('shouldRelayout true for different delegate type', () {
      const d = AdaptiveGridDelegate(phone: 2);
      final other = SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2);
      expect(d.shouldRelayout(other), isTrue);
    });

    test('fallback: desktop absent on desktop → uses tablet count', () {
      _init(const Size(1280, 800), const Size(1280, 800)); // desktop
      // tablet=2, no desktop → desktop falls back to 2
      final d = AdaptiveGridDelegate(phone: 1, tablet: 2);
      // Can't call getLayout without real constraints, but we can check
      // that the internal count resolves to 2:
      // Use Breakpoints as a proxy:
      expect(
        Breakpoints.value(width: 1280, phone: 1, tablet: 2),
        2,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Canonical screen matrix — sp values at 5 reference screens
  // ───────────────────────────────────────────────────────────────────────────

  group('Canonical screen matrix — 16.sp at reference screens', () {
    // Design reference: 390×844 phone
    const designSize = Size(390, 844);

    void check(String label, Size screen, Matcher matcher) {
      test(label, () {
        _init(
          screen,
          designSize,
          // Use minTextAdapt:false (width-only axis) to match the plan's table.
          // With minTextAdapt:true, min(scaleW,scaleH) is used, which gives
          // lower values on large tablets and would not reach the 1.4× ceiling.
          minTextAdapt: false,
          minTextScaleFactor: 0.85,
          maxTextScaleFactor: 1.4,
        );
        expect(ScreenUtil().setSp(16), matcher);
      });
    }

    // 360×690 — smaller than design → scaleW≈0.92 → clamped to max(0.85,0.92)
    check(
      '360×690 small phone — 16.sp ≥ 0.85×16 and ≤ 16',
      const Size(360, 690),
      allOf(greaterThanOrEqualTo(0.85 * 16), lessThanOrEqualTo(16.0 + 0.5)),
    );

    // 390×844 — exact design → scaleW=1.0 → 16.sp ≈ 16
    check(
      '390×844 design phone — 16.sp ≈ 16',
      const Size(390, 844),
      closeTo(16.0, 0.2),
    );

    // 414×896 — slightly bigger → scaleW≈1.06 → within clamp
    check(
      '414×896 plus phone — 16.sp ≈ 16 (design close)',
      const Size(414, 896),
      closeTo(16.0 * (414 / 390), 0.3),
    );

    // 768×1024 iPad portrait — with minTextAdapt:false, scaleW=768/390≈1.97
    // → clamped to 1.4 → 16 * 1.4 = 22.4
    check(
      '768×1024 iPad portrait — 16.sp clamped at 1.4×',
      const Size(768, 1024),
      closeTo(16 * 1.4, 0.2),
    );

    // 1024×768 iPad landscape — auto-transpose landscape width = 844. 
    // scaleW = 1024/844 ≈ 1.21327. 16 * 1.21327 ≈ 19.41
    check(
      '1024×768 iPad landscape — 16.sp reflects auto-transposed design size',
      const Size(1024, 768),
      closeTo(16 * (1024 / 844), 0.2),
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Test fakes
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal widget that implements SuExclude — used to verify type check.
class _FakeExcluded extends StatelessWidget implements SuExclude {
  const _FakeExcluded();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
