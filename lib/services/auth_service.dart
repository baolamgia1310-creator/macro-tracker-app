import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. Đăng nhập Email & Mật khẩu
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // 2. Đăng nhập Google (Trả về UserCredential để kiểm tra trạng thái)
  Future<UserCredential?> signInWithGoogle() async {
    await _googleSignIn.signOut();
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user != null) {
      await _syncUserToFirestore(userCredential.user!);
    }

    return userCredential;
  }

  // 3. Đăng ký bằng Email & Mật khẩu
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (credential.user != null) {
      await credential.user!.updateDisplayName(displayName.trim());
      await _syncUserToFirestore(credential.user!, customName: displayName.trim(), hasPassword: true);
    }

    return credential;
  }

  // 4. Gửi link đặt lại mật khẩu qua email (Dùng trang web mặc định Firebase)
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // 5. Kiểm tra tài khoản đã thiết lập mật khẩu hay chưa
  Future<bool> hasSetPassword(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    return (doc.data()?['hasPassword'] as bool?) ?? false;
  }

  // 6. Đặt mật khẩu mới cho tài khoản đăng nhập Google
  Future<void> setAccountPassword(String newPassword) async {
  final user = _auth.currentUser;
  if (user == null) throw Exception('No user currently signed in.');

  // 1. Cập nhật hoặc liên kết mật khẩu với tài khoản Google
  try {
    await user.updatePassword(newPassword.trim());
  } catch (_) {
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: newPassword.trim(),
    );
    await user.linkWithCredential(credential);
  }

  // 2. Cập nhật cờ hasPassword trên Cloud Firestore
  await _db.collection('users').doc(user.uid).set({
    'hasPassword': true,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
  

  // Khởi tạo hồ sơ người dùng trên Firestore
  Future<void> _syncUserToFirestore(User user, {String? customName, bool hasPassword = false}) async {
    final userDoc = _db.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': customName ?? user.displayName ?? 'Macro User',
        'photoUrl': user.photoURL ?? '',
        'hasPassword': hasPassword,
        'age': 25,
        'gender': 'male',
        'heightCm': 170.0,
        'weightKg': 65.0,
        'activityLevel': 'moderatelyActive',
        'goal': 'maintenance',
        'bmr': 1600.0,
        'tdee': 2200.0,
        'targetMacros': {
          'targetCalories': 2200.0,
          'targetProteinGrams': 150.0,
          'targetCarbsGrams': 250.0,
          'targetFatGrams': 65.0,
        },
        'settings': {
          'theme': 'dark',
          'unitSystem': 'metric',
          'reminderNotification': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
  
  // Đăng xuất
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  
}