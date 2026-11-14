import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/analytics_controller.dart';
import '../../core/constants/app_colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsController _controller = AnalyticsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showLogWeightDialog(
    BuildContext context,
    Color cardColor,
    Color textColor,
  ) {
    final weightCtrl = TextEditingController(
      text: '${_controller.currentWeight}',
    );

    void submitWeight(BuildContext dialogContext) {
      final rawText = weightCtrl.text.trim().replaceAll(',', '.');
      final val = double.tryParse(rawText);
      Navigator.of(dialogContext).pop();
      if (val != null && val >= 20 && val <= 300) {
        _controller.logWeight(val);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Log Today\'s Weight',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: textColor,
            ),
          ),
          content: TextField(
            controller: weightCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => submitWeight(ctx),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              suffixText: 'kg',
              hintText: 'e.g. 82.0',
              hintStyle: TextStyle(color: AppColors.greySubtext),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.greySubtext),
              ),
            ),
            ElevatedButton(
              onPressed: () => submitWeight(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(
          'Progress',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _controller.selectedRange,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: subtextColor,
                    ),
                    dropdownColor: cardColor,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    items: _controller.timeRanges.map((range) {
                      return DropdownMenuItem(
                        value: range,
                        child: Text(range),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _controller.setRange(val);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Khung Biểu đồ Cân nặng (Weight Trend)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Weight Trend (kg)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showLogWeightDialog(
                              context,
                              cardColor,
                              textColor,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${_controller.currentWeight} kg',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.lime : AppColors.lightText,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 15,
                                  color: isDark ? AppColors.lime : AppColors.lightText,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 160,
                        child: LineChart(
                          _buildWeightChartData(isDark, subtextColor),
                          duration: const Duration(milliseconds: 350),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Khung Biểu đồ Macro Adherence
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Macro Adherence',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 150,
                        child: BarChart(
                          _buildMacroBarChartData(isDark, textColor, subtextColor),
                          duration: const Duration(milliseconds: 350),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Ba Thẻ Tóm Tắt Chân Trang
                Row(
                  children: [
                    _buildStatCard(
                      title: 'Avg. Calories',
                      value: '${_controller.avgCalories}',
                      unit: 'kcal / day',
                      isDark: isDark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      title: 'Weight Change',
                      value: '${_controller.weightChange}',
                      unit: 'kg',
                      isDark: isDark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      title: 'Streak',
                      value: '${_controller.streakDays}',
                      unit: 'days',
                      isDark: isDark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  LineChartData _buildWeightChartData(bool isDark, Color subtextColor) {
    final weights = _controller.weeklyWeights;
    final spots = weights.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    double minW = 60.0;
    double maxW = 75.0;
    if (weights.isNotEmpty) {
      minW = weights.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
      maxW = weights.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    }

    // Tạo khoảng đệm trên và dưới để đường thẳng không bị dính sát đáy
    final double chartMinY = (minW - 2.0).clamp(0.0, 500.0);
    final double chartMaxY = maxW + 2.0;

    return LineChartData(
      minX: 0,
      maxX: (weights.length > 1 ? weights.length - 1 : 6).toDouble(),
      minY: chartMinY,
      maxY: chartMaxY,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1, // Khóa bước nhảy = 1 để không bị lặp thứ (Sun Sun Mon Mon)
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              if (value != value.roundToDouble()) {
                return const SizedBox.shrink();
              }
              final index = value.toInt();
              if (index < 0 || index >= weights.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  weights[index].day,
                  style: TextStyle(
                    fontSize: 11,
                    color: subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => isDark ? const Color(0xFF2C3540) : Colors.black87,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} kg',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.protein,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.protein,
                strokeWidth: 2,
                strokeColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.protein.withOpacity(isDark ? 0.3 : 0.15),
                AppColors.protein.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartData _buildMacroBarChartData(
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final barBgColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 120, // Tăng trần lên 120 để nhãn % trên đỉnh cột luôn thoáng
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: false,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.transparent,
          tooltipPadding: EdgeInsets.zero,
          tooltipMargin: 6,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${rod.toY.round()}%',
              TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final titles = ['Protein', 'Carbs', 'Fat'];
              final index = value.toInt();
              if (index >= 0 && index < titles.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    titles[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      barGroups: [
        _buildBarGroup(
          0,
          (_controller.proteinAdherence * 100).roundToDouble(),
          AppColors.protein,
          barBgColor,
        ),
        _buildBarGroup(
          1,
          (_controller.carbsAdherence * 100).roundToDouble(),
          AppColors.carbs,
          barBgColor,
        ),
        _buildBarGroup(
          2,
          (_controller.fatAdherence * 100).roundToDouble(),
          AppColors.fat,
          barBgColor,
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(
    int x,
    double value,
    Color barColor,
    Color backColor,
  ) {
    return BarChartGroupData(
      x: x,
      showingTooltipIndicators: [0],
      barRods: [
        BarChartRodData(
          toY: value,
          color: barColor,
          width: 38,
          borderRadius: BorderRadius.circular(10),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: backColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.lime : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}