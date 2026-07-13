import 'package:fcode_pos/screens/tabs/report_screen.dart';
import 'package:fcode_pos/screens/tabs/orders_screen.dart';
import 'package:fcode_pos/screens/tabs/more_screen.dart';
import 'package:fcode_pos/screens/tabs/product_hub_screen.dart';
import 'package:amazing_icons/filled.dart';
import 'package:amazing_icons/twotone.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PageStorageBucket _bucket = PageStorageBucket();
  int _currentIndex = 0;
  int _tabDirection = 1;

  late final List<Widget> _screens = [
    const HomeScreen(key: PageStorageKey('orders')),
    const DashboardScreen(key: PageStorageKey('dashboard')),
    const ProductHubScreen(key: PageStorageKey('products')),
    const MoreScreen(key: PageStorageKey('more')),
  ];

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _tabDirection = index > _currentIndex ? 1 : -1;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const iconSize = 24.0;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return PageStorage(
            bucket: _bucket,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: Offset(_tabDirection * 0.04, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: SizedBox(
                key: ValueKey(_currentIndex),
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                child: _screens[_currentIndex],
              ),
            ),
          );
        },
      ),
      // extendBody: true,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          NavigationDestination(
            icon: AmazingIconTwotone.receipt(
              size: iconSize,
              color: cs.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              AmazingIconFilled.receipt,
              size: iconSize,
              color: cs.onSecondaryContainer,
            ),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: AmazingIconTwotone.chartSquare(
              size: iconSize,
              color: cs.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              AmazingIconFilled.chartSquare,
              size: iconSize,
              color: cs.onSecondaryContainer,
            ),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: AmazingIconTwotone.category(
              size: iconSize,
              color: cs.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              AmazingIconFilled.category,
              size: iconSize,
              color: cs.onSecondaryContainer,
            ),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: AmazingIconTwotone.setting(
              size: iconSize,
              color: cs.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              AmazingIconFilled.setting,
              size: iconSize,
              color: cs.onSecondaryContainer,
            ),
            label: 'Khác',
          ),
        ],
      ),
    );
  }
}
