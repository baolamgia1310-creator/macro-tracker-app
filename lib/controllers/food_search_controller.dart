import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_item.dart';
import '../repositories/food_repository.dart';

typedef FoodList = List<FoodItem>;

class FoodSearchController extends ChangeNotifier {
  final FoodRepository _foodRepository;

  static const int _pageSize = 15;
  static const int _maxApiCacheItems = 50; // Chốt chặn phình RAM cho API

  final List<String> categories = const [
    'All',
    'Món ăn',
    'Nguyên liệu',
    'USDA API',
    'My Foods'
  ];

  FoodSearchController({FoodRepository? foodRepository})
      : _foodRepository = foodRepository ?? FoodRepository() {
    _initWithWarmCacheOrFetch();
  }

  Timer? _debounceTimer;
  Timer? _feedbackTimer;
  int _latestSearchTimestamp = 0;

  FoodList _catalogFoods = [];
  FoodList _apiFoods = [];
  FoodList _customFoods = [];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  double _selectedAmount = 100.0;
  FoodItem? _selectedFood;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _visibleCount = _pageSize;
  int _apiPage = 1;

  // Trạng thái phục vụ thêm nhiều món liên tiếp trong 1 bữa
  int _addedCountInSession = 0;
  bool _justAddedFeedback = false;

  FoodList get _allMatchedFoods {
    final query = _searchQuery.trim().toLowerCase();
    final cleanUnsigned = FoodRepository.removeAccents(query);

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
      if (query.isEmpty) return _customFoods;
      return _customFoods.where((f) {
        return f.name.toLowerCase().contains(query) ||
            f.nameUnsigned.contains(cleanUnsigned);
      }).toList();
    }

    final matchedCustom = query.isEmpty
        ? _customFoods
        : _customFoods.where((f) {
            return f.name.toLowerCase().contains(query) ||
                f.nameUnsigned.contains(cleanUnsigned);
          }).toList();

