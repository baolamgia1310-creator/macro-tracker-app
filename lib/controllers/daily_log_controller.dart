import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/logged_food_item.dart';
import '../repositories/daily_log_repository.dart';

typedef LoggedFoodList = List<LoggedFoodItem>;
typedef JsonMap = Map<String, dynamic>;

class DailyLogController extends ChangeNotifier {
  final DailyLogRepository _logRepository;
  final FirebaseFirestore _firestore;

  DailyLogController({
    DailyLogRepository? logRepository,
    FirebaseFirestore? firestore,
  })  : _logRepository = logRepository ?? DailyLogRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _bindUserStreams(user?.uid);
    });
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<LoggedFoodList>? _logsSub;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  LoggedFoodList _todayLogs = [];
  DateTime _selectedDate = DateTime.now();

  int _targetCalories = 2000;
  double _targetProtein = 150.0;
  double _targetCarbs = 200.0;
  double _targetFat = 65.0;
  String _userGoal = 'maintenance';
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  int get targetCalories => _targetCalories;
  double get targetProtein => _targetProtein;
  double get targetCarbs => _targetCarbs;
  double get targetFat => _targetFat;
  String get userGoal => _userGoal;

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get formattedDateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[_selectedDate.month - 1]}${_selectedDate.day}';
  }

  int get consumedCalories =>
      _todayLogs.fold(0, (sum, item) => sum + item.calories);
  double get consumedProtein =>
      _todayLogs.fold(0.0, (sum, item) => sum + item.protein);
  double get consumedCarbs =>
      _todayLogs.fold(0.0, (sum, item) => sum + item.carbs);
  double get consumedFat =>
      _todayLogs.fold(0.0, (sum, item) => sum + item.fat);

  int get remainingCalories =>
      (_targetCalories - consumedCalories).clamp(0, 999999);

  int get overCalories =>
      (consumedCalories - _targetCalories).clamp(0, 999999);

  bool get isOverBudget => consumedCalories > _targetCalories;

  double get rawCalorieRatio =>
      (_targetCalories > 0) ? (consumedCalories / _targetCalories) : 0.0;

  int get caloriePercentage => (rawCalorieRatio * 100).round();

  double get calorieProgress => rawCalorieRatio.clamp(0.0, 1.0);

  bool get isSlightlyOver {
    if (!isOverBudget) return false;
    final isMuscleGain = _userGoal.toLowerCase().contains('gain');
    if (isMuscleGain && overCalories <= 200) {
      return true;
    }
    return rawCalorieRatio <= 1.10;
  }

  String get budgetStatusMessage {
    if (!isOverBudget) {
      if (consumedCalories == 0) return 'Log your meals to start tracking today';
      return 'On track • Within your daily calorie goal';
    }
    if (isSlightlyOver) {
      return 'Slightly over target (+$overCalories kcal) • Buffer zone';
    }
    return 'Over daily budget by $overCalories kcal';
  }

  LoggedFoodList get breakfastItems => _todayLogs
      .where((i) => i.mealType.toLowerCase() == 'breakfast')
      .toList();
  LoggedFoodList get lunchItems => _todayLogs
      .where((i) => i.mealType.toLowerCase() == 'lunch')
      .toList();
  LoggedFoodList get dinnerItems => _todayLogs
      .where((i) => i.mealType.toLowerCase() == 'dinner')
      .toList();
  LoggedFoodList get snackItems => _todayLogs
      .where((i) =>
          i.mealType.toLowerCase() == 'snacks' ||
          i.mealType.toLowerCase() == 'snack')
      .toList();

  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _subscribeToLogs(uid);
    notifyListeners();
  }

  void previousDay() {
    setSelectedDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  void nextDay() {
    setSelectedDate(_selectedDate.add(const Duration(days: 1)));
  }

  void _bindUserStreams(String? uid) {
    _logsSub?.cancel();
    _userDocSub?.cancel();

    if (uid == null || uid.isEmpty) {
      _todayLogs = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _userDocSub = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        final targets = data['targetMacros'] as JsonMap? ?? data;
        _targetCalories =
            (targets['targetCalories'] ?? data['tdee'] ?? 2000 as num).toInt();
        _targetProtein =
            (targets['targetProteinGrams'] ?? data['proteinGrams'] ?? 150.0 as num)
                .toDouble();
        _targetCarbs =
            (targets['targetCarbsGrams'] ?? data['carbsGrams'] ?? 200.0 as num)
                .toDouble();
        _targetFat =
            (targets['targetFatGrams'] ?? data['fatGrams'] ?? 65.0 as num)
                .toDouble();
        _userGoal = (data['goal'] ?? targets['goal'] ?? 'maintenance').toString();
        notifyListeners();
      }
    });

    _subscribeToLogs(uid);
  }

  void _subscribeToLogs(String? uid) {
    _logsSub?.cancel();
    if (uid == null || uid.isEmpty) return;

    _logsSub = _logRepository.watchLogsForDate(uid, _selectedDate).listen((logs) {
      _todayLogs = logs;
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> removeFoodLog(String logId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    await _logRepository.deleteLoggedFood(uid: uid, logId: logId);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _logsSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}