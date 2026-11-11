class FoodItem {
  final String id;
  final String name;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const FoodItem({
    required this.id,
    required this.name,
    this.category = 'All',
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  factory FoodItem.fromMap(String id, Map<String, dynamic> data) {
    return FoodItem(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'All',
      caloriesPer100g: (data['caloriesPer100g'] as num?)?.toDouble() ?? 0.0,
      proteinPer100g: (data['proteinPer100g'] as num?)?.toDouble() ?? 0.0,
      carbsPer100g: (data['carbsPer100g'] as num?)?.toDouble() ?? 0.0,
      fatPer100g: (data['fatPer100g'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'caloriesPer100g': caloriesPer100g,
      'proteinPer100g': proteinPer100g,
      'carbsPer100g': carbsPer100g,
      'fatPer100g': fatPer100g,
    };
  }
}