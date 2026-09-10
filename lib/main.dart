import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Services (Hạ tầng thiết bị & Dịch vụ bảo mật)
import 'services/display_service.dart';
import 'services/auth_service.dart';

// Core Tokens & Enums
import 'core/constants/app_colors.dart';
import 'core/enums/auth_status.dart';

// Controllers (State Management)
import 'controllers/theme_controller.dart';
import 'controllers/daily_log_controller.dart';
import 'controllers/auth_controller.dart';

// Presentation Views
import 'views/auth/auth_screen.dart';
import 'views/auth/sign_up_screen.dart';
import 'views/auth/set_password_screen.dart';
import 'views/calculator/bmr_tdee_calculator_screen.dart';
import 'views/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Kích hoạt tần số quét tương thích phần cứng (120Hz/90Hz/60Hz/LTPO)
  await DisplayService().optimizeRefreshRate();

  // 2. Khởi tạo dịch vụ nền tảng Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Cấu hình bộ nhớ đệm Offline Cache không giới hạn cho Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 4. Quét dọn Cold Boot: Xóa sổ tài khoản chưa kích hoạt nếu app bị tắt ngang
  await AuthService().purgeUnverifiedUserOnColdBoot();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Quản lý vòng đời Controller tập trung tại gốc ứng dụng
  final ThemeController _themeController = ThemeController();
  final DailyLogController _logController = DailyLogController();
  final AuthController _authController = AuthController();

  @override
  void dispose() {
    _themeController.dispose();
    _logController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

          // Bộ định tuyến phân tầng độc lập theo máy trạng thái AuthStatus
          home: ListenableBuilder(
            listenable: _authController,
            builder: (context, _) {
              switch (_authController.status) {
                case AuthStatus.loading:
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.lime,
                        strokeWidth: 2.5,
                      ),
                    ),
                  );

                case AuthStatus.unauthenticated:
                case AuthStatus.unverified:
                  return Builder(
                    builder: (navContext) => AuthScreen(
                      onLoginSuccess: () {},
                      onNavigateToRegister: () {
                        Navigator.of(navContext).push(
                          MaterialPageRoute(
                            builder: (_) => SignUpScreen(
                              onSignUpSuccess: () => Navigator.of(navContext).pop(),
                              onNavigateToLogin: () => Navigator.of(navContext).pop(),
                            ),
                          ),
                        );
                      },
                    ),
                  );

                case AuthStatus.needsPassword:
                  return SetPasswordScreen(
                    onPasswordSetSuccess: () {},
                  );

                case AuthStatus.needsOnboarding:
                  return BmrTdeeCalculatorScreen(
                    onSetupCompleted: () {},
                  );

                case AuthStatus.authenticated:
                  return MainNavigationShell(
                    logController: _logController,
                    themeController: _themeController,
                  );
              }
            },
          ),
        );
      },
    );
  }
}