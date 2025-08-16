import 'package:cloud_firestore/cloud_firestore.dart';

class SalesItem {
  final String itemId;
  final String itemName;
  final String category;
  final double price;
  final int quantity;
  final double totalPrice;

  SalesItem({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'itemName': itemName,
    'category': category,
    'price': price,
    'quantity': quantity,
    'totalPrice': totalPrice,
  };

  factory SalesItem.fromMap(Map<String, dynamic> map) => SalesItem(
    itemId: map['itemId'] ?? '',
    itemName: map['itemName'] ?? '',
    category: map['category'] ?? '',
    price: (map['price'] ?? 0).toDouble(),
    quantity: map['quantity'] ?? 0,
    totalPrice: (map['totalPrice'] ?? 0).toDouble(),
  );
}

class SalesTransaction {
  final String? id;
  final String userId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final List<SalesItem> items;
  final double subtotal;
  final double discount;
  final double serviceCharge;
  final double totalAmount;
  final double amountReceived;
  final String paymentMode;
  final bool paymentReceived;
  final String? billingTerm;
  final DateTime? billDueDate;
  final String? deliveryState;
  final String parcelMode;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  SalesTransaction({
    this.id,
    required this.userId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.serviceCharge,
    required this.totalAmount,
    required this.amountReceived,
    required this.paymentMode,
    required this.paymentReceived,
    this.billingTerm,
    this.billDueDate,
    this.deliveryState,
    required this.parcelMode,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerAddress': customerAddress,
    'items': items.map((item) => item.toMap()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'serviceCharge': serviceCharge,
    'totalAmount': totalAmount,
    'amountReceived': amountReceived,
    'paymentMode': paymentMode,
    'paymentReceived': paymentReceived,
    'billingTerm': billingTerm,
    'billDueDate': billDueDate != null ? Timestamp.fromDate(billDueDate!) : null,
    'deliveryState': deliveryState,
    'parcelMode': parcelMode,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory SalesTransaction.fromMap(String id, Map<String, dynamic> map) => SalesTransaction(
    id: id,
    userId: map['userId'] ?? '',
    customerName: map['customerName'] ?? '',
    customerPhone: map['customerPhone'],
    customerAddress: map['customerAddress'],
    items: (map['items'] as List<dynamic>?)
        ?.map((item) => SalesItem.fromMap(item as Map<String, dynamic>))
        .toList() ?? [],
    subtotal: (map['subtotal'] ?? 0).toDouble(),
    discount: (map['discount'] ?? 0).toDouble(),
    serviceCharge: (map['serviceCharge'] ?? 0).toDouble(),
    totalAmount: (map['totalAmount'] ?? 0).toDouble(),
    amountReceived: (map['amountReceived'] ?? 0).toDouble(),
    paymentMode: map['paymentMode'] ?? '',
    paymentReceived: map['paymentReceived'] ?? false,
    billingTerm: map['billingTerm'],
    billDueDate: (map['billDueDate'] as Timestamp?)?.toDate(),
    deliveryState: map['deliveryState'],
    parcelMode: map['parcelMode'] ?? '',
    note: map['note'],
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
  );
} 