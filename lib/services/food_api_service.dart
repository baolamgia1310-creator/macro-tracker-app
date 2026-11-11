import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

typedef FoodList = List;

class FoodApiService {
  final http.Client _client;

  static const String _apiKey = String.fromEnvironment(
    'USDA_API_KEY',
    defaultValue: '',
  );

  FoodApiService({http.Client? client}) : _client = client ?? http.Client();

  Future searchExternalFoods(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || _apiKey.isEmpty) {
      return [];
    }

    final url = Uri.parse(
      'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=\({_apiKey.trim()}&query=\){Uri.encodeComponent(cleanQuery)}&pageSize=20',
    );

    try {
      final response = await _client.get(
        url,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return [];
      }

      final Map data = jsonDecode(response.body);
      final List foodsJson = data['foods'] as List? ?? [];
      final FoodList items = [];

      for (final item in foodsJson) {
        if (item is! Map) continue;

        final List nutrients = item['foodNutrients'] as List? ?? [];

        double calories = 0.0;
        double protein = 0.0;
        double carbs = 0.0;
        double fat = 0.0;

        for (final n in nutrients) {
          if (n is! Map) continue;

          final int id = (n['nutrientId'] as num?)?.toInt() ?? 0;
          final String number = n['nutrientNumber']?.toString() ?? '';
          final String name = (n['nutrientName'] ?? '').toString().toLowerCase();
          final double val = (n['value'] as num?)?.toDouble() ?? 0.0;

          if (id == 1008 || number == '208' || name.contains('energy')) {
            calories = (n['unitName']?.toString().toUpperCase() == 'KJ')
                ? val / 4.184
                : val;
          } else if (id == 1003 || number == '203' || name.contains('protein')) {
            protein = val;
          } else if (id == 1005 || number == '205' || name.contains('carbohydrate')) {
            carbs = val;
          } else if (id == 1004 || number == '204' || name.contains('total lipid') || name.contains('fat')) {
            fat = val;
          }
        }

        String rawName = (item['description'] ?? 'Unnamed Food').toString();
        if (rawName.length > 35) {
          rawName = '${rawName.substring(0, 32)}...';
        }

        if (calories > 0) {
          items.add(
            FoodItem(
              id: 'usda_${item['fdcId'] ?? DateTime.now().millisecondsSinceEpoch}',
              name: rawName,
              nameUnsigned: rawName.toLowerCase(),
              category: 'USDA API',
              servingType: 'g',
              unitName: '100 g',
              calories: double.parse(calories.toStringAsFixed(1)),
              protein: double.parse(protein.toStringAsFixed(1)),
              carbs: double.parse(carbs.toStringAsFixed(1)),
              fat: double.parse(fat.toStringAsFixed(1)),
            ),
          );
        }
      }

      return items;
    } catch (_) {
      return [];
    }
  }
}