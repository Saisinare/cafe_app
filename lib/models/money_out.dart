import 'package:cloud_firestore/cloud_firestore.dart';

class MoneyOutEntry {
	final String? id;
	final String userId;
	final String receiptNo;
	final DateTime moneyOutDate;
	final String partyName; // Customer/Supplier Name
	final double amountPaid;
	final String paymentMode; // Cash, Card, UPI, Bank Transfer, Cheque
	final String? note;
	final DateTime createdAt;
	final DateTime updatedAt;

	MoneyOutEntry({
		required this.id,
		required this.userId,
		required this.receiptNo,
		required this.moneyOutDate,
		required this.partyName,
		required this.amountPaid,
		required this.paymentMode,
		this.note,
		required this.createdAt,
		required this.updatedAt,
	});

	Map<String, dynamic> toMap() => {
		'userId': userId,
		'receiptNo': receiptNo,
		'moneyOutDate': Timestamp.fromDate(moneyOutDate),
		'partyName': partyName,
		'amountPaid': amountPaid,
		'paymentMode': paymentMode,
		'note': note,
		'createdAt': Timestamp.fromDate(createdAt),
		'updatedAt': Timestamp.fromDate(updatedAt),
	};

	factory MoneyOutEntry.fromMap(String id, Map<String, dynamic> map) => MoneyOutEntry(
		id: id,
		userId: map['userId'] ?? '',
		receiptNo: map['receiptNo'] ?? '',
		moneyOutDate: (map['moneyOutDate'] as Timestamp).toDate(),
		partyName: map['partyName'] ?? '',
		amountPaid: (map['amountPaid'] ?? 0).toDouble(),
		paymentMode: map['paymentMode'] ?? '',
		note: map['note'],
		createdAt: (map['createdAt'] as Timestamp).toDate(),
		updatedAt: (map['updatedAt'] as Timestamp).toDate(),
	);
} 