enum Gender { male, female }
enum ActivityLevel { sedentary, lightlyActive, moderatelyActive, veryActive, extremelyActive }
enum GoalType { weightLoss, maintenance, muscleGain }

class UserMacroProfile {
  final int age;
  final double weightKg;
  final double heightCm;
  final Gender gender;
  final ActivityLevel activityLevel;
  final GoalType goal;
  final double bmr;
  final double tdee;
  final int targetCalories;
  final int targetProteinGrams;
  final int targetCarbsGrams;
  final int targetFatGrams;

  const UserMacroProfile({
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.targetProteinGrams,
    required this.targetCarbsGrams,
    required this.targetFatGrams,
  });

  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'gender': gender.name,
      'activityLevel': activityLevel.name,
      'goal': goal.name,
      'bmr': bmr,
      'tdee': tdee,
      'targetCalories': targetCalories,
      'targetProteinGrams': targetProteinGrams,
      'targetCarbsGrams': targetCarbsGrams,
      'targetFatGrams': targetFatGrams,
      'isProfileCompleted': true,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}