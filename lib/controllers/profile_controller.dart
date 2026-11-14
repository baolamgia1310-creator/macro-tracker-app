import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef JsonMap = Map<String, dynamic>;

class ProfileController extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileController({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _authSub = _auth.authStateChanges().listen((user) {
      _bindUserProfile(user);
    });
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  String _displayName = 'Macro User';
  String _email = '';
  int _bmr = 1600;
  int _tdee = 2200;
  int _targetCalories = 2000;
  double _weightKg = 68.0;

  int _proteinPercent = 30;
  int _carbsPercent = 40;
  int _fatPercent = 30;

  double _proteinGrams = 150.0;
  double _carbsGrams = 200.0;
  double _fatGrams = 67.0;

  String _unitSystem = 'Metric (kg, cm, g)';
  bool _notificationsEnabled = true;
  final String appVersion = 'v1.0.0';
  bool _isLoading = true;

  // Getters
  bool get isLoading => _isLoading;
  String get displayName => _displayName;
  String get email => _email;
  int get bmr => _bmr;
  int get tdee => _tdee;
  int get targetCalories => _targetCalories;
  double get weightKg => _weightKg;

  int get proteinPercent => _proteinPercent;
  int get carbsPercent => _carbsPercent;
  int get fatPercent => _fatPercent;

  double get proteinGrams => _proteinGrams;
  double get carbsGrams => _carbsGrams;
  double get fatGrams => _fatGrams;

  String get unitSystem => _unitSystem;
  bool get notificationsEnabled => _notificationsEnabled;

  void _bindUserProfile(User? user) {
    _userDocSub?.cancel();

    if (user == null) {
      _displayName = 'Guest User';
      _email = '';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _email = user.email ?? '';
    final fallbackName = _email.contains('@')
        ? _email.split('@').first
        : 'Macro User';
    _displayName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : fallbackName;

    _userDocSub = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        if (data['displayName'] != null &&
            data['displayName'].toString().trim().isNotEmpty) {
          _displayName = data['displayName'].toString().trim();
        }

        _bmr = _toDouble(data['bmr'], 1600).round();
        _tdee = _toDouble(data['tdee'], 2200).round();
        _weightKg = _toDouble(data['weightKg'], 68.0);
        _notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;
        _unitSystem = (data['unitSystem'] ?? 'Metric (kg, cm, g)').toString();

        final targets = data['targetMacros'] as JsonMap? ?? data;
        _targetCalories =
            _toDouble(targets['targetCalories'] ?? data['tdee'], 2000).round();
        _proteinGrams =
            _toDouble(targets['targetProteinGrams'], (_targetCalories * 0.3) / 4);
        _carbsGrams =
            _toDouble(targets['targetCarbsGrams'], (_targetCalories * 0.4) / 4);
        _fatGrams =
            _toDouble(targets['targetFatGrams'], (_targetCalories * 0.3) / 9);

        // Tính phần trăm từ số gram hoặc đọc trực tiếp nếu đã lưu
        if (targets['proteinPercent'] != null &&
            targets['carbsPercent'] != null &&
            targets['fatPercent'] != null) {
          _proteinPercent = _toDouble(targets['proteinPercent'], 30).round();
          _carbsPercent = _toDouble(targets['carbsPercent'], 40).round();
          _fatPercent = _toDouble(targets['fatPercent'], 30).round();
        } else {
          final totalCalFromMacros =
              (_proteinGrams * 4) + (_carbsGrams * 4) + (_fatGrams * 9);
          if (totalCalFromMacros > 0) {
            _proteinPercent =
                (((_proteinGrams * 4) / totalCalFromMacros) * 100).round();
            _carbsPercent =
                (((_carbsGrams * 4) / totalCalFromMacros) * 100).round();
            _fatPercent = (100 - _proteinPercent - _carbsPercent).clamp(5, 80);
          }
        }
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  // Cập nhật tỷ lệ % Macro và tự động tính lại số Gram mục tiêu trên Firestore
  Future<bool> updateTargetMacros({
    required int targetCalories,
    required int proteinPct,
    required int carbsPct,
    required int fatPct,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;
    if (proteinPct + carbsPct + fatPct != 100) return false;

    final newProteinGrams =
        double.parse(((targetCalories * (proteinPct / 100.0)) / 4.0).toStringAsFixed(1));
    final newCarbsGrams =
        double.parse(((targetCalories * (carbsPct / 100.0)) / 4.0).toStringAsFixed(1));
    final newFatGrams =
        double.parse(((targetCalories * (fatPct / 100.0)) / 9.0).toStringAsFixed(1));

    try {
      await _firestore.collection('users').doc(uid).set({
        'targetMacros': {
          'targetCalories': targetCalories,
          'targetProteinGrams': newProteinGrams,
          'targetCarbsGrams': newCarbsGrams,
          'targetFatGrams': newFatGrams,
          'proteinPercent': proteinPct,
          'carbsPercent': carbsPct,
          'fatPercent': fatPct,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateDisplayName(String newName) async {
    final clean = newName.trim();
    final user = _auth.currentUser;
    if (user == null || clean.isEmpty) return;

    try {
      await user.updateDisplayName(clean);
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': clean,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'notificationsEnabled': enabled,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> logOut() async {
    await _auth.signOut();
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
    _userDocSub?.cancel();
    super.dispose();
  }
}