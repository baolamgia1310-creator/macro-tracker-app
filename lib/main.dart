import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Bảng màu chuẩn & Controller quản lý trạng thái
import 'core/constants/app_colors.dart';
import 'controllers/theme_controller.dart';
import 'controllers/daily_log_controller.dart';

// Các màn hình trong luồng xác thực & điều hướng
import 'views/auth/auth_screen.dart';
import 'views/auth/set_password_screen.dart';
import 'views/calculator/bmr_tdee_calculator_screen.dart';
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

          // Tự động điều hướng theo phiên đăng nhập Firebase Auth & hồ sơ Firestore
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              // 1. Đang kiểm tra phiên lưu trữ cục bộ
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.lime,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }

              // 2. Bắt lỗi kết nối mạng từ Firebase Auth
              if (authSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Startup error occurred. Please try again!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }

              // 3. Đã đăng nhập -> Theo dõi hồ sơ trên Cloud Firestore
              if (authSnapshot.hasData && authSnapshot.data != null) {
                final user = authSnapshot.data!;

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, userDocSnapshot) {
                    if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.lime,
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    }

                    final userData = userDocSnapshot.data?.data() as Map<String, dynamic>?;
                    final hasPassword = userData?['hasPassword'] == true;
                    final isProfileCompleted = userData?['isProfileCompleted'] == true;

                    // Bước 3.1: Tài khoản Google chưa đặt mật khẩu
                    if (!hasPassword) {
                      return SetPasswordScreen(
                        onPasswordSetSuccess: () {
                          // Firestore cập nhật hasPassword = true sẽ tự kích hoạt Stream chuyển màn
                        },
                      );
                    }

                    // Bước 3.2: Tài khoản chưa hoàn tất khảo sát thông số BMR & TDEE
                    if (!isProfileCompleted) {
                      return BmrTdeeCalculatorScreen(
                        onSetupCompleted: () {
                          // Firestore cập nhật isProfileCompleted = true sẽ tự kích hoạt Stream vào Shell
                        },
                      );
                    }

                    // Bước 3.3: Đã đầy đủ thông tin -> Vào khung điều hướng 4 tab
                    return MainNavigationShell(
                      logController: _logController,
                      themeController: _themeController,
                    );
                  },
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