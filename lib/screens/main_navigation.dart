// lib/screens/main_navigation.dart
//
// Responsive app shell (Lecture 4 + 5):
//   * phone portrait            -> bottom NavigationBar
//   * phone landscape / tablet  -> NavigationRail on the side
//   * large screens (>= 1024)   -> extended NavigationRail with labels
// The pages live in an IndexedStack with a GlobalKey, so rotating the phone
// (which swaps bar <-> rail) keeps each tab's scroll position and state.
import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import 'expenses_screen.dart';
import 'goals_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  static const routeName = '/';

  /// Lets any screen switch tab, e.g. "See all" on Home -> Expenses tab.
  static void goTo(BuildContext context, int index) {
    context.findAncestorStateOfType<_MainNavigationState>()?.select(index);
  }

  static const home = 0;
  static const expenses = 1;
  static const insights = 2;
  static const goals = 3;
  static const settings = 4;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final _bodyKey = GlobalKey();

  static const _screens = <Widget>[
    HomeScreen(),
    ExpensesScreen(),
    InsightsScreen(),
    GoalsScreen(),
    SettingsScreen(),
  ];

  void select(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final items = [
      _NavItem(Icons.home_outlined, Icons.home, s.navHome),
      _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, s.navExpenses),
      _NavItem(Icons.insights_outlined, Icons.insights, s.navInsights),
      _NavItem(Icons.savings_outlined, Icons.savings, s.navGoals),
      _NavItem(Icons.settings_outlined, Icons.settings, s.navSettings),
    ];

    final body = IndexedStack(
      key: _bodyKey,
      index: _currentIndex,
      children: _screens,
    );

    if (!context.useSideNavigation) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: select,
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon, color: AppColors.hotPink),
                label: item.label,
              ),
          ],
        ),
      );
    }

    final extended = context.isExpanded;
    final shortScreen = context.screenSize.height < 500;

    // On a phone turned sideways the height is small: hide the logo and only
    // label the selected item so all 5 destinations fit without scrolling.
    final rail = NavigationRail(
      extended: extended,
      selectedIndex: _currentIndex,
      onDestinationSelected: select,
      groupAlignment: shortScreen ? 0 : -0.6,
      labelType: extended
          ? NavigationRailLabelType.none
          : (shortScreen
              ? NavigationRailLabelType.selected
              : NavigationRailLabelType.all),
      leading: shortScreen
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: extended
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/logo.png',
                            width: 40, height: 40),
                        const SizedBox(width: 10),
                        Text(
                          s.appName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: AppColors.hotPink,
                          ),
                        ),
                      ],
                    )
                  : Image.asset('assets/images/logo.png',
                      width: 36, height: 36),
            ),
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            rail,
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
