import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  // 1. Đăng ký tài khoản và gửi email xác thực (giữ phiên để kiểm tra link)
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
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
  }

  // 2. Xóa tài khoản ngay lập tức nếu người dùng hủy hoặc không xác thực
  Future<void> deleteCurrentUser() async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.delete();
    }
  }

  // 3. Đăng nhập bằng Email/Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (credential.user != null && !credential.user!.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Your email has not been verified yet.',
      );
    }

    return credential;
  }

  // 4. Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // 5. Đăng nhập Google
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }
  // 6. Kiểm tra và xóa sổ tài khoản nếu chưa kích hoạt email khi khởi động
  Future<bool> purgeIfUnverified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Đồng bộ trạng thái mới nhất từ Firebase
      final refreshedUser = _auth.currentUser;
      
      // Nếu vẫn chưa bấm link xác thực -> Xóa vĩnh viễn khỏi Authentication
      if (refreshedUser != null && !refreshedUser.emailVerified) {
        await refreshedUser.delete();
        return true; // Đã xóa
      }
    }
    return false;
  }
  // 7. Đăng xuất
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}