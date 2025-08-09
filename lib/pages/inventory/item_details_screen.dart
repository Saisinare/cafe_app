// item_details_screen.dart
import 'package:flutter/material.dart';
import 'add_item_screen.dart';

class ItemDetailsScreen extends StatelessWidget {
  final Map<String, String> item;
  final String heroTag;
  final List<String> categories;

  const ItemDetailsScreen({
    super.key,
    required this.item,
    required this.heroTag,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item['imageUrl'] ?? '';
    final qty = int.tryParse(item['quantity'] ?? '0') ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(item['name'] ?? 'Item'),
        backgroundColor: const Color(0xFF6F4E37),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Open AddItemScreen prefilled for editing
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddItemScreen(
                    categories: categories,
                    existingItem: Map<String, String>.from(item),
                  ),
                ),
              );

              // if user saved changes or deleted, return to caller
              if (res != null) {
                if (res is Map && res['action'] == 'delete') {
                  Navigator.pop(context, {'action': 'delete', 'item': item});
                } else if (res is Map<String, String>) {
                  Navigator.pop(context, {'action': 'update', 'item': res});
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete item'),
                  content: const Text('Are you sure you want to delete this item?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                Navigator.pop(context, {'action': 'delete', 'item': item});
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[200],
                        height: 220,
                        child: const Icon(Icons.local_cafe, size: 96, color: Colors.brown),
                      ),
                    )
                  : Container(
                      height: 220,
                      color: Colors.grey[100],
                      child: const Icon(Icons.local_cafe, size: 96, color: Colors.brown),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(item['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(label: Text(item['category'] ?? 'Uncategorized'), backgroundColor: Colors.brown.shade50),
              const SizedBox(width: 12),
              Text("₹${item['price'] ?? '0'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: qty <= 3 ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Stock: ${item['quantity']}",
                  style: TextStyle(color: qty <= 3 ? Colors.red : Colors.green.shade700, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if ((item['description'] ?? '').isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(item['description'] ?? ''),
                const SizedBox(height: 12),
              ],
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37)),
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text("Mark Sold (decrement qty)"),
            onPressed: () {
              final current = int.tryParse(item['quantity'] ?? '0') ?? 0;
              if (current <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No stock left to sell")));
                return;
              }
              final updated = Map<String, String>.from(item);
              updated['quantity'] = (current - 1).toString();
              Navigator.pop(context, {'action': 'update', 'item': updated});
            },
          ),
        ],
      ),
    );
  }
}
