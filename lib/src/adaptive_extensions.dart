/// Phase 5 — Advanced Adaptive Extensions.
///
/// Every major Flutter dimension type now has an adaptive variant that
/// understands phone / tablet / desktop / TV device classes and plugs
/// directly into [ScreenUtil]'s orientation-aware scaling.
///
/// **Quick-reference:**
///
/// | Class | Use for |
/// |---|---|
/// | [AdaptiveNum] | Lengths, sizes, font sizes — any `num` value |
/// | [AdaptiveDouble] | Unitless doubles: opacities, flex ratios, counts |
/// | [AdaptiveSize] | Flutter [Size] objects (icon boxes, image frames) |
/// | [AdaptiveEdgeInsets] | Padding / margin |
/// | [AdaptiveTextStyle] | Full [TextStyle] including weight and color |
/// | [AdaptiveBorderRadius] | Corner radii |
/// | [AdaptiveColor] | Brand colours that shift per device |
/// | [AppSpacing] | Semantic T-shirt-size spacing tokens |
/// | [AdaptiveGridDelegate] | `SliverGridDelegate` with adaptive column count |
library flutter_screenutil.adaptive_extensions;

import 'dart:math' show min;

import 'package:flutter/rendering.dart'
    show
        SliverConstraints,
        SliverGridDelegate,
        SliverGridLayout,
        SliverGridRegularTileLayout;
import 'package:flutter/widgets.dart';

import 'screen_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal helper — resolves the correct value for the current device type.
// ─────────────────────────────────────────────────────────────────────────────

