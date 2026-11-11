import 'dart:async';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../repositories/food_repository.dart';
import '../services/auth_service.dart';

class FoodSearchController extends ChangeNotifier {
  final FoodRepository _foodRepository;
  final AuthService _authService;

  final List<String> categories = const ['All', 'My Foods', 'USDA Database'];

  FoodSearchController({
    FoodRepository? foodRepository,
    AuthService? authService,
  })  : _foodRepository = foodRepository ?? FoodRepository(),
        _authService = authService ?? AuthService() {
    loadInitialData();
  }

  Timer? _debounceTimer;
  int _latestSearchTimestamp = 0;

  List<FoodItem> _customFoods = [];
  List<FoodItem> _apiFoods = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  double _selectedGrams = 150.0;
  FoodItem? _selectedFood;
  bool _isLoading = false;

  List<FoodItem> get filteredFoods {
    final query = _searchQuery.toLowerCase().trim();

    if (_selectedCategory == 'My Foods') {
      return _customFoods.where((f) => f.name.toLowerCase().contains(query)).toList();
    }
    if (_selectedCategory == 'USDA Database') {
      return _apiFoods;
    }

    final filteredCustom = _customFoods.where((f) => f.name.toLowerCase().contains(query));
    return [...filteredCustom, ..._apiFoods];
  }

  String get selectedCategory => _selectedCategory;
  double get selectedGrams => _selectedGrams;
  FoodItem? get selectedFood => _selectedFood;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Tự nạp dữ liệu mẫu ban đầu để màn hình không bị rỗng
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    final uid = _authService.currentUserId;
    if (uid != null) {
      try {
        _customFoods = await _foodRepository.getUserCustomFoods(uid);
      } catch (_) {}
    }

    // Tự động lấy một số món phổ biến từ USDA khi vừa mở màn hình
    try {
      _apiFoods = await _foodRepository.searchRemoteApi('chicken');
      if (_apiFoods.isNotEmpty) {
        _selectedFood = _apiFoods.first;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();

    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
        final requestTime = DateTime.now().millisecondsSinceEpoch;
        _latestSearchTimestamp = requestTime;

        _isLoading = true;
        notifyListeners();

        // Tự động map một số từ khóa tiếng Việt phổ biến sang tiếng Anh
        final translatedQuery = _mapVietnameseToEnglish(trimmed);

        try {
          final results = await _foodRepository.searchRemoteApi(translatedQuery);

          if (_latestSearchTimestamp == requestTime) {
            _apiFoods = results;
            if (_selectedFood == null && _apiFoods.isNotEmpty) {
              _selectedFood = _apiFoods.first;
            }
          }
        } finally {
          if (_latestSearchTimestamp == requestTime) {
            _isLoading = false;
            notifyListeners();
          }
        }
      });
    } else if (trimmed.isEmpty) {
      // Nếu xóa trắng thì tải lại danh sách món mẫu
      loadInitialData();
    }
  }

  String _mapVietnameseToEnglish(String input) {
    final lower = input.toLowerCase();
    const dict = {
      'trung': 'egg', 'trứng': 'egg',
      'ga': 'chicken', 'gà': 'chicken', 'thit ga': 'chicken', 'thịt gà': 'chicken',
      'bo': 'beef', 'bò': 'beef', 'thit bo': 'beef', 'thịt bò': 'beef',
      'heo': 'pork', 'lon': 'pork', 'thit heo': 'pork', 'thịt lợn': 'pork',
      'com': 'rice', 'cơm': 'rice', 'gao': 'rice', 'gạo': 'rice',
      'ca': 'fish', 'cá': 'fish',
      'sua': 'milk', 'sữa': 'milk',
      'chuoi': 'banana', 'chuối': 'banana',
      'tao': 'apple', 'táo': 'apple',
      'banh mi': 'bread', 'bánh mì': 'bread',
    };
    return dict[lower] ?? input;
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void selectFood(FoodItem food) {
    _selectedFood = food;
    notifyListeners();
  }

  void incrementGrams() {
    _selectedGrams += 10.0;
    notifyListeners();
  }

  void decrementGrams() {
    if (_selectedGrams > 10.0) {
      _selectedGrams -= 10.0;
      notifyListeners();
    }
  }

  Future<bool> logFood({required String mealType}) async {
    if (_selectedFood == null) return false;
    final uid = _authService.currentUserId;
    if (uid == null) return false;

    try {
      await _foodRepository.logFoodToMeal(
        uid: uid,
        mealType: mealType,
        food: _selectedFood!,
        grams: _selectedGrams,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}