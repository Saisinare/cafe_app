// lib/pages/inventory/add_item_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';

class AddItemScreen extends StatefulWidget {
  final Map<String, String>? existingItem;

  const AddItemScreen({super.key, this.existingItem});

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

    // Set a default category - will be updated when categories are loaded
    selectedCategory = "Uncategorized";
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Item' : 'Add New Item'),
        backgroundColor: const Color(0xFF6F4E37),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _onDelete,
            ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: FirestoreService.instance.streamCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading categories: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Prepare category list
          final rawCats = snapshot.data ?? [];
          final seen = <String>{};
          final catList = <String>[];
          for (var c in rawCats) {
            final s = c.trim();
            if (s.isNotEmpty && !seen.contains(s)) {
              seen.add(s);
              catList.add(s);
            }
          }

          // If no categories exist, add a default one
          if (catList.isEmpty) {
            catList.add("Uncategorized");
          }

          // Set selected category if not already set or if current selection is invalid
          if (!catList.contains(selectedCategory)) {
            selectedCategory = catList.first;
          }

          // If editing, try to use the existing item's category
          if (isEdit && widget.existingItem != null) {
            final existingCategory = widget.existingItem!['category'];
            if (existingCategory != null && catList.contains(existingCategory)) {
              selectedCategory = existingCategory;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Image picker section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _pickedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_pickedImage!, fit: BoxFit.cover),
                                )
                              : widget.existingItem?['imageUrl']?.isNotEmpty == true
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.existingItem!['imageUrl']!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6F4E37),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: PopupMenuButton<ImageSource>(
                              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              onSelected: _pickImage,
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: ImageSource.camera,
                                  child: Row(
                                    children: [
                                      Icon(Icons.camera_alt),
                                      SizedBox(width: 8),
                                      Text('Camera'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: ImageSource.gallery,
                                  child: Row(
                                    children: [
                                      Icon(Icons.photo_library),
                                      SizedBox(width: 8),
                                      Text('Gallery'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name field
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      prefixIcon: Icon(Icons.inventory_2),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter item name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: catList.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantity and Price row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            prefixIcon: Icon(Icons.shopping_cart),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final qty = int.tryParse(value);
                            if (qty == null || qty < 0) {
                              return 'Invalid quantity';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Price (₹)',
                            prefixIcon: Icon(Icons.currency_rupee_sharp),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price < 0) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F4E37),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isEdit ? 'Update Item' : 'Add Item',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
