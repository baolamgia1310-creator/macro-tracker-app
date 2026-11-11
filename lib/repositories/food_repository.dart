import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item.dart';
import '../services/food_api_service.dart';

class FoodRepository {
  final FirebaseFirestore _firestore;
  final FoodApiService _apiService;

  FoodRepository({
    FirebaseFirestore? firestore,
    FoodApiService? apiService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _apiService = apiService ?? FoodApiService();

  // 1. Gọi API USDA bên ngoài
  Future<List<FoodItem>> searchRemoteApi(String query) async {
    return await _apiService.searchExternalFoods(query);
  }

  // 2. Lấy danh sách món tự tạo riêng biệt của User ID hiện tại
  Future<List<FoodItem>> getUserCustomFoods(String uid) async {
    if (uid.isEmpty) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('custom_foods')
        .get();

    return snapshot.docs
        .map((doc) => FoodItem.fromMap(doc.id, doc.data()))
        .toList();
  }

  // 3. Tạo món ăn thủ công lưu trong sub-collection của user
  Future<void> createCustomFood({
    required String uid,
    required FoodItem food,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('custom_foods')
        .doc(food.id)
        .set(food.toMap(), SetOptions(merge: true));
  }

  // 4. Ghi nhật ký bữa ăn vào daily_logs của User
  Future<void> logFoodToMeal({
    required String uid,
    required String mealType,
    required FoodItem food,
    required double grams,
  }) async {
    final factor = grams / 100.0;
    final logData = {
      'foodId': food.id,
      'name': food.name,
      'grams': grams,
      'calories': (food.caloriesPer100g * factor).round(),
      'protein': double.parse((food.proteinPer100g * factor).toStringAsFixed(1)),
      'carbs': double.parse((food.carbsPer100g * factor).toStringAsFixed(1)),
      'fat': double.parse((food.fatPer100g * factor).toStringAsFixed(1)),
      'mealType': mealType,
      'loggedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .add(logData);
  }
}