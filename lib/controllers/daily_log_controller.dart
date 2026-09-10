import 'dart:async';
import 'package:flutter/material.dart';
import '../models/logged_food_item.dart';
import '../services/bmr_calculator_service.dart';
import '../repositories/daily_log_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';

class DailyLogController extends ChangeNotifier {
  final DailyLogRepository _logRepository;
  final UserRepository _userRepository;
  final AuthService _authService;

  DailyLogController({
    DailyLogRepository? logRepository,
    UserRepository? userRepository,
    AuthService? authService,
  })  : _logRepository = logRepository ?? DailyLogRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _authService = authService ?? AuthService() {
    _initDataStreams();
  }

  StreamSubscription<List<LoggedFoodItem>>? _logsSubscription;
  StreamSubscription<Map<String, dynamic>?>? _userDocSubscription;

  List<LoggedFoodItem> _todayLogs = [];
  MacroTarget _target = const MacroTarget(
    targetCalories: 2000,
    targetProteinGrams: 150,
    targetCarbsGrams: 200,
    targetFatGrams: 65,
  );
  bool _isLoading = true;

  // --- Getters khớp 100% với giao diện Dashboard của bạn ---
  bool get isLoading => _isLoading;
  MacroTarget get target => _target;

  double get totalConsumedCalories =>
      _todayLogs.fold(0.0, (sum, item) => sum + item.calories);

  double get totalConsumedProtein =>
      _todayLogs.fold(0.0, (sum, item) => sum + item.protein);

  double get totalConsumedCarbs =>
      _todayLogs.fold(0.0, (sum, item) => sum + item.carbs);

  double get totalConsumedFat =>
      _todayLogs.fold(0.0, (sum, item) => sum + item.fat);

  double get calorieProgress => (_target.targetCalories > 0)
      ? (totalConsumedCalories / _target.targetCalories).clamp(0.0, 1.0)
      : 0.0;

  // --- Phương thức hỗ trợ hiển thị 4 bữa ăn động ---
  double getMealCalories(String mealType) {
    return _todayLogs
        .where((item) => item.mealType.toLowerCase() == mealType.toLowerCase())
        .fold(0.0, (sum, item) => sum + item.calories);
  }

  String getMealCaloriesString(String mealType) {
    final cals = getMealCalories(mealType);
    return cals > 0 ? '${cals.round()} kcal' : '-- kcal';
  }

  bool isMealCompleted(String mealType) {
    return getMealCalories(mealType) > 0;
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  void _initDataStreams() {
    final uid = _authService.currentUserId;
    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 1. Lắng nghe mục tiêu dinh dưỡng cá nhân từ Firestore
    _userDocSubscription = _userRepository.watchUserDoc(uid).listen((userData) {
      if (userData != null && userData['targetMacros'] != null) {
        final rawTarget = userData['targetMacros'] as Map<String, dynamic>;
        _target = MacroTarget(
          targetCalories: (rawTarget['targetCalories'] as num?)?.toDouble() ?? 2000.0,
          targetProteinGrams: (rawTarget['targetProteinGrams'] as num?)?.toDouble() ?? 150.0,
          targetCarbsGrams: (rawTarget['targetCarbsGrams'] as num?)?.toDouble() ?? 200.0,
          targetFatGrams: (rawTarget['targetFatGrams'] as num?)?.toDouble() ?? 65.0,
        );
        notifyListeners();
      }
    });

    // 2. Lắng nghe danh sách món ăn trong ngày theo thời gian thực
    _logsSubscription = _logRepository.watchTodayLogs(uid).listen((logs) {
      _todayLogs = logs;
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }
}