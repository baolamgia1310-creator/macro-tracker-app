class FoodItem {
  final String id;
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const FoodItem({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  // OOP Method: Tính dinh dưỡng theo số gram thực tế
  double calculateCalories(double grams) => (caloriesPer100g * grams) / 100;
  double calculateProtein(double grams) => (proteinPer100g * grams) / 100;
  double calculateCarbs(double grams) => (carbsPer100g * grams) / 100;
  double calculateFat(double grams) => (fatPer100g * grams) / 100;

  String get macroSummary => 
      'P ${proteinPer100g}g • C ${carbsPer100g}g • F ${fatPer100g}g (per 100g)';
}

class MealLogEntry {
  final FoodItem food;
  final double amountGrams;
  final String mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snacks'

  const MealLogEntry({
    required this.food,
    required this.amountGrams,
    required this.mealType,
  });

  double get totalCalories => food.calculateCalories(amountGrams);
  double get totalProtein => food.calculateProtein(amountGrams);
  double get totalCarbs => food.calculateCarbs(amountGrams);
  double get totalFat => food.calculateFat(amountGrams);
}