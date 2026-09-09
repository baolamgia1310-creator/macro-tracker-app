import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import 'auth_screen.dart';

class SetPasswordScreen extends StatefulWidget {
  final VoidCallback? onPasswordSetSuccess;
  final VoidCallback? onNavigateToLogin;

  const SetPasswordScreen({
    super.key,
    this.onPasswordSetSuccess,
    this.onNavigateToLogin,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final AuthController _controller = AuthController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Hộp thoại thông báo tạo mật khẩu thành công tương tự màn hình Đăng ký
  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                child: const Icon(Icons.check, color: Colors.black, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Password Set Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your password has been created. Please sign in with your new password to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.greySubtext,
              height: 1.45,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            ElevatedButton(
              onPressed: () {
                // 1. Đóng Dialog
                Navigator.of(dialogContext).pop();

                // 2. Chuyển hướng về màn hình Đăng nhập
                if (widget.onNavigateToLogin != null) {
                  widget.onNavigateToLogin!();
                } else {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => AuthScreen(
                        onLoginSuccess: () {},
                        onNavigateToRegister: () {},
                      ),
                    ),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'OK, Sign In',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSetPassword() async {
    final success = await _controller.setPassword(
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: widget.onNavigateToLogin != null
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: widget.onNavigateToLogin,
              )
            : null,
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
                    // Icon Khóa
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_outline,
                            size: 34,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Password',
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

                    // Thông báo lỗi
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

                    // 1. Ô New Password
                    _buildInputContainer(
                      cardColor: cardColor,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _controller.obscurePassword,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'New Password',
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

                    // 2. Ô Confirm Password
                    _buildInputContainer(
                      cardColor: cardColor,
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: _controller.obscureConfirmPassword,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
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

                    // Nút xác nhận
                    ElevatedButton(
                      onPressed: _controller.isLoading ? null : _handleSetPassword,
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
                              'Save Password',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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