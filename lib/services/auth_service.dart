import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  String? get currentUserId => _auth.currentUser?.uid;
  bool get hasPasswordProvider =>
      _auth.currentUser?.providerData.any((info) => info.providerId == 'password') ?? false;

  Stream<bool> watchAuthState() {
    return _auth.authStateChanges().map((user) => user != null);
  }

  // Quét dọn Cold Boot: Xóa tài khoản chưa xác thực khi mở lại ứng dụng
  Future<void> purgeUnverifiedUserOnColdBoot() async {
    try {
      final initialUser = await _auth.authStateChanges().first;
      if (initialUser != null && !initialUser.emailVerified) {
        await initialUser.reload();
        if (!initialUser.emailVerified) {
          await initialUser.delete();
        }
      }
    } catch (_) {}
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (cred.user != null && !cred.user!.emailVerified) {
        await _auth.signOut();
        throw AuthException('Please verify your email address before signing in. Check your inbox or Spam folder.');
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return result.user != null;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    } catch (_) {
      throw AuthException('Unable to sign in with Google account.');
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        if (displayName.trim().isNotEmpty) {
          await credential.user!.updateDisplayName(displayName.trim());
        }
        await credential.user!.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePassword(newPassword.trim());
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    }
  }

  Future<void> deleteCurrentUser() async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.delete();
      }
    } catch (_) {}
  }

  Future<bool> checkEmailVerified() async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.reload();
      return _auth.currentUser?.emailVerified ?? false;
    }
    return false;
  }

  Future<void> resendVerificationEmail() async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password, or no account found.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'Password does not meet security requirements.';
      case 'requires-recent-login':
        return 'This sensitive operation requires a recent sign-in. Please log in again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication error ($code). Please try again.';
    }
  }
}