import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/bmr_calculator_service.dart';

class CalculatorController extends ChangeNotifier {
  final BmrCalculatorService _calculatorService = BmrCalculatorService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _age = 25;
  double _weightKg = 68.0;
  double _heightCm = 172.0;
  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  GoalType _selectedGoal = GoalType.weightLoss;

  bool _isLoading = false;
  String? _errorMessage;
  double? _bmr;
  double? _tdee;
  MacroTarget? _calculatedTarget;

  int get age => _age;
  double get weightKg => _weightKg;
  double get heightCm => _heightCm;
  Gender get gender => _gender;
  ActivityLevel get activityLevel => _activityLevel;
  GoalType get selectedGoal => _selectedGoal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double? get bmr => _bmr;
  double? get tdee => _tdee;
  MacroTarget? get calculatedTarget => _calculatedTarget;

  // Tính toán BMI và phân nhóm y tế
  double get bmi => _calculatorService.calculateBMI(_weightKg, _heightCm);
  BmiCategory get bmiCategory => _calculatorService.getBmiCategory(bmi);
  String get bmiCategoryLabel => _calculatorService.getCategoryLabel(bmiCategory);
  String get goalRecommendation => _calculatorService.getGoalRecommendation(bmiCategory);

  // Nhận diện trạng thái để đổi màu chỉ báo (Normal: Xanh; Underweight: Cyan; Overweight/Obese: Cam/Đỏ)
  Color get bmiStatusColor {
    if (bmi < 18.5) return const Color(0xFF06B6D4); // Cyan
    if (bmi < 25.0) return const Color(0xFFC6F235); // Lime
    if (bmi < 30.0) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  void setAge(int val) { _age = val; notifyListeners(); }
  void setWeight(double val) { _weightKg = val; notifyListeners(); }
  void setHeight(double val) { _heightCm = val; notifyListeners(); }
  void setGender(Gender val) { _gender = val; notifyListeners(); }
  void setActivityLevel(ActivityLevel val) { _activityLevel = val; notifyListeners(); }
  void setGoal(GoalType val) { _selectedGoal = val; notifyListeners(); }

  String? validateInputs() {
    if (_age < 15 || _age > 90) return 'Age must be between 15 and 90.';
    if (_weightKg < 30.0 || _weightKg > 250.0) return 'Weight must be between 30 and 250 kg.';
    if (_heightCm < 100.0 || _heightCm > 230.0) return 'Height must be between 100 and 230 cm.';
    return null;
  }

  void calculate() {
    final validation = validateInputs();
    if (validation != null) {
      _errorMessage = validation;
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _bmr = _calculatorService.calculateBMR(
      weightKg: _weightKg,
      heightCm: _heightCm,
      age: _age,
      gender: _gender,
    );

    _tdee = _calculatorService.calculateTDEE(_bmr!, _activityLevel);

    _calculatedTarget = _calculatorService.calculateTarget(
      bmr: _bmr!,
      tdee: _tdee!,
      goal: _selectedGoal,
      gender: _gender,
      bmi: bmi,
    );

    notifyListeners();
  }

  Future<bool> saveProfileAndTargets(String uid) async {
    if (_calculatedTarget == null) calculate();
    if (_errorMessage != null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _db.collection('users').doc(uid).set({
        'age': _age,
        'gender': _gender.name,
        'weightKg': _weightKg,
        'heightCm': _heightCm,
        'bmi': double.parse(bmi.toStringAsFixed(1)),
        'bmiCategory': bmiCategory.name,
        'activityLevel': _activityLevel.name,
        'goal': _selectedGoal.name,
        'bmr': _bmr,
        'tdee': _tdee,
        'targetMacros': {
          'targetCalories': _calculatedTarget!.targetCalories,
          'targetProteinGrams': _calculatedTarget!.targetProteinGrams,
          'targetCarbsGrams': _calculatedTarget!.targetCarbsGrams,
          'targetFatGrams': _calculatedTarget!.targetFatGrams,
        },
        'isProfileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save profile. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}