import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/logged_food_item.dart';

typedef LoggedFoodList = List<LoggedFoodItem>;
typedef LogStream = Stream<LoggedFoodList>;

class DailyLogRepository {
  final FirebaseFirestore _firestore;

  DailyLogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  LogStream watchLogsForDate(String uid, DateTime date) {
    if (uid.isEmpty) return Stream.value([]);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .snapshots()
        .map((snapshot) {
      final LoggedFoodList items = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final item = LoggedFoodItem.fromMap(doc.id, data);

        // Lọc các món ăn thuộc ngày đang chọn (kể cả khi serverTimestamp đang pending)
        final isSameDay = item.loggedAt.isAfter(
                startOfDay.subtract(const Duration(seconds: 1))) &&
            item.loggedAt.isBefore(endOfDay);

        if (isSameDay || data['loggedAt'] == null) {
          items.add(item);
        }
      }

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

  Future<void> restoreLoggedFood({
    required String uid,
    required LoggedFoodItem item,
  }) async {
    if (uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(item.id)
        .set(item.toMap());
  }
}