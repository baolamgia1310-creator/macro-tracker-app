import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_item.dart';
import '../repositories/food_repository.dart';

class FoodSearchController extends ChangeNotifier {
  final FoodRepository _foodRepository;

  final List categories = const [
    'All',
    'Món ăn',
    'Nguyên liệu',
    'USDA API',
    'My Foods'
  ];

  FoodSearchController({FoodRepository? foodRepository})
      : _foodRepository = foodRepository ?? FoodRepository() {
    loadInitialData();
  }

  Timer? _debounceTimer;
  int _latestSearchTimestamp = 0;

  List _catalogFoods = [];
  List _apiFoods = [];
  List _customFoods = [];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  double _selectedAmount = 100.0;
  FoodItem? _selectedFood;
  bool _isLoading = false;

  List get filteredFoods {
    final query = _searchQuery.trim().toLowerCase();

    if (_selectedCategory == 'Món ăn') {
      return _catalogFoods.where((f) => f.servingType == 'serving').toList();
    }
    if (_selectedCategory == 'Nguyên liệu') {
      return _catalogFoods.where((f) => f.servingType == 'g').toList();
    }
    if (_selectedCategory == 'USDA API') {
      return _apiFoods;
    }
    if (_selectedCategory == 'My Foods') {
      return _customFoods
          .where((f) => f.name.toLowerCase().contains(query))
          .toList();
    }

    return [..._customFoods, ..._catalogFoods, ..._apiFoods];
  }

  String get selectedCategory => _selectedCategory;
  FoodItem? get selectedFood => _selectedFood;
  bool get isLoading => _isLoading;
  double get selectedAmount => _selectedAmount;
  double get selectedGrams => _selectedAmount;

  String get amountLabel {
    if (_selectedFood?.servingType == 'serving') {
      return _selectedAmount == _selectedAmount.roundToDouble()
          ? '${_selectedAmount.toInt()}'
          : _selectedAmount.toStringAsFixed(1);
    }
    return '${_selectedAmount.toInt()}';
  }

  String get unitLabel => _selectedFood?.servingType == 'serving'
      ? (_selectedFood?.unitName ?? 'suất')
      : 'grams';

  double get calculatedCalories {
    if (_selectedFood == null) return 0.0;
    final factor = _selectedFood!.servingType == 'serving'
        ? _selectedAmount
        : (_selectedAmount / 100.0);
    return _selectedFood!.calories * factor;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        _customFoods = await _foodRepository.getUserCustomFoods(uid);
      } catch (_) {}
    }

    _catalogFoods = await _foodRepository.searchLocalCatalog('');
    if (_catalogFoods.isNotEmpty && _selectedFood == null) {
      selectFood(_catalogFoods.first);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();

    _debounceTimer?.cancel();
    final trimmed = query.trim();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final requestTime = DateTime.now().millisecondsSinceEpoch;
      _latestSearchTimestamp = requestTime;

      _isLoading = true;
      notifyListeners();

      try {
        final localResults = await _foodRepository.searchLocalCatalog(trimmed);

        List remoteResults = [];
        if (trimmed.length >= 2) {
          remoteResults = await _foodRepository.searchRemoteApi(trimmed);
        }

        if (_latestSearchTimestamp == requestTime) {
          _catalogFoods = localResults;
          _apiFoods = remoteResults;

          if (filteredFoods.isNotEmpty && _selectedFood == null) {
            selectFood(filteredFoods.first);
          }
        }
      } finally {
        if (_latestSearchTimestamp == requestTime) {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    if (filteredFoods.isNotEmpty) {
      selectFood(filteredFoods.first);
    }
    notifyListeners();
  }

  void selectFood(FoodItem food) {
    _selectedFood = food;
    _selectedAmount = food.servingType == 'serving' ? 1.0 : 100.0;
    notifyListeners();
  }

  void incrementAmount() {
    if (_selectedFood?.servingType == 'serving') {
      _selectedAmount += 0.5;
    } else {
      _selectedAmount += 10.0;
    }
    notifyListeners();
  }

  void decrementAmount() {
    if (_selectedFood?.servingType == 'serving') {
      if (_selectedAmount > 0.5) _selectedAmount -= 0.5;
    } else {
      if (_selectedAmount > 10.0) _selectedAmount -= 10.0;
    }
    notifyListeners();
  }

  Future logFood({required String mealType}) async {
    if (_selectedFood == null) return false;
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;

    try {
      await _foodRepository.logFoodToMeal(
        uid: uid,
        mealType: mealType,
        food: _selectedFood!,
        amount: _selectedAmount,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}