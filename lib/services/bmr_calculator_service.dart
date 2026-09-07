import '../models/user_profile.dart';

class MacroTarget {
  final double targetCalories;
  final double targetProteinGrams;
  final double targetCarbsGrams;
  final double targetFatGrams;

  const MacroTarget({
    required this.targetCalories,
    required this.targetProteinGrams,
    required this.targetCarbsGrams,
    required this.targetFatGrams,
  });
}

class BmrCalculatorService {
  // 1. Tính BMR theo công thức Mifflin-St Jeor
  double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    if (gender == Gender.male) {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  // 2. Tính TDEE dựa trên hệ số vận động
  double calculateTDEE(double bmr, ActivityLevel activityLevel) {
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return bmr * 1.2;
      case ActivityLevel.lightlyActive:
        return bmr * 1.375;
      case ActivityLevel.moderatelyActive:
        return bmr * 1.55;
      case ActivityLevel.veryActive:
        return bmr * 1.725;
    }
  }

  // 3. Tính lượng Calo và Macro mục tiêu theo Goal
  MacroTarget calculateTarget(double tdee, GoalType goal) {
    double calories;
    double proteinRatio;
    double carbsRatio;
    double fatRatio;

    switch (goal) {
      case GoalType.weightLoss:
        calories = tdee - 500; // Thâm hụt 500 kcal
        proteinRatio = 0.35;
        carbsRatio = 0.40;
        fatRatio = 0.25;
        break;
      case GoalType.maintenance:
        calories = tdee;
        proteinRatio = 0.30;
        carbsRatio = 0.45;
        fatRatio = 0.25;
        break;
      case GoalType.muscleGain:
        calories = tdee + 300; // Dư thừa 300 kcal
        proteinRatio = 0.30;
        carbsRatio = 0.50;
        fatRatio = 0.20;
        break;
    }

    // 1g Protein = 4 kcal, 1g Carbs = 4 kcal, 1g Fat = 9 kcal
    final proteinGrams = (calories * proteinRatio) / 4;
    final carbsGrams = (calories * carbsRatio) / 4;
    final fatGrams = (calories * fatRatio) / 9;

    return MacroTarget(
      targetCalories: calories,
      targetProteinGrams: proteinGrams,
      targetCarbsGrams: carbsGrams,
      targetFatGrams: fatGrams,
    );
  }
}