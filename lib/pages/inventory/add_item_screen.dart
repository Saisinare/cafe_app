import 'package:flutter/material.dart';

class AddItemScreen extends StatefulWidget {
  final List<String> categories;
  const AddItemScreen({super.key, required this.categories});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> itemData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Item")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Item Name"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter item name" : null,
                onSaved: (value) => itemData["name"] = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Please enter quantity" : null,
                onSaved: (value) => itemData["quantity"] = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Please enter price" : null,
                onSaved: (value) => itemData["price"] = value!,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Category"),
                items: widget.categories
                    .where((c) => c != "All")
                    .map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                validator: (value) =>
                    value == null ? "Please select category" : null,
                onChanged: (value) {
                  itemData["category"] = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pop(context, itemData);
                  }
                },
                child: const Text("Add Item"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
