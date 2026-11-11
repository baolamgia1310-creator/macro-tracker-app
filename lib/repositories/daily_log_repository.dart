import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/logged_food_item.dart';

class DailyLogRepository {
  final FirebaseFirestore _firestore;

  DailyLogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<LoggedFoodItem>> watchTodayLogs(String uid) {
    if (uid.isEmpty) return const Stream.empty();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => LoggedFoodItem.fromMap(doc.id, doc.data()))
              .toList();

          // Sắp xếp thời gian giảm dần trên RAM, an toàn 100% không lo lỗi Index
          items.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
          return items;
        });
  }

  Future<void> deleteLoggedFood({
    required String uid,
    required String logId,
  }) async {
    if (uid.isEmpty || logId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(logId)
        .delete();
  }
}