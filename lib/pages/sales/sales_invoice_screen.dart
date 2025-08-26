import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/sales_invoice.dart';
import '../../models/item.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  final FirestoreService _firestoreService = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, String>> allItems = [];
  List<InvoiceItem> selectedItems = [];
  String searchQuery = "";
  bool _isLoading = false;

  // Form controllers
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerPhoneController = TextEditingController();
  final TextEditingController customerAddressController = TextEditingController();
  final TextEditingController customerGstinController = TextEditingController();
  final TextEditingController customerEmailController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController termsController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  DateTime invoiceDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 30));
  String paymentTerms = "Net 30";
  double cgstRate = 9.0;
  double sgstRate = 9.0;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final itemsStream = _firestoreService.streamItems();
      await for (final items in itemsStream) {
        if (mounted) {
          setState(() {
            allItems = items;
            _isLoading = false;
          });
        }
        break;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  List<Map<String, String>> get filteredItems {
    if (searchQuery.isEmpty) return allItems;
    return allItems.where((item) {
      final name = item["name"]?.toLowerCase() ?? "";
      final category = item["category"]?.toLowerCase() ?? "";
      final query = searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  void _addItemToInvoice(Map<String, String> item) {
    final existingIndex = selectedItems.indexWhere((invoiceItem) => invoiceItem.itemId == item["id"]);
    
    if (existingIndex != -1) {
      // Update quantity
      final existing = selectedItems[existingIndex];
      final newQuantity = existing.quantity + 1;
      final newTotalPrice = (double.tryParse(item["price"] ?? "0") ?? 0) * newQuantity;
      
      setState(() {
        selectedItems[existingIndex] = InvoiceItem(
          itemId: existing.itemId,
          itemName: existing.itemName,
          description: existing.description,
          quantity: newQuantity,
          unitPrice: existing.unitPrice,
          totalPrice: newTotalPrice,
          hsnCode: existing.hsnCode,
          gstRate: existing.gstRate,
        );
      });
    } else {
      // Add new item
      final price = double.tryParse(item["price"] ?? "0") ?? 0;
      setState(() {
        selectedItems.add(InvoiceItem(
          itemId: item["id"]!,
          itemName: item["name"] ?? "",
          description: item["description"] ?? "",
          quantity: 1,
          unitPrice: price,
          totalPrice: price,
          hsnCode: "9983", // Default HSN code for restaurant services
          gstRate: 18.0, // Default GST rate
        ));
      });
    }
  }

  void _removeItemFromInvoice(int index) {
    setState(() {
      selectedItems.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItemFromInvoice(index);
      return;
    }
    
    final item = selectedItems[index];
    final newTotalPrice = item.unitPrice * newQuantity;
    
    setState(() {
      selectedItems[index] = InvoiceItem(
        itemId: item.itemId,
        itemName: item.itemName,
        description: item.description,
        quantity: newQuantity,
        unitPrice: item.unitPrice,
        totalPrice: newTotalPrice,
        hsnCode: item.hsnCode,
        gstRate: item.gstRate,
      );
    });
  }

  double get subtotal => selectedItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalDiscount => subtotal * (double.tryParse(discountController.text) ?? 0) / 100;
  double get taxableAmount => subtotal - totalDiscount;
  double get cgstAmount => taxableAmount * (cgstRate / 100);
  double get sgstAmount => taxableAmount * (sgstRate / 100);
  double get totalTax => cgstAmount + sgstAmount;
  double get totalAmount => taxableAmount + totalTax;

  Future<void> _createInvoice() async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    if (customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate invoice number
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final invoiceNumber = 'INV-${timestamp.toString().substring(8)}';

      final invoice = SalesInvoice(
        userId: _auth.currentUser!.uid,
        invoiceNumber: invoiceNumber,
        customerName: customerNameController.text.trim(),
        customerPhone: customerPhoneController.text.trim().isEmpty ? null : customerPhoneController.text.trim(),
        customerAddress: customerAddressController.text.trim().isEmpty ? null : customerAddressController.text.trim(),
        customerGstin: customerGstinController.text.trim().isEmpty ? null : customerGstinController.text.trim(),
        customerEmail: customerEmailController.text.trim().isEmpty ? null : customerEmailController.text.trim(),
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        items: selectedItems,
        subtotal: subtotal,
        cgstRate: cgstRate,
        sgstRate: sgstRate,
        cgstAmount: cgstAmount,
        sgstAmount: sgstAmount,
        totalTax: totalTax,
        discount: double.tryParse(discountController.text) ?? 0,
        totalAmount: totalAmount,
        paymentTerms: paymentTerms,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        termsAndConditions: termsController.text.trim().isEmpty ? null : termsController.text.trim(),
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createSalesInvoice(invoice);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating invoice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Sales Invoice"),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Details Section
                  const Text(
                    "Customer Details",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: customerNameController,
                    decoration: const InputDecoration(
                      labelText: "Customer Name *",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customerPhoneController,
                          decoration: const InputDecoration(
                            labelText: "Phone Number",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: customerEmailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: customerAddressController,
                    decoration: const InputDecoration(
                      labelText: "Billing Address",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: customerGstinController,
                    decoration: const InputDecoration(
                      labelText: "GSTIN (Optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Invoice Details Section
                  const Text(
                    "Invoice Details",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: invoiceDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => invoiceDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text("Invoice Date: ${invoiceDate.toString().split(' ')[0]}"),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => dueDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text("Due Date: ${dueDate.toString().split(' ')[0]}"),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: paymentTerms,
                          decoration: const InputDecoration(
                            labelText: "Payment Terms",
                            border: OutlineInputBorder(),
                          ),
                          items: ["Net 0", "Net 7", "Net 15", "Net 30", "Net 60"]
                              .map((term) => DropdownMenuItem(value: term, child: Text(term)))
                              .toList(),
                          onChanged: (val) => setState(() => paymentTerms = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: discountController,
                          decoration: const InputDecoration(
                            labelText: "Discount (%)",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Items Section
                  const Text(
                    "Items",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items by name or category...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                  const SizedBox(height: 16),

                  // Items List
                  if (filteredItems.isEmpty)
                    const Center(
                      child: Text('No items found', style: TextStyle(fontSize: 16)),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSelected = selectedItems.any((invoiceItem) => invoiceItem.itemId == item["id"]);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF6F4E37),
                                child: Text(
                                  item["name"]?.substring(0, 1).toUpperCase() ?? "?",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(item["name"] ?? ""),
                              subtitle: Text(
                                "${item["category"] ?? ""} • Stock: ${item["quantity"] ?? "0"}",
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "₹${item["price"] ?? "0"}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Text(
                                      "Added",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () => _addItemToInvoice(item),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Selected Items Summary
                  if (selectedItems.isNotEmpty) ...[
                    const Text(
                      "Selected Items:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...selectedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Card(
                        child: ListTile(
                          title: Text(item.itemName),
                          subtitle: Text("₹${item.unitPrice} × ${item.quantity}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => _updateItemQuantity(index, item.quantity - 1),
                              ),
                              Text("${item.quantity}"),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _updateItemQuantity(index, item.quantity + 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeItemFromInvoice(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),

                  // Additional Details
                  const Text(
                    "Additional Details",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: "Notes",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: termsController,
                    decoration: const InputDecoration(
                      labelText: "Terms & Conditions",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Invoice Summary",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Subtotal:"),
                              Text("₹${subtotal.toStringAsFixed(2)}"),
                            ],
                          ),
                          if (totalDiscount > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Discount:"),
                                Text("-₹${totalDiscount.toStringAsFixed(2)}"),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Taxable Amount:"),
                                Text("₹${taxableAmount.toStringAsFixed(2)}"),
                              ],
                            ),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("CGST (${cgstRate}%):"),
                              Text("₹${cgstAmount.toStringAsFixed(2)}"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("SGST (${sgstRate}%):"),
                              Text("₹${sgstAmount.toStringAsFixed(2)}"),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Amount:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "₹${totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Create Invoice Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedItems.isEmpty ? null : _createInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F4E37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Create Invoice",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
