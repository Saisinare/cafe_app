// add_item_screen.dart
import 'package:flutter/material.dart';

class AddItemScreen extends StatefulWidget {
  final List<String> categories;
  final Map<String, String>? existingItem;

  const AddItemScreen({
    super.key,
    required this.categories,
    this.existingItem,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _descCtrl;
  late String selectedCategory;

  bool get isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    _nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    _qtyCtrl = TextEditingController(text: existing?['quantity'] ?? '1');
    _priceCtrl = TextEditingController(text: existing?['price'] ?? '');
    _imageCtrl = TextEditingController(text: existing?['imageUrl'] ?? '');
    _descCtrl = TextEditingController(text: existing?['description'] ?? '');

    // default category (prefer existing; else first non-All)
    selectedCategory = existing?['category'] ??
        (widget.categories.firstWhere((c) => c != "All", orElse: () => widget.categories.first));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, String> item = {
      'name': _nameCtrl.text.trim(),
      'quantity': _qtyCtrl.text.trim(),
      'price': _priceCtrl.text.trim(),
      'category': selectedCategory,
      'imageUrl': _imageCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
    };

    Navigator.pop(context, item);
  }

  Future<void> _onDelete() async {
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
      // return special action so caller can remove the item
      Navigator.pop(context, {'action': 'delete', 'item': widget.existingItem});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Cafe Item" : "Add Cafe Item"),
        backgroundColor: const Color(0xFF6F4E37),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _onDelete,
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  prefixIcon: Icon(Icons.local_cafe),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? "Please enter item name" : null,
              ),

              const SizedBox(height: 12),

              // Quantity & Price row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        prefixIcon: Icon(Icons.confirmation_num_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty ? "Enter qty" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: "Price (₹)",
                        prefixIcon: Icon(Icons.price_check),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || v.trim().isEmpty ? "Enter price" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Category selector
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Category",
                  prefixIcon: Icon(Icons.category),
                ),
                value: selectedCategory,
                items: widget.categories
                    .where((c) => c != "All")
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCategory = v ?? selectedCategory),
                validator: (v) => v == null || v.isEmpty ? "Please select category" : null,
              ),

              const SizedBox(height: 12),

              // Image URL
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: "Image URL (optional)",
                  hintText: "Paste an image URL to display in the app",
                  prefixIcon: Icon(Icons.image),
                ),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: "Short Description (optional)",
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 18),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F4E37),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _onSave,
                child: Text(isEditing ? "Save Changes" : "Add Item", style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
