import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MacroProgressRing extends StatelessWidget {
  final double consumedCalories;
  final double targetCalories;
  final double progressPercent;

  const MacroProgressRing({
    super.key,
    required this.consumedCalories,
    required this.targetCalories,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tự động đổi màu %: đen ở Light Mode, lime ở Dark Mode
    final percentTextColor = isDark ? AppColors.lime : AppColors.lightText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 175,
              height: 175,
              child: CircularProgressIndicator(
                value: progressPercent,
                strokeWidth: 13,
                backgroundColor: isDark 
                    ? Colors.white.withOpacity(0.08) 
                    : Colors.black.withOpacity(0.06),
                color: AppColors.lime,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  consumedCalories.toInt().toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      ),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '/ ${targetCalories.toInt().toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progressPercent * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: percentTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}