import 'package:fcode_pos/screens/dashboard_screen.dart';
import 'package:fcode_pos/screens/orders_screen.dart';
import 'package:fcode_pos/screens/more_screen.dart';
import 'package:fcode_pos/screens/product_hub_screen.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PageStorageBucket _bucket = PageStorageBucket();
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const DashboardScreen(key: PageStorageKey('dashboard')),
    const HomeScreen(key: PageStorageKey('orders')),
    const ProductHubScreen(key: PageStorageKey('products')),
    const MoreScreen(key: PageStorageKey('more')),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      // extendBody: true,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        height: 72,
        indicatorColor: colorScheme.secondaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Quản lý',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Khác',
          ),
        ],
      ),
    );
  }
}
