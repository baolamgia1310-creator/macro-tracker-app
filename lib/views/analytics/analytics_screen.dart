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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
                    icon: Icon(Icons.keyboard_arrow_down, size: 18, color: subtextColor),
                    dropdownColor: cardColor,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    items: _controller.timeRanges.map((range) {
                      return DropdownMenuItem(value: range, child: Text(range));
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
                // 1. Khung Biểu đồ Cân nặng (Weight Trend)[cite: 2]
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
                          Text(
                            '${_controller.currentWeight} kg',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.lime : AppColors.lightText,
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

                // 2. Khung Biểu đồ Macro Adherence (Màu riêng từng chất)[cite: 1, 2]
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
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 140,
                        child: BarChart(
                          _buildMacroBarChartData(isDark, subtextColor),
                          duration: const Duration(milliseconds: 350),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Ba Thẻ Tóm Tắt Chân Trang[cite: 2]
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
    final spots = _controller.weeklyWeights.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= _controller.weeklyWeights.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _controller.weeklyWeights[index].day,
                  style: TextStyle(fontSize: 11, color: subtextColor, fontWeight: FontWeight.w500),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y} kg',
                TextStyle(
                  color: isDark ? AppColors.darkText : Colors.white,
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

  // Cấu hình Biểu đồ cột đã sửa triệt để 3 vấn đề
BarChartData _buildMacroBarChartData(bool isDark, Color subtextColor) {
  final barBgColor = isDark
      ? Colors.white.withOpacity(0.04)
      : Colors.black.withOpacity(0.04);

  return BarChartData(
    alignment: BarChartAlignment.spaceAround,
    maxY: 120, // Tăng lên 120 để đỉnh cột không bao giờ đè lên tiêu đề phía trên
    gridData: const FlGridData(show: false),
    borderData: FlBorderData(show: false),

    // Cấu hình hiển thị số trên đỉnh cột
    barTouchData: BarTouchData(
      enabled: false,
      touchTooltipData: BarTouchTooltipData(
        // Xóa khung nền đen thô cứng, để chữ nổi trực tiếp trên biểu đồ
        getTooltipColor: (group) => Colors.transparent,
        tooltipPadding: EdgeInsets.zero,
        tooltipMargin: 8,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            '${rod.toY.toInt()}', // CHỈ HIỂN THỊ SỐ NGUYÊN (78, 82, 85)
            TextStyle(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontWeight: FontWeight.w800,
              fontSize: 14,
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

    // 3 Cột với bảng màu chuẩn: Xanh lá (Lime) -> Cyan -> Cam ấm
    barGroups: [
      _buildBarGroup(
        0,
        _controller.proteinAdherence * 100,
        AppColors.lime, // Cột 1: Xanh lá thương hiệu
        barBgColor,
      ),
      _buildBarGroup(
        1,
        _controller.carbsAdherence * 100,
        AppColors.protein, // Cột 2: Xanh Cyan
        barBgColor,
      ),
      _buildBarGroup(
        2,
        _controller.fatAdherence * 100,
        AppColors.carbs, // Cột 3: Cam hổ phách
        barBgColor,
      ),
    ],
  );
}

  BarChartGroupData _buildBarGroup(int x, double value, Color barColor, Color backColor) {
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