import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getSchemes() async {
    final snapshot = await _db.collection('schemes').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}