T _resolve<T>(T phone, T? tablet, T? desktop, T? tv) {
  final su = ScreenUtil();
  if (su.isTV) return tv ?? desktop ?? tablet ?? phone;
  if (su.isDesktop) return desktop ?? tablet ?? phone;
  if (su.isTablet) return tablet ?? phone;
  return phone;
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveNum
// ─────────────────────────────────────────────────────────────────────────────

/// A dimensional value that provides different raw dp values per device class,
/// then exposes every [ScreenUtil] scaling axis as a getter.
///
/// ```dart
/// // Width
/// Container(
///   width: AdaptiveNum(phone: 200, tablet: 320, desktop: 480).w,
/// )
///
/// // Font size
/// Text(
///   'Heading',
///   style: TextStyle(
///     fontSize: AdaptiveNum(phone: 20, tablet: 24, desktop: 28).sp,
///   ),
/// )
///
/// // Icon (square — uses shorter axis)
/// Icon(Icons.star, size: AdaptiveNum(phone: 24, tablet: 32, desktop: 40).r)
///
/// // Spacing widget
/// AdaptiveNum(phone: 12, tablet: 16, desktop: 24).verticalSpace
/// ```
class AdaptiveNum {
  /// Creates an [AdaptiveNum].
  ///
  /// [phone] is required; other tiers fall back to the next smaller value.
  const AdaptiveNum({
    required this.phone,
    this.tablet,
    this.desktop,
    this.tv,
  });

  final num phone;
  final num? tablet;
  final num? desktop;
  final num? tv;

  /// Resolved raw value for the current device (unscaled, in design dp).
  num get _raw => _resolve(phone, tablet, desktop, tv);

  /// Unscaled value — already in logical pixels as designed.
  double get raw => _raw.toDouble();

  /// Scaled to screen width (`.w` axis).
  double get w => ScreenUtil().setWidth(_raw);

  /// Scaled to screen height (`.h` axis).
  double get h => ScreenUtil().setHeight(_raw);

  /// Orientation-aware font size (`.sp` axis, respects [ScreenUtil.minTextAdapt]).
  double get sp => ScreenUtil().setSp(_raw);

  /// Scaled to the shorter axis — ideal for radii and icon sizes (`.r` axis).
  double get r => ScreenUtil().radius(_raw);

  /// Diagonal scale — `scaleWidth × scaleHeight`.
  double get dm => ScreenUtil().diagonal(_raw);

  /// A [SizedBox] with this value as its **height** (vertical spacer).
  SizedBox get verticalSpace => SizedBox(height: h);

  /// A [SizedBox] with this value as its **width** (horizontal spacer).
  SizedBox get horizontalSpace => SizedBox(width: w);

  @override
  String toString() => 'AdaptiveNum(phone: $phone, tablet: $tablet, '
      'desktop: $desktop, tv: $tv) → raw=${_raw.toStringAsFixed(2)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// num extension — .adaptive() + quick-shortcut getters
// ─────────────────────────────────────────────────────────────────────────────

/// Extensions on [num] that integrate adaptive layout directly into numeric
/// literals and variables.
extension AdaptiveNumExtension on num {
  /// Seeds an [AdaptiveNum] using `this` as the phone value.
  ///
  /// Override only the breakpoints you need; others fall back automatically:
  ///
  /// ```dart
  /// 16.adaptive(tablet: 18, desktop: 20).sp
  /// 12.adaptive(tablet: 16).verticalSpace
  /// ```
  AdaptiveNum adaptive({num? tablet, num? desktop, num? tv}) =>
      AdaptiveNum(phone: this, tablet: tablet, desktop: desktop, tv: tv);

  // ── Quick shortcut getters (golden-ratio multipliers) ──────────────────

  /// Adaptive width: phone×1, tablet×1.3, desktop×1.6.
  ///
  /// ```dart
  /// Container(width: 200.aw)   // 200 → 260 → 320 depending on device
  /// ```
  double get aw =>
      AdaptiveNum(phone: this, tablet: this * 1.3, desktop: this * 1.6).w;

  /// Adaptive height: phone×1, tablet×1.2, desktop×1.4.
  ///
  /// ```dart
  /// SizedBox(height: 100.ah)
  /// ```
  double get ah =>
      AdaptiveNum(phone: this, tablet: this * 1.2, desktop: this * 1.4).h;

  /// Adaptive font size: phone×1, tablet×1.15, desktop×1.25 (gentler growth).
  ///
  /// ```dart
  /// Text('Hello', style: TextStyle(fontSize: 14.asp))
  /// ```
  double get asp =>
      AdaptiveNum(phone: this, tablet: this * 1.15, desktop: this * 1.25).sp;

  /// Adaptive radius / icon size: phone×1, tablet×1.2, desktop×1.3.
  ///
  /// ```dart
  /// Icon(Icons.star, size: 24.ar)
  /// ```
  double get ar =>
      AdaptiveNum(phone: this, tablet: this * 1.2, desktop: this * 1.3).r;
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveDouble
// ─────────────────────────────────────────────────────────────────────────────

/// A raw `double` that picks a value per device class with **no** [ScreenUtil]
/// scaling applied.
///
/// Use for unitless quantities: column counts, flex ratios, opacities,
/// animation durations in milliseconds.
///
/// ```dart
/// // Column count
/// GridView.count(
///   crossAxisCount: AdaptiveDouble(phone: 1, tablet: 2, desktop: 4).toInt,
/// )
///
/// // Opacity
/// Opacity(
///   opacity: AdaptiveDouble(phone: 1.0, tablet: 0.9, desktop: 0.8).value,
///   child: SidePanel(),
/// )
///
/// // Flex
/// Expanded(
///   flex: AdaptiveDouble(phone: 1, tablet: 2, desktop: 3).toInt,
///   child: Content(),
/// )
/// ```
class AdaptiveDouble {
  const AdaptiveDouble({
    required this.phone,
    this.tablet,
    this.desktop,
    this.tv,
  });

  final double phone;
  final double? tablet;
  final double? desktop;
  final double? tv;

  /// Resolved value for the current device — no scaling applied.
  double get value => _resolve(phone, tablet, desktop, tv);

  /// Resolved value rounded to the nearest integer.
  int get toInt => value.round();

  @override
  String toString() =>
      'AdaptiveDouble(${value.toStringAsFixed(2)})';
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveSize
// ─────────────────────────────────────────────────────────────────────────────

/// A [Size] value per device class, with multiple scaling modes.
///
/// ```dart
/// final avatarSize = AdaptiveSize(
///   phone:   const Size(40, 40),
///   tablet:  const Size(56, 56),
///   desktop: const Size(72, 72),
/// );
///
/// CircleAvatar(radius: avatarSize.r.width / 2)
///
/// SizedBox.fromSize(size: bannerSize.wh)
/// ```
class AdaptiveSize {
  const AdaptiveSize({
    required this.phone,
    this.tablet,
    this.desktop,
    this.tv,
  });

  final Size phone;
  final Size? tablet;
  final Size? desktop;
  final Size? tv;

  /// Resolved [Size] for the current device — raw, unscaled.
  Size get value => _resolve(phone, tablet, desktop, tv);

  /// Width scaled by [ScreenUtil.scaleWidth], height by [ScreenUtil.scaleHeight].
  Size get wh {
    final v = value;
    final su = ScreenUtil();
    return Size(su.setWidth(v.width), su.setHeight(v.height));
  }

  /// Both axes scaled by [ScreenUtil.scaleWidth] — preserves aspect ratio.
  Size get w {
    final v = value;
    final sw = ScreenUtil().scaleWidth;
    return Size(v.width * sw, v.height * sw);
  }

  /// Both axes scaled by the **shorter** scale axis — ideal for square icons.
  Size get r {
    final v = value;
    final su = ScreenUtil();
    final s = min(su.scaleWidth, su.scaleHeight);
    return Size(v.width * s, v.height * s);
  }

  @override
  String toString() => 'AdaptiveSize(value: $value)';
}

/// Extension on [Size] to conveniently create an [AdaptiveSize].
extension AdaptiveSizeExtension on Size {
  /// Seeds an [AdaptiveSize] using `this` as the phone value.
  ///
  /// ```dart
  /// SizedBox.fromSize(
  ///   size: const Size(200, 60).adaptive(
  ///     tablet:  const Size(280, 72),
  ///     desktop: const Size(360, 80),
  ///   ).wh,
  /// )
  /// ```
  AdaptiveSize adaptive({Size? tablet, Size? desktop, Size? tv}) =>
      AdaptiveSize(phone: this, tablet: tablet, desktop: desktop, tv: tv);
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveEdgeInsets
// ─────────────────────────────────────────────────────────────────────────────

/// Per-device [EdgeInsets] with multiple scaling modes.
///
/// ```dart
/// Padding(
///   padding: AdaptiveEdgeInsets.symmetric(
///     phoneH: 16, phoneV: 12,
///     tabletH: 24, tabletV: 16,
///     desktopH: 40, desktopV: 20,
///   ).wh,
/// )
/// ```
class AdaptiveEdgeInsets {
  const AdaptiveEdgeInsets({
    required this.phone,
    this.tablet,
    this.desktop,
    this.tv,
  });

  /// All sides equal per device.
  ///
  /// ```dart
  /// AdaptiveEdgeInsets.all(phone: 16, tablet: 24, desktop: 32).w
  /// ```
  AdaptiveEdgeInsets.all({
    required double phone,
    double? tablet,
    double? desktop,
    double? tv,
  }) : this(
          phone: EdgeInsets.all(phone),
          tablet: tablet != null ? EdgeInsets.all(tablet) : null,
          desktop: desktop != null ? EdgeInsets.all(desktop) : null,
          tv: tv != null ? EdgeInsets.all(tv) : null,
        );

  /// Symmetric insets per device.
  ///
  /// Omitted sides fall back to the phone values.
  ///
  /// ```dart
  /// AdaptiveEdgeInsets.symmetric(
  ///   phoneH: 16, phoneV: 12,
  ///   tabletH: 24, tabletV: 16,
  ///   desktopH: 40, desktopV: 20,
  /// ).wh
  /// ```
  AdaptiveEdgeInsets.symmetric({
    required double phoneH,
    required double phoneV,
    double? tabletH,
    double? tabletV,
    double? desktopH,
    double? desktopV,
    double? tvH,
    double? tvV,
  }) : this(
          phone: EdgeInsets.symmetric(
            horizontal: phoneH,
            vertical: phoneV,
          ),
          tablet: (tabletH != null || tabletV != null)
              ? EdgeInsets.symmetric(
                  horizontal: tabletH ?? phoneH,
                  vertical: tabletV ?? phoneV,
                )
              : null,
          desktop: (desktopH != null || desktopV != null)
              ? EdgeInsets.symmetric(
                  horizontal: desktopH ?? phoneH,
                  vertical: desktopV ?? phoneV,
                )
              : null,
          tv: (tvH != null || tvV != null)
              ? EdgeInsets.symmetric(
                  horizontal: tvH ?? phoneH,
                  vertical: tvV ?? phoneV,
                )
              : null,
        );

  /// Per-side insets per device.  Omitted tablet/desktop sides fall
  /// back to the corresponding phone value.
  ///
  /// ```dart
  /// AdaptiveEdgeInsets.only(
  ///   phoneLeft: 16, phoneTop: 8, phoneRight: 16, phoneBottom: 8,
  ///   tabletLeft: 24, tabletTop: 12,
  /// ).w
  /// ```
  AdaptiveEdgeInsets.only({
    double phoneLeft = 0,
    double phoneTop = 0,
    double phoneRight = 0,
    double phoneBottom = 0,
    double? tabletLeft,
    double? tabletTop,
    double? tabletRight,
    double? tabletBottom,
    double? desktopLeft,
    double? desktopTop,
    double? desktopRight,
    double? desktopBottom,
  }) : this(
          phone: EdgeInsets.only(
            left: phoneLeft,
            top: phoneTop,
            right: phoneRight,
            bottom: phoneBottom,
          ),
          tablet: (tabletLeft ??
                      tabletTop ??
                      tabletRight ??
                      tabletBottom) !=
                  null
              ? EdgeInsets.only(
                  left: tabletLeft ?? phoneLeft,
                  top: tabletTop ?? phoneTop,
                  right: tabletRight ?? phoneRight,
                  bottom: tabletBottom ?? phoneBottom,
                )
              : null,
          desktop: (desktopLeft ??
                      desktopTop ??
                      desktopRight ??
                      desktopBottom) !=
                  null
              ? EdgeInsets.only(
                  left: desktopLeft ?? phoneLeft,
                  top: desktopTop ?? phoneTop,
                  right: desktopRight ?? phoneRight,
                  bottom: desktopBottom ?? phoneBottom,
                )
              : null,
        );

  final EdgeInsets phone;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;
  final EdgeInsets? tv;

  /// Resolved [EdgeInsets] for the current device — raw, unscaled.
  EdgeInsets get value => _resolve(phone, tablet, desktop, tv);

  /// All sides scaled by [ScreenUtil.scaleWidth].
  EdgeInsets get w {
    final v = value;
    final sw = ScreenUtil().scaleWidth;
    return EdgeInsets.only(
      left: v.left * sw,
      top: v.top * sw,
      right: v.right * sw,
      bottom: v.bottom * sw,
    );
  }

  /// Horizontal sides scaled by [ScreenUtil.scaleWidth],
  /// vertical sides by [ScreenUtil.scaleHeight].
  EdgeInsets get wh {
    final v = value;
    final su = ScreenUtil();
    return EdgeInsets.only(
      left: v.left * su.scaleWidth,
      top: v.top * su.scaleHeight,
      right: v.right * su.scaleWidth,
      bottom: v.bottom * su.scaleHeight,
    );
  }

  /// All sides scaled by the **shorter** axis.
  EdgeInsets get r {
    final v = value;
    final su = ScreenUtil();
    final s = min(su.scaleWidth, su.scaleHeight);
    return EdgeInsets.only(
      left: v.left * s,
      top: v.top * s,
      right: v.right * s,
      bottom: v.bottom * s,
    );
  }

  @override
  String toString() => 'AdaptiveEdgeInsets(value: $value)';
}

/// Extension on [EdgeInsets] to conveniently create an [AdaptiveEdgeInsets].
extension AdaptiveEdgeInsetsExtension on EdgeInsets {
  /// Seeds an [AdaptiveEdgeInsets] using `this` as the phone value.
  ///
  /// ```dart
  /// Padding(
  ///   padding: EdgeInsets.all(16).adaptive(
  ///     tablet:  EdgeInsets.all(24),
  ///     desktop: EdgeInsets.all(40),
  ///   ).w,
  /// )
  /// ```
  AdaptiveEdgeInsets adaptive({
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? tv,
  }) =>
      AdaptiveEdgeInsets(
        phone: this,
        tablet: tablet,
        desktop: desktop,
        tv: tv,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveBorderRadius
// ─────────────────────────────────────────────────────────────────────────────

/// Per-device [BorderRadius] with scaling.
///
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: AdaptiveBorderRadius.circular(
///       phone: 8, tablet: 12, desktop: 16,
///     ).r,
///   ),
/// )
/// ```
class AdaptiveBorderRadius {
  const AdaptiveBorderRadius({
    required this.phone,
    this.tablet,
    this.desktop,
    this.tv,
  });

  /// All corners equal per device.
  ///
  /// ```dart
  /// AdaptiveBorderRadius.circular(phone: 8, tablet: 12, desktop: 16).r
  /// ```
  AdaptiveBorderRadius.circular({
    required double phone,
    double? tablet,
    double? desktop,
    double? tv,
  }) : this(
          phone: BorderRadius.all(Radius.circular(phone)),
          tablet: tablet != null
              ? BorderRadius.all(Radius.circular(tablet))
              : null,
          desktop: desktop != null
              ? BorderRadius.all(Radius.circular(desktop))
              : null,
          tv: tv != null ? BorderRadius.all(Radius.circular(tv)) : null,
        );

  /// Per-corner radii per device.  Omitted tablet/desktop corners fall
  /// back to the corresponding phone corner.
  ///
  /// ```dart
  /// AdaptiveBorderRadius.only(
  ///   phoneTL: 8, phoneTR: 8,
  ///   tabletTL: 12, tabletTR: 12,
  ///   desktopTL: 16, desktopTR: 16,
  /// ).r
  /// ```
  AdaptiveBorderRadius.only({
    double phoneTL = 0,
    double phoneTR = 0,
    double phoneBL = 0,
    double phoneBR = 0,
    double? tabletTL,
    double? tabletTR,
    double? tabletBL,
    double? tabletBR,
    double? desktopTL,
    double? desktopTR,
    double? desktopBL,
    double? desktopBR,
  }) : this(
          phone: BorderRadius.only(
            topLeft: Radius.circular(phoneTL),
            topRight: Radius.circular(phoneTR),
            bottomLeft: Radius.circular(phoneBL),
            bottomRight: Radius.circular(phoneBR),
          ),
          tablet: (tabletTL ?? tabletTR ?? tabletBL ?? tabletBR) != null
              ? BorderRadius.only(
                  topLeft: Radius.circular(tabletTL ?? phoneTL),
                  topRight: Radius.circular(tabletTR ?? phoneTR),
                  bottomLeft: Radius.circular(tabletBL ?? phoneBL),
                  bottomRight: Radius.circular(tabletBR ?? phoneBR),
                )
              : null,
          desktop:
              (desktopTL ?? desktopTR ?? desktopBL ?? desktopBR) != null
                  ? BorderRadius.only(
                      topLeft: Radius.circular(desktopTL ?? phoneTL),
                      topRight: Radius.circular(desktopTR ?? phoneTR),
                      bottomLeft: Radius.circular(desktopBL ?? phoneBL),
                      bottomRight: Radius.circular(desktopBR ?? phoneBR),
                    )
                  : null,
        );

  final BorderRadius phone;
  final BorderRadius? tablet;
  final BorderRadius? desktop;
  final BorderRadius? tv;

  /// Resolved [BorderRadius] for the current device — raw, unscaled.
  BorderRadius get value => _resolve(phone, tablet, desktop, tv);

  /// Each corner radius scaled by the **shorter** axis (`min(scaleW, scaleH)`).
  BorderRadius get r {
    final v = value;
    final su = ScreenUtil();
    final s = min(su.scaleWidth, su.scaleHeight);
    return BorderRadius.only(
      topLeft: Radius.circular(v.topLeft.x * s),
      topRight: Radius.circular(v.topRight.x * s),
      bottomLeft: Radius.circular(v.bottomLeft.x * s),
      bottomRight: Radius.circular(v.bottomRight.x * s),
    );
  }

  /// Each corner radius scaled by [ScreenUtil.scaleWidth].
  BorderRadius get w {
    final v = value;
    final sw = ScreenUtil().scaleWidth;
    return BorderRadius.only(
      topLeft: Radius.circular(v.topLeft.x * sw),
      topRight: Radius.circular(v.topRight.x * sw),
      bottomLeft: Radius.circular(v.bottomLeft.x * sw),
      bottomRight: Radius.circular(v.bottomRight.x * sw),
    );
  }

  @override
  String toString() => 'AdaptiveBorderRadius(value: $value)';
}

/// Extension on [BorderRadius] to conveniently create an [AdaptiveBorderRadius].
extension AdaptiveBorderRadiusExtension on BorderRadius {
  /// Seeds an [AdaptiveBorderRadius] using `this` as the phone value.
  ///
  /// ```dart
  /// ClipRRect(
  ///   borderRadius: BorderRadius.circular(8).adaptive(
  ///     tablet:  BorderRadius.circular(12),
  ///     desktop: BorderRadius.circular(16),
  ///   ).r,
  /// )
  /// ```
  AdaptiveBorderRadius adaptive({
    BorderRadius? tablet,
    BorderRadius? desktop,
    BorderRadius? tv,
  }) =>
      AdaptiveBorderRadius(
        phone: this,
        tablet: tablet,
        desktop: desktop,
        tv: tv,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveColor
// ─────────────────────────────────────────────────────────────────────────────

/// A [Color] value that can shift per device class — useful for contrast
/// adjustments, tints, or opacity differences between phone and desktop.
///
/// ```dart
/// Container(
///   color: AdaptiveColor(
///     phone:   Colors.blue.shade700,   // higher contrast on small screen
///     tablet:  Colors.blue.shade600,
///     desktop: Colors.blue.shade500,
///   ).value,
/// )
/// ```
class AdaptiveColor {
  const AdaptiveColor({
    required this.phone,
    this.tablet,
    this.desktop,
    this.tv,
  });

  final Color phone;
  final Color? tablet;
  final Color? desktop;
  final Color? tv;

  /// Resolved [Color] for the current device.
  Color get value => _resolve(phone, tablet, desktop, tv);

  @override
  String toString() => 'AdaptiveColor(value: $value)';
}

/// Extension on [Color] to conveniently create an [AdaptiveColor].
extension AdaptiveColorExtension on Color {
  /// Seeds an [AdaptiveColor] using `this` as the phone value.
  ///
  /// ```dart
  /// Icon(
  ///   Icons.favorite,
  ///   color: Colors.red.shade600.adaptive(
  ///     tablet:  Colors.red.shade500,
  ///     desktop: Colors.red.shade400,
  ///   ).value,
  /// )
  /// ```
  AdaptiveColor adaptive({Color? tablet, Color? desktop, Color? tv}) =>
      AdaptiveColor(phone: this, tablet: tablet, desktop: desktop, tv: tv);
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveTextStyle
// ─────────────────────────────────────────────────────────────────────────────

/// A complete per-device [TextStyle] including font size, weight, and colour.
///
/// ```dart
/// Text(
///   'Section title',
///   style: AdaptiveTextStyle(
///     phoneFontSize:   20,
///     tabletFontSize:  24,
///     desktopFontSize: 28,
///     phoneWeight:     FontWeight.w700,
///     desktopWeight:   FontWeight.w500,
///     letterSpacing:   -0.5,
///   ).style,
/// )
/// ```
class AdaptiveTextStyle {
  const AdaptiveTextStyle({
    required this.phoneFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.tvFontSize,
    this.phoneWeight,
    this.tabletWeight,
    this.desktopWeight,
    this.tvWeight,
    this.phoneColor,
    this.tabletColor,
    this.desktopColor,
    this.tvColor,
    this.fontFamily,
    this.letterSpacing,
    this.height,
  });

  final num phoneFontSize;
  final num? tabletFontSize;
  final num? desktopFontSize;
  final num? tvFontSize;

  final FontWeight? phoneWeight;
  final FontWeight? tabletWeight;
  final FontWeight? desktopWeight;
  final FontWeight? tvWeight;

  final Color? phoneColor;
  final Color? tabletColor;
  final Color? desktopColor;
  final Color? tvColor;

  /// Optional font family applied across all device classes.
  final String? fontFamily;

  /// Optional letter spacing applied across all device classes (dp).
  final double? letterSpacing;

  /// Optional line height multiplier applied across all device classes.
  final double? height;

  /// Resolved, scaled [TextStyle] for the current device and orientation.
  TextStyle get style {
    final fontSize = _resolve(
      phoneFontSize,
      tabletFontSize,
      desktopFontSize,
      tvFontSize,
    );
    final fontWeight = _resolve<FontWeight?>(
      phoneWeight,
      tabletWeight,
      desktopWeight,
      tvWeight,
    );
    final color = _resolve<Color?>(
      phoneColor,
      tabletColor,
      desktopColor,
      tvColor,
    );

    return TextStyle(
      fontSize: ScreenUtil().setSp(fontSize),
      fontWeight: fontWeight,
      color: color,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSpacing — semantic T-shirt-size spacing tokens
// ─────────────────────────────────────────────────────────────────────────────

/// Semantic spacing tokens with pre-set adaptive values for all breakpoints.
///
/// | Token | Phone | Tablet | Desktop |
/// |---    |---    |---     |---      |
/// | [xxs] | 2dp   | 4dp    | 6dp     |
/// | [xs]  | 4dp   | 6dp    | 8dp     |
/// | [sm]  | 8dp   | 10dp   | 12dp    |
/// | [md]  | 12dp  | 16dp   | 20dp    |
/// | [lg]  | 16dp  | 20dp   | 24dp    |
/// | [xl]  | 24dp  | 32dp   | 40dp    |
/// | [xxl] | 32dp  | 48dp   | 64dp    |
/// | [xxxl]| 48dp  | 64dp   | 96dp    |
///
/// **Usage:**
///
/// ```dart
/// Column(
///   children: [
///     ProfileHeader(),
///     AppSpacing.lg.hs,        // 16dp phone, 20dp tablet, 24dp desktop
///     ProfileBody(),
///     AppSpacing.xl.hs,
///     ActionButtons(),
///   ],
/// )
///
/// Padding(
///   padding: EdgeInsets.symmetric(
///     horizontal: AppSpacing.lg.w,
///     vertical:   AppSpacing.md.h,
///   ),
///   child: content,
/// )
/// ```
/// Semantic spacing token.
///
/// Do not construct directly — use the named constants:
/// [AppSpacing.xxs], [AppSpacing.xs], [AppSpacing.sm], [AppSpacing.md],
/// [AppSpacing.lg], [AppSpacing.xl], [AppSpacing.xxl], [AppSpacing.xxxl].
class AppSpacing {
  const AppSpacing._({
    required double phone,
    required double tablet,
    required double desktop,
  })  : phoneVal = phone,
        tabletVal = tablet,
        desktopVal = desktop;

  /// Raw phone value in design dp.
  final double phoneVal;

  /// Raw tablet value in design dp.
  final double tabletVal;

  /// Raw desktop value in design dp.
  final double desktopVal;

  // ── Predefined tokens ───────────────────────────────────────────────────

  static const AppSpacing xxs  = AppSpacing._(phone: 2,  tablet: 4,  desktop: 6);
  static const AppSpacing xs   = AppSpacing._(phone: 4,  tablet: 6,  desktop: 8);
  static const AppSpacing sm   = AppSpacing._(phone: 8,  tablet: 10, desktop: 12);
  static const AppSpacing md   = AppSpacing._(phone: 12, tablet: 16, desktop: 20);
  static const AppSpacing lg   = AppSpacing._(phone: 16, tablet: 20, desktop: 24);
  static const AppSpacing xl   = AppSpacing._(phone: 24, tablet: 32, desktop: 40);
  static const AppSpacing xxl  = AppSpacing._(phone: 32, tablet: 48, desktop: 64);
  static const AppSpacing xxxl = AppSpacing._(phone: 48, tablet: 64, desktop: 96);

  AdaptiveNum get _adaptive =>
      AdaptiveNum(phone: phoneVal, tablet: tabletVal, desktop: desktopVal);

  /// Scaled to screen width.
  double get w => _adaptive.w;

  /// Scaled to screen height.
  double get h => _adaptive.h;

  /// Orientation-aware font size.
  double get sp => _adaptive.sp;

  /// Scaled to the shorter axis.
  double get r => _adaptive.r;

  /// A vertical [SizedBox] spacer (height = [h]).
  SizedBox get hs => _adaptive.verticalSpace;

  /// A horizontal [SizedBox] spacer (width = [w]).
  SizedBox get ws => _adaptive.horizontalSpace;

  @override
  String toString() =>
      'AppSpacing(phone: $phoneVal, tablet: $tabletVal, desktop: $desktopVal)';
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveGridDelegate
// ─────────────────────────────────────────────────────────────────────────────

/// A [SliverGridDelegate] with an adaptive cross-axis count driven by
/// [ScreenUtil]'s current device type.
///
/// ```dart
/// GridView.builder(
///   gridDelegate: AdaptiveGridDelegate(
///     phone:            1,
///     tablet:           2,
///     desktop:          3,
///     spacing:          12,
///     childAspectRatio: 0.75,
///   ),
///   itemCount: products.length,
///   itemBuilder: (_, i) => ProductCard(products[i]),
/// )
/// ```
class AdaptiveGridDelegate extends SliverGridDelegate {
  /// Creates an [AdaptiveGridDelegate].
  ///
  /// [phone] is required; other tiers fall back to the next smaller value.
  const AdaptiveGridDelegate({
    required this.phone,
    this.tablet,
    this.desktop,
    this.tv,
    this.spacing = 0,
    this.childAspectRatio = 1.0,
  })  : assert(phone >= 1, 'phone column count must be ≥ 1'),
        assert(spacing >= 0, 'spacing must be ≥ 0'),
        assert(childAspectRatio > 0, 'childAspectRatio must be > 0');

  /// Number of columns on a phone.
  final int phone;

  /// Number of columns on a tablet.  Defaults to [phone].
  final int? tablet;

  /// Number of columns on desktop.  Defaults to [tablet] → [phone].
  final int? desktop;

  /// Number of columns on TV.  Defaults to [desktop] → [tablet] → [phone].
  final int? tv;

  /// Uniform spacing between cells (both main-axis and cross-axis).
  final double spacing;

  /// Width-to-height ratio of each cell.
  final double childAspectRatio;

  int get _count => _resolve(phone, tablet, desktop, tv);

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final count = _count;
    final usableWidth =
        constraints.crossAxisExtent - spacing * (count - 1);
    final cellWidth = usableWidth / count;
    final cellHeight = cellWidth / childAspectRatio;

    return SliverGridRegularTileLayout(
      crossAxisCount: count,
      mainAxisStride: cellHeight + spacing,
      crossAxisStride: cellWidth + spacing,
      childMainAxisExtent: cellHeight,
      childCrossAxisExtent: cellWidth,
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) {
    if (oldDelegate is! AdaptiveGridDelegate) return true;
    return oldDelegate.phone != phone ||
        oldDelegate.tablet != tablet ||
        oldDelegate.desktop != desktop ||
        oldDelegate.tv != tv ||
        oldDelegate.spacing != spacing ||
        oldDelegate.childAspectRatio != childAspectRatio;
  }
}
