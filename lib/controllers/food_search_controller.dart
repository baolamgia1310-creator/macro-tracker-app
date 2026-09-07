import 'package:flutter/material.dart';
import '../models/food_item.dart';

class FoodSearchController extends ChangeNotifier {
  final List<String> categories = const ['All', 'My Foods', 'Meals', 'Recipes'];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  double _selectedGrams = 150.0;
  FoodItem? _selectedFood;

  // Dữ liệu mẫu chuẩn hóa theo ảnh thiết kế[cite: 1, 3]
  final List<FoodItem> _allFoods = [
    const FoodItem(
      id: 'chicken_breast',
      name: 'Grilled Chicken Breast',
      caloriesPer100g: 165.0,
      proteinPer100g: 31.0,
      carbsPer100g: 0.0,
      fatPer100g: 3.6,
    ),
    const FoodItem(
      id: 'brown_rice',
      name: 'Brown Rice (Cooked)',
      caloriesPer100g: 110.0,
      proteinPer100g: 2.6,
      carbsPer100g: 23.0,
      fatPer100g: 0.9,
    ),
    const FoodItem(
      id: 'steamed_broccoli',
      name: 'Broccoli (Steamed)',
      caloriesPer100g: 55.0,
      proteinPer100g: 3.7,
      carbsPer100g: 11.0,
      fatPer100g: 0.6,
    ),
    const FoodItem(
      id: 'avocado',
      name: 'Avocado',
      caloriesPer100g: 160.0,
      proteinPer100g: 2.0,
      carbsPer100g: 8.5,
      fatPer100g: 14.7,
    ),
  ];

  FoodSearchController() {
    _selectedFood = _allFoods.first; // Mặc định chọn món đầu tiên theo ảnh mẫu
  }

  // Getters
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  double get selectedGrams => _selectedGrams;
  FoodItem? get selectedFood => _selectedFood;

  List<FoodItem> get filteredFoods {
    if (_searchQuery.trim().isEmpty) return _allFoods;
    return _allFoods
        .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase().trim()))
        .toList();
  }

  // Setters & Actions
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectFood(FoodItem food) {
    _selectedFood = food;
    notifyListeners();
  }

  void incrementGrams([double step = 10.0]) {
    _selectedGrams += step;
    notifyListeners();
  }

  void decrementGrams([double step = 10.0]) {
    if (_selectedGrams > step) {
      _selectedGrams -= step;
      notifyListeners();
    }
  }
}