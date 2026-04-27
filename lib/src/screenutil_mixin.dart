/// Backwards-compatibility shim — re-exports [su_mixin.dart].
///
/// This file is retained so that any existing code that imports
/// `screenutil_mixin.dart` directly continues to work without changes.
/// New code should prefer importing `su_mixin.dart` or the barrel
/// `flutter_screenutil.dart`.
library flutter_screenutil.screenutil_mixin;

export 'su_mixin.dart';
