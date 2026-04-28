import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdvancedDemoPage extends StatelessWidget {
  const AdvancedDemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final su = ScreenUtil();

    return Scaffold(
      body: SingleChildScrollView(
        padding: AdaptiveEdgeInsets.all(
          phone: 16,
          tablet: 24,
          desktop: 32,
        ).w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────────────────────────────
            // 1. Hero Header (AdaptiveTextStyle + Orientation)
            // ─────────────────────────────────────────────────────────────────
            AdaptiveLayout(
              phone: (_) => _buildHeader('Phone Experience'),
              tablet: (_) => _buildHeader('Tablet Dashboard'),
              desktop: (_) => _buildHeader('Desktop Workspace'),
            ),
            AppSpacing.md.hs,

            // ─────────────────────────────────────────────────────────────────
            // 2. Shape Playground (AdaptiveBorderRadius + AdaptiveSize)
            // ─────────────────────────────────────────────────────────────────
            _SectionTitle('Adaptive Shapes & Sizes'),
            AppSpacing.sm.hs,
            Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: [
                // A responsive circle
                Container(
                  width: 80.ar,
                  height: 80.ar,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.indigo, width: 2.r),
                  ),
                  child: Center(child: Icon(Icons.star, size: 30.r, color: Colors.indigo)),
                ),
                // A responsive rounded rect with different radius per device
                Container(
                  width: 140.aw,
                  height: 80.ah,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: AdaptiveBorderRadius.circular(
                      phone: 8,
                      tablet: 16,
                      desktop: 24,
                    ).r,
                    border: Border.all(color: Colors.orange, width: 2.r),
                  ),
                  child: Center(
                    child: Text('Rounded', 
                      style: AdaptiveTextStyle(phoneFontSize: 12, desktopFontSize: 14).style,
                    ),
                  ),
                ),
                // A responsive box that changes aspect ratio
                Container(
                  width: AdaptiveNum(phone: 100, tablet: 150, desktop: 200).w,
                  height: AdaptiveNum(phone: 50, tablet: 60, desktop: 70).h,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(4.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Center(child: Text('Shadow Box', style: TextStyle(fontSize: 12.sp))),
                ),
              ],
            ),
            AppSpacing.xl.hs,

            // ─────────────────────────────────────────────────────────────────
            // 3. Button Gallery (Adaptive Padding & Text)
            // ─────────────────────────────────────────────────────────────────
            _SectionTitle('Adaptive Buttons'),
            AppSpacing.sm.hs,
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: AdaptiveEdgeInsets.symmetric(
                      phoneH: 16, phoneV: 10,
                      tabletH: 24, tabletV: 14,
                      desktopH: 32, desktopV: 18,
                    ).w,
                  ),
                  child: Text('Primary Action', style: TextStyle(fontSize: 14.sp)),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.add, size: 18.r),
                  label: Text('Add Item', style: TextStyle(fontSize: 14.sp)),
                  style: OutlinedButton.styleFrom(
                    padding: AdaptiveEdgeInsets.all(phone: 12, tablet: 16, desktop: 20).w,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: Icon(Icons.settings, size: 24.r),
                  padding: EdgeInsets.all(12.r),
                ),
              ],
            ),
            AppSpacing.xl.hs,

            // ─────────────────────────────────────────────────────────────────
            // 4. Orientation & Grid (AdaptiveGridDelegate)
            // ─────────────────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _SectionTitle('Dynamic Grid (Sensors)')),
                _Chip(su.isLandscape ? 'Landscape Active' : 'Portrait Active'),
              ],
            ),
            AppSpacing.sm.hs,
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: AdaptiveGridDelegate(
                phone: su.isLandscape ? 3 : 2,
                tablet: su.isLandscape ? 4 : 3,
                desktop: 5,
                spacing: 12.w,
                childAspectRatio: 1.0,
              ),
              itemCount: 10,
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.accents[index % Colors.accents.length].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.accents[index % Colors.accents.length],
                    width: 1.r,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      [Icons.bolt, Icons.eco, Icons.face, Icons.access_time, Icons.heart_broken][index % 5],
                      size: 28.r,
                      color: Colors.accents[index % Colors.accents.length],
                    ),
                    AppSpacing.xs.hs,
                    Text('Item $index', 
                      style: AdaptiveTextStyle(phoneFontSize: 11, desktopFontSize: 13, phoneWeight: FontWeight.bold).style,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.xxxl.hs,
            
            // ─────────────────────────────────────────────────────────────────
            // 5. Mixed Content Section
            // ─────────────────────────────────────────────────────────────────
            if (su.isDesktop || su.isTablet) ...[
               _SectionTitle('Advanced Detail View'),
               AppSpacing.sm.hs,
               Container(
                 width: double.infinity,
                 padding: EdgeInsets.all(24.r),
                 decoration: BoxDecoration(
                   color: Theme.of(context).colorScheme.surfaceVariant,
                   borderRadius: BorderRadius.circular(16.r),
                 ),
                 child: Row(
                   children: [
                     Expanded(
                       flex: 2,
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text('Scale Information', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                           AppSpacing.xs.hs,
                           Text(
                             'This section only appears on tablets and desktops to utilize extra horizontal space. '
                             'Current scale factor: ${su.scaleWidth.toStringAsFixed(2)}x',
                             style: TextStyle(fontSize: 14.sp),
                           ),
                         ],
                       ),
                     ),
                     AppSpacing.lg.ws,
                     Expanded(
                       child: Placeholder(fallbackHeight: 100.h),
                     ),
                   ],
                 ),
               ),
               AppSpacing.xl.hs,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Playground',
          style: AdaptiveTextStyle(
            phoneFontSize: 12,
            tabletFontSize: 14,
            desktopFontSize: 16,
            phoneColor: Colors.indigo,
            phoneWeight: FontWeight.w600,
            letterSpacing: 2,
          ).style,
        ),
        Text(
          label,
          style: AdaptiveTextStyle(
            phoneFontSize: 28,
            tabletFontSize: 36,
            desktopFontSize: 48,
            phoneWeight: FontWeight.w900,
            height: 1.1,
          ).style,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: ShapeDecoration(
        color: Colors.green.shade50,
        shape: StadiumBorder(side: BorderSide(color: Colors.green.shade200)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.sp, color: Colors.green.shade800, fontWeight: FontWeight.bold),
      ),
    );
  }
}
