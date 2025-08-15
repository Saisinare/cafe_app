import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final DateTime? createdAt;

  Category({required this.id, required this.name, this.createdAt});

  Map<String, dynamic> toMap() => {
    'name': name,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory Category.fromMap(String id, Map<String, dynamic> map) => Category(
    id: id,
    name: map['name'] ?? '',
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
  );
}
