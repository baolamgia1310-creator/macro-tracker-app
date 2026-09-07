import 'package:flutter/material.dart';

class ProfileController extends ChangeNotifier {
  // Thông tin người dùng theo bản vẽ
  String _displayName = 'Alex Johnson';
  String _email = 'alex@email.com';
  
  // Chỉ số calo cá nhân
  final int _bmr = 1750;
  final int _tdee = 2200;

  // Tỷ lệ Macro mục tiêu (%)
  int _proteinPercent = 30;
  int _carbsPercent = 45;
  int _fatPercent = 25;

  // Tùy chọn cài đặt
  String _unitSystem = 'Metric (kg, cm)';
  bool _notificationsEnabled = true;
  final String _appVersion = 'v1.0.0';

  // Getters
  String get displayName => _displayName;
  String get email => _email;
  int get bmr => _bmr;
  int get tdee => _tdee;
  int get proteinPercent => _proteinPercent;
  int get carbsPercent => _carbsPercent;
  int get fatPercent => _fatPercent;
  String get unitSystem => _unitSystem;
  bool get notificationsEnabled => _notificationsEnabled;
  String get appVersion => _appVersion;

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void updateMacroTargets({required int protein, required int carbs, required int fat}) {
    _proteinPercent = protein;
    _carbsPercent = carbs;
    _fatPercent = fat;
    notifyListeners();
  }

  Future<void> logOut() async {
    // Logic gọi AuthService.signOut() khi liên kết Firebase
    notifyListeners();
  }
}