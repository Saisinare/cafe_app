// lib/services/firestore_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/sales.dart';
import '../models/money_in.dart';
import '../models/money_out.dart';
import '../models/purchase.dart';
import '../models/premium_subscription.dart';
import '../models/expense.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  CollectionReference get _items => _db.collection('items');
  CollectionReference get _categories => _db.collection('categories');
  CollectionReference get _sales => _db.collection('sales');
  CollectionReference get _moneyIn => _db.collection('money_in');
  CollectionReference get _moneyOut => _db.collection('money_out');
  CollectionReference get _purchases => _db.collection('purchases');
  CollectionReference get _premiumSubscriptions => _db.collection('premium_subscriptions');
  // Removed: sales invoices collection
  CollectionReference get _expenses => _db.collection('expenses');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ---- Helpers: convert doc -> UI map (your UI uses Map<String,String>)
  Map<String, String> _docToUiMap(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return {
      'id': doc.id,
      'name': (d['name'] ?? '').toString(),
      'quantity': (d['stockQty'] ?? 0).toString(),
      'price': (d['price'] ?? 0).toString(),
      'category': (d['category'] ?? '').toString(),
      'unit': (d['unit'] ?? '').toString(),
      'imageUrl': (d['imageUrl'] ?? '').toString(),
      'description': (d['description'] ?? '').toString(),
    };
  }

  // ---------- Premium Subscription Methods ----------
  Future<String> createPremiumSubscription(PremiumSubscription subscription) async {
    final doc = await _premiumSubscriptions.add(subscription.toMap());
    return doc.id;
  }

  Future<void> updatePremiumSubscriptionStatus({
    required String subscriptionId,
    required String paymentStatus,
    String? razorpayPaymentId,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{
      'paymentStatus': paymentStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (razorpayPaymentId != null) {
      data['razorpayPaymentId'] = razorpayPaymentId;
    }
    
    if (isActive != null) {
      data['isActive'] = isActive;
    }
    
    await _premiumSubscriptions.doc(subscriptionId).update(data);
  }

  Stream<PremiumSubscription?> streamCurrentUserSubscription() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(null);
    
    return _premiumSubscriptions
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          
          final doc = snap.docs.first;
          final subscription = PremiumSubscription.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          
          // Check if subscription is still valid
          if (subscription.isExpired) {
            // Mark as inactive if expired
            updatePremiumSubscriptionStatus(
              subscriptionId: doc.id,
              paymentStatus: 'expired',
              isActive: false,
            );
            return null;
          }
          
          return subscription;
        });
  }

  // Get user data for business information
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Removed deleteSalesInvoice as invoices feature is deprecated

  // ---------- Streams ----------
  Stream<List<Map<String, String>>> streamItems() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _items
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map((d) => _docToUiMap(d)).toList();
          // Sort in memory to avoid composite index requirement
          items.sort((a, b) => a['name']!.compareTo(b['name']!));
          return items;
        });
  }

  Stream<List<Map<String, String>>> streamItemsByCategory(String category) {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _items
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map((d) => _docToUiMap(d)).toList();
          // Sort in memory to avoid composite index requirement
          items.sort((a, b) => a['name']!.compareTo(b['name']!));
          return items;
        });
  }

  Stream<List<String>> streamCategories() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _categories
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final categories = snap.docs
              .map((d) => (d.data() as Map<String, dynamic>)['name'].toString())
              .toList();
          // Sort in memory to avoid requiring a composite index
          categories.sort();
          return categories;
        });
  }

  // ---------- Sales Streams ----------
  Stream<List<SalesTransaction>> streamSales() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _sales
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final transactions = snap.docs
              .map((d) => SalesTransaction.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();
          
          // Sort by createdAt descending (most recent first)
          transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return transactions;
        });
  }

  // ---------- Money In Streams ----------
  Stream<List<MoneyInEntry>> streamMoneyIn() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _moneyIn
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final entries = snap.docs
              .map((d) => MoneyInEntry.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();
          entries.sort((a, b) => b.moneyInDate.compareTo(a.moneyInDate));
          return entries;
        });
  }

  // ---------- Money Out Streams ----------
  Stream<List<MoneyOutEntry>> streamMoneyOut() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _moneyOut
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final entries = snap.docs
              .map((d) => MoneyOutEntry.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();
          entries.sort((a, b) => b.moneyOutDate.compareTo(a.moneyOutDate));
          return entries;
        });
  }

  // ---------- Purchases Streams ----------
  Stream<List<PurchaseOrder>> streamPurchases() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _purchases
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final orders = snap.docs
              .map((d) => PurchaseOrder.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  // ---------- Expenses Stream ----------
  Stream<List<ExpenseEntry>> streamExpenses() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _expenses
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final entries = snap.docs
              .map((d) => ExpenseEntry.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();
          entries.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
          return entries;
        });
  }

  // ---------- CRUD ----------
  Future<String> addItem({
    required String name,
    required int stockQty,
    required double price,
    required String category,
    String? unit,
    String? imageUrl,
    String? description,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    final now = FieldValue.serverTimestamp();
    final doc = await _items.add({
      'userId': userId, // Add user ID to ensure data isolation
      'name': name,
      'stockQty': stockQty,
      'price': price,
      'category': category,
      'unit': unit ?? 'Pieces',
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
    String? unit,
    String? imageUrl,
    String? description,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    // First verify the item belongs to the current user
    final doc = await _items.doc(id).get();
    if (!doc.exists) throw Exception('Item not found');
    
    final itemData = doc.data() as Map<String, dynamic>;
    if (itemData['userId'] != userId) {
      throw Exception('You can only update your own items');
    }
    
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (stockQty != null) 'stockQty': stockQty,
      if (price != null) 'price': price,
      if (category != null) 'category': category,
      if (unit != null) 'unit': unit,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (description != null) 'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _items.doc(id).update(data);
  }

  Future<void> deleteItem(String id) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    // First verify the item belongs to the current user
    final doc = await _items.doc(id).get();
    if (!doc.exists) throw Exception('Item not found');
    
    final itemData = doc.data() as Map<String, dynamic>;
    if (itemData['userId'] != userId) {
      throw Exception('You can only delete your own items');
    }
    
    // optional: delete subcollections like stock_moves if used
    await _items.doc(id).delete();
  }

  // ---------- Sales CRUD ----------
  Future<String> createSalesTransaction(SalesTransaction transaction) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Create the sales transaction
    final doc = await _sales.add(transaction.toMap());
    
    // Update stock quantities for all items in the sale
    for (final item in transaction.items) {
      await adjustStock(
        id: item.itemId,
        delta: -item.quantity,
        reason: 'sale_${doc.id}',
      );
    }
    
    return doc.id;
  }

  Future<List<SalesTransaction>> getSalesTransactions() async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    final snapshot = await _sales
        .where('userId', isEqualTo: userId)
        .get();
    
    final transactions = snapshot.docs
        .map((d) => SalesTransaction.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
    
    // Sort by createdAt descending (most recent first)
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transactions;
  }

  Future<SalesTransaction?> getSalesTransaction(String id) async {
    final doc = await _sales.doc(id).get();
    if (!doc.exists) return null;
    
    return SalesTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<void> deleteSalesTransaction(String id) async {
    final transaction = await getSalesTransaction(id);
    if (transaction == null) return;
    
    // Restore stock quantities
    for (final item in transaction.items) {
      await adjustStock(
        id: item.itemId,
        delta: item.quantity,
        reason: 'sale_cancellation_$id',
      );
    }
    
    await _sales.doc(id).delete();
  }

  // ---------- Money In CRUD ----------
  Future<String> createMoneyInEntry(MoneyInEntry entry) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    final data = entry.toMap();
    data['userId'] = userId; // enforce current user
    final doc = await _moneyIn.add(data);
    return doc.id;
  }

  // ---------- Money Out CRUD ----------
  Future<String> createMoneyOutEntry(MoneyOutEntry entry) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    final data = entry.toMap();
    data['userId'] = userId; // enforce current user
    final doc = await _moneyOut.add(data);
    return doc.id;
  }

  // ---------- Purchases CRUD ----------
  Future<String> createPurchaseOrder(PurchaseOrder order) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final doc = await _purchases.add(order.toMap());

    // Increase stock for each purchased item
    for (final item in order.items) {
      await adjustStock(
        id: item.itemId,
        delta: item.quantity,
        reason: 'purchase_${doc.id}',
      );
    }

    return doc.id;
  }

  // ---------- Expenses CRUD ----------
  Future<String> createExpenseEntry(ExpenseEntry entry) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    final data = entry.toMap();
    data['userId'] = userId; // enforce current user
    final doc = await _expenses.add(data);
    return doc.id;
  }

  // ---------- Stock adjustment (transactional) ----------
  Future<void> adjustStock({
    required String id,
    required int delta,
    required String reason,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    final docRef = _items.doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw Exception('Item not found');
      
      final data = snap.data() as Map<String, dynamic>;
      
      // Verify the item belongs to the current user
      if (data['userId'] != userId) {
        throw Exception('You can only adjust stock for your own items');
      }
      
      final current = (data['stockQty'] ?? 0) as num;
      final newQty = current.toInt() + delta;
      if (newQty < 0) throw Exception('Insufficient stock');
      
      tx.update(docRef, {'stockQty': newQty, 'updatedAt': FieldValue.serverTimestamp()});
      final moveRef = docRef.collection('stock_moves').doc();
      tx.set(moveRef, {
        'userId': userId, // Add user ID to stock moves
        'delta': delta,
        'reason': reason,
        'at': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------- Storage: upload and delete images ----------
  /// Upload a File (mobile) to `item_images/` and return the download URL.
  Future<String> uploadItemImage(File file, {String? fileName}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final ext = file.path.split('.').last.toLowerCase();
    final name = fileName ?? '${_uuid.v4()}.$ext';

    // Best-effort content type
    String? contentType;
    if (ext == 'jpg' || ext == 'jpeg') contentType = 'image/jpeg';
    if (ext == 'png') contentType = 'image/png';
    if (ext == 'gif') contentType = 'image/gif';
    final metadata = contentType != null ? SettableMetadata(contentType: contentType) : null;

    // Try user-scoped path first
    final primaryRef = _storage.ref().child('users').child(userId).child('item_images').child(name);
    try {
      await primaryRef.putFile(file, metadata);
      return await primaryRef.getDownloadURL();
    } on FirebaseException catch (_) {
      // Fallback to legacy/global path if rules block user-scoped path
      final fallbackRef = _storage.ref().child('item_images').child(name);
      await fallbackRef.putFile(file, metadata);
      return await fallbackRef.getDownloadURL();
    }
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
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    final doc = await _categories.add({
      'userId': userId, // Add user ID to ensure data isolation
      'name': name, 
      'createdAt': FieldValue.serverTimestamp()
    });
    return doc.id;
  }

  Future<void> updateCategory(String id, String name) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    // First verify the category belongs to the current user
    final doc = await _categories.doc(id).get();
    if (!doc.exists) throw Exception('Category not found');
    
    final categoryData = doc.data() as Map<String, dynamic>;
    if (categoryData['userId'] != userId) {
      throw Exception('You can only update your own categories');
    }
    
    await _categories.doc(id).update({'name': name});
  }

  Future<void> deleteCategory(String id) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    
    // First verify the category belongs to the current user
    final doc = await _categories.doc(id).get();
    if (!doc.exists) throw Exception('Category not found');
    
    final categoryData = doc.data() as Map<String, dynamic>;
    if (categoryData['userId'] != userId) {
      throw Exception('You can only delete your own categories');
    }
    
    await _categories.doc(id).delete();
  }

  // ---------- Analytics & Insights Methods ----------
  
  /// Get total sales amount for the current month
  Stream<double> streamMonthlySales() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(0.0);
    
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return _sales
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          double total = 0.0;
          for (final doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            
            // Filter by date in memory to avoid composite index requirement
            if (createdAt != null && 
                createdAt.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                createdAt.isBefore(endOfMonth.add(const Duration(days: 1)))) {
              total += (data['totalAmount'] ?? 0).toDouble();
            }
          }
          return total;
        });
  }

  /// Get top selling products based on quantity sold
  Stream<List<Map<String, dynamic>>> streamTopSellingProducts({int limit = 5}) {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _sales
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final Map<String, int> productSales = {};
          
                  for (final doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>? ?? [];
          
          for (final item in items) {
            final itemName = item['itemName'] ?? '';
            final quantity = (item['quantity'] ?? 0) as int;
            productSales[itemName] = (productSales[itemName] ?? 0) + quantity;
          }
        }
          
          // Sort by quantity sold and take top products
          final sortedProducts = productSales.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          return sortedProducts.take(limit).map((entry) => {
            'name': entry.key,
            'quantity': entry.value,
            'label': '${entry.value} units sold'
          }).toList();
        });
  }

  /// Get stock alerts for items with low stock
  Stream<List<Map<String, dynamic>>> streamStockAlerts({int threshold = 10}) {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _items
        .where('userId', isEqualTo: userId)
        .where('stockQty', isLessThanOrEqualTo: threshold)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['name'] ?? '',
              'stockQty': data['stockQty'] ?? 0,
              'label': '${data['stockQty']} units remaining'
            };
          }).toList();
        });
  }

  /// Get weekly sales data for the chart
  Stream<List<Map<String, dynamic>>> streamWeeklySalesData() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _sales
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final Map<int, double> dailySales = {};
          
          // Initialize all days of the week with 0
          for (int i = 0; i < 7; i++) {
            dailySales[i] = 0.0;
          }
          
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          
          for (final doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            
            if (createdAt != null) {
              final daysDiff = createdAt.difference(startOfWeek).inDays;
              if (daysDiff >= 0 && daysDiff < 7) {
                dailySales[daysDiff] = (dailySales[daysDiff] ?? 0.0) + 
                    (data['totalAmount'] ?? 0).toDouble();
              }
            }
          }
          
          return dailySales.entries.map((entry) => {
            'day': entry.key,
            'amount': entry.value,
            'label': _getDayLabel(entry.key)
          }).toList();
        });
  }

  /// Get total inventory value
  Stream<double> streamTotalInventoryValue() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(0.0);
    
    return _items
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          double totalValue = 0.0;
          for (final doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final stockQty = (data['stockQty'] ?? 0);
            final price = (data['price'] ?? 0).toDouble();
            totalValue += stockQty * price;
          }
          return totalValue;
        });
  }

  /// Get recent financial summary
  Stream<Map<String, dynamic>> streamFinancialSummary() {
    final userId = currentUserId;
    if (userId == null) return Stream.value({});
    
    return _moneyIn.where('userId', isEqualTo: userId).snapshots().map((snap) {
      double totalMoneyIn = 0.0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalMoneyIn += (data['amount'] ?? 0).toDouble();
      }
      return {'totalMoneyIn': totalMoneyIn};
    });
  }

  /// Helper method to get day labels
  String _getDayLabel(int dayIndex) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayIndex];
  }
}
