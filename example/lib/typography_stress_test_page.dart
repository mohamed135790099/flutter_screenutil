import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension TypographyExtension on BuildContext {
  TextStyle get subtitle => AdaptiveTextStyle(
        phoneFontSize: 16,
        tabletFontSize: 18,
        desktopFontSize: 20,
        phoneWeight: FontWeight.bold,
        phoneColor: Colors.indigo.shade700,
      ).style;

  TextStyle get body => AdaptiveTextStyle(
        phoneFontSize: 14,
        tabletFontSize: 15,
        desktopFontSize: 16,
        phoneColor: Colors.grey.shade800,
        height: 1.5,
      ).style;
}

class TypographyStressTestPage extends StatelessWidget {
  const TypographyStressTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: AdaptiveEdgeInsets.all(phone: 16, tablet: 24, desktop: 32).w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────────────────────────────
            // 1. Adaptive Hero Typography
            // ─────────────────────────────────────────────────────────────────
            _SectionHeader('01. Adaptive Branding'),
            AppSpacing.sm.hs,
            Text(
              'Fluid Device Experience',
              style: AdaptiveTextStyle(
                phoneFontSize: 32,
                tabletFontSize: 44,
                desktopFontSize: 56,
                phoneWeight: FontWeight.w900,
                phoneColor: Colors.black,
                letterSpacing: -1.0,
                height: 1.1,
              ).style,
            ),
            AppSpacing.xs.hs,
            Text(
              'This heading scales from 32sp on phones to 56sp on desktop using the AdaptiveTextStyle class.',
              style: context.body,
            ),
            AppSpacing.xl.hs,

            // ─────────────────────────────────────────────────────────────────
            // 2. Weight & Color Evolution
            // ─────────────────────────────────────────────────────────────────
            _SectionHeader('02. Weight & Color Evolution'),
            AppSpacing.sm.hs,
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Text(
                    'Weight shifts per device',
                    style: AdaptiveTextStyle(
                      phoneFontSize: 18,
                      desktopFontSize: 22,
                      phoneWeight: FontWeight.w300, // Light on phone
                      tabletWeight: FontWeight.w500, // Medium on tablet
                      desktopWeight: FontWeight.w900, // Heavy on desktop
                    ).style,
                  ),
                  AppSpacing.xs.hs,
                  Text(
                    'Color shifts per device',
                    style: AdaptiveTextStyle(
                      phoneFontSize: 16,
                      phoneColor: Colors.red.shade700,
                      tabletColor: Colors.orange.shade700,
                      desktopColor: Colors.green.shade700,
                    ).style,
                  ),
                ],
              ),
            ),
            AppSpacing.xl.hs,

            // ─────────────────────────────────────────────────────────────────
            // 3. Grid of Scaling Tokens
            // ─────────────────────────────────────────────────────────────────
            _SectionHeader('03. Scaling Tokens Map'),
            AppSpacing.sm.hs,
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [10, 12, 14, 16, 20, 24, 32, 40, 48, 56, 64]
                  .map((size) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '${size}sp',
                          style: TextStyle(
                            fontSize: size.toDouble().sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            AppSpacing.xl.hs,

            // ─────────────────────────────────────────────────────────────────
            // 4. Adaptive Quote (Rich Text)
            // ─────────────────────────────────────────────────────────────────
            _SectionHeader('04. Semantic Quote'),
            AppSpacing.sm.hs,
            Container(
              padding: EdgeInsets.only(left: 16.w),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.indigo, width: 4.w)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '"Design is not just what it looks like and feels like. ',
                      style: AdaptiveTextStyle(
                        phoneFontSize: 18,
                        tabletFontSize: 22,
                        desktopFontSize: 26,
                        phoneWeight: FontWeight.w500,
                        height: 1.4,
                      ).style,
                      children: [
                        TextSpan(
                          text: 'Design is how it works."',
                          style: TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.xs.hs,
                  Text('— Steve Jobs', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
                ],
              ),
            ),
            AppSpacing.xl.hs,

            // ─────────────────────────────────────────────────────────────────
            // 5. Line Height & Letter Spacing
            // ─────────────────────────────────────────────────────────────────
            _SectionHeader('05. Readability & Spacing'),
            AppSpacing.sm.hs,
            Column(
              children: [
                _SpacingBox(
                  label: 'Loose Height (2.0)',
                  style: AdaptiveTextStyle(phoneFontSize: 14, height: 2.0).style,
                ),
                AppSpacing.sm.hs,
                _SpacingBox(
                  label: 'Wide Spacing (4.0)',
                  style: AdaptiveTextStyle(phoneFontSize: 14, letterSpacing: 4.0).style,
                ),
                AppSpacing.sm.hs,
                _SpacingBox(
                  label: 'Compact Header',
                  style: AdaptiveTextStyle(
                    phoneFontSize: 24,
                    letterSpacing: -1.5,
                    phoneWeight: FontWeight.bold,
                  ).style,
                ),
              ],
            ),
            AppSpacing.xxxl.hs,
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w900,
        color: Colors.indigo.shade300,
        letterSpacing: 2.0,
      ),
    );
  }
}

class _SpacingBox extends StatelessWidget {
  const _SpacingBox({required this.label, required this.style});
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(label, style: style),
    );
  }
}
