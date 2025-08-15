// lib/pages/inventory/add_item_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';

class AddItemScreen extends StatefulWidget {
  final List<String> categories;
  final Map<String, String>? existingItem;

  const AddItemScreen({super.key, required this.categories, this.existingItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
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
    _descCtrl = TextEditingController(text: existing?['description'] ?? '');

    final preferred = existing?['category'];
    final available = widget.categories.where((c) => c != "All").map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (preferred != null && available.contains(preferred)) {
      selectedCategory = preferred;
    } else if (available.isNotEmpty) {
      selectedCategory = available.first;
    } else {
      selectedCategory = "Uncategorized";
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() => _pickedImage = File(picked.path));
    } catch (e) {
      // optionally show error
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final desc = _descCtrl.text.trim();

    String? imageUrl = widget.existingItem?['imageUrl'];

    try {
      // If user picked a new local image, upload it first
      if (_pickedImage != null) {
        final newUrl = await FirestoreService.instance.uploadItemImage(_pickedImage!);
        // Optionally delete old image (avoid orphaned storage files)
        final oldUrl = widget.existingItem?['imageUrl'];
        if (oldUrl != null && oldUrl.isNotEmpty && oldUrl != newUrl) {
          await FirestoreService.instance.deleteItemImageByUrl(oldUrl);
        }
        imageUrl = newUrl;
      }

      if (isEditing) {
        final id = widget.existingItem!['id']!;
        await FirestoreService.instance.updateItem(
          id: id,
          name: name,
          stockQty: qty,
          price: price,
          category: selectedCategory,
          imageUrl: imageUrl,
          description: desc,
        );
      } else {
        await FirestoreService.instance.addItem(
          name: name,
          stockQty: qty,
          price: price,
          category: selectedCategory,
          imageUrl: imageUrl,
          description: desc,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onDelete() async {
    if (!isEditing) return;
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
      final id = widget.existingItem!['id']!;
      // Optionally delete image from storage too
      final oldUrl = widget.existingItem?['imageUrl'];
      if (oldUrl != null && oldUrl.isNotEmpty) {
        await FirestoreService.instance.deleteItemImageByUrl(oldUrl);
      }
      await FirestoreService.instance.deleteItem(id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = isEditing;

    // prepare category list
    final rawCats = widget.categories.where((c) => c != "All").map((s) => s.trim()).toList();
    final seen = <String>{};
    final catList = <String>[];
    for (var c in rawCats) {
      if (c.isNotEmpty && !seen.contains(c)) {
        seen.add(c);
        catList.add(c);
      }
    }

    // choose dropdown value safely
    String? dropdownValue;
    if (catList.isEmpty) {
      dropdownValue = null;
    } else if (catList.contains(selectedCategory)) {
      dropdownValue = selectedCategory;
    } else {
      dropdownValue = catList.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => selectedCategory = dropdownValue!);
      });
    }

    final existingImageUrl = widget.existingItem?['imageUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Cafe Item" : "Add Cafe Item"),
        backgroundColor: const Color(0xFF6F4E37),
        actions: [ if (isEdit) IconButton(icon: const Icon(Icons.delete), onPressed: _onDelete) ],
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
                decoration: const InputDecoration(labelText: "Item Name", prefixIcon: Icon(Icons.local_cafe)),
                validator: (v) => v == null || v.trim().isEmpty ? "Please enter item name" : null,
              ),
              const SizedBox(height: 12),

              // Quantity & Price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      decoration: const InputDecoration(labelText: "Quantity", prefixIcon: Icon(Icons.confirmation_num_outlined)),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty ? "Enter qty" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: "Price (₹)", prefixIcon: Icon(Icons.price_check)),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || v.trim().isEmpty ? "Enter price" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Category", prefixIcon: Icon(Icons.category)),
                value: dropdownValue,
                items: catList.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (v) => setState(() => selectedCategory = v ?? selectedCategory),
                validator: (v) => v == null || v.isEmpty ? "Please select category" : null,
              ),
              const SizedBox(height: 12),

              // Image picker + preview
              const Text("Image (optional)"),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_pickedImage != null)
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_pickedImage!, width: 92, height: 92, fit: BoxFit.cover))
                  else if (existingImageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(existingImageUrl, width: 92, height: 92, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 92, height: 92, color: Colors.grey[200], child: const Icon(Icons.broken_image))),
                    )
                  else
                    Container(width: 92, height: 92, color: Colors.grey[100], child: const Icon(Icons.image, size: 44)),

                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(icon: const Icon(Icons.photo), label: const Text("Gallery"), onPressed: () => _pickImage(ImageSource.gallery)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(icon: const Icon(Icons.camera_alt), label: const Text("Camera"), onPressed: () => _pickImage(ImageSource.camera)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: "Short Description (optional)", prefixIcon: Icon(Icons.notes)), maxLines: 2),
              const SizedBox(height: 18),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _saving ? null : _onSave,
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text(isEdit ? "Save Changes" : "Add Item", style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
