enum GoalType { weightLoss, maintenance, muscleGain }
enum ActivityLevel { sedentary, lightlyActive, moderatelyActive, veryActive }
enum Gender { male, female }

class UserProfile {
  final String name;
  final String email;
  final int age;
  final double weightKg;
  final double heightCm;
  final Gender gender;
  final ActivityLevel activityLevel;
  final GoalType goal;

  UserProfile({
    required this.name,
    required this.email,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    this.gender = Gender.male,
    this.activityLevel = ActivityLevel.moderatelyActive,
    this.goal = GoalType.weightLoss,
  });
}