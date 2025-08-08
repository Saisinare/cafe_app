import 'package:flutter/material.dart';

class ItemDetailsScreen extends StatelessWidget {
  final Map<String, String> item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item["name"] ?? "Item Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailTile("Name", item["name"]),
            _detailTile("Quantity", item["quantity"]),
            _detailTile("Price", "₹${item["price"]}"),
            _detailTile("Category", item["category"]),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value ?? "Not Provided")),
        ],
      ),
    );
  }
}
