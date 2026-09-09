import 'package:flutter/material.dart';
import '../../controllers/daily_log_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/macro_progress_ring.dart';
import '../../widgets/macro_bar.dart';

class DailyDashboardScreen extends StatelessWidget {
  final DailyLogController logController;
  final ThemeController themeController;

  const DailyDashboardScreen({
    super.key,
    required this.logController,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([logController, themeController]),
      builder: (context, _) {
        // Đồng bộ gọi qua BuildContext để hỗ trợ System Default
        final isDark = themeController.isDarkMode(context);
        final cardColor = Theme.of(context).colorScheme.surface;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {},
            ),
            centerTitle: true,
            title: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'Today',
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                items: ['Today', 'Yesterday', 'Aug 28'].map((val) {
                  return DropdownMenuItem(
                    value: val,
                    child: Text(
                      val,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: (_) {},
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeController.toggleTheme(!isDark),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Vòng tròn calo tiến độ
                MacroProgressRing(
                  consumedCalories: logController.totalConsumedCalories,
                  targetCalories: logController.target.targetCalories,
                  progressPercent: logController.calorieProgress,
                ),
                const SizedBox(height: 14),

                // 2. Thẻ Macro Bars (Protein, Carbs, Fat)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      MacroBar(
                        title: 'Protein',
                        currentGrams: logController.totalConsumedProtein,
                        targetGrams: logController.target.targetProteinGrams,
                        barColor: AppColors.protein,
                      ),
                      const SizedBox(height: 14),
                      MacroBar(
                        title: 'Carbs',
                        currentGrams: logController.totalConsumedCarbs,
                        targetGrams: logController.target.targetCarbsGrams,
                        barColor: AppColors.carbs,
                      ),
                      const SizedBox(height: 14),
                      MacroBar(
                        title: 'Fat',
                        currentGrams: logController.totalConsumedFat,
                        targetGrams: logController.target.targetFatGrams,
                        barColor: AppColors.fat,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Tiêu đề danh sách bữa ăn
                Text(
                  'Meals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Danh sách các bữa ăn
                _buildMealItem(
                  context: context,
                  title: 'Breakfast',
                  calories: '450 kcal',
                  icon: Icons.free_breakfast_outlined,
                  isCompleted: true,
                ),
                _buildMealItem(
                  context: context,
                  title: 'Lunch',
                  calories: '620 kcal',
                  icon: Icons.lunch_dining_outlined,
                  isCompleted: true,
                ),
                _buildMealItem(
                  context: context,
                  title: 'Dinner',
                  calories: '-- kcal',
                  icon: Icons.dinner_dining_outlined,
                  isCompleted: false,
                ),
                _buildMealItem(
                  context: context,
                  title: 'Snacks',
                  calories: '-- kcal',
                  icon: Icons.cookie_outlined,
                  isCompleted: false,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealItem({
    required BuildContext context,
    required String title,
    required String calories,
    required IconData icon,
    required bool isCompleted,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                calories,
                style: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
              ),
            ],
          ),
          const Spacer(),
          isCompleted
              ? Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.lime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.black),
                )
              : Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}