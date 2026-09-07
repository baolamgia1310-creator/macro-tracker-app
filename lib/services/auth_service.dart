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

  // 1. Đăng nhập Email
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    if (credential.user != null) {
      await _syncUserToFirestore(credential.user!);
    }
    return credential;
  }

  // 2. Đăng nhập Google (Popup tài khoản)
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

  // 3. Đăng ký tài khoản mới bằng Email
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
      await _syncUserToFirestore(credential.user!, customName: displayName.trim());
    }

    return credential;
  }

  // 4. Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Khởi tạo hồ sơ người dùng trên Firestore
  Future<void> _syncUserToFirestore(User user, {String? customName}) async {
    final userDoc = _db.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': customName ?? user.displayName ?? 'Macro User',
        'photoUrl': user.photoURL ?? '',
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