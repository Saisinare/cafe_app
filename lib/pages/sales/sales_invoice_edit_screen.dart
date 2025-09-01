import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/sales_invoice.dart';

class SalesInvoiceEditScreen extends StatefulWidget {
  final SalesInvoice invoice;

  const SalesInvoiceEditScreen({
    super.key,
    required this.invoice,
  });

  @override
  State<SalesInvoiceEditScreen> createState() => _SalesInvoiceEditScreenState();
}

class _SalesInvoiceEditScreenState extends State<SalesInvoiceEditScreen> {
  final FirestoreService _firestoreService = FirestoreService.instance;
  
  List<Map<String, String>> allItems = [];
  List<InvoiceItem> selectedItems = [];
  String searchQuery = "";
  bool _isLoading = false;
  bool _isSaving = false;

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
    _initializeForm();
    _loadItems();
  }

  void _initializeForm() {
    // Pre-fill form with existing invoice data
    customerNameController.text = widget.invoice.customerName;
    customerPhoneController.text = widget.invoice.customerPhone ?? '';
    customerAddressController.text = widget.invoice.customerAddress ?? '';
    customerGstinController.text = widget.invoice.customerGstin ?? '';
    customerEmailController.text = widget.invoice.customerEmail ?? '';
    notesController.text = widget.invoice.notes ?? '';
    termsController.text = widget.invoice.termsAndConditions ?? '';
    discountController.text = widget.invoice.discount.toString();
    
    invoiceDate = widget.invoice.invoiceDate;
    dueDate = widget.invoice.dueDate;
    paymentTerms = widget.invoice.paymentTerms;
    cgstRate = widget.invoice.cgstRate;
    sgstRate = widget.invoice.sgstRate;
    
    // Copy existing items
    selectedItems = List.from(widget.invoice.items);
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
      final newItem = InvoiceItem(
        itemId: item["id"] ?? "",
        itemName: item["name"] ?? "",
        description: item["description"] ?? "",
        quantity: 1,
        unitPrice: double.tryParse(item["price"] ?? "0") ?? 0,
        totalPrice: double.tryParse(item["price"] ?? "0") ?? 0,
        hsnCode: item["hsnCode"] ?? "",
        gstRate: 9.0, // Default GST rate
      );
      
      setState(() {
        selectedItems.add(newItem);
      });
    }
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

  void _removeItemFromInvoice(int index) {
    setState(() {
      selectedItems.removeAt(index);
    });
  }

  void _updateItemPrice(int index, double newPrice) {
    final item = selectedItems[index];
    final newTotalPrice = newPrice * item.quantity;
    
    setState(() {
      selectedItems[index] = InvoiceItem(
        itemId: item.itemId,
        itemName: item.itemName,
        description: item.description,
        quantity: item.quantity,
        unitPrice: newPrice,
        totalPrice: newTotalPrice,
        hsnCode: item.hsnCode,
        gstRate: item.gstRate,
      );
    });
  }

  // Calculated values
  double get subtotal => selectedItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalDiscount => double.tryParse(discountController.text) ?? 0;
  double get taxableAmount => subtotal - totalDiscount;
  double get cgstAmount => taxableAmount * (cgstRate / 100);
  double get sgstAmount => taxableAmount * (sgstRate / 100);
  double get totalTax => cgstAmount + sgstAmount;
  double get totalAmount => taxableAmount + totalTax;

  Future<void> _updateInvoice() async {
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

    setState(() => _isSaving = true);

    try {
      final updatedInvoice = SalesInvoice(
        id: widget.invoice.id,
        userId: widget.invoice.userId,
        invoiceNumber: widget.invoice.invoiceNumber,
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
        discount: totalDiscount,
        totalAmount: totalAmount,
        paymentTerms: paymentTerms,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        termsAndConditions: termsController.text.trim().isEmpty ? null : termsController.text.trim(),
        status: widget.invoice.status, // Keep existing status
        createdAt: widget.invoice.createdAt, // Keep original creation date
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateSalesInvoice(updatedInvoice);
      
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedInvoice); // Return updated invoice
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating invoice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Invoice ${widget.invoice.invoiceNumber}"),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
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
                            labelText: "Phone",
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
                      labelText: "Address",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: customerGstinController,
                    decoration: const InputDecoration(
                      labelText: "GSTIN",
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
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: invoiceDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() => invoiceDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: "Invoice Date",
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(invoiceDate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dueDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() => dueDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: "Due Date",
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(dueDate),
                            ),
                          ),
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
                          items: const [
                            DropdownMenuItem(value: "Net 30", child: Text("Net 30")),
                            DropdownMenuItem(value: "Net 15", child: Text("Net 15")),
                            DropdownMenuItem(value: "Net 7", child: Text("Net 7")),
                            DropdownMenuItem(value: "Due on Receipt", child: Text("Due on Receipt")),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => paymentTerms = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: discountController,
                          decoration: const InputDecoration(
                            labelText: "Discount (₹)",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {}); // Trigger recalculation
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                                                  child: TextField(
                            decoration: InputDecoration(
                              labelText: "CGST Rate (%)",
                              border: const OutlineInputBorder(),
                              suffixText: "%",
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: cgstRate.toString()),
                            onChanged: (value) {
                              final rate = double.tryParse(value);
                              if (rate != null) {
                                setState(() => cgstRate = rate);
                              }
                            },
                          ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "SGST Rate (%)",
                            border: const OutlineInputBorder(),
                            suffixText: "%",
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: sgstRate.toString()),
                          onChanged: (value) {
                            final rate = double.tryParse(value);
                            if (rate != null) {
                              setState(() => sgstRate = rate);
                            }
                          },
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
                    decoration: const InputDecoration(
                      labelText: "Search Items",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  
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
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.itemName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          "₹${item.unitPrice.toStringAsFixed(2)} per unit",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () => _updateItemQuantity(index, item.quantity - 1),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              "${item.quantity}",
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () => _updateItemQuantity(index, item.quantity + 1),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            child: TextField(
                                              decoration: const InputDecoration(
                                                labelText: "Price",
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              ),
                                              keyboardType: TextInputType.number,
                                              controller: TextEditingController(text: item.unitPrice.toString()),
                                              onChanged: (value) {
                                                final price = double.tryParse(value);
                                                if (price != null) {
                                                  _updateItemPrice(index, price);
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _removeItemFromInvoice(index),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total: ₹${item.totalPrice.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF6F4E37),
                                    ),
                                  ),
                                ],
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

                  // Update Invoice Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedItems.isEmpty ? null : _updateInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F4E37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Updating Invoice...'),
                              ],
                            )
                          : const Text(
                              "Update Invoice",
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
