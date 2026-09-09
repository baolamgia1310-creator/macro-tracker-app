import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/daily_log_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/constants/app_colors.dart';
import '../calculator/bmr_tdee_calculator_screen.dart';
import '../main_navigation_shell.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onSignUpSuccess;
  final VoidCallback onNavigateToLogin;

  const SignUpScreen({
    super.key,
    required this.onSignUpSuccess,
    required this.onNavigateToLogin,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthController _controller = AuthController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Quản lý đếm ngược 30s cho nút Resend
  Timer? _resendTimer;
  int _countdown = 30;
  bool _canResend = false;
  bool _isChecking = false;
  void Function(void Function())? _dialogSetState;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Khởi động đồng hồ đếm lùi 30 giây
  void _startCooldownTimer() {
    _resendTimer?.cancel();
    _countdown = 30;
    _canResend = false;
    _dialogSetState?.call(() {});

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        _countdown--;
        _dialogSetState?.call(() {});
      } else {
        timer.cancel();
        _canResend = true;
        _dialogSetState?.call(() {});
      }
    });
  }

  void _showVerificationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    // Kích hoạt ngay bộ đếm 30s khi vừa tạo tài khoản thành công
    _startCooldownTimer();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _dialogSetState = setDialogState;

            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined, color: Colors.black, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A verification link has been sent to:\n${_emailController.text.trim()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.greySubtext,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please click the link in your email to activate your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greySubtext,
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actions: [
                // 1. Nút kiểm tra trạng thái xác thực
                ElevatedButton(
                  onPressed: _isChecking
                      ? null
                      : () async {
                          setDialogState(() => _isChecking = true);
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await user.reload();
                            final refreshedUser = FirebaseAuth.instance.currentUser;

                            if (refreshedUser != null && refreshedUser.emailVerified) {
                              _resendTimer?.cancel();
                              if (mounted) {
                                Navigator.of(dialogContext).pop();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => BmrTdeeCalculatorScreen(
                                      onSetupCompleted: () {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (_) => MainNavigationShell(
                                              logController: DailyLogController(),
                                              themeController: ThemeController(),
                                            ),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                          }

                          setDialogState(() => _isChecking = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email not verified yet. Please check your inbox or spam folder!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text(
                          'I Have Verified',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
                const SizedBox(height: 10),

                // 2. Nút gửi lại link kích hoạt có đếm lùi 30s
                Center(
                  child: TextButton(
                    onPressed: _canResend
                        ? () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await user.sendEmailVerification();
                              _startCooldownTimer(); // Reset đếm lại 30s ở mỗi lần click
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('A new verification link has been sent!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    child: Text(
                      _canResend
                          ? 'Resend verification link'
                          : 'Resend link in ${_countdown}s',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _canResend
                            ? (isDark ? AppColors.lime : Colors.black)
                            : AppColors.greySubtext,
                      ),
                    ),
                  ),
                ),

                // 3. Nút Hủy: Tự động xóa user khỏi Firebase Auth ngay lập tức
                Center(
                  child: TextButton(
                    onPressed: () async {
                      _resendTimer?.cancel();
                      await _controller.cancelRegistration();
                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registration cancelled. Account removed.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Cancel Registration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _dialogSetState = null;
      _resendTimer?.cancel();
    });
  }

  Future<void> _handleSignUp() async {
    final success = await _controller.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      _showVerificationDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final faintHintColor = isDark
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.25);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: widget.onNavigateToLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '8-32 chars, uppercase, lowercase, numbers & symbols',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.greySubtext),
                    ),
                    const SizedBox(height: 24),

                    if (_controller.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          _controller.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),

                    // 1. Full Name
                    _buildInputContainer(
                      cardColor: cardColor,
                      child: TextField(
                        controller: _nameController,
                        enableSuggestions: false,
                        autocorrect: false,
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: AppColors.greySubtext, fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Email
                    _buildInputContainer(
                      cardColor: cardColor,
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: AppColors.greySubtext, fontSize: 13),
                          hintText: 'your@email.com',
                          hintStyle: TextStyle(color: faintHintColor, fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Password
                    _buildInputContainer(
                      cardColor: cardColor,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _controller.obscurePassword,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: AppColors.greySubtext, fontSize: 13),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _controller.obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.greySubtext,
                              size: 20,
                            ),
                            onPressed: _controller.togglePasswordVisibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Confirm Password
                    _buildInputContainer(
                      cardColor: cardColor,
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: _controller.obscureConfirmPassword,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: const TextStyle(color: AppColors.greySubtext, fontSize: 13),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _controller.obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.greySubtext,
                              size: 20,
                            ),
                            onPressed: _controller.toggleConfirmPasswordVisibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _controller.isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lime,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppColors.greySubtext, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToLogin,
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: isDark ? AppColors.lime : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Color cardColor, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: child,
    );
  }
}