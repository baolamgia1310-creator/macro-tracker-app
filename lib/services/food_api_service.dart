import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class FoodApiService {
  final http.Client _client;

  // Lấy key từ cờ build-time --dart-define-from-file
  static const String _apiKey = String.fromEnvironment(
    'USDA_API_KEY',
    defaultValue: '',
  );

  FoodApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<FoodItem>> searchExternalFoods(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Kiểm tra an toàn: nếu chưa truyền key khi build thì cảnh báo và dừng gọi
    if (_apiKey.isEmpty) {
      debugPrint(
        '[USDA API Warning] USDA_API_KEY chưa được truyền. '
        'Hãy chạy app với cờ: --dart-define-from-file=secrets.json',
      );
      return [];
    }

    final url = Uri.parse(
      'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=${_apiKey.trim()}&query=${Uri.encodeComponent(cleanQuery)}&pageSize=20',
    );

    try {
      final response = await _client.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint('[USDA API] HTTP ${response.statusCode}: ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final foodsJson = data['foods'] as List<dynamic>? ?? [];

      return foodsJson.map<FoodItem>((item) {
        final nutrients = item['foodNutrients'] as List<dynamic>? ?? [];

        double calories = 0.0;
        double protein = 0.0;
        double carbs = 0.0;
        double fat = 0.0;

        for (final nutrient in nutrients) {
          final id = nutrient['nutrientId'] as int? ?? 0;
          final number = nutrient['nutrientNumber']?.toString() ?? '';
          final name = (nutrient['nutrientName'] ?? '').toString().toLowerCase();
          final value = (nutrient['value'] as num?)?.toDouble() ?? 0.0;

          if (id == 1008 || number == '208' || name.contains('energy')) {
            if (nutrient['unitName']?.toString().toUpperCase() == 'KJ') {
              calories = value / 4.184;
            } else {
              calories = value;
            }
          } else if (id == 1003 || number == '203' || name.contains('protein')) {
            protein = value;
          } else if (id == 1005 || number == '205' || name.contains('carbohydrate')) {
            carbs = value;
          } else if (id == 1004 || number == '204' || name.contains('total lipid') || name.contains('fat')) {
            fat = value;
          }
        }

        String rawName = (item['description'] ?? 'Unnamed Food').toString();
        if (rawName.length > 35) {
          rawName = '${rawName.substring(0, 32)}...';
        }

        return FoodItem(
          id: 'usda_${item['fdcId'] ?? DateTime.now().millisecondsSinceEpoch}',
          name: rawName,
          category: 'USDA Database',
          caloriesPer100g: double.parse(calories.toStringAsFixed(1)),
          proteinPer100g: double.parse(protein.toStringAsFixed(1)),
          carbsPer100g: double.parse(carbs.toStringAsFixed(1)),
          fatPer100g: double.parse(fat.toStringAsFixed(1)),
        );
      }).where((f) => f.caloriesPer100g > 0).toList();
    } catch (e) {
      debugPrint('[USDA API] Exception: $e');
      return [];
    }
  }
}