import 'dart:async';
import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBackToLogin;

  const ForgotPasswordScreen({
    super.key,
    required this.onBackToLogin,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthController _controller = AuthController();
  final TextEditingController _emailController = TextEditingController();

  bool _emailSent = false;
  Timer? _timer;
  int _countdown = 30;
  bool _canSend = true;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Khởi động bộ đếm lùi 30 giây chống spam
  void _startCooldownTimer() {
    setState(() {
      _canSend = false;
      _countdown = 30;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canSend = true;
        });
      }
    });
  }

  Future<void> _handleReset() async {
    if (!_canSend || _controller.isLoading) return;

    final success = await _controller.sendPasswordReset(_emailController.text);
    
    if (!mounted) return;

    if (success) {
      setState(() {
        _emailSent = true;
      });
      _startCooldownTimer();
    } else {
      setState(() {
        _emailSent = false;
      });
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

    final isButtonDisabled = !_canSend || _controller.isLoading;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: widget.onBackToLogin,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Icon chìa khóa
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_reset_outlined,
                        size: 28,
                        color: AppColors.lime,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your registered email address and we will send you a link to reset your password.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.greySubtext,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Banner thông báo lỗi
                  if (_controller.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      margin: const EdgeInsets.only(bottom: 16),
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

                  // Banner thông báo đã gửi email thành công
                  if (_emailSent)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.lime.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.lime.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.lime, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Reset link sent! Please check your inbox (and Spam folder).',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Ô nhập Email
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: const TextStyle(color: AppColors.greySubtext, fontSize: 13),
                        hintText: 'your@email.com',
                        hintStyle: TextStyle(color: faintHintColor, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Send / Resend Reset Link kèm đếm ngược
                  ElevatedButton(
                    onPressed: isButtonDisabled ? null : _handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      disabledBackgroundColor: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08),
                      foregroundColor: Colors.black,
                      disabledForegroundColor: AppColors.greySubtext,
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
                        : Text(
                            !_canSend
                                ? 'Resend in ${_countdown}s'
                                : (_emailSent ? 'Resend Reset Link' : 'Send Reset Link'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const Spacer(),

                  // Nút quay lại Login
                  Center(
                    child: TextButton.icon(
                      onPressed: widget.onBackToLogin,
                      icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.greySubtext),
                      label: const Text(
                        'Back to Sign In',
                        style: TextStyle(
                          color: AppColors.greySubtext,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}