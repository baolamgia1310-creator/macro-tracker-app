import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  // Mặc định khởi tạo theo hệ thống máy (nếu máy không bật Dark mode thì hiển thị Light mode trắng)
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Kiểm tra trạng thái tối thực tế tại thời điểm hiển thị
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Tên hiển thị tương ứng với từng chế độ
  String get themeModeTitle {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }

  // Cập nhật chế độ cụ thể (System / Light / Dark)
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  // Hỗ trợ cả 2 cách gọi: truyền giá trị cụ thể hoặc đảo trạng thái tự động
  void toggleTheme([bool? isDark]) {
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }
}