import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/bmr_calculator_service.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';

class CalculatorController extends ChangeNotifier {
  final BmrCalculatorService _calculatorService;
  final UserRepository _userRepository;
  final AuthService _authService;

  CalculatorController({
    BmrCalculatorService? calculatorService,
    UserRepository? userRepository,
    AuthService? authService,
  })  : _calculatorService = calculatorService ?? BmrCalculatorService(),
        _userRepository = userRepository ?? UserRepository(),
        _authService = authService ?? AuthService();

  int _age = 25;
  double _weightKg = 68.0;
  double _heightCm = 172.0;
  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  GoalType _selectedGoal = GoalType.weightLoss;
  bool _isLoading = false;
  String? _errorMessage;

  // Các Getter phục vụ trực tiếp cho giao diện bmr_tdee_calculator_screen.dart
  int get age => _age;
  double get weightKg => _weightKg;
  double get heightCm => _heightCm;
  Gender get gender => _gender;
  ActivityLevel get activityLevel => _activityLevel;
  GoalType get selectedGoal => _selectedGoal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get bmi => _calculatorService.calculateBMI(_weightKg, _heightCm);
  BmiCategory get bmiCategory => _calculatorService.getBmiCategory(bmi);
  String get bmiCategoryLabel => _calculatorService.getCategoryLabel(bmiCategory);
  String get goalRecommendation => _calculatorService.getGoalRecommendation(bmiCategory);

  Color get bmiStatusColor {
    if (bmi < 18.5) return const Color(0xFF06B6D4); // Cyan
    if (bmi < 25.0) return const Color(0xFFC6F235); // Lime
    if (bmi < 30.0) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444);                 // Red
  }

  // Các Setter cập nhật trạng thái
  void setAge(int val) {
    _age = val;
    notifyListeners();
  }

  void setWeight(double val) {
    _weightKg = val;
    notifyListeners();
  }

  void setHeight(double val) {
    _heightCm = val;
    notifyListeners();
  }

  void setGender(Gender val) {
    _gender = val;
    notifyListeners();
  }

  void setActivityLevel(ActivityLevel val) {
    _activityLevel = val;
    notifyListeners();
  }

  void setGoal(GoalType val) {
    _selectedGoal = val;
    notifyListeners();
  }

  // Phương thức lưu Firestore được gọi từ nút "Calculate & Continue"
  Future<bool> saveProfileAndTargets() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      _errorMessage = 'User session expired. Please sign in again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bmr = _calculatorService.calculateBMR(
        weightKg: _weightKg,
        heightCm: _heightCm,
        age: _age,
        gender: _gender,
      );
      final tdee = _calculatorService.calculateTDEE(bmr, _activityLevel);
      final target = _calculatorService.calculateTarget(
        bmr: bmr,
        tdee: tdee,
        goal: _selectedGoal,
        gender: _gender,
        bmi: bmi,
      );

      final data = {
        'uid': uid,
        'hasPassword': true,
        'isProfileCompleted': true,
        'age': _age,
        'gender': _gender.name,
        'weightKg': _weightKg,
        'heightCm': _heightCm,
        'bmi': double.parse(bmi.toStringAsFixed(1)),
        'bmiCategory': bmiCategory.name,
        'activityLevel': _activityLevel.name,
        'goal': _selectedGoal.name,
        'bmr': bmr,
        'tdee': tdee,
        'targetMacros': target.toMap(),
      };

      await _userRepository.saveUserMacroProfile(uid: uid, data: data);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Failed to save profile. Please check connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}