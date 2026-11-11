import '../models/user_profile.dart';

enum BmiCategory {
  severeThinness,   // < 16.0
  moderateThinness, // 16.0 - 16.9
  mildThinness,     // 17.0 - 18.4
  normal,           // 18.5 - 24.9
  overweight,       // 25.0 - 29.9
  obeseClass1,      // 30.0 - 34.9
  obeseClass2,      // 35.0 - 39.9
  obeseClass3,      // >= 40.0
}

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

  Map<String, dynamic> toMap() {
    return {
      'targetCalories': targetCalories,
      'targetProteinGrams': targetProteinGrams,
      'targetCarbsGrams': targetCarbsGrams,
      'targetFatGrams': targetFatGrams,
    };
  }
}

class BmrCalculatorService {
  // 1. Chỉ số BMI chuẩn WHO
  double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  // 2. Phân loại 8 cấp bậc BMI y khoa
  BmiCategory getBmiCategory(double bmi) {
    if (bmi < 16.0) return BmiCategory.severeThinness;
    if (bmi < 17.0) return BmiCategory.moderateThinness;
    if (bmi < 18.5) return BmiCategory.mildThinness;
    if (bmi < 25.0) return BmiCategory.normal;
    if (bmi < 30.0) return BmiCategory.overweight;
    if (bmi < 35.0) return BmiCategory.obeseClass1;
    if (bmi < 40.0) return BmiCategory.obeseClass2;
    return BmiCategory.obeseClass3;
  }

  String getCategoryLabel(BmiCategory category) {
    switch (category) {
      case BmiCategory.severeThinness:
        return 'Severe Thinness';
      case BmiCategory.moderateThinness:
        return 'Moderate Thinness';
      case BmiCategory.mildThinness:
        return 'Mild Thinness';
      case BmiCategory.normal:
        return 'Normal Weight';
      case BmiCategory.overweight:
        return 'Overweight';
      case BmiCategory.obeseClass1:
        return 'Obese Class I';
      case BmiCategory.obeseClass2:
        return 'Obese Class II';
      case BmiCategory.obeseClass3:
        return 'Obese Class III';
    }
  }

  // 3. Khuyến nghị dinh dưỡng lâm sàng theo phân nhóm BMI
  String getGoalRecommendation(BmiCategory category) {
    switch (category) {
      case BmiCategory.severeThinness:
      case BmiCategory.moderateThinness:
        return 'Recommended: Muscle Gain. A caloric surplus is clinically advised to restore essential body mass.';
      case BmiCategory.mildThinness:
        return 'Recommended: Muscle Gain or Maintain Weight to build healthy lean tissue.';
      case BmiCategory.normal:
        return 'Healthy range! All 3 goals are medically safe based on your fitness targets.';
      case BmiCategory.overweight:
        return 'Recommended: Weight Loss (caloric deficit) or Maintain Weight (body recomposition).';
      case BmiCategory.obeseClass1:
      case BmiCategory.obeseClass2:
      case BmiCategory.obeseClass3:
        return 'Recommended: Weight Loss. A sustained caloric deficit will optimize cardiovascular and metabolic health.';
    }
  }

  // 4. Công thức Mifflin-St Jeor (1990)
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

  // 5. Tính TDEE theo hệ số vận động PAL
  double calculateTDEE(double bmr, ActivityLevel activityLevel) {
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return bmr * 1.200;
      case ActivityLevel.lightlyActive:
        return bmr * 1.375;
      case ActivityLevel.moderatelyActive:
        return bmr * 1.550;
      case ActivityLevel.veryActive:
        return bmr * 1.725;
    }
  }

  // 6. Phân bổ Calo & Macro có ngưỡng an toàn (Safety Floor)
  MacroTarget calculateTarget({
    required double bmr,
    required double tdee,
    required GoalType goal,
    required Gender gender,
    required double bmi,
  }) {
    double calories;
    double proteinRatio;
    double carbsRatio;
    double fatRatio;

    switch (goal) {
      case GoalType.weightLoss:
        calories = tdee - 500;
        final minSafeFloor = gender == Gender.male ? 1500.0 : 1200.0;
        if (calories < minSafeFloor) calories = minSafeFloor;
        if (calories < bmr) calories = bmr;

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
        if (bmi >= 25.0) {
          calories = tdee + 100;
          proteinRatio = 0.35;
          carbsRatio = 0.45;
          fatRatio = 0.20;
        } else {
          calories = tdee + 300;
          proteinRatio = 0.30;
          carbsRatio = 0.50;
          fatRatio = 0.20;
        }
        break;
    }

    final proteinGrams = (calories * proteinRatio) / 4;
    final carbsGrams = (calories * carbsRatio) / 4;
    final fatGrams = (calories * fatRatio) / 9;

    return MacroTarget(
      targetCalories: double.parse(calories.toStringAsFixed(0)),
      targetProteinGrams: double.parse(proteinGrams.toStringAsFixed(0)),
      targetCarbsGrams: double.parse(carbsGrams.toStringAsFixed(0)),
      targetFatGrams: double.parse(fatGrams.toStringAsFixed(0)),
    );
  }
}