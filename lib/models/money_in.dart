import 'package:cloud_firestore/cloud_firestore.dart';

class MoneyInEntry {
	final String? id;
	final String userId;
	final String receiptNo;
	final DateTime moneyInDate;
	final String partyName; // Customer/Supplier Name
	final double amountReceived;
	final String paymentMode; // Cash, Card, UPI, Bank Transfer, Cheque
	final String? note;
	final DateTime createdAt;
	final DateTime updatedAt;

	MoneyInEntry({
		required this.id,
		required this.userId,
		required this.receiptNo,
		required this.moneyInDate,
		required this.partyName,
		required this.amountReceived,
		required this.paymentMode,
		this.note,
		required this.createdAt,
		required this.updatedAt,
	});

	Map<String, dynamic> toMap() => {
		'userId': userId,
		'receiptNo': receiptNo,
		'moneyInDate': Timestamp.fromDate(moneyInDate),
		'partyName': partyName,
		'amountReceived': amountReceived,
		'paymentMode': paymentMode,
		'note': note,
		'createdAt': Timestamp.fromDate(createdAt),
		'updatedAt': Timestamp.fromDate(updatedAt),
	};

	factory MoneyInEntry.fromMap(String id, Map<String, dynamic> map) => MoneyInEntry(
		id: id,
		userId: map['userId'] ?? '',
		receiptNo: map['receiptNo'] ?? '',
		moneyInDate: (map['moneyInDate'] as Timestamp).toDate(),
		partyName: map['partyName'] ?? '',
		amountReceived: (map['amountReceived'] ?? 0).toDouble(),
		paymentMode: map['paymentMode'] ?? '',
		note: map['note'],
		createdAt: (map['createdAt'] as Timestamp).toDate(),
		updatedAt: (map['updatedAt'] as Timestamp).toDate(),
	);
} 