import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item.dart';
import '../services/food_api_service.dart';

typedef FoodList = List<FoodItem>;

class FoodRepository {
  final FirebaseFirestore _firestore;
  final FoodApiService _apiService;

  FoodList? _cachedCatalog;

  FoodRepository({
    FirebaseFirestore? firestore,
    FoodApiService? apiService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _apiService = apiService ?? FoodApiService();

  Future<FoodList> getCatalogFoods() async {
    if (_cachedCatalog != null && _cachedCatalog!.isNotEmpty) {
      return _cachedCatalog!;
    }

    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('catalog_foods').get();

      _cachedCatalog = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return FoodItem.fromMap(doc.id, data);
      }).toList();

      return _cachedCatalog!;
    } catch (_) {
      return [];
    }
  }

  Future<FoodList> searchLocalCatalog(String query) async {
    final FoodList catalog = await getCatalogFoods();
    final String cleanQuery = removeAccents(query.trim().toLowerCase());

    if (cleanQuery.isEmpty) {
      return catalog;
    }

    return catalog.where((item) {
      return item.nameUnsigned.contains(cleanQuery) ||
          item.name.toLowerCase().contains(cleanQuery);
    }).toList();
  }

  Future<FoodList> searchRemoteApi(
    String query, {
    int pageSize = 10,
    int pageNumber = 1,
  }) async {
    return await _apiService.searchExternalFoods(
      query,
      pageSize: pageSize,
      pageNumber: pageNumber,
    );
  }

  Future<FoodList> getUserCustomFoods(String uid) async {
    if (uid.isEmpty) return [];
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('custom_foods')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return FoodItem.fromMap(doc.id, data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Lưu món ăn do người dùng tự tạo lên Firebase
  Future<void> createCustomFood({
    required String uid,
    required FoodItem food,
  }) async {
    if (uid.isEmpty) return;

    final foodData = {
      'id': food.id,
      'name': food.name,
      'name_unsigned': food.nameUnsigned,
      'category': food.category,
      'serving_type': food.servingType,
      'unit_name': food.unitName,
      'calories': food.calories,
      'protein': food.protein,
      'carbs': food.carbs,
      'fat': food.fat,
    };

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('custom_foods')
        .doc(food.id)
        .set(foodData, SetOptions(merge: true));
  }

  Future<void> deleteCustomFood({
    required String uid,
    required String foodId,
  }) async {
    if (uid.isEmpty || foodId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('custom_foods')
        .doc(foodId)
        .delete();
  }
  
  Future<void> logFoodToMeal({
    required String uid,
    required String mealType,
    required FoodItem food,
    required double amount,
  }) async {
    final double factor =
        food.servingType == 'serving' ? amount : (amount / 100.0);

    final logData = {
      'foodId': food.id,
      'name': food.name,
      'servingType': food.servingType,
      'unitName': food.unitName,
      'amount': amount,
      'calories': (food.calories * factor).round(),
      'protein': double.parse((food.protein * factor).toStringAsFixed(1)),
      'carbs': double.parse((food.carbs * factor).toStringAsFixed(1)),
      'fat': double.parse((food.fat * factor).toStringAsFixed(1)),
      'mealType': mealType,
      'loggedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .add(logData);
  }

  static String removeAccents(String str) {
    var result = str;
    const accents = [
      'aàảãáạăằẳẵắặâầẩẫấậ',
      'AÀẢÃÁẠĂẰẲẴẮẶÂẦẨẪẤẬ',
      'dđ',
      'DĐ',
      'eèẻẽéẹêềểễếệ',
      'EÈẺẼÉẸÊỀỂỄẾỆ',
      'iìỉĩíị',
      'IÌỈĨÍỊ',
      'oòỏõóọôồổỗốộơờởỡớợ',
      'OÒỎÕÓỌÔỒỔỖỐỘƠỜỞỠỚỢ',
      'uùủũúụưừửữứự',
      'UÙỦŨÚỤƯỪỬỮỨỰ',
      'yỳỷỹýỵ',
      'YỲỶỸÝỴ'
    ];
    for (var group in accents) {
      final baseChar = group[0];
      for (var i = 1; i < group.length; i++) {
        result = result.replaceAll(group[i], baseChar);
      }
    }
    return result;
  }
}