import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/bmr_calculator_service.dart';

class DailyLogController extends ChangeNotifier {
  // Mục tiêu mặc định
  MacroTarget _target = const MacroTarget(
    targetCalories: 2200,
    targetProteinGrams: 140,
    targetCarbsGrams: 198,
    targetFatGrams: 73,
  );

  final List<MealLogEntry> _logs = [];

  MacroTarget get target => _target;
  List<MealLogEntry> get logs => List.unmodifiable(_logs);

  // Computed Values
  double get totalConsumedCalories =>
      _logs.fold(0, (sum, item) => sum + item.totalCalories);

  double get totalConsumedProtein =>
      _logs.fold(0, (sum, item) => sum + item.totalProtein);

  double get totalConsumedCarbs =>
      _logs.fold(0, (sum, item) => sum + item.totalCarbs);

  double get totalConsumedFat =>
      _logs.fold(0, (sum, item) => sum + item.totalFat);

  double get calorieProgress => (_target.targetCalories > 0)
      ? (totalConsumedCalories / _target.targetCalories).clamp(0.0, 1.0)
      : 0.0;

  void addFoodEntry(FoodItem food, double grams, String mealType) {
    _logs.add(MealLogEntry(food: food, amountGrams: grams, mealType: mealType));
    notifyListeners();
  }

  void updateTarget(MacroTarget newTarget) {
    _target = newTarget;
    notifyListeners();
  }
}