import 'package:fcode_pos/screens/tabs/report_screen.dart';
import 'package:fcode_pos/screens/tabs/orders_screen.dart';
import 'package:fcode_pos/screens/tabs/more_screen.dart';
import 'package:fcode_pos/screens/tabs/product_hub_screen.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PageStorageBucket _bucket = PageStorageBucket();
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const _tabTransitionDuration = Duration(milliseconds: 320);
  static const _tabTransitionCurve = Curves.easeInOutCubic;

  late final List<Widget> _screens = [
    const HomeScreen(key: PageStorageKey('orders')),
    const DashboardScreen(key: PageStorageKey('dashboard')),
    const ProductHubScreen(key: PageStorageKey('products')),
    const MoreScreen(key: PageStorageKey('more')),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: _tabTransitionDuration,
      curve: _tabTransitionCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
          },
          children: _screens,
        ),
      ),
      // extendBody: true,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Quản lý',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Khác',
          ),
        ],
      ),
    );
  }
}
