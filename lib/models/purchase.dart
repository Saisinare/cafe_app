import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseItem {
	final String itemId;
	final String itemName;
	final String category;
	final double unitCost;
	final int quantity;
	final double totalCost;

	PurchaseItem({
		required this.itemId,
		required this.itemName,
		required this.category,
		required this.unitCost,
		required this.quantity,
		required this.totalCost,
	});

	Map<String, dynamic> toMap() => {
		'itemId': itemId,
		'itemName': itemName,
		'category': category,
		'unitCost': unitCost,
		'quantity': quantity,
		'totalCost': totalCost,
	};

	factory PurchaseItem.fromMap(Map<String, dynamic> map) => PurchaseItem(
		itemId: map['itemId'] ?? '',
		itemName: map['itemName'] ?? '',
		category: map['category'] ?? '',
		unitCost: (map['unitCost'] ?? 0).toDouble(),
		quantity: (map['quantity'] ?? 0).toInt(),
		totalCost: (map['totalCost'] ?? 0).toDouble(),
	);
}

class PurchaseOrder {
	final String? id;
	final String userId;
	final String supplierName;
	final String invoiceNo;
	final DateTime purchaseDate;
	final List<PurchaseItem> items;
	final double subtotal;
	final double discount; // percentage 0-100
	final double tax; // absolute currency amount
	final double shipping; // absolute currency amount
	final double totalAmount;
	final double amountPaid;
	final String paymentMode; // Cash, Card, UPI, Bank Transfer, Cheque
	final String? note;
	final DateTime createdAt;
	final DateTime updatedAt;

	PurchaseOrder({
		this.id,
		required this.userId,
		required this.supplierName,
		required this.invoiceNo,
		required this.purchaseDate,
		required this.items,
		required this.subtotal,
		required this.discount,
		required this.tax,
		required this.shipping,
		required this.totalAmount,
		required this.amountPaid,
		required this.paymentMode,
		this.note,
		required this.createdAt,
		required this.updatedAt,
	});

	Map<String, dynamic> toMap() => {
		'userId': userId,
		'supplierName': supplierName,
		'invoiceNo': invoiceNo,
		'purchaseDate': Timestamp.fromDate(purchaseDate),
		'items': items.map((e) => e.toMap()).toList(),
		'subtotal': subtotal,
		'discount': discount,
		'tax': tax,
		'shipping': shipping,
		'totalAmount': totalAmount,
		'amountPaid': amountPaid,
		'paymentMode': paymentMode,
		'note': note,
		'createdAt': Timestamp.fromDate(createdAt),
		'updatedAt': Timestamp.fromDate(updatedAt),
	};

	factory PurchaseOrder.fromMap(String id, Map<String, dynamic> map) => PurchaseOrder(
		id: id,
		userId: map['userId'] ?? '',
		supplierName: map['supplierName'] ?? '',
		invoiceNo: map['invoiceNo'] ?? '',
		purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
		items: (map['items'] as List<dynamic>? ?? [])
			.map((e) => PurchaseItem.fromMap(e as Map<String, dynamic>))
			.toList(),
		subtotal: (map['subtotal'] ?? 0).toDouble(),
		discount: (map['discount'] ?? 0).toDouble(),
		tax: (map['tax'] ?? 0).toDouble(),
		shipping: (map['shipping'] ?? 0).toDouble(),
		totalAmount: (map['totalAmount'] ?? 0).toDouble(),
		amountPaid: (map['amountPaid'] ?? 0).toDouble(),
		paymentMode: map['paymentMode'] ?? '',
		note: map['note'],
		createdAt: (map['createdAt'] as Timestamp).toDate(),
		updatedAt: (map['updatedAt'] as Timestamp).toDate(),
	);
} 