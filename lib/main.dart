import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Để dùng FirebaseAuth và User
import 'firebase_options.dart';

// Bảng màu chuẩn & Controller quản lý trạng thái
import 'core/constants/app_colors.dart';
import 'controllers/theme_controller.dart';
import 'controllers/daily_log_controller.dart';

// Màn hình xác thực & Khung điều hướng 4 tab chính
import 'views/auth/auth_screen.dart';
import 'views/main_navigation_shell.dart';

// Mở chú thích nếu cần nạp dữ liệu mẫu lên Cloud Firestore
// import 'seed_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase với cấu hình môi trường
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Kích hoạt bộ nhớ đệm Offline Cache không giới hạn cho Cloud Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Mở dòng này khi cần nạp dữ liệu demo ban đầu
  // await FirebaseSeeder.seedAll();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Khởi tạo các Controller dùng chung cho toàn bộ app
  final ThemeController _themeController = ThemeController();
  final DailyLogController _logController = DailyLogController();

  @override
  void dispose() {
    _themeController.dispose();
    _logController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi Theme bằng ListenableBuilder thuần (không cần package bên thứ ba)
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Macro Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: _themeController.themeMode,

          // Cấu hình Theme Sáng (Light Theme)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.lightBg,
            colorScheme: const ColorScheme.light(
              primary: AppColors.lime,
              surface: AppColors.lightCard,
              onSurface: AppColors.lightText,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              iconTheme: IconThemeData(color: AppColors.lightText),
            ),
          ),

          // Cấu hình Theme Tối (Dark Theme)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.darkBg,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.lime,
              surface: AppColors.darkCard,
              onSurface: AppColors.darkText,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              iconTheme: IconThemeData(color: AppColors.darkText),
            ),
          ),

          // Tự động điều hướng theo phiên đăng nhập Firebase Auth
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // 1. Khi đang kiểm tra phiên lưu trữ trên máy
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.lime,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }

              // 2. Bắt lỗi kết nối nếu Firebase Auth gặp sự cố
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Đã xảy ra lỗi khởi động. Vui lòng thử lại!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }

              // 3. Đã có phiên đăng nhập -> Vào thẳng Navigation chính 4 tab
              if (snapshot.hasData && snapshot.data != null) {
                return MainNavigationShell(
                  logController: _logController,
                  themeController: _themeController,
                );
              }

              // 4. Chưa đăng nhập -> Hiển thị AuthScreen
              return AuthScreen(
                onLoginSuccess: () {},
                onNavigateToRegister: () {},
              );
            },
          ),
        );
      },
    );
  }
}