import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MacroBar extends StatelessWidget {
  final String title;
  final double currentGrams;
  final double targetGrams;
  final Color barColor;

  const MacroBar({
    super.key,
    required this.title,
    required this.currentGrams,
    required this.targetGrams,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (targetGrams > 0) ? (currentGrams / targetGrams).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();

    return Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${currentGrams.toInt()} / ${targetGrams.toInt()}g',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.greySubtext,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[300] : AppColors.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: isDark 
                ? Colors.white.withOpacity(0.08) 
                : Colors.black.withOpacity(0.06),
            color: barColor,
          ),
        ),
      ],
    );
  }
}