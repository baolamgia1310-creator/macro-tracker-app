// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/services.dart';

// class DatabaseSeeder {
//   static Future seedToFirebase() async {
//     final firestore = FirebaseFirestore.instance;

//     try {
//       // 1. Seed raw foods data
//       final rawString = await rootBundle.loadString('assets/vietnamese_raw_foods.json');
//       final List rawList = jsonDecode(rawString);
      
//       final rawBatch = firestore.batch();
//       for (var item in rawList) {
//         final docRef = firestore.collection('catalog_foods').doc(item['id']);
//         rawBatch.set(docRef, item, SetOptions(merge: true));
//       }
//       await rawBatch.commit();

//       // 2. Seed dishes data
//       final dishString = await rootBundle.loadString('assets/vietnamese_dishes.json');
//       final List dishList = jsonDecode(dishString);

//       final dishBatch = firestore.batch();
//       for (var item in dishList) {
//         final docRef = firestore.collection('catalog_foods').doc(item['id']);
//         dishBatch.set(docRef, item, SetOptions(merge: true));
//       }
//       await dishBatch.commit();
      
//     } catch (e) {
//       // Xử lý lỗi ngầm nếu cần
//     }
//   }
// }