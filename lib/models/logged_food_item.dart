class LoggedFoodItem {
  final String id;
  final String foodId;
  final String name;
  final double grams;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType;
  final DateTime loggedAt;

  const LoggedFoodItem({
    required this.id,
    required this.foodId,
    required this.name,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
    required this.loggedAt,
  });

  factory LoggedFoodItem.fromMap(String id, Map<String, dynamic> data) {
    return LoggedFoodItem(
      id: id,
      foodId: data['foodId'] ?? '',
      name: data['name'] ?? '',
      grams: (data['grams'] as num?)?.toDouble() ?? 0.0,
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      mealType: data['mealType'] ?? 'Breakfast',
      loggedAt: data['loggedAt'] != null
          ? (data['loggedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }
}