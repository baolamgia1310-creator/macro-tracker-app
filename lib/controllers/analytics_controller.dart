import 'package:flutter/material.dart';

class WeightDataPoint {
  final String day;
  final double weight;

  const WeightDataPoint({required this.day, required this.weight});
}

class AnalyticsController extends ChangeNotifier {
  final List<String> timeRanges = const ['This Week', 'This Month', '3 Months'];
  String _selectedRange = 'This Week';

  // 7 mốc cân nặng trong tuần khớp ảnh thiết kế[cite: 2]
  final List<WeightDataPoint> _weeklyWeights = const [
    WeightDataPoint(day: 'Mon', weight: 71.5),
    WeightDataPoint(day: 'Tue', weight: 71.2),
    WeightDataPoint(day: 'Wed', weight: 71.0),
    WeightDataPoint(day: 'Thu', weight: 70.8),
    WeightDataPoint(day: 'Fri', weight: 70.6),
    WeightDataPoint(day: 'Sat', weight: 70.4),
    WeightDataPoint(day: 'Sun', weight: 70.2),
  ];

  // Chỉ số tuân thủ Macro (Adherence)[cite: 2]
  final double proteinAdherence = 0.78;
  final double carbsAdherence = 0.82;
  final double fatAdherence = 0.85;

  // 3 Thống kê tóm tắt[cite: 2]
  final int avgCalories = 2120;
  final double weightChange = -1.3;
  final int streakDays = 7;

  // Getters
  String get selectedRange => _selectedRange;
  List<WeightDataPoint> get weeklyWeights => _weeklyWeights;
  double get currentWeight => _weeklyWeights.isNotEmpty ? _weeklyWeights.last.weight : 0.0;

  void setRange(String range) {
    _selectedRange = range;
    notifyListeners();
  }
}