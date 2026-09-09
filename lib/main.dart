import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Bảng màu & Controller quản lý trạng thái
import 'core/constants/app_colors.dart';
import 'controllers/theme_controller.dart';
import 'controllers/daily_log_controller.dart';

// Màn hình trong luồng xác thực & điều hướng
import 'views/auth/auth_screen.dart';
import 'views/auth/sign_up_screen.dart';
import 'views/auth/set_password_screen.dart';
import 'views/calculator/bmr_tdee_calculator_screen.dart';
import 'views/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Chờ Firebase Auth khôi phục phiên đăng nhập từ ổ cứng máy
  try {
    final initialUser = await FirebaseAuth.instance.authStateChanges().first;
    // Nếu có tài khoản sót lại từ lần dùng trước mà chưa bấm link xác thực -> Xóa sổ ngay lập tức
    if (initialUser != null && !initialUser.emailVerified) {
      await initialUser.reload();
      if (!initialUser.emailVerified) {
        await initialUser.delete();
      }
    }
  } catch (_) {}

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Macro Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: _themeController.themeMode,
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
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.lime, strokeWidth: 2.5),
                  ),
                );
              }

              final user = authSnapshot.data;

              // Chưa đăng nhập hoặc chưa bấm link xác thực -> Luôn giữ ở AuthScreen
              if (user == null || !user.emailVerified) {
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
              }

              // Đã xác thực email -> Tiến vào luồng kiểm tra dữ liệu Firestore
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, userDocSnapshot) {
                  if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(color: AppColors.lime, strokeWidth: 2.5),
                      ),
                    );
                  }

                  final userData = userDocSnapshot.data?.data() as Map<String, dynamic>?;

                  final hasPasswordProvider = user.providerData.any(
                    (info) => info.providerId == 'password',
                  );
                  final hasPassword = (userData?['hasPassword'] == true) || hasPasswordProvider;
                  final isProfileCompleted = userData?['isProfileCompleted'] == true;

                  if (!hasPassword) {
                    return SetPasswordScreen(onPasswordSetSuccess: () {});
                  }

                  if (!isProfileCompleted) {
                    return BmrTdeeCalculatorScreen(onSetupCompleted: () {});
                  }

                  return MainNavigationShell(
                    logController: _logController,
                    themeController: _themeController,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}