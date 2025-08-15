// lib/services/firestore_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  CollectionReference get _items => _db.collection('items');
  CollectionReference get _categories => _db.collection('categories');

  // ---- Helpers: convert doc -> UI map (your UI uses Map<String,String>)
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

  // ---------- Streams ----------
  Stream<List<Map<String, String>>> streamItems() {
    return _items.orderBy('name').snapshots().map(
        (snap) => snap.docs.map((d) => _docToUiMap(d)).toList());
  }

  Stream<List<Map<String, String>>> streamItemsByCategory(String category) {
    return _items
        .where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => _docToUiMap(d)).toList());
  }

  Stream<List<String>> streamCategories() {
    return _categories.orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => (d.data() as Map<String, dynamic>)['name'].toString()).toList());
  }

  // ---------- CRUD ----------
  Future<String> addItem({
    required String name,
    required int stockQty,
    required double price,
    required String category,
    String? imageUrl,
    String? description,
  }) async {
    final now = FieldValue.serverTimestamp();
    final doc = await _items.add({
      'name': name,
      'stockQty': stockQty,
      'price': price,
      'category': category,
      'imageUrl': imageUrl ?? '',
      'description': description ?? '',
      'createdAt': now,
      'updatedAt': now,
    });
    return doc.id;
  }

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

  Future<void> deleteItem(String id) async {
    // optional: delete subcollections like stock_moves if used
    await _items.doc(id).delete();
  }

  // ---------- Stock adjustment (transactional) ----------
  Future<void> adjustStock({
    required String id,
    required int delta,
    required String reason,
  }) async {
    final docRef = _items.doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw Exception('Item not found');
      final data = snap.data() as Map<String, dynamic>;
      final current = (data['stockQty'] ?? 0) as num;
      final newQty = current.toInt() + delta;
      if (newQty < 0) throw Exception('Insufficient stock');
      tx.update(docRef, {'stockQty': newQty, 'updatedAt': FieldValue.serverTimestamp()});
      final moveRef = docRef.collection('stock_moves').doc();
      tx.set(moveRef, {
        'delta': delta,
        'reason': reason,
        'at': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------- Storage: upload and delete images ----------
  /// Upload a File (mobile) to `item_images/` and return the download URL.
  Future<String> uploadItemImage(File file, {String? fileName}) async {
    final ext = file.path.split('.').last;
    final name = fileName ?? '${_uuid.v4()}.$ext';
    final ref = _storage.ref().child('item_images').child(name);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Delete image from storage given its download URL (ignore if not found)
  Future<void> deleteItemImageByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // ignore or log
    }
  }

  // ---------- Categories ----------
  Future<String> addCategory(String name) async {
    final doc = await _categories.add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
    return doc.id;
  }

  Future<void> updateCategory(String id, String name) async {
    await _categories.doc(id).update({'name': name});
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }
}
