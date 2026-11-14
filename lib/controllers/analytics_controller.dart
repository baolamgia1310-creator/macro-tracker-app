import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef JsonMap = Map<String, dynamic>;
typedef WeightList = List<WeightDataPoint>;

class WeightDataPoint {
  final String day;
  final double weight;

  const WeightDataPoint({required this.day, required this.weight});
}

class AnalyticsController extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final List<String> timeRanges = const ['This Week', 'This Month', '3 Months'];
  String _selectedRange = 'This Week';

  AnalyticsController({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _authSub = _auth.authStateChanges().listen((user) {
      _bindAnalyticsStreams(user?.uid);
    });
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<QuerySnapshot>? _logsSub;
  StreamSubscription<QuerySnapshot>? _weightSub;

  double _startingWeight = 68.0;
  double _currentWeight = 68.0;
  double _targetProtein = 150.0;
  double _targetCarbs = 200.0;
  double _targetFat = 65.0;

  // Lưu lịch sử cân nặng theo ngày ('YYYY-M-D': weight)
  final Map<String, double> _dateToWeight = {};

  WeightList _weeklyWeights = const [
    WeightDataPoint(day: 'Mon', weight: 68.0),
    WeightDataPoint(day: 'Tue', weight: 68.0),
    WeightDataPoint(day: 'Wed', weight: 68.0),
    WeightDataPoint(day: 'Thu', weight: 68.0),
    WeightDataPoint(day: 'Fri', weight: 68.0),
    WeightDataPoint(day: 'Sat', weight: 68.0),
    WeightDataPoint(day: 'Sun', weight: 68.0),
  ];

  double _proteinAdherence = 0.0;
  double _carbsAdherence = 0.0;
  double _fatAdherence = 0.0;

  int _avgCalories = 0;
  double _weightChange = 0.0;
  int _streakDays = 0;

  List<QueryDocumentSnapshot> _rawLogDocs = [];
  List<QueryDocumentSnapshot> _rawWeightDocs = [];

  // Getters
  String get selectedRange => _selectedRange;
  WeightList get weeklyWeights => _weeklyWeights;
  double get currentWeight =>
      _weeklyWeights.isNotEmpty ? _weeklyWeights.last.weight : _currentWeight;

  double get proteinAdherence => _proteinAdherence;
  double get carbsAdherence => _carbsAdherence;
  double get fatAdherence => _fatAdherence;

  int get avgCalories => _avgCalories;
  double get weightChange => _weightChange;
  int get streakDays => _streakDays;

  // Khi đổi khoảng thời gian -> Cập nhật lại cả Biểu đồ cân nặng lẫn Macro
  void setRange(String range) {
    if (_selectedRange == range) return;
    _selectedRange = range;
    _recomputeWeightTrend();
    _recomputeLogsMetrics();
    notifyListeners();
  }

  int _resolveDaysCount() {
    if (_selectedRange == 'This Month') return 30;
    if (_selectedRange == '3 Months') return 90;
    return 7;
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void _bindAnalyticsStreams(String? uid) {
    _userSub?.cancel();
    _logsSub?.cancel();
    _weightSub?.cancel();

    if (uid == null || uid.isEmpty) return;

    // 1. Lắng nghe hồ sơ người dùng & lịch sử cân nặng lưu trong users/{uid}
    _userSub = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        final w = _toDouble(data['weightKg'], 68.0);
        _currentWeight = w;
        _startingWeight = _toDouble(data['startingWeightKg'], w);

        // Đọc map weightHistory trực tiếp từ users/{uid}
        final rawHistory = data['weightHistory'];
        if (rawHistory is Map) {
          rawHistory.forEach((k, v) {
            _dateToWeight[k.toString()] = _toDouble(v, w);
          });
        }

        final targets = data['targetMacros'] as JsonMap? ?? data;
        _targetProtein = _toDouble(targets['targetProteinGrams'], 150.0);
        _targetCarbs = _toDouble(targets['targetCarbsGrams'], 200.0);
        _targetFat = _toDouble(targets['targetFatGrams'], 65.0);

        _recomputeWeightTrend();
        _recomputeLogsMetrics();
        notifyListeners();
      }
    });

    // 2. Lắng nghe nhật ký ăn uống
    _logsSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .snapshots()
        .listen((snapshot) {
      _rawLogDocs = snapshot.docs;
      _recomputeLogsMetrics();
      notifyListeners();
    }, onError: (_) {});

    // 3. Lắng nghe subcollection weight_logs (nếu có)
    _weightSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('weight_logs')
        .orderBy('loggedAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      _rawWeightDocs = snapshot.docs;
      for (final doc in _rawWeightDocs) {
        final data = doc.data() as JsonMap?;
        if (data == null) continue;
        final w = _toDouble(data['weightKg'], _currentWeight);
        DateTime dt = DateTime.now();
        final rawTime = data['loggedAt'];
        if (rawTime is Timestamp) dt = rawTime.toDate();
        _dateToWeight[_dateKey(dt)] = w;
      }
      _recomputeWeightTrend();
      notifyListeners();
    }, onError: (_) {});
  }

  // Tra cứu cân nặng tại một ngày cụ thể (nếu ngày đó chưa nhập thì lấy mốc gần nhất trước đó)
  double _getWeightOnOrBefore(DateTime targetDate) {
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final exactKey = _dateKey(targetDay);
    if (_dateToWeight.containsKey(exactKey)) {
      return _dateToWeight[exactKey]!;
    }

    DateTime? latestBefore;
    double? foundWeight;

    _dateToWeight.forEach((key, val) {
      final parts = key.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? 2026;
        final m = int.tryParse(parts[1]) ?? 1;
        final d = int.tryParse(parts[2]) ?? 1;
        final dt = DateTime(y, m, d);
        if (!dt.isAfter(targetDay)) {
          if (latestBefore == null || dt.isAfter(latestBefore!)) {
            latestBefore = dt;
            foundWeight = val;
          }
        }
      }
    });

    if (foundWeight != null) return foundWeight!;

    // Nếu là ngày hôm nay thì trả về cân nặng hiện tại, các ngày trước trả về cân nặng ban đầu
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!targetDay.isBefore(today)) {
      return _currentWeight;
    }
    return _startingWeight;
  }

  void _recomputeWeightTrend() {
    final now = DateTime.now();
    final WeightList points = [];

    if (_selectedRange == 'This Week') {
      // 7 ngày gần nhất: Mon, Tue, Wed, Thu, Fri, Sat, Sun
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final w = _getWeightOnOrBefore(d);
        points.add(
          WeightDataPoint(
            day: weekdays[d.weekday - 1],
            weight: double.parse(w.toStringAsFixed(1)),
          ),
        );
      }
    } else if (_selectedRange == 'This Month') {
      // 4 tuần trong tháng: W1, W2, W3, W4
      final weekOffsets = [21, 14, 7, 0];
      for (int i = 0; i < weekOffsets.length; i++) {
        final d = now.subtract(Duration(days: weekOffsets[i]));
        final w = _getWeightOnOrBefore(d);
        points.add(
          WeightDataPoint(
            day: 'W${i + 1}',
            weight: double.parse(w.toStringAsFixed(1)),
          ),
        );
      }
    } else {
      // 3 Months: Hiển thị tên 3 tháng (ví dụ: Sep, Oct, Nov)
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      for (int i = 2; i >= 0; i--) {
        final sampleDate = i == 0
            ? now
            : DateTime(now.year, now.month - i, 15);
        final w = _getWeightOnOrBefore(sampleDate);
        points.add(
          WeightDataPoint(
            day: monthNames[sampleDate.month - 1],
            weight: double.parse(w.toStringAsFixed(1)),
          ),
        );
      }
    }

    _weeklyWeights = points;
    if (points.length >= 2) {
      _weightChange = double.parse(
        (points.last.weight - points.first.weight).toStringAsFixed(1),
      );
    } else {
      _weightChange = 0.0;
    }
  }

  void _recomputeLogsMetrics() {
    if (_rawLogDocs.isEmpty) {
      _avgCalories = 0;
      _proteinAdherence = 0.0;
      _carbsAdherence = 0.0;
      _fatAdherence = 0.0;
      _streakDays = 0;
      return;
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final cutoffDate =
        todayStart.subtract(Duration(days: _resolveDaysCount() - 1));

    final Map<String, int> dailyCalMap = {};
    final Map<String, double> dailyProMap = {};
    final Map<String, double> dailyCarbMap = {};
    final Map<String, double> dailyFatMap = {};
    final Set<String> allLoggedDayKeys = {};

    for (final doc in _rawLogDocs) {
      final data = doc.data() as JsonMap?;
      if (data == null) continue;

      DateTime dt = now;
      final rawTime = data['loggedAt'];
      if (rawTime is Timestamp) dt = rawTime.toDate();

      final dayDate = DateTime(dt.year, dt.month, dt.day);
      final key = _dateKey(dayDate);
      allLoggedDayKeys.add(key);

      if (!dayDate.isBefore(cutoffDate)) {
        dailyCalMap[key] =
            (dailyCalMap[key] ?? 0) + _toDouble(data['calories']).round();
        dailyProMap[key] =
            (dailyProMap[key] ?? 0.0) + _toDouble(data['protein']);
        dailyCarbMap[key] =
            (dailyCarbMap[key] ?? 0.0) + _toDouble(data['carbs']);
        dailyFatMap[key] = (dailyFatMap[key] ?? 0.0) + _toDouble(data['fat']);
      }
    }

    final activeDays = dailyCalMap.length;
    if (activeDays > 0) {
      final totalCal = dailyCalMap.values.fold(0, (a, b) => a + b);
      final avgPro =
          dailyProMap.values.fold(0.0, (a, b) => a + b) / activeDays;
      final avgCarb =
          dailyCarbMap.values.fold(0.0, (a, b) => a + b) / activeDays;
      final avgFat =
          dailyFatMap.values.fold(0.0, (a, b) => a + b) / activeDays;

      _avgCalories = (totalCal / activeDays).round();
      _proteinAdherence = _targetProtein > 0
          ? (avgPro / _targetProtein).clamp(0.0, 1.0)
          : 0.0;
      _carbsAdherence = _targetCarbs > 0
          ? (avgCarb / _targetCarbs).clamp(0.0, 1.0)
          : 0.0;
      _fatAdherence =
          _targetFat > 0 ? (avgFat / _targetFat).clamp(0.0, 1.0) : 0.0;
    } else {
      _avgCalories = 0;
      _proteinAdherence = 0.0;
      _carbsAdherence = 0.0;
      _fatAdherence = 0.0;
    }

    int streak = 0;
    DateTime cursor = todayStart;
    final todayKey = _dateKey(cursor);
    if (!allLoggedDayKeys.contains(todayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (true) {
      final k = _dateKey(cursor);
      if (allLoggedDayKeys.contains(k)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    _streakDays = streak;
  }

  // Ghi nhận cân nặng mới tức thì (0ms) và đồng bộ an toàn lên Firestore
  Future<void> logWeight(double newWeightKg) async {
    if (newWeightKg < 20 || newWeightKg > 300) return;

    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    // Giữ lại cân nặng cũ cho ngày hôm qua nếu đây là lần đầu tiên log
    if (_dateToWeight.isEmpty && _currentWeight != newWeightKg) {
      _startingWeight = _currentWeight;
      _dateToWeight[yesterdayKey] = _startingWeight;
    }

    // 1. Cập nhật ngay trên RAM và vẽ lại biểu đồ tức thì (0ms)
    _currentWeight = newWeightKg;
    _dateToWeight[todayKey] = newWeightKg;
    _recomputeWeightTrend();
    notifyListeners();

    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    // 2. Đồng bộ ngầm lên document users/{uid} (luôn có quyền ghi)
    try {
      await _firestore.collection('users').doc(uid).set({
        'weightKg': newWeightKg,
        'startingWeightKg': _startingWeight,
        'weightHistory': {
          yesterdayKey: _dateToWeight[yesterdayKey] ?? _startingWeight,
          todayKey: newWeightKg,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    // 3. Ghi phụ vào subcollection weight_logs (bọc try-catch để không bao giờ treo)
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('weight_logs')
          .add({
        'weightKg': newWeightKg,
        'loggedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static double _toDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    _logsSub?.cancel();
    _weightSub?.cancel();
    super.dispose();
  }
}