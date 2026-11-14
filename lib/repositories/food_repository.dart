import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item.dart';
import '../services/food_api_service.dart';

typedef FoodList = List<FoodItem>;

class FoodRepository {
  final FirebaseFirestore _firestore;
  final FoodApiService _apiService;

  // Bộ nhớ đệm tĩnh (Singleton RAM Cache) dùng chung cho toàn bộ ứng dụng (~1MB RAM)
  static FoodList? _sharedCatalogCache;
  static FoodList? _sharedCustomCache;
  static String? _cachedCustomUid;
  static FoodList? _sharedDefaultApiCache;

  FoodRepository({
    FirebaseFirestore? firestore,
    FoodApiService? apiService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _apiService = apiService ?? FoodApiService();

  bool get hasWarmCache =>
      _sharedCatalogCache != null && _sharedCatalogCache!.isNotEmpty;

  FoodList get cachedCatalog => _sharedCatalogCache ?? [];
  FoodList get cachedCustomFoods => _sharedCustomCache ?? [];
  FoodList get cachedDefaultApiFoods => _sharedDefaultApiCache ?? [];

  Future<FoodList> getCatalogFoods() async {
    if (_sharedCatalogCache != null && _sharedCatalogCache!.isNotEmpty) {
      return _sharedCatalogCache!;
    }

    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('catalog_foods').get();

      _sharedCatalogCache = snapshot.docs.map((doc) {
        final data = doc.data() as Map<dynamic, dynamic>?;
        return FoodItem.fromMap(doc.id, data);
      }).toList();

      return _sharedCatalogCache!;
    } catch (_) {
      return [];
    }
  }

  // Lọc trực tiếp trên RAM ở mức 0ms khi cache đã ấm
  FoodList filterCachedCatalogSync(String query) {
    final FoodList catalog = _sharedCatalogCache ?? [];
    final String cleanQuery = removeAccents(query.trim().toLowerCase());
    if (cleanQuery.isEmpty) return catalog;

    return catalog.where((item) {
      return item.nameUnsigned.contains(cleanQuery) ||
          item.name.toLowerCase().contains(cleanQuery);
    }).toList();
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
    final isDefaultFirstPage =
        (query.trim().toLowerCase() == 'chicken') && pageNumber == 1;

    if (isDefaultFirstPage &&
        _sharedDefaultApiCache != null &&
        _sharedDefaultApiCache!.isNotEmpty) {
      return _sharedDefaultApiCache!;
    }

    final results = await _apiService.searchExternalFoods(
      query,
      pageSize: pageSize,
      pageNumber: pageNumber,
    );

    if (isDefaultFirstPage && results.isNotEmpty) {
      _sharedDefaultApiCache = results;
    }

    return results;
  }

  Future<FoodList> getUserCustomFoods(
    String uid, {
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return [];
    if (!forceRefresh &&
        _cachedCustomUid == uid &&
        _sharedCustomCache != null) {
      return _sharedCustomCache!;
    }

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('custom_foods')
          .get();

      _sharedCustomCache = snapshot.docs.map((doc) {
        final data = doc.data() as Map<dynamic, dynamic>?;
        return FoodItem.fromMap(doc.id, data);
      }).toList();
      _cachedCustomUid = uid;

      return _sharedCustomCache!;
    } catch (_) {
      return _sharedCustomCache ?? [];
    }
  }

  Future<void> createCustomFood({
    required String uid,
    required FoodItem food,
  }) async {
    if (uid.isEmpty) return;
    _sharedCustomCache = [
      food,
      ...(_sharedCustomCache ?? []).where((f) => f.id != food.id),
    ];
    _cachedCustomUid = uid;

    // Đóng gói trực tiếp Map<String, dynamic> để tránh lỗi kiểu trả về của food.toMap()
    final foodData = <String, dynamic>{
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
    _sharedCustomCache =
        (_sharedCustomCache ?? []).where((f) => f.id != foodId).toList();

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('custom_foods')
        .doc(foodId)
        .delete();
  }

  // Ghi không chặn luồng UI (Optimistic Local Persistence)
  Future<void> logFoodToMeal({
    required String uid,
    required String mealType,
    required FoodItem food,
    required double amount,
  }) async {
    final double factor =
        food.servingType == 'serving' ? amount : (amount / 100.0);

    final logData = <String, dynamic>{
      'foodId': food.id,
      'name': food.name,
      'servingType': food.servingType,
      'unitName': food.unitName,
      'amount': amount,
      'grams': food.servingType == 'serving' ? (amount * 100.0) : amount,
      'calories': (food.calories * factor).round(),
      'protein': double.parse((food.protein * factor).toStringAsFixed(1)),
      'carbs': double.parse((food.carbs * factor).toStringAsFixed(1)),
      'fat': double.parse((food.fat * factor).toStringAsFixed(1)),
      'mealType': mealType,
      'loggedAt': FieldValue.serverTimestamp(),
    };

    _firestore
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