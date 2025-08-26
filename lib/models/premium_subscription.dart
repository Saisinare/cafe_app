import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumSubscription {
  final String? id;
  final String userId;
  final String planType; // 'monthly', 'yearly'
  final double amount;
  final String currency;
  final String paymentStatus; // 'pending', 'completed', 'failed'
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PremiumSubscription({
    this.id,
    required this.userId,
    required this.planType,
    required this.amount,
    required this.currency,
    required this.paymentStatus,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'planType': planType,
    'amount': amount,
    'currency': currency,
    'paymentStatus': paymentStatus,
    'razorpayOrderId': razorpayOrderId,
    'razorpayPaymentId': razorpayPaymentId,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory PremiumSubscription.fromMap(String id, Map<String, dynamic> map) => PremiumSubscription(
    id: id,
    userId: map['userId'] ?? '',
    planType: map['planType'] ?? '',
    amount: (map['amount'] ?? 0).toDouble(),
    currency: map['currency'] ?? 'INR',
    paymentStatus: map['paymentStatus'] ?? '',
    razorpayOrderId: map['razorpayOrderId'],
    razorpayPaymentId: map['razorpayPaymentId'],
    startDate: (map['startDate'] as Timestamp).toDate(),
    endDate: (map['endDate'] as Timestamp).toDate(),
    isActive: map['isActive'] ?? false,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
  );

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isValid => isActive && !isExpired;
}
