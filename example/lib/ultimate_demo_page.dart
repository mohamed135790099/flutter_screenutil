import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UltimateFeaturesPage extends StatelessWidget {
  const UltimateFeaturesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ── 1. Helper variables for the page ─────────────────────────────────────
    
    // Adaptive column count using the .adaptive() helper
    final cols = ScreenUtil().adaptive<int>(
      phone: 2,
      tablet: 3,
      desktop: 4,
    );

    // Adaptive font size using the .adaptive() helper
    final fontSize = ScreenUtil().adaptive<double>(
      phone: 14.sp,
      tablet: 16.sp,
      desktop: 18.sp,
    );

    // Orientation-specific padding
    final pagePadding = OrientationValue<EdgeInsets>(
      portrait: EdgeInsets.all(16.w),
      landscape: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
    );

    // Adaptive sizes for media
    final avatarSize = AdaptiveSize(
      phone: const Size(40, 40),
      tablet: const Size(56, 56),
      desktop: const Size(72, 72),
    );

    final bannerSize = AdaptiveSize(
      phone: const Size(double.infinity, 180),
      tablet: const Size(double.infinity, 240),
      desktop: const Size(double.infinity, 300),
    );

    // ── 2. The UI Structure ──────────────────────────────────────────────────
    
    return Scaffold(
      body: ScreenOrientationBuilder(
        portrait: (ctx) => _buildPortraitLayout(
          ctx, 
          cols, 
          fontSize, 
          pagePadding.value, 
          avatarSize, 
          bannerSize,
        ),
        landscape: (ctx) => _buildLandscapeLayout(
          ctx, 
          cols, 
          fontSize, 
          pagePadding.value, 
          avatarSize, 
          bannerSize,
        ),
      ),
    );
  }

  // ── Portrait Layout ──────────────────────────────────────────────────────
  
  Widget _buildPortraitLayout(
    BuildContext context,
    int cols,
    double fontSize,
    EdgeInsets padding,
    AdaptiveSize avatarSize,
    AdaptiveSize bannerSize,
  ) {
    return ListView(
      padding: padding,
      children: [
        _buildHeroBanner(bannerSize),
        AppSpacing.lg.hs,
        _buildSectionHeader('Profile & Lists (Portrait)', fontSize),
        AppSpacing.md.hs,
        _buildProfileRow(avatarSize),
        AppSpacing.lg.hs,
        _buildAdaptiveList(),
        AppSpacing.xl.hs,
        _buildSectionHeader('Grid Explorer', fontSize),
        AppSpacing.md.hs,
        _buildAdaptiveGrid(cols),
      ],
    );
  }

  // ── Landscape Layout ─────────────────────────────────────────────────────
  
  Widget _buildLandscapeLayout(
    BuildContext context,
    int cols,
    double fontSize,
    EdgeInsets padding,
    AdaptiveSize avatarSize,
    AdaptiveSize bannerSize,
  ) {
    return Row(
      children: [
        // Left side: Hero & Profile
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(bannerSize),
                AppSpacing.lg.hs,
                _buildSectionHeader('Wide View Controls', fontSize),
                AppSpacing.md.hs,
                _buildProfileRow(avatarSize),
                AppSpacing.lg.hs,
                const Text('Landscape mode provides more horizontal clarity. '
                    'Notice how the padding and layouts split into columns.'),
              ],
            ),
          ),
        ),
        const VerticalDivider(),
        // Right side: Interactive Grid
        Expanded(
          flex: 3,
          child: _buildAdaptiveGrid(cols + 1), // Extra col in landscape
        ),
      ],
    );
  }

  // ── Reusable Component Builders ──────────────────────────────────────────

  Widget _buildHeroBanner(AdaptiveSize size) {
    return Container(
      width: size.wh.width,
      height: size.wh.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&q=80&w=800'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        padding: EdgeInsets.all(16.r),
        alignment: Alignment.bottomLeft,
        child: Text(
          'Featured Product',
          style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProfileRow(AdaptiveSize avatarSize) {
    return Row(
      children: [
       Expanded(
         child: Row(
           children: [
             CircleAvatar(
               radius: avatarSize.r.width / 2,
               backgroundImage: const NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026704d'),
             ),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('John Doe', style:
                   TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                   Text('Pro User • Seattle, WA', style:
                   TextStyle(fontSize: 14.sp, color: Colors.grey)),
                 ],
               ),
             ),
           ],
         ),
       ),
        IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.edit)),
      ],
    );
  }

  Widget _buildAdaptiveList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) => Card(
        margin: EdgeInsets.only(bottom: AppSpacing.sm.h),
        child: ListTile(
          leading: Icon(Icons.check_circle_outline, color: Colors.green, size: 24.r),
          title: Text('Task Item #$index', style: TextStyle(fontSize: 16.sp)),
          subtitle: const Text('Adaptive scaling applied to font and icons'),
          trailing: Icon(Icons.chevron_right, size: 20.r),
        ),
      ),
    );
  }

  Widget _buildAdaptiveGrid(int columnCount) {
    return GridView.builder(
      padding: EdgeInsets.all(8.r),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category, size: 30.r, color: Colors.blue),
              AppSpacing.xs.hs,
              Text('Cat $index', style: TextStyle(fontSize: 12.asp, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, double fontSize) {
    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: Colors.blueGrey.shade800,
      ),
    );
  }
}
