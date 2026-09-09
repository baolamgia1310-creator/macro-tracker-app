import 'package:flutter/material.dart';
import '../controllers/daily_log_controller.dart';
import '../controllers/theme_controller.dart';
import '../core/constants/app_colors.dart';
import 'dashboard/daily_dashboard_screen.dart';
import 'search/food_search_screen.dart';
import 'analytics/analytics_screen.dart';
import 'profiles/profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final DailyLogController logController;
  final ThemeController themeController;

  const MainNavigationShell({
    super.key,
    required this.logController,
    required this.themeController,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeController.isDarkMode(context);

    // Danh sách 4 tab chính, truyền đúng các controller cần thiết
    final screens = [
      DailyDashboardScreen(
        logController: widget.logController,
        themeController: widget.themeController,
      ),
      const FoodSearchScreen(),
      const AnalyticsScreen(),
      ProfileScreen(
        themeController: widget.themeController,
      ),
    ];

    return Scaffold(
      // Giữ nguyên trạng thái (Scroll, input) của từng màn hình khi đổi tab
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.lime,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.black),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant, color: Colors.black),
            label: 'Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: Colors.black),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.black),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}