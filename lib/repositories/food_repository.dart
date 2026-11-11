import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item.dart';
import '../services/food_api_service.dart';

typedef FoodList = List;

class FoodRepository {
  final FirebaseFirestore _firestore;
  final FoodApiService _apiService;

  FoodList? _cachedCatalog;

  FoodRepository({
    FirebaseFirestore? firestore,
    FoodApiService? apiService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _apiService = apiService ?? FoodApiService();

  Future getCatalogFoods() async {
    if (_cachedCatalog != null) return _cachedCatalog!;

    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('catalog_foods').get();

      _cachedCatalog = snapshot.docs.map((doc) {
        final data = doc.data() as Map?;
        return FoodItem.fromMap(doc.id, data);
      }).toList();

      return _cachedCatalog!;
    } catch (_) {
      return [];
    }
  }

  Future searchLocalCatalog(String query) async {
    final FoodList catalog = await getCatalogFoods();
    final String cleanQuery = _removeAccents(query.trim().toLowerCase());

    if (cleanQuery.isEmpty) return catalog.take(40).toList();

    return catalog.where((item) {
      return item.nameUnsigned.contains(cleanQuery) ||
          item.name.toLowerCase().contains(cleanQuery);
    }).toList();
  }

  Future searchRemoteApi(String query) async {
    return await _apiService.searchExternalFoods(query);
  }

  Future getUserCustomFoods(String uid) async {
    if (uid.isEmpty) return [];
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('custom_foods')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map?;
        return FoodItem.fromMap(doc.id, data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future logFoodToMeal({
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

  static String _removeAccents(String str) {
    var result = str;
    const accents = [
      'aàảãáạăằẳẵắặâầẩẫấậ',
      'AÀẢÃÁẠĂẰẲẴẮẶÂẦẨẪẤẬ',
      'dđ', 'DĐ',
      'eèẻẽéẹêềểễếệ',
      'EÈẺẼÉẸÊỀỂỄẾỆ',
      'iìỉĩíị', 'IÌỈĨÍỊ',
      'oòỏõóọôồổỗốộơờởỡớợ',
      'OÒỎÕÓỌÔỒỔỖỐỘƠỜỞỠỚỢ',
      'uùủũúụưừửữứự',
      'UÙỦŨÚỤƯỪỬỮỨỰ',
      'yỳỷỹýỵ', 'YỲỶỸÝỴ'
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