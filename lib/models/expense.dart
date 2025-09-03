import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseEntry {
  final String? id;
  final String userId;
  final DateTime expenseDate;
  final String category;
  final String? description;
  final double amount;
  final String paymentMode; // Cash, Card, UPI, Bank Transfer, Cheque
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseEntry({
    required this.id,
    required this.userId,
    required this.expenseDate,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMode,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'expenseDate': Timestamp.fromDate(expenseDate),
        'category': category,
        'description': description,
        'amount': amount,
        'paymentMode': paymentMode,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory ExpenseEntry.fromMap(String id, Map<String, dynamic> map) => ExpenseEntry(
        id: id,
        userId: map['userId'] ?? '',
        expenseDate: (map['expenseDate'] as Timestamp).toDate(),
        category: map['category'] ?? '',
        description: map['description'],
        amount: (map['amount'] ?? 0).toDouble(),
        paymentMode: map['paymentMode'] ?? 'Cash',
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      );
}


