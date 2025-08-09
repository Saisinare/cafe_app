// inventory_page.dart
import 'package:flutter/material.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'add_category_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, String>> items = [];
  String searchQuery = "";
  String selectedCategory = "All";
  List<String> categories = [
    "All",
    "Beverages",
    "Pastries",
    "Sandwiches",
    "Ingredients",
    "Merch"
  ];

  int get totalItems =>
      items.fold(0, (sum, it) => sum + (int.tryParse(it["quantity"] ?? "0") ?? 0));

  double get stockValue {
    double sum = 0;
    for (var it in items) {
      final q = double.tryParse(it["quantity"] ?? "0") ?? 0;
      final p = double.tryParse(it["price"] ?? "0") ?? 0;
      sum += q * p;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = items.where((item) {
      final name = item["name"]?.toLowerCase() ?? "";
      final matchesSearch = name.contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == "All" || item["category"] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      // Elegant gradient AppBar
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6F4E37), Color(0xFFB77B57)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text("Cafe Inventory"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$totalItems",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Text("Items", style: TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${stockValue.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Text("Stock value", style: TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 10),
                // Category dropdown compact
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: DropdownButton<String>(
                    dropdownColor: Colors.white,
                    value: selectedCategory,
                    underline: const SizedBox(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with subtle elevation
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search items, e.g. Cappuccino, Croissant...",
                  suffixIcon: searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              searchQuery = "";
                            });
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
          ),

          // Category chips row (quick filter)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: categories.map((cat) {
                final selected = cat == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      selectedCategory = cat;
                    }),
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.brown[300],
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87),
                  ),
                );
              }).toList(),
            ),
          ),

          // Item list
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.inventory_2_outlined, size: 64),
                        SizedBox(height: 12),
                        Text(
                          "No items found",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final qty =
                          int.tryParse(item["quantity"] ?? "0") ?? 0;
                      final lowStock = qty <= 3;
                      final imageUrl = item["imageUrl"] ?? "";
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: Hero(
                              tag: "img_${item["name"]}_${index}",
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          width: 64,
                                          height: 64,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.coffee),
                                        ),
                                      )
                                    : Container(
                                        width: 64,
                                        height: 64,
                                        color: Colors.grey[100],
                                        child: const Icon(
                                          Icons.local_cafe,
                                          size: 36,
                                          color: Colors.brown,
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              item["name"] ?? "",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                    "${item["category"] ?? "-"} • Qty: ${item["quantity"] ?? "0"}"),
                                if ((item["description"] ?? "").isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      item["description"] ?? "",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₹${item["price"] ?? '0'}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    if (lowStock)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "Low",
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),

                                // small spacing
                                const SizedBox(width: 8),

                                // Popup menu for Edit / Delete (uses AddItemScreen)
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    final originalIndex = items.indexOf(item);
                                    if (value == 'edit') {
                                      // Open AddItemScreen in edit mode
                                      final res = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddItemScreen(
                                            categories: categories,
                                            existingItem: Map<String, String>.from(item),
                                          ),
                                        ),
                                      );

                                      if (res != null) {
                                        // if user chose delete from AddItemScreen
                                        if (res is Map && res['action'] == 'delete') {
                                          setState(() {
                                            items.removeAt(originalIndex);
                                          });
                                        } else if (res is Map<String, String>) {
                                          setState(() {
                                            if (originalIndex != -1 && originalIndex < items.length) {
                                              items[originalIndex] = res;
                                            }
                                          });
                                        }
                                      }
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Delete item"),
                                          content: const Text("Are you sure you want to delete this item?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        setState(() {
                                          items.removeAt(originalIndex);
                                        });
                                      }
                                    }
                                  },
                                  itemBuilder: (ctx) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailsScreen(
                                    item: Map<String, String>.from(item),
                                    heroTag: "img_${item["name"]}_$index",
                                    categories: categories,
                                  ),
                                ),
                              );

                              // optionally handle edited/deleted item returned from details screen
                              if (result != null && result is Map<String, dynamic>) {
                                final action = result['action'] as String?;
                                final originalIndex = items.indexOf(item);

                                if (action == 'delete') {
                                  setState(() {
                                    items.removeAt(originalIndex);
                                  });
                                } else if (action == 'update' && result['item'] is Map<String, String>) {
                                  final updated = Map<String, String>.from(result['item']);
                                  setState(() {
                                    if (originalIndex != -1 && originalIndex < items.length) {
                                      items[originalIndex] = updated;
                                    }
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // FAB opens a bottom sheet with actions
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: const Color(0xFF6F4E37),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text("Add New Item"),
                  onTap: () async {
                    Navigator.pop(context);
                    final newItem = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddItemScreen(categories: categories),
                      ),
                    );
                    if (newItem != null && newItem is Map<String, String>) {
                      setState(() {
                        items.add(newItem);
                      });
                    } else if (newItem is Map && newItem['action'] == 'delete') {
                      // nothing to do for delete when adding
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text("Add Category"),
                  onTap: () async {
                    Navigator.pop(context);
                    final newCategory = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddCategoryScreen(),
                      ),
                    );
                    if (newCategory != null &&
                        newCategory is String &&
                        newCategory.isNotEmpty) {
                      setState(() {
                        if (!categories.contains(newCategory)) {
                          categories.add(newCategory);
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 6),
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
