class FoodItem {
  final String id;
  final String name;
  final String nameUnsigned;
  final String category;
  final String servingType; // 'serving' hoặc 'g'
  final String unitName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodItem({
    required this.id,
    required this.name,
    this.nameUnsigned = '',
    this.category = 'Chung',
    this.servingType = 'g',
    this.unitName = '100 g',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  // Getter hỗ trợ tương thích ngược
  double get caloriesPer100g => calories;
  double get proteinPer100g => protein;
  double get carbsPer100g => carbs;
  double get fatPer100g => fat;

  factory FoodItem.fromMap(String id, Map? data) {
    final map = data ?? {};
    final sType = (map['serving_type'] ?? map['servingType'] ?? 'g').toString();
    final uName = (map['unit_name'] ?? map['unitName'] ?? (sType == 'serving' ? 'suất' : '100 g')).toString();
    final rawCal = map['calories'] ?? map['caloriesPer100g'] ?? 0.0;
    final rawPro = map['protein'] ?? map['proteinPer100g'] ?? 0.0;
    final rawCarb = map['carbs'] ?? map['carbsPer100g'] ?? 0.0;
    final rawFat = map['fat'] ?? map['fatPer100g'] ?? 0.0;

    return FoodItem(
      id: id,
      name: (map['name'] ?? '').toString(),
      nameUnsigned: (map['name_unsigned'] ?? map['nameUnsigned'] ?? '').toString(),
      category: (map['category'] ?? 'Chung').toString(),
      servingType: sType,
      unitName: uName,
      calories: _toDouble(rawCal),
      protein: _toDouble(rawPro),
      carbs: _toDouble(rawCarb),
      fat: _toDouble(rawFat),
    );
  }

  Map toMap() {
    return {
      'id': id,
      'name': name,
      'name_unsigned': nameUnsigned,
      'category': category,
      'serving_type': servingType,
      'unit_name': unitName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}