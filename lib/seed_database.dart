import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script tự động tạo toàn bộ dữ liệu mẫu (Seed Data) lên Cloud Firestore
/// cho ứng dụng Macro App[cite: 1, 2].
class FirebaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Hàm chính thực thi toàn bộ tiến trình nạp dữ liệu
  static Future<void> seedAll({String? customUserId}) async {
    print('====================================================');
    print('🚀 [FirebaseSeeder] Bắt đầu khởi tạo dữ liệu Firestore...');

    try {
      // 1. Xác định User ID: lấy user hiện tại đã đăng nhập, hoặc dùng ID demo cố định
      final currentAuthUser = FirebaseAuth.instance.currentUser;
      final String userId = customUserId ?? currentAuthUser?.uid ?? 'demo_user_alex_2026';
      
      print('👤 Target User ID: $userId');

      // 2. Nạp kho dữ liệu thực phẩm toàn cầu (Global foods collection)[cite: 1, 2]
      await _seedGlobalFoods();

      // 3. Nạp thông tin User Profile & Chỉ số Macro Target
      await _seedUserProfile(userId, currentAuthUser?.email);

      // 4. Nạp nhật ký ăn uống theo ngày (daily_logs sub-collection)[cite: 1, 2]
      await _seedDailyLogs(userId);

      // 5. Nạp lịch sử cân nặng phục vụ biểu đồ Analytics (weight_history)[cite: 2, 3]
      await _seedWeightHistory(userId);

      // 6. Nạp thực phẩm tùy chỉnh cá nhân (custom_foods sub-collection)[cite: 3]
      await _seedCustomFoods(userId);

      print('🎉 [FirebaseSeeder] TOÀN BỘ DỮ LIỆU ĐÃ ĐƯỢC TẠO THÀNH CÔNG!');
      print('====================================================');
    } catch (e, stackTrace) {
      print('❌ [FirebaseSeeder] Lỗi khi nạp dữ liệu: $e');
      print(stackTrace);
    }
  }

  // ---------------------------------------------------------------------------
  // 1. KHO THỰC PHẨM CHUẨN TOÀN CẦU (Collection: foods)[cite: 1, 2]
  // ---------------------------------------------------------------------------
  static Future<void> _seedGlobalFoods() async {
    print('📦 [1/5] Đang nạp danh mục thực phẩm toàn cầu (foods/)...');
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
        'searchKeywords': ['egg', 'boiled', 'trung', 'trung ga', 'trung luoc'],
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
        'searchKeywords': ['beef', 'meat', 'thit bo', 'bo ap chao'],
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
        'searchKeywords': ['salmon', 'fish', 'ca hoi', 'ca hoi phi le'],
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
        'searchKeywords': ['oats', 'yen mach', 'oatmeal'],
      },
      {
        'id': 'food_avocado',
        'name': 'Fresh Avocado',
        'category': 'Fruits',
        'servingUnit': '100g',
        'caloriesPer100g': 160.0,
        'proteinPer100g': 2.0,
        'carbsPer100g': 8.5,
        'fatPer100g': 14.7,
        'isVerified': true,
        'searchKeywords': ['avocado', 'bo', 'qua bo'],
      },
      {
        'id': 'food_banana',
        'name': 'Fresh Banana',
        'category': 'Fruits',
        'servingUnit': '100g',
        'caloriesPer100g': 89.0,
        'proteinPer100g': 1.1,
        'carbsPer100g': 23.0,
        'fatPer100g': 0.3,
        'isVerified': true,
        'searchKeywords': ['banana', 'chuoi', 'chuoi tieu'],
      },
      {
        'id': 'food_sweet_potato',
        'name': 'Steamed Sweet Potato',
        'category': 'Veggies',
        'servingUnit': '100g',
        'caloriesPer100g': 86.0,
        'proteinPer100g': 1.6,
        'carbsPer100g': 20.1,
        'fatPer100g': 0.1,
        'isVerified': true,
        'searchKeywords': ['sweet potato', 'potato', 'khoai lang', 'khoai'],
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
      {
        'id': 'food_whey_isolate',
        'name': 'Whey Protein Powder',
        'category': 'Supplement',
        'servingUnit': '100g',
        'caloriesPer100g': 370.0,
        'proteinPer100g': 85.0,
        'carbsPer100g': 3.0,
        'fatPer100g': 1.5,
        'isVerified': true,
        'searchKeywords': ['whey', 'protein', 'isolate', 'sua tang co'],
      },
    ];

    for (final food in globalFoods) {
      final docRef = foodsRef.doc(food['id'] as String);
      batch.set(docRef, food, SetOptions(merge: true));
    }

    await batch.commit();
    print('✅ Đã nạp thành công ${globalFoods.length} thực phẩm chuẩn vào foods/');
  }

  // ---------------------------------------------------------------------------
  // 2. USER PROFILE VÀ MỤC TIÊU MACRO (users/{userId})[cite: 2, 3]
  // ---------------------------------------------------------------------------
  static Future<void> _seedUserProfile(String userId, String? email) async {
    print('👤 [2/5] Đang nạp hồ sơ người dùng (users/$userId)...');
    final userRef = _db.collection('users').doc(userId);

    await userRef.set({
      'uid': userId,
      'email': email ?? 'alex.macro@example.com',
      'displayName': 'Alex Johnson',
      'photoUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'age': 28,
      'gender': 'male',
      'heightCm': 176.0,
      'weightKg': 70.0,
      'activityLevel': 'moderatelyActive',
      'goal': 'weightLoss',
      'bmr': 1680.0,
      'tdee': 2604.0,
      'targetMacros': {
        'targetCalories': 2104.0,
        'targetProteinGrams': 184.0,
        'targetCarbsGrams': 210.0,
        'targetFatGrams': 58.0,
      },
      'settings': {
        'theme': 'dark',
        'unitSystem': 'metric',
        'reminderNotification': true,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Đã nạp thành công User Profile.');
  }

  // ---------------------------------------------------------------------------
  // 3. NHẬT KÝ ĂN UỐNG THEO NGÀY (users/{userId}/daily_logs/{date})[cite: 1, 2]
  // ---------------------------------------------------------------------------
  static Future<void> _seedDailyLogs(String userId) async {
    print('📅 [3/5] Đang nạp nhật ký ăn uống các ngày gần nhất (daily_logs)...');
    final logsRef = _db.collection('users').doc(userId).collection('daily_logs');

    // Dữ liệu ngày 2026-09-06 (Hôm nay - Khớp chuẩn thông số màn hình Dashboard)
    await logsRef.doc('2026-09-06').set({
      'date': '2026-09-06',
      'isTargetReached': false,
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
          'loggedAt': '2026-09-06T07:30:00Z',
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
          'loggedAt': '2026-09-06T07:35:00Z',
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
          'loggedAt': '2026-09-06T12:15:00Z',
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
          'loggedAt': '2026-09-06T12:20:00Z',
        },
        {
          'entryId': 'entry_05',
          'mealType': 'Lunch',
          'foodId': 'food_broccoli',
          'foodName': 'Steamed Broccoli',
          'amountGrams': 150.0,
          'calories': 52.5,
          'protein': 4.2,
          'carbs': 10.5,
          'fat': 0.6,
          'loggedAt': '2026-09-06T12:25:00Z',
        },
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Dữ liệu ngày 2026-09-05 (Hôm qua - Trạng thái hoàn thành mục tiêu)
    await logsRef.doc('2026-09-05').set({
      'date': '2026-09-05',
      'isTargetReached': true,
      'waterMl': 2200,
      'loggedWeightKg': 70.4,
      'totalConsumed': {
        'calories': 2085.0,
        'protein': 180.0,
        'carbs': 205.0,
        'fat': 57.0,
      },
      'meals': [
        {
          'entryId': 'entry_05_01',
          'mealType': 'Breakfast',
          'foodId': 'food_boiled_egg',
          'foodName': 'Boiled Whole Egg',
          'amountGrams': 150.0,
          'calories': 232.5,
          'protein': 19.5,
          'carbs': 1.6,
          'fat': 16.5,
          'loggedAt': '2026-09-05T07:15:00Z',
        },
        {
          'entryId': 'entry_05_02',
          'mealType': 'Lunch',
          'foodId': 'food_beef_lean',
          'foodName': 'Lean Sirloin Beef',
          'amountGrams': 250.0,
          'calories': 500.0,
          'protein': 65.0,
          'carbs': 0.0,
          'fat': 25.0,
          'loggedAt': '2026-09-05T12:30:00Z',
        },
        {
          'entryId': 'entry_05_03',
          'mealType': 'Dinner',
          'foodId': 'food_chicken_breast',
          'foodName': 'Grilled Chicken Breast',
          'amountGrams': 200.0,
          'calories': 330.0,
          'protein': 62.0,
          'carbs': 0.0,
          'fat': 7.2,
          'loggedAt': '2026-09-05T19:00:00Z',
        },
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Đã nạp thành công nhật ký 2 ngày gần nhất.');
  }

  // ---------------------------------------------------------------------------
  // 4. LỊCH SỬ CÂN NẶNG (users/{userId}/weight_history)[cite: 2, 3]
  // ---------------------------------------------------------------------------
  static Future<void> _seedWeightHistory(String userId) async {
    print('📈 [4/5] Đang nạp 7 ngày lịch sử cân nặng phục vụ biểu đồ Analytics...');
    final weightRef = _db.collection('users').doc(userId).collection('weight_history');
    final batch = _db.batch();

    final List<Map<String, dynamic>> weightLogs = [
      {'id': 'rec_2026_08_31', 'date': '2026-08-31', 'weightKg': 71.5},
      {'id': 'rec_2026_09_01', 'date': '2026-09-01', 'weightKg': 71.2},
      {'id': 'rec_2026_09_02', 'date': '2026-09-02', 'weightKg': 71.0},
      {'id': 'rec_2026_09_03', 'date': '2026-09-03', 'weightKg': 70.8},
      {'id': 'rec_2026_09_04', 'date': '2026-09-04', 'weightKg': 70.6},
      {'id': 'rec_2026_09_05', 'date': '2026-09-05', 'weightKg': 70.4},
      {'id': 'rec_2026_09_06', 'date': '2026-09-06', 'weightKg': 70.2},
    ];

    for (final record in weightLogs) {
      final doc = weightRef.doc(record['id'] as String);
      batch.set(doc, {
        ...record,
        'recordedAt': '${record['date']}T07:00:00Z',
      }, SetOptions(merge: true));
    }

    await batch.commit();
    print('✅ Đã nạp thành công 7 mốc cân nặng.');
  }

  // ---------------------------------------------------------------------------
  // 5. THỰC PHẨM CÁ NHÂN (users/{userId}/custom_foods)[cite: 3]
  // ---------------------------------------------------------------------------
  static Future<void> _seedCustomFoods(String userId) async {
    print('🥗 [5/5] Đang nạp thực phẩm tùy chỉnh cá nhân (custom_foods)...');
    final customRef = _db.collection('users').doc(userId).collection('custom_foods');

    await customRef.doc('custom_protein_smoothie').set({
      'id': 'custom_protein_smoothie',
      'name': 'Alex Morning High-Protein Smoothie',
      'servingUnit': '1 Ly (350ml)',
      'calories': 320.0,
      'protein': 32.0,
      'carbs': 35.0,
      'fat': 4.5,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Đã nạp thành công Custom Foods.');
  }
}