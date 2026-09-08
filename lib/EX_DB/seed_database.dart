import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script tự động nạp toàn bộ dữ liệu mẫu lên Cloud Firestore
/// theo đúng kiến trúc đã chốt cho Macro App.
class FirebaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedAll({String? customUserId}) async {
    print('====================================================');
    print('🚀 [FirebaseSeeder] Bắt đầu khởi tạo dữ liệu mẫu lên Firestore...');

    try {
      // Xác định userId: lấy user hiện đang đăng nhập hoặc ID demo dự phòng
      final currentAuthUser = FirebaseAuth.instance.currentUser;
      final String userId = customUserId ?? currentAuthUser?.uid ?? 'demo_user_alex_2026';
      print('👤 Đang nạp cho User UID: $userId');

      // 1. Tạo kho thực phẩm toàn cầu (Global Foods)
      await _seedGlobalFoods();

      // 2. Tạo User Profile & Macro Target
      await _seedUserProfile(userId, currentAuthUser?.email);

      // 3. Tạo Daily Logs (Khớp chuẩn số liệu Dashboard UI)
      await _seedDailyLogs(userId);

      // 4. Tạo Lịch sử cân nặng (Weight History cho Analytics)
      await _seedWeightHistory(userId);

      print('🎉 [FirebaseSeeder] NẠP DỮ LIỆU HOÀN TẤT THÀNH CÔNG!');
      print('====================================================');
    } catch (e, stackTrace) {
      print('❌ [FirebaseSeeder] Lỗi trong quá trình nạp: $e');
      print(stackTrace);
    }
  }

  // 1. Collection toàn cầu: foods/
  static Future<void> _seedGlobalFoods() async {
    print('📦 [1/4] Đang nạp danh mục thực phẩm toàn cầu (foods/)...');
    final foodsRef = _db.collection('foods');
    final batch = _db.batch();

    final List<Map<String, dynamic>> globalFoods = [
      {
        'id': 'food_chicken_breast',
        'name': 'Grilled Chicken Breast',
        'category': 'Meat',
        'servingUnit': '100g',
        'caloriesPer100g': 165.0,
        'proteinPer100g': 31.0,
        'carbsPer100g': 0.0,
        'fatPer100g': 3.6,
        'isVerified': true,
        'searchKeywords': ['chicken', 'grilled', 'breast', 'uc ga', 'thit ga'],
      },
      {
        'id': 'food_brown_rice',
        'name': 'Brown Rice (Cooked)',
        'category': 'Grains',
        'servingUnit': '100g',
        'caloriesPer100g': 110.0,
        'proteinPer100g': 2.6,
        'carbsPer100g': 23.0,
        'fatPer100g': 0.9,
        'isVerified': true,
        'searchKeywords': ['rice', 'brown', 'gao lut', 'com gao lut'],
      },
      {
        'id': 'food_white_rice',
        'name': 'White Rice (Cooked)',
        'category': 'Grains',
        'servingUnit': '100g',
        'caloriesPer100g': 130.0,
        'proteinPer100g': 2.7,
        'carbsPer100g': 28.0,
        'fatPer100g': 0.3,
        'isVerified': true,
        'searchKeywords': ['rice', 'white', 'com trang', 'gao trang'],
      },
      {
        'id': 'food_boiled_egg',
        'name': 'Boiled Whole Egg',
        'category': 'Eggs',
        'servingUnit': '100g',
        'caloriesPer100g': 155.0,
        'proteinPer100g': 13.0,
        'carbsPer100g': 1.1,
        'fatPer100g': 11.0,
        'isVerified': true,
        'searchKeywords': ['egg', 'boiled', 'trung ga', 'trung luoc'],
      },
      {
        'id': 'food_beef_lean',
        'name': 'Lean Sirloin Beef',
        'category': 'Meat',
        'servingUnit': '100g',
        'caloriesPer100g': 200.0,
        'proteinPer100g': 26.0,
        'carbsPer100g': 0.0,
        'fatPer100g': 10.0,
        'isVerified': true,
        'searchKeywords': ['beef', 'thit bo', 'bo ap chao'],
      },
      {
        'id': 'food_salmon',
        'name': 'Fresh Atlantic Salmon',
        'category': 'Fish',
        'servingUnit': '100g',
        'caloriesPer100g': 208.0,
        'proteinPer100g': 20.0,
        'carbsPer100g': 0.0,
        'fatPer100g': 13.0,
        'isVerified': true,
        'searchKeywords': ['salmon', 'ca hoi'],
      },
      {
        'id': 'food_rolled_oats',
        'name': 'Rolled Oats (Dry)',
        'category': 'Grains',
        'servingUnit': '100g',
        'caloriesPer100g': 389.0,
        'proteinPer100g': 16.9,
        'carbsPer100g': 66.3,
        'fatPer100g': 6.9,
        'isVerified': true,
        'searchKeywords': ['oats', 'yen mach'],
      },
      {
        'id': 'food_broccoli',
        'name': 'Steamed Broccoli',
        'category': 'Veggies',
        'servingUnit': '100g',
        'caloriesPer100g': 35.0,
        'proteinPer100g': 2.8,
        'carbsPer100g': 7.0,
        'fatPer100g': 0.4,
        'isVerified': true,
        'searchKeywords': ['broccoli', 'sup lo', 'bong cai xanh'],
      },
    ];

    for (final food in globalFoods) {
      final docRef = foodsRef.doc(food['id'] as String);
      batch.set(docRef, food, SetOptions(merge: true));
    }

    await batch.commit();
    print('✅ Đã nạp thành công ${globalFoods.length} thực phẩm chuẩn vào foods/');
  }

  // 2. Collection cá nhân: users/{userId}
  static Future<void> _seedUserProfile(String userId, String? email) async {
    print('👤 [2/4] Đang nạp hồ sơ người dùng (users/$userId)...');
    final userRef = _db.collection('users').doc(userId);

    await userRef.set({
      'uid': userId,
      'email': email ?? 'alex.macro@example.com',
      'displayName': 'Alex Johnson',
      'age': 28,
      'gender': 'male',
      'heightCm': 176.0,
      'weightKg': 70.0,
      'activityLevel': 'moderatelyActive',
      'goal': 'weightLoss',
      'bmr': 1680.0,
      'tdee': 2604.0,
      'targetMacros': {
        'targetCalories': 2200.0,
        'targetProteinGrams': 140.0,
        'targetCarbsGrams': 198.0,
        'targetFatGrams': 73.0,
      },
      'settings': {
        'theme': 'dark',
        'unitSystem': 'metric',
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Đã nạp User Profile & Target Macros thành công.');
  }

  // 3. Sub-collection: users/{userId}/daily_logs/{date}
  static Future<void> _seedDailyLogs(String userId) async {
    print('📅 [3/4] Đang nạp nhật ký ăn uống khớp giao diện Dashboard...');
    final logsRef = _db.collection('users').doc(userId).collection('daily_logs');

    // Dữ liệu ngày hôm nay: Khớp thông số 1,420 kcal / 92g P / 126g C / 41g F
    await logsRef.doc('2026-09-08').set({
      'date': '2026-09-08',
      'waterMl': 1750,
      'loggedWeightKg': 70.2,
      'totalConsumed': {
        'calories': 1420.0,
        'protein': 92.0,
        'carbs': 126.0,
        'fat': 41.0,
      },
      'meals': [
        {
          'entryId': 'entry_01',
          'mealType': 'Breakfast',
          'foodId': 'food_chicken_breast',
          'foodName': 'Grilled Chicken Breast',
          'amountGrams': 150.0,
          'calories': 247.5,
          'protein': 46.5,
          'carbs': 0.0,
          'fat': 5.4,
          'isCustom': false,
          'loggedAt': '2026-09-08T07:30:00Z',
        },
        {
          'entryId': 'entry_02',
          'mealType': 'Breakfast',
          'foodId': 'food_rolled_oats',
          'foodName': 'Rolled Oats (Dry)',
          'amountGrams': 50.0,
          'calories': 194.5,
          'protein': 8.4,
          'carbs': 33.1,
          'fat': 3.4,
          'isCustom': false,
          'loggedAt': '2026-09-08T07:35:00Z',
        },
        {
          'entryId': 'entry_03',
          'mealType': 'Lunch',
          'foodId': 'food_brown_rice',
          'foodName': 'Brown Rice (Cooked)',
          'amountGrams': 200.0,
          'calories': 220.0,
          'protein': 5.2,
          'carbs': 46.0,
          'fat': 1.8,
          'isCustom': false,
          'loggedAt': '2026-09-08T12:15:00Z',
        },
        {
          'entryId': 'entry_04',
          'mealType': 'Lunch',
          'foodId': 'food_salmon',
          'foodName': 'Fresh Atlantic Salmon',
          'amountGrams': 150.0,
          'calories': 312.0,
          'protein': 30.0,
          'carbs': 0.0,
          'fat': 19.5,
          'isCustom': false,
          'loggedAt': '2026-09-08T12:20:00Z',
        },
        // Mẫu món ăn Custom được log (Không chứa URL ảnh, chỉ lưu định lượng)
        {
          'entryId': 'entry_05',
          'mealType': 'Lunch',
          'foodId': 'custom_pho_bo_123',
          'foodName': 'Phở bò nhà nấu',
          'amountGrams': 300.0,
          'calories': 446.0,
          'protein': 1.9,
          'carbs': 46.9,
          'fat': 10.9,
          'isCustom': true,
          'loggedAt': '2026-09-08T12:25:00Z',
        },
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Đã nạp thành công Daily Logs.');
  }

  // 4. Sub-collection: users/{userId}/weight_history/{recordId}
  static Future<void> _seedWeightHistory(String userId) async {
    print('📈 [4/4] Đang nạp lịch sử cân nặng phục vụ biểu đồ fl_chart...');
    final weightRef = _db.collection('users').doc(userId).collection('weight_history');
    final batch = _db.batch();

    final List<Map<String, dynamic>> weights = [
      {'id': 'rec_2026_09_02', 'date': '2026-09-02', 'weightKg': 71.0},
      {'id': 'rec_2026_09_03', 'date': '2026-09-03', 'weightKg': 70.8},
      {'id': 'rec_2026_09_04', 'date': '2026-09-04', 'weightKg': 70.6},
      {'id': 'rec_2026_09_05', 'date': '2026-09-05', 'weightKg': 70.5},
      {'id': 'rec_2026_09_06', 'date': '2026-09-06', 'weightKg': 70.4},
      {'id': 'rec_2026_09_07', 'date': '2026-09-07', 'weightKg': 70.3},
      {'id': 'rec_2026_09_08', 'date': '2026-09-08', 'weightKg': 70.2},
    ];

    for (final w in weights) {
      final doc = weightRef.doc(w['id'] as String);
      batch.set(doc, {
        ...w,
        'recordedAt': '${w['date']}T07:00:00Z',
      }, SetOptions(merge: true));
    }

    await batch.commit();
    print('✅ Đã nạp thành công 7 mốc cân nặng.');
  }
}