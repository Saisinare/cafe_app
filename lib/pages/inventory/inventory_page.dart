// inventory_page.dart
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'add_category_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String searchQuery = "";
  String selectedCategory = "All";

  // Utility: compute totals from list
  int totalItemsFrom(List<Map<String, String>> items) =>
      items.fold(0, (sum, it) => sum + (int.tryParse(it["quantity"] ?? "0") ?? 0));

  double stockValueFrom(List<Map<String, String>> items) {
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
    // Use a single stream for all items and apply filters locally
    return StreamBuilder<List<Map<String, String>>>(
      stream: FirestoreService.instance.streamItems(),
      builder: (ctx, snap) {
        final allItems = snap.data ?? [];
        
        // Apply category and search filters locally
        final filteredItems = allItems.where((item) {
          final name = item["name"]?.toLowerCase() ?? "";
          final matchesSearch = name.contains(searchQuery.toLowerCase());
          final matchesCategory =
              selectedCategory == "All" || item["category"] == selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        final totalItems = totalItemsFrom(allItems);
        final stockValue = stockValueFrom(allItems);

        // Get categories from items data to avoid nested streams
        final categories = <String>["All"];
        final seenCategories = <String>{};
        for (var item in allItems) {
          final category = item["category"]?.trim() ?? "";
          if (category.isNotEmpty && !seenCategories.contains(category)) {
            seenCategories.add(category);
            categories.add(category);
          }
        }

        // Determine safe dropdown value: either null or exact match
        final dropdownValue =
            categories.contains(selectedCategory) ? selectedCategory : null;

        return Scaffold(
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
                        Text("$totalItems", style: const TextStyle(fontSize: 12)),
                        const Text("Items", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("₹${stockValue.toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 12)),
                        const Text("Stock value", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: DropdownButton<String>(
                        dropdownColor: Colors.white,
                        value: dropdownValue,
                        hint: const Text("All"),
                        underline: const SizedBox(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                        items: categories
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
              ),
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
                        labelStyle:
                            TextStyle(color: selected ? Colors.white : Colors.black87),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 64),
                            SizedBox(height: 12),
                            Text("No items found", style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final qty = int.tryParse(item["quantity"] ?? "0") ?? 0;
                          final lowStock = qty <= 3;
                          final imageUrl = item["imageUrl"] ?? "";
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: Hero(
                                  tag: "img_${item["id"]}",
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.image_not_supported,
                                                  color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.inventory_2_outlined,
                                                color: Colors.grey),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  item["name"] ?? "Unknown Item",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                                        child: Text(item["description"] ?? "",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12)),
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
                                        Text("₹${item["price"] ?? '0'}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        if (lowStock)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(12)),
                                            child: const Text("Low",
                                                style: TextStyle(
                                                    color: Colors.red, fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => AddItemScreen(
                                                      categories: categories,
                                                      existingItem: item)));
                                        } else if (value == 'delete') {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text("Delete item"),
                                              content: const Text(
                                                  "Are you sure you want to delete this item?"),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, false),
                                                    child: const Text("Cancel")),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, true),
                                                    child: const Text("Delete",
                                                        style: TextStyle(
                                                            color: Colors.red))),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await FirestoreService.instance
                                                .deleteItem(item['id']!);
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
                                  await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ItemDetailsScreen(
                                              item: item,
                                              heroTag: "img_${item["id"]}",
                                              categories: categories)));
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddMenu(context, categories),
            backgroundColor: const Color(0xFF6F4E37),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddMenu(BuildContext ctx, List<String> categories) {
    showModalBottomSheet(
      context: ctx,
      shape:
          const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                    await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => AddItemScreen(categories: categories)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text("Add Category"),
                  onTap: () async {
                    Navigator.pop(context);
                    final newCategory = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddCategoryScreen()),
                    );
                    if (newCategory != null && newCategory is String && newCategory.isNotEmpty) {
                      await FirestoreService.instance.addCategory(newCategory);
                    }
                  },
                ),
                const SizedBox(height: 6),
                TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        );
      },
    );
  }
}
