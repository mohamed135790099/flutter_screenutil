/*
 * Created by 李卓原 on 2018/9/29.
 * email: zhuoyuan93@gmail.com
 */

library flutter_screenutil;

// ── Original exports (unchanged) ──────────────────────────────────────────
export 'src/r_padding.dart';
export 'src/r_sizedbox.dart';
export 'src/screen_util.dart';
export 'src/screenutil_init.dart';
export 'src/size_extension.dart';
// Shim — re-exports su_mixin.dart for backwards compatibility.
export 'src/screenutil_mixin.dart';

// ── Phase 1: FontSizeResolver factories ───────────────────────────────────
export 'src/font_size_resolver.dart';

// ── Phase 2: Orientation helpers ──────────────────────────────────────────
export 'src/orientation_builder.dart';

// ── Phase 3: Device-class widgets ─────────────────────────────────────────
export 'src/device_type.dart';

// ── Phase 4: Rebuild engine + debug tools ─────────────────────────────────
export 'src/su_mixin.dart';
export 'src/debug_overlay.dart';

// ── Phase 5: Advanced adaptive extensions ─────────────────────────────────
export 'src/adaptive_extensions.dart';
