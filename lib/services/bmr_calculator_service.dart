import '../models/user_profile.dart';

typedef JsonMap = Map<String, dynamic>;

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
  final int proteinPercent;
  final int carbsPercent;
  final int fatPercent;

  const MacroTarget({
    required this.targetCalories,
    required this.targetProteinGrams,
    required this.targetCarbsGrams,
    required this.targetFatGrams,
    this.proteinPercent = 30,
    this.carbsPercent = 45,
    this.fatPercent = 25,
  });

  JsonMap toMap() {
    return {
      'targetCalories': targetCalories,
      'targetProteinGrams': targetProteinGrams,
      'targetCarbsGrams': targetCarbsGrams,
      'targetFatGrams': targetFatGrams,
      'proteinPercent': proteinPercent,
      'carbsPercent': carbsPercent,
      'fatPercent': fatPercent,
    };
  }
}

class BmrCalculatorService {
  // 1. Chỉ số BMI chuẩn WHO: kg / (m^2)
  double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  // 2. Phân loại 8 cấp bậc BMI chuẩn WHO
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

  // 3. Khuyến nghị mục tiêu theo phân nhóm BMI
  String getGoalRecommendation(BmiCategory category) {
    switch (category) {
      case BmiCategory.severeThinness:
      case BmiCategory.moderateThinness:
        return 'Recommended: Muscle Gain. A controlled caloric surplus is advised to restore healthy body mass.';
      case BmiCategory.mildThinness:
        return 'Recommended: Muscle Gain or Maintain Weight to build lean tissue steadily.';
      case BmiCategory.normal:
        return 'Healthy range! Choose Weight Loss to get leaner, Maintain for body recomposition, or Muscle Gain to bulk.';
      case BmiCategory.overweight:
        return 'Recommended: Weight Loss (15-20% deficit) or Maintain Weight (body recomposition).';
      case BmiCategory.obeseClass1:
      case BmiCategory.obeseClass2:
      case BmiCategory.obeseClass3:
        return 'Recommended: Weight Loss. A sustainable 20% caloric deficit will optimize fat loss and metabolic health.';
    }
  }

