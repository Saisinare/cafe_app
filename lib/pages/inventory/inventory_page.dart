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
  List<String> categories = ["All", "Electronics", "Groceries", "Clothing"];

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredItems = items.where((item) {
      final matchesSearch =
          item["name"]!.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == "All" || item["category"] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
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
          )
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search items...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // Item list
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text("No items found"))
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.inventory),
                        title: Text(filteredItems[index]["name"]!),
                        subtitle: Text(
                            "Qty: ${filteredItems[index]["quantity"]} | ₹${filteredItems[index]["price"]}"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailsScreen(
                                item: filteredItems[index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),

      // FAB with menu
      floatingActionButton: PopupMenuButton<String>(
        icon: const Icon(Icons.add),
        onSelected: (value) async {
          if (value == "item") {
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
            }
          } else if (value == "category") {
            final newCategory = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddCategoryScreen(),
              ),
            );
            if (newCategory != null && newCategory is String && newCategory.isNotEmpty) {
              setState(() {
                if (!categories.contains(newCategory)) {
                  categories.add(newCategory);
                }
              });
            }
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: "item",
            child: Text("Add Item"),
          ),
          const PopupMenuItem(
            value: "category",
            child: Text("Add Category"),
          ),
        ],
      ),
    );
  }
}
