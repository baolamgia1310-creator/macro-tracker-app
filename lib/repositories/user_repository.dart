import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Lắng nghe thay đổi Document của người dùng trong Firestore
  Stream<Map<String, dynamic>?> watchUserDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  // Đánh dấu người dùng đã tạo mật khẩu
  Future<void> markPasswordSet(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'hasPassword': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}