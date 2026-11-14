import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/bmr_calculator_service.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';

typedef JsonMap = Map<String, dynamic>;

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
        _authService = authService ?? AuthService() {
    calculate();
    _loadExistingProfileIfAvailable();
  }

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

  // Các getter phục vụ thẻ Xem trước (Live Plan Preview) trên UI
  int get previewBmr => (_bmr ?? 1600).round();
  int get previewTdee => (_tdee ?? 2200).round();
  int get previewTargetCalories =>
      (_calculatedTarget?.targetCalories ?? 1800).round();
  int get previewProteinGrams =>
      (_calculatedTarget?.targetProteinGrams ?? 135).round();
  int get previewCarbsGrams =>
      (_calculatedTarget?.targetCarbsGrams ?? 180).round();
  int get previewFatGrams =>
      (_calculatedTarget?.targetFatGrams ?? 55).round();

  double get bmi => _calculatorService.calculateBMI(_weightKg, _heightCm);
  BmiCategory get bmiCategory => _calculatorService.getBmiCategory(bmi);
  String get bmiCategoryLabel =>
      _calculatorService.getCategoryLabel(bmiCategory);
  String get goalRecommendation =>
      _calculatorService.getGoalRecommendation(bmiCategory);

  Color get bmiStatusColor {
    if (bmi < 18.5) return const Color(0xFF06B6D4); // Cyan
    if (bmi < 25.0) return const Color(0xFFC6F235); // Lime
    if (bmi < 30.0) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  Future<void> _loadExistingProfileIfAvailable() async {
    final uid =
        _authService.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return;

      if (data['age'] is num) _age = (data['age'] as num).toInt();
      if (data['weightKg'] is num) {
        _weightKg = (data['weightKg'] as num).toDouble();
      }
      if (data['heightCm'] is num) {
        _heightCm = (data['heightCm'] as num).toDouble();
      }

      final genderStr = data['gender']?.toString() ?? '';
      if (genderStr == Gender.female.name) {
        _gender = Gender.female;
      } else if (genderStr == Gender.male.name) {
        _gender = Gender.male;
      }

      final actStr = data['activityLevel']?.toString() ?? '';
      for (final level in ActivityLevel.values) {
        if (level.name == actStr) {
          _activityLevel = level;
          break;
        }
      }

      final goalStr = data['goal']?.toString() ?? '';
      for (final g in GoalType.values) {
        if (g.name == goalStr) {
          _selectedGoal = g;
          break;
        }
      }

      calculate();
    } catch (_) {}
  }

  void setAge(int val) {
    _age = val;
    calculate();
  }

  void setWeight(double val) {
    _weightKg = val;
    calculate();
  }

  void setHeight(double val) {
    _heightCm = val;
    calculate();
  }

  void setGender(Gender val) {
    _gender = val;
    calculate();
  }

  void setActivityLevel(ActivityLevel val) {
    _activityLevel = val;
    calculate();
  }

  void setGoal(GoalType val) {
    _selectedGoal = val;
    calculate();
  }

  String? validateInputs() {
    if (_age < 12 || _age > 100) return 'Age must be between 12 and 100.';
    if (_weightKg < 30.0 || _weightKg > 250.0) {
      return 'Weight must be between 30 and 250 kg.';
    }
    if (_heightCm < 100.0 || _heightCm > 240.0) {
      return 'Height must be between 100 and 240 cm.';
    }
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
      weightKg: _weightKg,
      heightCm: _heightCm,
      activityLevel: _activityLevel,
    );

    notifyListeners();
  }

  Future<bool> saveProfileAndTargets() async {
    // Luôn gọi calculate() mới nhất trước khi lưu
    calculate();
    if (_errorMessage != null || _calculatedTarget == null) return false;

    final uid =
        _authService.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      _errorMessage = 'User session expired. Please sign in again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final JsonMap payload = {
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
        'bmr': _bmr!.round(),
        'tdee': _tdee!.round(),
        'targetMacros': _calculatedTarget!.toMap(),
      };

      await _userRepository.saveUserMacroProfile(uid: uid, data: payload);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Failed to save profile. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}