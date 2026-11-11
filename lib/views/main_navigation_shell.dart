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
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Hiệu ứng lướt trang mượt mà khi bấm vào icon dưới thanh NavigationBar
  Future<void> _onTabSelected(int index) async {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
      _isProgrammaticScroll = true;
    });

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );

    if (mounted) {
      _isProgrammaticScroll = false;
    }
  }

  // Đồng bộ nút sáng dưới thanh NavigationBar khi người dùng dùng tay lướt ngang
  void _onPageChanged(int index) {
    if (!_isProgrammaticScroll && _currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.themeController,
      builder: (context, _) {
        final isDark = widget.themeController.isDarkMode(context);

        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            // ClampingScrollPhysics chặn lướt quá biên ở trang đầu (Dashboard) và trang cuối (Profile)
            physics: const ClampingScrollPhysics(),
            children: [
              _KeepAliveTab(
                child: DailyDashboardScreen(
                  logController: widget.logController,
                  themeController: widget.themeController,
                ),
              ),
              const _KeepAliveTab(
                child: FoodSearchScreen(),
              ),
              const _KeepAliveTab(
                child: AnalyticsScreen(),
              ),
              _KeepAliveTab(
                child: ProfileScreen(
                  themeController: widget.themeController,
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
            indicatorColor: AppColors.lime,
            onDestinationSelected: _onTabSelected,
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
      },
    );
  }
}

// Giữ trạng thái của cả 4 tab luôn sống trên RAM khi lướt qua lại
class _KeepAliveTab extends StatefulWidget {
  final Widget child;

  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}