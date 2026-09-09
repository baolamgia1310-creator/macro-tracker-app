import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;

  AuthController({AuthService? authService})
      : _authService = authService ?? AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  static String? validatePassword(String password) {
    final cleanPass = password.trim();

    if (cleanPass.length < 8 || cleanPass.length > 32) {
      return 'Password must be between 8 and 32 characters.';
    }
    if (cleanPass.contains(' ')) {
      return 'Password cannot contain spaces.';
    }
    if (!RegExp(r'[a-z]').hasMatch(cleanPass)) {
      return 'Password must contain at least one lowercase letter (a-z).';
    }
    if (!RegExp(r'[A-Z]').hasMatch(cleanPass)) {
      return 'Password must contain at least one uppercase letter (A-Z).';
    }
    if (!RegExp(r'\d').hasMatch(cleanPass)) {
      return 'Password must contain at least one number (0-9).';
    }
    if (!RegExp(r'[@$!%*?&#^()_+\-=\[\]{}|;:,.<>]').hasMatch(cleanPass)) {
      return 'Password must contain at least one special character (@\$!%*?&...).';
    }

    return null;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Please enter both email and password.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signInWithEmail(email: cleanEmail, password: password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected system error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authService.signInWithGoogle();
      _setLoading(false);
      return credential != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Unable to sign in with Google account.';
      _setLoading(false);
      return false;
    }
  }
  Future<void> cancelRegistration() async {
    _setLoading(true);
    try {
      await _authService.deleteCurrentUser();
    } catch (_) {}
    _setLoading(false);
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty || cleanPassword.isEmpty) {
      _errorMessage = 'Please fill in all fields.';
      notifyListeners();
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(cleanEmail)) {
      _errorMessage = 'Invalid email format.';
      notifyListeners();
      return false;
    }

    final passwordError = validatePassword(cleanPassword);
    if (passwordError != null) {
      _errorMessage = passwordError;
      notifyListeners();
      return false;
    }

    if (cleanPassword != confirmPassword.trim()) {
      _errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signUpWithEmail(
        email: cleanEmail,
        password: cleanPassword,
        displayName: cleanName,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred during account creation.';
      _setLoading(false);
      return false;
    }
  }

  // Phương thức thiết lập mật khẩu mới
  Future<bool> setPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final cleanPassword = newPassword.trim();
    final cleanConfirm = confirmPassword.trim();

    if (cleanPassword.isEmpty || cleanConfirm.isEmpty) {
      _errorMessage = 'Please fill in both password fields.';
      notifyListeners();
      return false;
    }

    final passwordError = validatePassword(cleanPassword);
    if (passwordError != null) {
      _errorMessage = passwordError;
      notifyListeners();
      return false;
    }

    if (cleanPassword != cleanConfirm) {
      _errorMessage = 'Passwords do not match.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Cập nhật mật khẩu trên Firebase Auth
        await user.updatePassword(cleanPassword);

        // Lưu cờ xác nhận tài khoản đã có mật khẩu lên Cloud Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'hasPassword': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Đăng xuất phiên hiện tại để người dùng đăng nhập lại từ đầu
        await _authService.signOut();
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to set password. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      _errorMessage = 'Please enter your email address.';
      notifyListeners();
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(cleanEmail)) {
      _errorMessage = 'Invalid email format.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      // Gọi trực tiếp FirebaseAuth vì file này đã import firebase_auth.dart
      await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send password reset email.';
      _setLoading(false);
      return false;
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      // 1. Luồng xác thực email (Email Verification)
      case 'email-not-verified':
        return 'Please verify your email address before signing in. Check your inbox or Spam folder.';

      // 2. Luồng quên mật khẩu & đăng nhập (User Lookup & Credentials)
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password, or no account found.';

      // 3. Luồng đăng ký tài khoản (Registration)
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'Password does not meet security requirements.';

      // 4. Luồng đổi / thiết lập mật khẩu (Sensitive Auth Operations)
      case 'requires-recent-login':
        return 'This action is sensitive and requires a recent sign-in. Please log in again.';

      // 5. Trạng thái tài khoản & cấu hình máy chủ
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently disabled in Firebase Console.';

      // 6. Tần suất gửi yêu cầu & kết nối mạng (Rate Limit & Network)
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      // Mặc định cho các mã lỗi chưa phân loại
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}