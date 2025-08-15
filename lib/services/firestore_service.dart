// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _items => _db.collection('items');
  CollectionReference get _categories => _db.collection('categories');

  // Convert doc -> Map<String,String> matching your UI fields
  Map<String, String> _docToUiMap(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return {
      'id': doc.id,
      'name': (d['name'] ?? '').toString(),
      'quantity': (d['stockQty'] ?? 0).toString(),
      'price': (d['price'] ?? 0).toString(),
      'category': (d['category'] ?? '').toString(),
      'imageUrl': (d['imageUrl'] ?? '').toString(),
      'description': (d['description'] ?? '').toString(),
    };
  }

  // Stream all items (real-time)
  Stream<List<Map<String, String>>> streamItems() {
    return _items.orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => _docToUiMap(d)).toList());
  }

  // Stream items filtered by category (pass category name)
  Stream<List<Map<String, String>>> streamItemsByCategory(String category) {
    return _items.where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => _docToUiMap(d)).toList());
  }

  // Add a new item
  Future<String> addItem({
    required String name,
    required int stockQty,
    required double price,
    required String category,
    String? imageUrl,
    String? description,
  }) async {
    final doc = await _items.add({
      'name': name,
      'stockQty': stockQty,
      'price': price,
      'category': category,
      'imageUrl': imageUrl ?? '',
      'description': description ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // Update item by docId
  Future<void> updateItem({
    required String id,
    String? name,
    int? stockQty,
    double? price,
    String? category,
    String? imageUrl,
    String? description,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (stockQty != null) 'stockQty': stockQty,
      if (price != null) 'price': price,
      if (category != null) 'category': category,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (description != null) 'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _items.doc(id).update(data);
  }

  // Delete item
  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }

  // Adjust stock safely via transaction
  Future<void> adjustStock({
    required String id,
    required int delta, // negative to reduce
    required String reason, // optional reason
  }) async {
    final docRef = _items.doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw Exception('Item not found');
      final current = (snap.data() as Map<String, dynamic>)['stockQty'] ?? 0;
      final newQty = (current as num).toInt() + delta;
      if (newQty < 0) throw Exception('Insufficient stock');
      tx.update(docRef, {'stockQty': newQty, 'updatedAt': FieldValue.serverTimestamp()});
      // optional: add log under items/{id}/stock_moves
      final moveRef = docRef.collection('stock_moves').doc();
      tx.set(moveRef, {
        'delta': delta,
        'reason': reason,
        'at': FieldValue.serverTimestamp(),
      });
    });
  }

  // Categories
  Stream<List<String>> streamCategories() {
    return _categories.orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => (d.data() as Map<String, dynamic>)['name'].toString()).toList());
  }

  Future<void> addCategory(String name) async {
    await _categories.add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
  }
}
