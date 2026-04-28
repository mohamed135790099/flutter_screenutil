/// Full adaptive example app — demonstrates every Phase 1-5 API.
///
/// Run with:
///   flutter run -t lib/main_adaptive.dart
library flutter_screenutil.example_adaptive;

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'typography_stress_test_page.dart';
import 'advanced_demo_page.dart';
import 'ultimate_demo_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

void main() => runApp(DevicePreview(
      enabled: kDebugMode && kIsWeb,
      builder: (BuildContext context) =>  MyApp(),
    ));

// ─────────────────────────────────────────────────────────────────────────────
// Root
// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // ── Per-device portrait frames ──────────────────────────────────────
      designSize: const Size(390, 844), // phone portrait (required)
      tabletDesignSize: const Size(768, 1024), // tablet portrait
      desktopDesignSize: const Size(1024, 768), // desktop portrait (narrow window)
      desktopLandscapeDesignSize: const Size(1280, 900), // desktop landscape (standard)

      // ── Per-device landscape frames (null = auto-transpose) ─────────────
      landscapeDesignSize: const Size(844, 390), // phone landscape
      tabletLandscapeDesignSize: const Size(1024, 768), // tablet landscape
      // desktopLandscapeDesignSize omitted → auto-transposed from desktop

      // ── Text ────────────────────────────────────────────────────────────
      minTextAdapt: false,
      minTextScaleFactor: 0.85,
      maxTextScaleFactor: 1.4, // ceiling, now user-overridable

      // ── Breakpoints (defaults shown) ────────────────────────────────────
      phoneBreakpoint: 600,
      tabletBreakpoint: 1024,

      // ── Debug HUD (live metrics overlay) ────────────────────────────────
      debugShowOverlay: kDebugMode,
      useInheritedMediaQuery: true,

      builder: (context, child) => MaterialApp(
        title: 'Adaptive ScreenUtil Demo',
        debugShowCheckedModeBanner: false,
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home:  HomePage(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HomePage — Phase 3 AdaptiveLayout selects the correct scaffold
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return Column(
          children: [
            _DeviceBanner(),
            const Expanded(child: ProductGrid(products: _kProducts)),
          ],
        );
      case 1:
        return Column(
          children: [
            _DeviceBanner(),
            const Expanded(child: TypographyStressTestPage()),
          ],
        );
      case 2:
        return Column(
          children: [
            _DeviceBanner(),
            const Expanded(child: AdvancedDemoPage()),
          ],
        );
      case 3:
        return Column(
          children: [
            _DeviceBanner(),
            const Expanded(child: UltimateFeaturesPage()),
          ],
        );
      default:
        return Column(
          children: [
            _DeviceBanner(),
            const Expanded(child: Center(child: Text('Coming soon...'))),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Phase 3 — full layout switcher with portrait + landscape variants.
    return AdaptiveLayout(
      phone: (_) => _PhoneScaffold(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        body: _buildBody(),
      ),
      landscapePhone: (_) => _LandscapePhoneScaffold(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        body: _buildBody(),
      ),
      tablet: (_) => _TabletScaffold(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        body: _buildBody(),
      ),
      desktop: (_) => _DesktopScaffold(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        body: _buildBody(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone scaffold (portrait)
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneScaffold extends StatelessWidget {
  const _PhoneScaffold({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Demo — Phone')),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onDestinationSelected,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 24.r),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_format, size: 24.r),
            label: 'Typography',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize, size: 24.r),
            label: 'Advanced',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.layers, size: 24.r),
            label: 'Ultimate',
          ),
        ],
        selectedLabelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 11.sp),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone landscape scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _LandscapePhoneScaffold extends StatelessWidget {
  const _LandscapePhoneScaffold({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Demo — Phone Landscape')),
      body: Row(
        children: [
          NavigationRail(
            destinations: [
              NavigationRailDestination(
                  icon: Icon(Icons.home, size: 24.r), 
                  label: Text('Home', style: TextStyle(fontSize: 13.sp))),
              NavigationRailDestination(
                  icon: Icon(Icons.text_format, size: 24.r), 
                  label: Text('Typography', style: TextStyle(fontSize: 13.sp))),
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard_customize, size: 24.r), 
                  label: Text('Advanced', style: TextStyle(fontSize: 13.sp))),
              NavigationRailDestination(
                  icon: Icon(Icons.layers, size: 24.r), 
                  label: Text('Ultimate', style: TextStyle(fontSize: 13.sp))),
            ],
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tablet scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _TabletScaffold extends StatelessWidget {
  const _TabletScaffold({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            children: [
              DrawerHeader(
                child: Text('Adaptive Demo — Tablet', 
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold))),
              NavigationDrawerDestination(
                  icon: Icon(Icons.home, size: 24.r), 
                  label: Text('Home', style: TextStyle(fontSize: 14.sp))),
              NavigationDrawerDestination(
                  icon: Icon(Icons.text_format, size: 24.r), 
                  label: Text('Typography', style: TextStyle(fontSize: 14.sp))),
              NavigationDrawerDestination(
                  icon: Icon(Icons.dashboard_customize, size: 24.r), 
                  label: Text('Advanced', style: TextStyle(fontSize: 14.sp))),
              NavigationDrawerDestination(
                  icon: Icon(Icons.layers, size: 24.r), 
                  label: Text('Ultimate', style: TextStyle(fontSize: 14.sp))),
            ],
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopScaffold extends StatelessWidget {
  const _DesktopScaffold({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: AdaptiveNum(phone: 160, desktop: 200).w,
            destinations: [
              NavigationRailDestination(
                  icon: Icon(Icons.home, size: 28.r), 
                  label: Text('Home', style: TextStyle(fontSize: 15.sp))),
              NavigationRailDestination(
                  icon: Icon(Icons.text_format, size: 28.r), 
                  label: Text('Typography', style: TextStyle(fontSize: 15.sp))),
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard_customize, size: 28.r), 
                  label: Text('Advanced', style: TextStyle(fontSize: 15.sp))),
              NavigationRailDestination(
                  icon: Icon(Icons.layers, size: 28.r), 
                  label: Text('Ultimate', style: TextStyle(fontSize: 15.sp))),
            ],
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
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
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typography Stress Test
// ─────────────────────────────────────────────────────────────────────────────
// The TypographyStressTestPage is defined in typography_stress_test_page.dart

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a live device-info banner — useful during development.
class _DeviceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final su = ScreenUtil();
    final metrics = ScreenMetrics.current();

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: AdaptiveEdgeInsets.symmetric(
        phoneH: 16,
        phoneV: 10,
        desktopH: 24,
        desktopV: 14,
      ).w,
      child: Wrap(
        spacing: AppSpacing.md.w,
        runSpacing: AppSpacing.xs.h,
        children: [
          _Chip('${metrics.screenWidth.toStringAsFixed(0)}'
              '×${metrics.screenHeight.toStringAsFixed(0)} dp'),
          _Chip(su.deviceType.name),
          _Chip(su.isLandscape ? 'landscape' : 'portrait'),
          _Chip('16.sp = ${su.setSp(16).toStringAsFixed(1)}'),
          _Chip('scaleW = ${su.scaleWidth.toStringAsFixed(3)}'),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: AdaptiveTextStyle(phoneFontSize: 11, desktopFontSize: 12).style,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProductCard — showcases Phase 5 classes
// ─────────────────────────────────────────────────────────────────────────────

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
      // Phase 5 — AdaptiveBorderRadius.circular
      shape: RoundedRectangleBorder(
        borderRadius: AdaptiveBorderRadius.circular(
          phone: 8,
          tablet: 12,
          desktop: 16,
        ).r,
      ),
      child: Padding(
        // Phase 5 — AdaptiveEdgeInsets.all
        padding: AdaptiveEdgeInsets.all(
          phone: 12,
          tablet: 16,
          desktop: 20,
        ).w,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji icon using AdaptiveNum.r (shorter axis scale)
            Text(
              emoji,
              style: TextStyle(
                fontSize: AdaptiveNum(phone: 32, tablet: 40, desktop: 48).r,
              ),
            ),
            AppSpacing.sm.hs, // Phase 5 — semantic spacing token
            Text(
              title,
              // Phase 5 — AdaptiveTextStyle
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
                // Phase 5 — AdaptiveColor via parameter
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

// ─────────────────────────────────────────────────────────────────────────────
// ProductGrid — AdaptiveGridDelegate
// ─────────────────────────────────────────────────────────────────────────────

class ProductGrid extends StatelessWidget {
  const ProductGrid({required this.products});
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.md.w),
      // Phase 5 — AdaptiveGridDelegate
      gridDelegate: AdaptiveGridDelegate(
        phone: 2,
        tablet: 3,
        desktop: 4,
        spacing: AdaptiveNum(phone: 8, tablet: 12, desktop: 16).w,
        childAspectRatio: AdaptiveDouble(
          phone: 0.75,
          tablet: 0.80,
          desktop: 0.85,
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

// ─────────────────────────────────────────────────────────────────────────────
// Sample data
// ─────────────────────────────────────────────────────────────────────────────

const _kProducts = [
  {'title': 'Wireless Headphones', 'price': 79.99, 'emoji': '🎧'},
  {'title': 'Mechanical Keyboard', 'price': 129.99, 'emoji': '⌨️'},
  {'title': 'Gaming Mouse', 'price': 59.99, 'emoji': '🖱️'},
  {'title': 'USB-C Hub', 'price': 39.99, 'emoji': '🔌'},
  {'title': 'Webcam 4K', 'price': 99.99, 'emoji': '📷'},
  {'title': 'Monitor Stand', 'price': 49.99, 'emoji': '🖥️'},
  {'title': 'Laptop Stand', 'price': 34.99, 'emoji': '💻'},
  {'title': 'Cable Organiser', 'price': 14.99, 'emoji': '🗂️'},
];
