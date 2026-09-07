import 'package:flutter/material.dart';
import '../../controllers/calculator_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_profile.dart';

class BmrTdeeCalculatorScreen extends StatefulWidget {
  final VoidCallback? onCalculated;

  const BmrTdeeCalculatorScreen({
    super.key,
    this.onCalculated,
  });

  @override
  State<BmrTdeeCalculatorScreen> createState() => _BmrTdeeCalculatorScreenState();
}

class _BmrTdeeCalculatorScreenState extends State<BmrTdeeCalculatorScreen> {
  final CalculatorController _controller = CalculatorController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMR & TDEE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Text(
              'Calculate your daily needs',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.greySubtext,
              ),
            ),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tiêu đề mục thông tin cá nhân
                Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Các trường nhập cá nhân
                _buildInputTile(
                  context: context,
                  label: 'Age',
                  value: '${_controller.age}',
                  icon: Icons.cake_outlined,
                  onTap: () {
                    // Logic mở dialog chọn tuổi khi cần
                  },
                ),
                const SizedBox(height: 10),
                _buildInputTile(
                  context: context,
                  label: 'Weight',
                  value: '${_controller.weightKg.toInt()}',
                  unit: 'kg',
                  icon: Icons.scale_outlined,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _buildInputTile(
                  context: context,
                  label: 'Height',
                  value: '${_controller.heightCm.toInt()}',
                  unit: 'cm',
                  icon: Icons.height_outlined,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _buildActivityTile(
                  context: context,
                  levelText: 'Moderately Active',
                  onTap: () {},
                ),

                const SizedBox(height: 28),

                // 3. Tiêu đề mục chọn mục tiêu
                Text(
                  'Your Goal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose your primary goal',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.greySubtext,
                  ),
                ),
                const SizedBox(height: 14),

                // 4. 3 Thẻ mục tiêu (Weight Loss, Maintenance, Muscle Gain)
                Row(
                  children: [
                    _buildGoalCard(
                      context: context,
                      goal: GoalType.weightLoss,
                      title: 'Weight\nLoss',
                      subtitle: 'Deficit',
                      icon: Icons.trending_down,
                    ),
                    const SizedBox(width: 10),
                    _buildGoalCard(
                      context: context,
                      goal: GoalType.maintenance,
                      title: 'Maintain\nWeight', // Tách 2 dòng đồng đều với 2 nút bên cạnh
                      subtitle: 'Maintain',
                      icon: Icons.horizontal_rule,
                    ),
                    const SizedBox(width: 10),
                    _buildGoalCard(
                      context: context,
                      goal: GoalType.muscleGain,
                      title: 'Muscle\nGain',
                      subtitle: 'Surplus',
                      icon: Icons.trending_up,
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // 5. Nút Calculate
                ElevatedButton(
                  onPressed: () {
                    _controller.calculateDailyNeeds();
                    if (widget.onCalculated != null) {
                      widget.onCalculated!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Calculate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputTile({
    required BuildContext context,
    required String label,
    required String value,
    String? unit,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.greySubtext),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(fontSize: 12, color: AppColors.greySubtext),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required BuildContext context,
    required String levelText,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_run, size: 20, color: AppColors.greySubtext),
          const SizedBox(width: 12),
          Text(
            'Activity Level',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const Spacer(),
          Text(
            levelText,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.greySubtext,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.greySubtext),
        ],
      ),
    );
  }

Widget _buildGoalCard({
  required BuildContext context,
  required GoalType goal,
  required String title,
  required String subtitle,
  required IconData icon,
}) {
  final isSelected = _controller.selectedGoal == goal;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Expanded(
    child: GestureDetector(
      onTap: () => _controller.setGoal(goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 138, // Tăng chiều cao để thẻ dài và thanh thoát hơn
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.lime : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.lime.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Icon đại diện có vòng nền bo tròn
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.lime.withOpacity(0.15)
                    : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.lime : AppColors.greySubtext,
                size: 24,
              ),
            ),

            // 2. Tiêu đề mục tiêu
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    height: 1.2,
                  ),
                ),
              ),
            ),

            // 3. Phụ đề trạng thái (Deficit / Maintain / Surplus)
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.lime : Colors.black)
                    : AppColors.greySubtext,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}