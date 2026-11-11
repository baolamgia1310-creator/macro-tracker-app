import 'package:cloud_firestore/cloud_firestore.dart';

typedef JsonMap = Map<String, dynamic>;

class LoggedFoodItem {
  final String id;
  final String foodId;
  final String name;
  final String mealType;
  final String servingType; // 'serving' or 'g'
  final String unitName;
  final double amount;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime loggedAt;

  const LoggedFoodItem({
    required this.id,
    required this.foodId,
    required this.name,
    required this.mealType,
    required this.servingType,
    required this.unitName,
    required this.amount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
  });

  // Tương thích ngược với code cũ
  double get grams => amount;

  String get formattedAmount {
    if (servingType == 'serving') {
      final cleanNum = amount == amount.roundToDouble()
          ? '${amount.toInt()}'
          : amount.toStringAsFixed(1);
      return '$cleanNum ${amount > 1 ? 'servings' : 'serving'}';
    }
    return '${amount.round()}g';
  }

  factory LoggedFoodItem.fromMap(String id, JsonMap? data) {
    final map = data ?? {};
    final sType = (map['servingType'] ?? map['serving_type'] ?? 'g').toString();
    final rawAmount = map['amount'] ?? map['grams'] ?? 100.0;

    DateTime parsedDate = DateTime.now();
    final rawTime = map['loggedAt'];
    if (rawTime is Timestamp) {
      parsedDate = rawTime.toDate();
    } else if (rawTime is String) {
      parsedDate = DateTime.tryParse(rawTime) ?? DateTime.now();
    }

    return LoggedFoodItem(
      id: id,
      foodId: (map['foodId'] ?? '').toString(),
      name: (map['name'] ?? 'Food Item').toString(),
      mealType: (map['mealType'] ?? 'Breakfast').toString(),
      servingType: sType,
      unitName: (map['unitName'] ?? (sType == 'serving' ? 'serving' : 'g')).toString(),
      amount: _toDouble(rawAmount),
      calories: _toDouble(map['calories']).round(),
      protein: _toDouble(map['protein']),
      carbs: _toDouble(map['carbs']),
      fat: _toDouble(map['fat']),
      loggedAt: parsedDate,
    );
  }

  JsonMap toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'mealType': mealType,
      'servingType': servingType,
      'unitName': unitName,
      'amount': amount,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'loggedAt': Timestamp.fromDate(loggedAt),
    };
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}