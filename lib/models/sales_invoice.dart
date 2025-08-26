import 'package:cloud_firestore/cloud_firestore.dart';

class SalesInvoice {
  final String? id;
  final String userId;
  final String invoiceNumber;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerGstin;
  final String? customerEmail;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double cgstRate;
  final double sgstRate;
  final double cgstAmount;
  final double sgstAmount;
  final double totalTax;
  final double discount;
  final double totalAmount;
  final String paymentTerms;
  final String? notes;
  final String? termsAndConditions;
  final String status; // 'draft', 'sent', 'paid', 'overdue', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  SalesInvoice({
    this.id,
    required this.userId,
    required this.invoiceNumber,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerGstin,
    this.customerEmail,
    required this.invoiceDate,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.cgstRate,
    required this.sgstRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.totalTax,
    required this.discount,
    required this.totalAmount,
    required this.paymentTerms,
    this.notes,
    this.termsAndConditions,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'invoiceNumber': invoiceNumber,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerAddress': customerAddress,
    'customerGstin': customerGstin,
    'customerEmail': customerEmail,
    'invoiceDate': Timestamp.fromDate(invoiceDate),
    'dueDate': Timestamp.fromDate(dueDate),
    'items': items.map((item) => item.toMap()).toList(),
    'subtotal': subtotal,
    'cgstRate': cgstRate,
    'sgstRate': sgstRate,
    'cgstAmount': cgstAmount,
    'sgstAmount': sgstAmount,
    'totalTax': totalTax,
    'discount': discount,
    'totalAmount': totalAmount,
    'paymentTerms': paymentTerms,
    'notes': notes,
    'termsAndConditions': termsAndConditions,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory SalesInvoice.fromMap(String id, Map<String, dynamic> map) => SalesInvoice(
    id: id,
    userId: map['userId'] ?? '',
    invoiceNumber: map['invoiceNumber'] ?? '',
    customerName: map['customerName'] ?? '',
    customerPhone: map['customerPhone'],
    customerAddress: map['customerAddress'],
    customerGstin: map['customerGstin'],
    customerEmail: map['customerEmail'],
    invoiceDate: (map['invoiceDate'] as Timestamp).toDate(),
    dueDate: (map['dueDate'] as Timestamp).toDate(),
    items: (map['items'] as List<dynamic>?)
        ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
        .toList() ?? [],
    subtotal: (map['subtotal'] ?? 0).toDouble(),
    cgstRate: (map['cgstRate'] ?? 0).toDouble(),
    sgstRate: (map['sgstRate'] ?? 0).toDouble(),
    cgstAmount: (map['cgstAmount'] ?? 0).toDouble(),
    sgstAmount: (map['sgstAmount'] ?? 0).toDouble(),
    totalTax: (map['totalTax'] ?? 0).toDouble(),
    discount: (map['discount'] ?? 0).toDouble(),
    totalAmount: (map['totalAmount'] ?? 0).toDouble(),
    paymentTerms: map['paymentTerms'] ?? '',
    notes: map['notes'],
    termsAndConditions: map['termsAndConditions'],
    status: map['status'] ?? 'draft',
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
  );
}

class InvoiceItem {
  final String itemId;
  final String itemName;
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String hsnCode;
  final double gstRate;

  InvoiceItem({
    required this.itemId,
    required this.itemName,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.hsnCode,
    required this.gstRate,
  });

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'itemName': itemName,
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
    'hsnCode': hsnCode,
    'gstRate': gstRate,
  };

  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
    itemId: map['itemId'] ?? '',
    itemName: map['itemName'] ?? '',
    description: map['description'] ?? '',
    quantity: map['quantity'] ?? 0,
    unitPrice: (map['unitPrice'] ?? 0).toDouble(),
    totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    hsnCode: map['hsnCode'] ?? '',
    gstRate: (map['gstRate'] ?? 0).toDouble(),
  );
}