    return [...matchedCustom, ..._catalogFoods, ..._apiFoods];
  }

  FoodList get filteredFoods {
    final all = _allMatchedFoods;
    if (all.length <= _visibleCount) {
      return all;
    }
    return all.take(_visibleCount).toList();
  }

  bool get hasMore => _visibleCount < _allMatchedFoods.length;
  bool get isLoadingMore => _isLoadingMore;
  String get selectedCategory => _selectedCategory;
  FoodItem? get selectedFood => _selectedFood;
  bool get isLoading => _isLoading;
  double get selectedAmount => _selectedAmount;
  double get selectedGrams => _selectedAmount;

  int get addedCountInSession => _addedCountInSession;
  bool get justAddedFeedback => _justAddedFeedback;

  String get amountLabel {
    if (_selectedFood?.servingType == 'serving') {
      return _selectedAmount == _selectedAmount.roundToDouble()
          ? '${_selectedAmount.toInt()}'
          : _selectedAmount.toStringAsFixed(1);
    }
    return '${_selectedAmount.toInt()}';
  }

  String get unitLabel => _selectedFood?.servingType == 'serving'
      ? (_selectedFood?.unitName ?? 'serving')
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
    _feedbackTimer?.cancel();
    super.dispose();
  }

  // Nếu RAM Cache đã có sẵn -> Hiển thị tức thì 0ms không cần xoay loading
  void _initWithWarmCacheOrFetch() {
    if (_foodRepository.hasWarmCache) {
      _catalogFoods = _foodRepository.cachedCatalog;
      _customFoods = _foodRepository.cachedCustomFoods;
      _apiFoods = _foodRepository.cachedDefaultApiFoods;
      _isLoading = false;

      if (filteredFoods.isNotEmpty && _selectedFood == null) {
        _selectedFood = filteredFoods.first;
        _selectedAmount =
            _selectedFood!.servingType == 'serving' ? 1.0 : 100.0;
      }

      // Đồng bộ ngầm custom foods nếu chưa tải cho user hiện tại
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty && _customFoods.isEmpty) {
        _foodRepository.getUserCustomFoods(uid).then((list) {
          _customFoods = list;
          notifyListeners();
        });
      }
      return;
    }

    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _visibleCount = _pageSize;
    _apiPage = 1;
    notifyListeners();

    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        _customFoods = await _foodRepository.getUserCustomFoods(uid);
      } catch (_) {}
    }

    final results = await Future.wait([
      _foodRepository.searchLocalCatalog(''),
      _foodRepository.searchRemoteApi(
        'chicken',
        pageSize: 10,
        pageNumber: 1,
      ),
    ]);

    _catalogFoods = results[0];
    _apiFoods = results[1];

    if (filteredFoods.isNotEmpty && _selectedFood == null) {
      selectFood(filteredFoods.first);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore) return;

    final totalAvailable = _allMatchedFoods.length;

    if (_visibleCount < totalAvailable) {
      _visibleCount += _pageSize;
      notifyListeners();
      return;
    }

    // Chặn gọi thêm API nếu đã chạm trần 50 món trên RAM
    if (_apiFoods.length >= _maxApiCacheItems) return;

    if (_selectedCategory == 'USDA API' || _selectedCategory == 'All') {
      _isLoadingMore = true;
      notifyListeners();

      try {
        _apiPage += 1;
        final queryToFetch = _searchQuery.trim().isEmpty
            ? 'chicken'
            : _mapVietnameseToEnglish(_searchQuery.trim());

        final nextApiBatch = await _foodRepository.searchRemoteApi(
          queryToFetch,
          pageSize: 10,
          pageNumber: _apiPage,
        );

        if (nextApiBatch.isNotEmpty) {
          final combined = [..._apiFoods, ...nextApiBatch];
          _apiFoods = combined.take(_maxApiCacheItems).toList();
          _visibleCount += _pageSize;
        }
      } finally {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _visibleCount = _pageSize;
    _apiPage = 1;

    // Lọc tức thì trên RAM (0ms) đối với kho món ăn trong nước & My Foods
    if (_foodRepository.hasWarmCache) {
      _catalogFoods = _foodRepository.filterCachedCatalogSync(query);
      if (filteredFoods.isNotEmpty) {
        selectFood(filteredFoods.first);
      }
    }
    notifyListeners();

    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _apiFoods = _foodRepository.cachedDefaultApiFoods;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Chỉ gọi mạng ngầm cho phần USDA API sau khi ngừng gõ 350ms
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final requestTime = DateTime.now().millisecondsSinceEpoch;
      _latestSearchTimestamp = requestTime;

      final showSpinner = _allMatchedFoods.isEmpty;
      if (showSpinner) {
        _isLoading = true;
        notifyListeners();
      }

      try {
        final apiQuery = _mapVietnameseToEnglish(trimmed);
        final remoteResults = await _foodRepository.searchRemoteApi(
          apiQuery,
          pageSize: 10,
          pageNumber: 1,
        );

        if (_latestSearchTimestamp == requestTime) {
          _apiFoods = remoteResults.take(_maxApiCacheItems).toList();
          if (_selectedFood == null && filteredFoods.isNotEmpty) {
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

  Future<bool> addCustomFood({
    required String name,
    required String servingType,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;

    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;

    final newFood = FoodItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      nameUnsigned: FoodRepository.removeAccents(cleanName.toLowerCase()),
      category: 'My Foods',
      servingType: servingType,
      unitName: servingType == 'serving' ? 'serving' : '100g',
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );

    try {
      await _foodRepository.createCustomFood(uid: uid, food: newFood);
      _customFoods = _foodRepository.cachedCustomFoods;
      _selectedCategory = 'My Foods';
      selectFood(newFood);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> removeCustomFood(String foodId) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      await _foodRepository.deleteCustomFood(uid: uid, foodId: foodId);
      _customFoods = _foodRepository.cachedCustomFoods;
      if (_selectedFood?.id == foodId) {
        _selectedFood = filteredFoods.isNotEmpty ? filteredFoods.first : null;
      }
      notifyListeners();
    } catch (_) {}
  }

  String _mapVietnameseToEnglish(String input) {
    final lower = input.toLowerCase().trim();
    const dict = {
      'trung': 'egg',
      'trứng': 'egg',
      'ga': 'chicken',
      'gà': 'chicken',
      'thit ga': 'chicken',
      'thịt gà': 'chicken',
      'uc ga': 'chicken breast',
      'ức gà': 'chicken breast',
      'bo': 'beef',
      'bò': 'beef',
      'thit bo': 'beef',
      'thịt bò': 'beef',
      'heo': 'pork',
      'lon': 'pork',
      'lợn': 'pork',
      'thit heo': 'pork',
      'thịt lợn': 'pork',
      'com': 'rice',
      'cơm': 'rice',
      'gao': 'rice',
      'gạo': 'rice',
      'ca': 'fish',
      'cá': 'fish',
      'ca hoi': 'salmon',
      'cá hồi': 'salmon',
      'sua': 'milk',
      'sữa': 'milk',
      'chuoi': 'banana',
      'chuối': 'banana',
      'tao': 'apple',
      'táo': 'apple',
      'banh mi': 'bread',
      'bánh mì': 'bread',
      'yen mach': 'oats',
      'yến mạch': 'oats',
      'khoai lang': 'sweet potato',
      'bo dau phong': 'peanut butter',
    };
    return dict[lower] ?? input;
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    _visibleCount = _pageSize;
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

  // Ghi nhận món ăn tức thì và bật hiệu ứng "Added ✓" trong 900ms
  Future<bool> logFood({required String mealType}) async {
    if (_selectedFood == null) return false;
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;

    try {
      _foodRepository.logFoodToMeal(
        uid: uid,
        mealType: mealType,
        food: _selectedFood!,
        amount: _selectedAmount,
      );

      _addedCountInSession += 1;
      _justAddedFeedback = true;
      notifyListeners();

      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(const Duration(milliseconds: 900), () {
        _justAddedFeedback = false;
        notifyListeners();
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}