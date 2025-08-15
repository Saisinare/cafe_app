import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final int stockQty;
  final double price;
  final String category;
  final String imageUrl;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    required this.id,
    required this.name,
    required this.stockQty,
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.description = '',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'stockQty': stockQty,
    'price': price,
    'category': category,
    'imageUrl': imageUrl,
    'description': description,
    'createdAt': createdAt != null ? createdAt : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory Item.fromMap(String id, Map<String, dynamic> map) => Item(
    id: id,
    name: map['name'] ?? '',
    stockQty: (map['stockQty'] ?? 0) as int,
    price: (map['price'] ?? 0).toDouble(),
    category: map['category'] ?? '',
    imageUrl: map['imageUrl'] ?? '',
    description: map['description'] ?? '',
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
  );
}
