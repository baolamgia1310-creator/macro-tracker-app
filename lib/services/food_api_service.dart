import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

typedef FoodList = List<FoodItem>;

class FoodApiService {
  final http.Client _client;

  // 1. Ưu tiên đọc từ --dart-define-from-file=secrets.json
  static const String _envApiKey = String.fromEnvironment(
    'USDA_API_KEY',
    defaultValue: '',
  );

  static String? _cachedRuntimeKey;

  FoodApiService({http.Client? client}) : _client = client ?? http.Client();

  // Đảm bảo luôn lấy được API Key dù chạy bằng nút Run hay Terminal
  Future<String> _resolveApiKey() async {
    if (_envApiKey.trim().isNotEmpty) {
      return _envApiKey.trim();
    }
    if (_cachedRuntimeKey != null && _cachedRuntimeKey!.isNotEmpty) {
      return _cachedRuntimeKey!;
    }
    try {
      final secretStr = await rootBundle.loadString('secrets.json');
      final secretMap = jsonDecode(secretStr) as Map<String, dynamic>;
      final keyFromFile = secretMap['USDA_API_KEY']?.toString().trim() ?? '';
      if (keyFromFile.isNotEmpty) {
        _cachedRuntimeKey = keyFromFile;
        return keyFromFile;
      }
    } catch (_) {}

    // Fallback an toàn để API luôn được gọi kể cả khi quên truyền file
    return 'DEMO_KEY';
  }

  Future<FoodList> searchExternalFoods(
    String query, {
    int pageSize = 10,
    int pageNumber = 1,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return [];
    }

    final apiKey = await _resolveApiKey();

    final url = Uri.parse(
      'https://api.nal.usda.gov/fdc/v1/foods/search'
      '?api_key=$apiKey'
      '&query=${Uri.encodeComponent(cleanQuery)}'
      '&pageSize=$pageSize'
      '&pageNumber=$pageNumber',
    );

    try {
      final response = await _client.get(
        url,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint('[USDA API] HTTP ${response.statusCode}: ${response.body}');
        return [];
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> foodsJson = data['foods'] as List<dynamic>? ?? [];
      final FoodList items = [];

      for (final item in foodsJson) {
        if (item is! Map<String, dynamic>) continue;

        final List<dynamic> nutrients =
            item['foodNutrients'] as List<dynamic>? ?? [];

        double calories = 0.0;
        double protein = 0.0;
        double carbs = 0.0;
        double fat = 0.0;

        for (final n in nutrients) {
          if (n is! Map<String, dynamic>) continue;

          final int id = (n['nutrientId'] as num?)?.toInt() ?? 0;
          final String number = n['nutrientNumber']?.toString() ?? '';
          final String name =
              (n['nutrientName'] ?? '').toString().toLowerCase();
          final double val = (n['value'] as num?)?.toDouble() ?? 0.0;

          if (id == 1008 || number == '208' || name.contains('energy')) {
            calories = (n['unitName']?.toString().toUpperCase() == 'KJ')
                ? val / 4.184
                : val;
          } else if (id == 1003 ||
              number == '203' ||
              name.contains('protein')) {
            protein = val;
          } else if (id == 1005 ||
              number == '205' ||
              name.contains('carbohydrate')) {
            carbs = val;
          } else if (id == 1004 ||
              number == '204' ||
              name.contains('total lipid') ||
              name.contains('fat')) {
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
    } catch (e) {
      debugPrint('[USDA API] Error: $e');
      return [];
    }
  }
}