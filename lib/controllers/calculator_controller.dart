import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/bmr_calculator_service.dart';

class CalculatorController extends ChangeNotifier {
  final BmrCalculatorService _calculatorService = BmrCalculatorService();

  int _age = 28;
  double _weightKg = 70.0;
  double _heightCm = 176.0;
  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  GoalType _selectedGoal = GoalType.weightLoss;

  MacroTarget? _calculatedResult;

  // Getters
  int get age => _age;
  double get weightKg => _weightKg;
  double get heightCm => _heightCm;
  Gender get gender => _gender;
  ActivityLevel get activityLevel => _activityLevel;
  GoalType get selectedGoal => _selectedGoal;
  MacroTarget? get calculatedResult => _calculatedResult;

  // Setters & Actions
  void setAge(int value) {
    _age = value;
    notifyListeners();
  }

  void setWeight(double value) {
    _weightKg = value;
    notifyListeners();
  }

  void setHeight(double value) {
    _heightCm = value;
    notifyListeners();
  }

  void setGender(Gender gender) {
    _gender = gender;
    notifyListeners();
  }

  void setActivityLevel(ActivityLevel level) {
    _activityLevel = level;
    notifyListeners();
  }

  void setGoal(GoalType goal) {
    _selectedGoal = goal;
    notifyListeners();
  }

  // Gọi service tính toán chỉ số
  void calculateDailyNeeds() {
    final bmr = _calculatorService.calculateBMR(
      weightKg: _weightKg,
      heightCm: _heightCm,
      age: _age,
      gender: _gender,
    );

    final tdee = _calculatorService.calculateTDEE(bmr, _activityLevel);
    _calculatedResult = _calculatorService.calculateTarget(tdee, _selectedGoal);
    notifyListeners();
  }
}