  // 4. Công thức Mifflin-St Jeor (Tiêu chuẩn ADA)
  double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return gender == Gender.male ? base + 5 : base - 161;
  }

  // 5. Tính TDEE theo hệ số vận động thực tế
  double calculateTDEE(double bmr, ActivityLevel activityLevel) {
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return bmr * 1.20;
      case ActivityLevel.lightlyActive:
        return bmr * 1.35;
      case ActivityLevel.moderatelyActive:
        return bmr * 1.50;
      case ActivityLevel.veryActive:
        return bmr * 1.70;
    }
  }

  // 6. Trọng lượng hiệu chỉnh (Adjusted Body Weight) cho người có BMI >= 25
  double _resolveEffectiveWeight({
    required double weightKg,
    required double heightCm,
    required double bmi,
  }) {
    if (bmi < 25.0 || heightCm <= 0) return weightKg;
    final heightM = heightCm / 100.0;
    final idealWeight = 22.0 * (heightM * heightM);
    // Công thức lâm sàng: IBW + 25% khối lượng vượt chuẩn
    return idealWeight + 0.25 * (weightKg - idealWeight);
  }

  // 7. Phân bổ Calo (% TDEE) & Macro (g/kg) thích ứng cho mọi đối tượng
  MacroTarget calculateTarget({
    required double bmr,
    required double tdee,
    required GoalType goal,
    required Gender gender,
    required double bmi,
    double weightKg = 68.0,
    double heightCm = 170.0,
    ActivityLevel activityLevel = ActivityLevel.moderatelyActive,
  }) {
    final bool isActiveUser =
        activityLevel == ActivityLevel.moderatelyActive ||
        activityLevel == ActivityLevel.veryActive;

    double targetCalories = tdee;

    switch (goal) {
      case GoalType.weightLoss:
        // Giảm 20% TDEE (giới hạn mức cắt tối đa 650 kcal để tránh suy nhược)
        final deficit = (tdee * 0.20).clamp(250.0, 650.0);
        targetCalories = tdee - deficit;

        // Ngưỡng sàn y khoa an toàn tuyệt đối (1500 kcal Nam / 1200 kcal Nữ)
        final minSafeFloor = gender == Gender.male ? 1500.0 : 1200.0;
        if (targetCalories < minSafeFloor) {
          targetCalories = minSafeFloor;
        }
        break;

      case GoalType.maintenance:
        // Giữ cân hoặc Tái cấu trúc cơ thể (Body Recomposition)
        targetCalories = tdee;
        break;

      case GoalType.muscleGain:
        if (bmi < 18.5) {
          // Người thiếu cân: Thặng dư 15% TDEE để phục hồi thể trạng
          final surplus = (tdee * 0.15).clamp(250.0, 450.0);
          targetCalories = tdee + surplus;
        } else if (bmi < 25.0) {
          // Người bình thường: Lean Bulk (+10% TDEE, hạn chế tích mỡ)
          final surplus = (tdee * 0.10).clamp(180.0, 320.0);
          targetCalories = tdee + surplus;
        } else {
          // Người có BMI >= 25 chọn Muscle Gain: Thặng dư tối thiểu (+100 kcal)
          targetCalories = tdee + 100.0;
        }
        break;
    }

    final double cleanCalories = targetCalories.roundToDouble();
    final double effectiveWeight = _resolveEffectiveWeight(
      weightKg: weightKg,
      heightCm: heightCm,
      bmi: bmi,
    );

    // Xác định hệ số Protein (g/kg) theo mức độ vận động và mục tiêu
    double proteinPerKg;
    switch (goal) {
      case GoalType.weightLoss:
        // Khi thâm hụt calo, cần đạm cao hơn để giữ cơ bắp và no lâu
        proteinPerKg = isActiveUser ? 2.0 : 1.5;
        break;
      case GoalType.maintenance:
        // Nếu có tập luyện thì ưu tiên mức đạm 1.8g/kg để Recomp (tăng cơ giảm mỡ)
        proteinPerKg = isActiveUser ? 1.8 : 1.3;
        break;
      case GoalType.muscleGain:
        proteinPerKg = isActiveUser ? 1.8 : 1.5;
        break;
    }

    double proteinGrams = effectiveWeight * proteinPerKg;
    // Đảm bảo lượng calo từ Protein luôn nằm trong vùng an toàn (15% - 38% tổng Calo)
    final minProteinGrams = (cleanCalories * 0.15) / 4.0;
    final maxProteinGrams = (cleanCalories * 0.38) / 4.0;
    proteinGrams = proteinGrams.clamp(minProteinGrams, maxProteinGrams);

    // Chất béo (Fat): 25% - 28% tổng Calo để bảo vệ nội tiết tố (tối thiểu 0.7g/kg)
    final double fatRatio = goal == GoalType.muscleGain ? 0.25 : 0.27;
    double fatGrams = (cleanCalories * fatRatio) / 9.0;
    final minFatGrams = effectiveWeight * 0.7;
    if (fatGrams < minFatGrams) {
      fatGrams = minFatGrams;
    }

    // Tinh bột (Carbs): Toàn bộ năng lượng còn lại chia cho 4
    final double usedCalories = (proteinGrams * 4.0) + (fatGrams * 9.0);
    final double remainingForCarbs =
        (cleanCalories - usedCalories).clamp(cleanCalories * 0.20, cleanCalories);
    final double carbsGrams = remainingForCarbs / 4.0;

    // Quy đổi ngược ra tỷ lệ % chính xác để đồng bộ với trang ProfileScreen
    final int pPct = (((proteinGrams * 4.0) / cleanCalories) * 100).round();
    final int fPct = (((fatGrams * 9.0) / cleanCalories) * 100).round();
    final int cPct = (100 - pPct - fPct).clamp(10, 75);

    return MacroTarget(
      targetCalories: cleanCalories,
      targetProteinGrams: proteinGrams.roundToDouble(),
      targetCarbsGrams: carbsGrams.roundToDouble(),
      targetFatGrams: fatGrams.roundToDouble(),
      proteinPercent: pPct,
      carbsPercent: cPct,
      fatPercent: fPct,
    );
  }
}