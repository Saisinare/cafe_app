import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/receipt_printer_service.dart';
import '../../services/firestore_service.dart';
import '../../models/sales.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int _currentStep = 0;
  String searchQuery = "";
  List<Map<String, String>> allItems = [];
  List<SalesItem> selectedItems = [];
  bool _isLoading = false;

  // Step 2 form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountReceivedController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool paymentReceived = false;
  String? paymentMode;
  String? billingTerm;
  DateTime? billDueDate;
  String? deliveryState;
  double discount = 0;
  double serviceCharge = 0;
  String? parcelMode;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final itemsStream = FirestoreService.instance.streamItems();
      await for (final items in itemsStream) {
        if (mounted) {
          setState(() {
            allItems = items;
            _isLoading = false;
          });
        }
        break; // Get first snapshot
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

  void _addItemToSale(Map<String, String> item) {
    final existingIndex = selectedItems.indexWhere((saleItem) => saleItem.itemId == item["id"]);
    
    if (existingIndex != -1) {
      // Update quantity
      final existing = selectedItems[existingIndex];
      final newQuantity = existing.quantity + 1;
      final newTotalPrice = (double.tryParse(item["price"] ?? "0") ?? 0) * newQuantity;
      
      setState(() {
        selectedItems[existingIndex] = SalesItem(
          itemId: existing.itemId,
          itemName: existing.itemName,
          category: existing.category,
          price: existing.price,
          quantity: newQuantity,
          totalPrice: newTotalPrice,
        );
      });
    } else {
      // Add new item
      final price = double.tryParse(item["price"] ?? "0") ?? 0;
      setState(() {
        selectedItems.add(SalesItem(
          itemId: item["id"]!,
          itemName: item["name"] ?? "",
          category: item["category"] ?? "",
          price: price,
          quantity: 1,
          totalPrice: price,
        ));
      });
    }
  }

  void _removeItemFromSale(int index) {
    setState(() {
      selectedItems.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItemFromSale(index);
      return;
    }
    
    final item = selectedItems[index];
    final newTotalPrice = item.price * newQuantity;
    
    setState(() {
      selectedItems[index] = SalesItem(
        itemId: item.itemId,
        itemName: item.itemName,
        category: item.category,
        price: item.price,
        quantity: newQuantity,
        totalPrice: newTotalPrice,
      );
    });
  }

  double get subtotal => selectedItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalDiscount => subtotal * (discount / 100);
  double get totalAmount => subtotal - totalDiscount + serviceCharge;
  double get amountDue => totalAmount - (double.tryParse(amountReceivedController.text) ?? 0);

  Future<void> _submitSale() async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    // Removed hard requirements for customer name, payment mode and parcel mode

    setState(() => _isLoading = true);

    try {
      final transaction = SalesTransaction(
        userId: FirebaseAuth.instance.currentUser!.uid,
        customerName: nameController.text.trim(),
        customerPhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        customerAddress: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
        items: selectedItems,
        subtotal: subtotal,
        discount: discount,
        serviceCharge: serviceCharge,
        totalAmount: totalAmount,
        amountReceived: double.tryParse(amountReceivedController.text) ?? 0,
        paymentMode: paymentMode ?? '',
        paymentReceived: paymentReceived,
        billingTerm: billingTerm,
        billDueDate: billDueDate,
        deliveryState: deliveryState,
        parcelMode: parcelMode ?? '',
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final saleId = await FirestoreService.instance.createSalesTransaction(transaction);
      
      // Auto-print receipt
      try {
        // Check if Bluetooth printing is enabled
        bool bluetoothEnabled = true;
        try {
          final printerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('preferences')
              .doc('printer')
              .get();
          
          if (printerDoc.exists) {
            final printerData = printerDoc.data() as Map<String, dynamic>;
            bluetoothEnabled = printerData['bluetoothEnabled'] ?? true;
          }
        } catch (e) {
          // Use default if settings can't be loaded
          bluetoothEnabled = true;
        }

        if (!bluetoothEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bluetooth printing is disabled in settings')),
            );
          }
          // Return to Home screen
          if (mounted) Navigator.pop(context);
          return;
        }

        final devices = await ReceiptPrinterService.instance.scanDevices();
        if (devices.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Printer not connected')),
            );
          }
          // Return to Home screen
          if (mounted) Navigator.pop(context);
        } else {
          final device = devices.first;
          final connected = await ReceiptPrinterService.instance.connect(device);
          if (!connected) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printer not connected')),
              );
            }
            // Return to Home screen
            if (mounted) Navigator.pop(context);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt printing...')),
              );
            }
            String? userId = FirestoreService.instance.currentUserId;
            Map<String, dynamic>? userData;
            if (userId != null) {
              userData = await FirestoreService.instance.getUserData(userId);
            }
            final businessName = (userData?['businessName'] ?? userData?['name'] ?? 'Receipt').toString();
            String? addressLine1;
            String? addressLine2;
            if (userData != null) {
              final addr = (userData['address'] ?? '').toString();
              if (addr.isNotEmpty) {
                final parts = addr.split(',');
                addressLine1 = parts.isNotEmpty ? parts.first.trim() : null;
                addressLine2 = parts.length > 1 ? parts.sublist(1).join(',').trim() : null;
              } else {
                addressLine1 = (userData['addressLine1'] ?? '').toString().trim();
                addressLine2 = (userData['addressLine2'] ?? '').toString().trim();
                if (addressLine1.isEmpty) addressLine1 = null;
                if (addressLine2.isEmpty) addressLine2 = null;
              }
            }
            final contact = (userData?['phone'] ?? userData?['contact'] ?? userData?['mobile'] ?? '').toString();

            // Load receipt settings
            String? customHeader;
            String? customFooter;
            double? headerFontSize;
            double? footerFontSize;
            
            try {
              final receiptDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('preferences')
                  .doc('receipt')
                  .get();
              
              if (receiptDoc.exists) {
                final receiptData = receiptDoc.data() as Map<String, dynamic>;
                customHeader = receiptData['headerText'];
                customFooter = receiptData['footerText'];
                headerFontSize = (receiptData['headerFontSize'] ?? 16.0).toDouble();
                footerFontSize = (receiptData['footerFontSize'] ?? 14.0).toDouble();
              }
            } catch (e) {
              // Use defaults if settings can't be loaded
              customHeader = 'Thank you for your business!';
              customFooter = 'Visit again soon!';
            }

            await ReceiptPrinterService.instance.printSaleReceipt(
              transaction,
              businessName: businessName,
              addressLine1: addressLine1,
              addressLine2: addressLine2,
              contact: contact.isEmpty ? null : contact,
              invoiceNumber: saleId,
              customHeader: customHeader,
              customFooter: customFooter,
              headerFontSize: headerFontSize,
              footerFontSize: footerFontSize,
            );
          }
        }
      } catch (_) {}
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale completed successfully!')),
        );
        // Stay on the details page; do not navigate away
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating sale: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Sale"),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 1) {
            if (selectedItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select at least one item')),
              );
              return;
            }
            setState(() => _currentStep += 1);
          } else {
            _submitSale();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: [
          // Step 1 - Item Selection
          Step(
            title: const Text("Items"),
            isActive: _currentStep >= 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
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
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (filteredItems.isEmpty)
                  const Center(
                    child: Text('No items found', style: TextStyle(fontSize: 16)),
                  )
                else
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = selectedItems.any((saleItem) => saleItem.itemId == item["id"]);
                        
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
                            onTap: () => _addItemToSale(item),
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
                        subtitle: Text("₹${item.price} × ${item.quantity}"),
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
                              onPressed: () => _removeItemFromSale(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    "Subtotal: ₹${subtotal.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),

          // Step 2 - Customer & Billing Details
          Step(
            title: const Text("Details"),
            isActive: _currentStep >= 1,
            content: SingleChildScrollView(
              child: Column(
                children: [
                  // Customer Details
                  const Text(
                    "Customer Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Customer Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: "Billing Address",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Payment Details
                  const Text(
                    "Payment Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: paymentMode,
                    decoration: const InputDecoration(
                      labelText: "Payment Mode",
                      border: OutlineInputBorder(),
                    ),
                    items: ["Cash", "Card", "UPI", "Bank Transfer"]
                        .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                        .toList(),
                    onChanged: (val) => setState(() => paymentMode = val),
                  ),
                  const SizedBox(height: 12),

                  CheckboxListTile(
                    title: const Text("Payment Received"),
                    value: paymentReceived,
                    onChanged: (val) => setState(() => paymentReceived = val ?? false),
                  ),

                  if (!paymentReceived) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: billingTerm,
                      decoration: const InputDecoration(
                        labelText: "Billing Term",
                        border: OutlineInputBorder(),
                      ),
                      items: ["Net 0", "Net 7", "Net 15", "Net 30", "Net 60"]
                          .map((term) => DropdownMenuItem(value: term, child: Text(term)))
                          .toList(),
                      onChanged: (val) => setState(() => billingTerm = val),
                    ),
                    const SizedBox(height: 12),
                    
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => billDueDate = picked);
                        }
                      },
                      child: Text(
                        billDueDate == null
                            ? "Select Bill Due Date"
                            : "Due Date: ${billDueDate.toString().split(' ')[0]}",
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Additional Details
                  const Text(
                    "Additional Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Delivery State",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => deliveryState = val,
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Discount (%)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() => discount = double.tryParse(val) ?? 0),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Service Charge (₹)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() => serviceCharge = double.tryParse(val) ?? 0),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: parcelMode,
                    decoration: const InputDecoration(
                      labelText: "Parcel Mode",
                      border: OutlineInputBorder(),
                    ),
                    items: ["Dine-in", "Takeaway", "Delivery"]
                        .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                        .toList(),
                    onChanged: (val) => setState(() => parcelMode = val),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: amountReceivedController,
                    decoration: const InputDecoration(
                      labelText: "Amount Received (₹)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: "Note",
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
                            "Order Summary",
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
                              const Text("Service Charge:"),
                              Text("+₹${serviceCharge.toStringAsFixed(2)}"),
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
                          if (amountDue > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Amount Due: ₹${amountDue.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
