import 'dart:async';
import 'package:flutter/material.dart';
import '../core/enums/auth_status.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepository;

  AuthController({
    AuthService? authService,
    UserRepository? userRepository,
  })  : _authService = authService ?? AuthService(),
        _userRepository = userRepository ?? UserRepository() {
    _initAuthListener();
  }

  AuthStatus _status = AuthStatus.loading;
  StreamSubscription<bool>? _authSubscription;
  StreamSubscription<Map<String, dynamic>?>? _userDocSubscription;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  void _initAuthListener() {
    _authSubscription = _authService.watchAuthState().listen((isLoggedIn) async {
      _userDocSubscription?.cancel();

      if (!isLoggedIn) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      final isVerified = await _authService.checkEmailVerified();
      if (!isVerified) {
        _status = AuthStatus.unverified;
        notifyListeners();
        return;
      }

      final uid = _authService.currentUserId;
      if (uid == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _userDocSubscription = _userRepository.watchUserDoc(uid).listen((userData) {
        final hasPassword = (userData?['hasPassword'] == true) || _authService.hasPasswordProvider;
        final isProfileCompleted = userData?['isProfileCompleted'] == true;

        if (!hasPassword) {
          _status = AuthStatus.needsPassword;
        } else if (!isProfileCompleted) {
          _status = AuthStatus.needsOnboarding;
        } else {
          _status = AuthStatus.authenticated;
        }
        notifyListeners();
      }, onError: (_) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      });
    });
  }

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
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected system error occurred.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _authService.signInWithGoogle();
      _setLoading(false);
      return success;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'Unable to sign in with Google account.';
      _setLoading(false);
      return false;
    }
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
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'An error occurred during account creation.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> checkEmailVerified() async {
    return await _authService.checkEmailVerified();
  }

  Future<bool> resendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelRegistration() async {
    _setLoading(true);
    await _authService.deleteCurrentUser();
    _setLoading(false);
  }

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
      final uid = _authService.currentUserId;
      if (uid != null) {
        await _authService.updatePassword(cleanPassword);
        await _userRepository.markPasswordSet(uid);
        await _authService.signOut();
      }
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
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
      await _authService.sendPasswordResetEmail(cleanEmail);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'Failed to send password reset email.';
      _setLoading(false);
      return false;
    }
  }
}