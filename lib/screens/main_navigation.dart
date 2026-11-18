import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/cart_provider.dart';
import 'cart/cart_screen.dart';
import 'categories/categories_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'return_gift/return_gift_solutions_screen.dart';

/// Lets nested screens switch tabs (e.g. "Shop all" on Home → Shop tab).
class MainNavigationScope extends InheritedWidget {
  final void Function(int index, {String? categoryHandle}) switchTab;

  const MainNavigationScope({super.key, required this.switchTab, required super.child});

  static MainNavigationScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainNavigationScope>();

  @override
  bool updateShouldNotify(MainNavigationScope oldWidget) => false;
}

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  static const int home = 0, shop = 1, gifts = 2, cart = 3, account = 4;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _index = widget.initialIndex;
  String? _shopCategory;
  int _shopKey = 0;

  void _switchTab(int index, {String? categoryHandle}) {
    setState(() {
      _index = index;
      if (categoryHandle != null) {
        _shopCategory = categoryHandle;
        _shopKey++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<CartProvider, int>((c) => c.totalItemCount);

    final screens = [
      const HomeScreen(),
      CategoriesScreen(key: ValueKey('shop-$_shopKey'), initialCategoryHandle: _shopCategory),
      const ReturnGiftSolutionsScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return MainNavigationScope(
      switchTab: _switchTab,
      child: PopScope(
        canPop: _index == MainNavigation.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _index = MainNavigation.home);
        },
        child: Scaffold(
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Shop',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.card_giftcard_outlined),
                  selectedIcon: Icon(Icons.card_giftcard_rounded),
                  label: 'Gift Bags',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    backgroundColor: AppColors.saleRed,
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    backgroundColor: AppColors.saleRed,
                    child: const Icon(Icons.shopping_bag_rounded),
                  ),
                  label: 'Cart',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Account',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
