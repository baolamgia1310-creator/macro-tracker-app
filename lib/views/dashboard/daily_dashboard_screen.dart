import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/daily_log_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/logged_food_item.dart';
import '../search/food_search_screen.dart';

typedef LoggedFoodList = List<LoggedFoodItem>;

class DailyDashboardScreen extends StatelessWidget {
  final DailyLogController logController;
  final ThemeController themeController;

  const DailyDashboardScreen({
    super.key,
    required this.logController,
    required this.themeController,
  });

  static const Color _warningAmber = Color(0xFFF59E0B);
  static const Color _alertRed = Color(0xFFEF4444);
  static const Color _emeraldGreen = Color(0xFF10B981);

  Future<void> _pickDate(BuildContext context, bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: logController.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.lime,
                    onPrimary: Colors.black,
                    surface: AppColors.darkCard,
                    onSurface: AppColors.darkText,
                  )
                : const ColorScheme.light(
                    primary: Colors.black,
                    onPrimary: AppColors.lime,
                    surface: Colors.white,
                    onSurface: AppColors.lightText,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      logController.setSelectedDate(picked);
    }
  }

  BoxDecoration _buildCardDecoration(Color cardColor, bool isDark) {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.05),
        width: 1,
      ),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([logController, themeController]),
      builder: (context, _) {
        final isDark = themeController.isDarkMode(context);
        final cardColor = Theme.of(context).colorScheme.surface;
        final textColor = isDark ? AppColors.darkText : AppColors.lightText;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: 'Select Date',
              icon: Icon(
                Icons.calendar_month_outlined,
                color: isDark ? AppColors.lime : Colors.black87,
              ),
              onPressed: () => _pickDate(context, isDark),
            ),
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: textColor, size: 22),
                  onPressed: logController.previousDay,
                  visualDensity: VisualDensity.compact,
                ),
                GestureDetector(
                  onTap: () => _pickDate(context, isDark),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      logController.formattedDateLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: textColor, size: 22),
                  onPressed: logController.nextDay,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeController.toggleTheme(!isDark),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: logController.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.lime,
                    strokeWidth: 2.5,
                  ),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Calorie Ring Card (RepaintBoundary 120Hz)
                      RepaintBoundary(
                        child: _buildCalorieRingCard(
                          cardColor: cardColor,
                          textColor: textColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Macro Progress Bars Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _buildCardDecoration(cardColor, isDark),
                        child: Column(
                          children: [
                            _buildMacroBar(
                              title: 'Protein',
                              current: logController.consumedProtein,
                              target: logController.targetProtein,
                              color: AppColors.protein,
                              textColor: textColor,
                              isDark: isDark,
                              isProtein: true,
                            ),
                            const SizedBox(height: 16),
                            _buildMacroBar(
                              title: 'Carbs',
                              current: logController.consumedCarbs,
                              target: logController.targetCarbs,
                              color: AppColors.carbs,
                              textColor: textColor,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildMacroBar(
                              title: 'Fat',
                              current: logController.consumedFat,
                              target: logController.targetFat,
                              color: AppColors.fat,
                              textColor: textColor,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Meals Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Meals',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const Text(
                            'Swipe left on an item to delete',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.greySubtext,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 4. Meal Sections
                      _buildMealCard(
                        context: context,
                        title: 'Breakfast',
                        icon: Icons.free_breakfast_outlined,
                        items: logController.breakfastItems,
                        cardColor: cardColor,
                        isDark: isDark,
                        textColor: textColor,
                      ),
                      _buildMealCard(
                        context: context,
                        title: 'Lunch',
                        icon: Icons.lunch_dining_outlined,
                        items: logController.lunchItems,
                        cardColor: cardColor,
                        isDark: isDark,
                        textColor: textColor,
                      ),
                      _buildMealCard(
                        context: context,
                        title: 'Dinner',
                        icon: Icons.dinner_dining_outlined,
                        items: logController.dinnerItems,
                        cardColor: cardColor,
                        isDark: isDark,
                        textColor: textColor,
                      ),
                      _buildMealCard(
                        context: context,
                        title: 'Snacks',
                        icon: Icons.cookie_outlined,
                        items: logController.snackItems,
                        cardColor: cardColor,
                        isDark: isDark,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCalorieRingCard({
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    final isOver = logController.isOverBudget;
    final isSlightlyOver = logController.isSlightlyOver;
    final progress = logController.calorieProgress;
    final percentage = logController.caloriePercentage;
    final consumed = logController.consumedCalories;
    final target = logController.targetCalories;

    final Color ringColor = !isOver
        ? AppColors.lime
        : (isSlightlyOver ? _warningAmber : _alertRed);

    final Color badgeBgColor = !isOver
        ? (isDark ? AppColors.lime.withOpacity(0.16) : AppColors.lime.withOpacity(0.35))
        : ringColor.withOpacity(isDark ? 0.18 : 0.14);

    final Color badgeTextColor = !isOver
        ? (isDark ? AppColors.lime : const Color(0xFF365314))
        : (isSlightlyOver
            ? (isDark ? _warningAmber : const Color(0xFFB45309))
            : (isDark ? _alertRed : const Color(0xFFB91C1C)));

    final String centerMainText = isOver
        ? '+${logController.overCalories}'
        : '${logController.remainingCalories}';

    final String centerSubLabel = isOver ? 'kcal over' : 'kcal left';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _buildCardDecoration(cardColor, isDark),
      child: Column(
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 176,
                  height: 176,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                    color: ringColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerMainText,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isOver ? ringColor : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      centerSubLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isOver ? ringColor.withOpacity(0.85) : AppColors.greySubtext,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 12,
                          color: badgeTextColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  !isOver
                      ? Icons.check_circle_outline
                      : (isSlightlyOver
                          ? Icons.info_outline
                          : Icons.warning_amber_rounded),
                  size: 16,
                  color: badgeTextColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    logController.budgetStatusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCalorieSubStat(
                'Consumed',
                '$consumed kcal',
                isOver ? ringColor : textColor,
              ),
              Container(
                width: 1,
                height: 26,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              _buildCalorieSubStat(
                'Daily Goal',
                '$target kcal',
                textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieSubStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.greySubtext),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroBar({
    required String title,
    required double current,
    required double target,
    required Color color,
    required Color textColor,
    required bool isDark,
    bool isProtein = false,
  }) {
    final progress = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;
    final int diff = (current - target).round();
    final bool isOverMacro = diff > 0;

    final Color overBadgeColor = isProtein ? _emeraldGreen : _alertRed;
    final Color barActiveColor =
        (!isProtein && isOverMacro) ? _alertRed : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: textColor,
              ),
            ),
            const Spacer(),
            Text(
              '${current.round()} /${target.round()} g',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isOverMacro ? FontWeight.w700 : FontWeight.w500,
                color: isOverMacro ? textColor : AppColors.greySubtext,
              ),
            ),
            if (isOverMacro) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: overBadgeColor.withOpacity(isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${diff}g',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: overBadgeColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withOpacity(isDark ? 0.15 : 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barActiveColor),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required LoggedFoodList items,
    required Color cardColor,
    required bool isDark,
    required Color textColor,
  }) {
    final totalMealCals = items.fold(0, (sum, i) => sum + i.calories);
    final isCompleted = totalMealCals > 0;
    final caloriesLabel = isCompleted ? '$totalMealCals kcal' : '-- kcal';

    final Color mealCaloriesColor = isDark
        ? AppColors.lime
        : const Color(0xFF3F6212);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _buildCardDecoration(cardColor, isDark),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(13),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caloriesLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.greySubtext,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Add food to $title',
                icon: Icon(
                  Icons.add_circle_outline,
                  color: isDark ? AppColors.lime : Colors.black87,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FoodSearchScreen(mealType: title),
                    ),
                  );
                },
              ),
              isCompleted
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.lime,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.black,
                      ),
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
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: _alertRed.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: _alertRed,
                      size: 20,
                    ),
                  ),
                  onDismissed: (_) => logController.removeFoodLog(item.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.formattedAmount}  •  P ${item.protein}g  C ${item.carbs}g  F${item.fat}g',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.greySubtext,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.calories} kcal',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: mealCaloriesColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => logController.removeFoodLog(item.id),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.greySubtext,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}