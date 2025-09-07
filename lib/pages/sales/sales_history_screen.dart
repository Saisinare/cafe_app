import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../models/sales.dart';
import '../../models/premium_subscription.dart';
import '../../services/receipt_printer_service.dart';
import '../premium/premium_subscription_screen.dart';
 

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  PremiumSubscription? _currentSubscription;
  bool _isLoadingPremium = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  void _checkPremiumStatus() {
    try {
      final subscriptionStream = FirestoreService.instance.streamCurrentUserSubscription();
      subscriptionStream.listen((subscription) {
        if (mounted) {
          setState(() {
            _currentSubscription = subscription;
            _isLoadingPremium = false;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _isLoadingPremium = false;
          });
          print('Error checking premium status: $error');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPremium = false;
        });
      }
      print('Error setting up premium status stream: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    // Show loading while checking premium status
    if (_isLoadingPremium) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Sales History"),
          backgroundColor: const Color(0xFF6F4E37),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Check if user has premium access
    if (_currentSubscription?.isValid != true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Sales History"),
          backgroundColor: const Color(0xFF6F4E37),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_border,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              const Text(
                'Premium Feature',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Sales History is a premium feature. Upgrade to premium to access detailed sales history, analytics, and more advanced features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PremiumSubscriptionScreen()),
                  );
                },
                icon: const Icon(Icons.star),
                label: const Text('Upgrade to Premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F4E37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User has premium access, show the sales history
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales History"),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SalesTransaction>>(
        stream: FirestoreService.instance.streamSales(),
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
                  Text('Error loading sales: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final sales = snapshot.data ?? [];

          if (sales.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No sales yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first sale to see it here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: sale.paymentReceived 
                        ? Colors.green 
                        : Colors.orange,
                    child: Icon(
                      sale.paymentReceived ? Icons.check : Icons.pending,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    sale.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${sale.items.length} items • ${sale.parcelMode}",
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${sale.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          // Ask for custom footer before printing
                          final footer = await showDialog<String>(
                            context: context,
                            builder: (ctx) {
                              final controller = TextEditingController(text: 'Thank you! Visit again.');
                              return AlertDialog(
                                title: const Text('Custom Footer'),
                                content: TextField(
                                  controller: controller,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter footer text (optional)'
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, null),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                                    child: const Text('Print'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (footer == null) return;

                          final devices = await ReceiptPrinterService.instance.scanDevices();
                          if (devices.isEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No paired Bluetooth printers found')),
                              );
                            }
                            return;
                          }

                          final device = devices.first;
                          final connected = await ReceiptPrinterService.instance.connect(device);
                          if (!connected) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to connect to ${device.name}')),
                              );
                            }
                            return;
                          }

                          // Fetch business info from current user profile to avoid hardcoding
                          String? userId = FirestoreService.instance.currentUserId;
                          Map<String, dynamic>? userData;
                          if (userId != null) {
                            userData = await FirestoreService.instance.getUserData(userId);
                          }

                          final businessName = (userData?['businessName'] ?? userData?['name'] ?? '');
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
                          final gstRateVal = (() {
                            final v = userData?['gstRate'];
                            if (v == null) return 0.0;
                            if (v is num) return v.toDouble();
                            final parsed = double.tryParse(v.toString());
                            return parsed ?? 0.0;
                          })();

                          // Load receipt settings
                          String? customHeader;
                          String? customFooter;
                          double? headerFontSize;
                          double? footerFontSize;
                          
                          try {
                            final receiptDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirestoreService.instance.currentUserId!)
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

                          final ok = await ReceiptPrinterService.instance.printSaleReceipt(
                            sale,
                            businessName: businessName.isEmpty ? 'Receipt' : businessName,
                            addressLine1: addressLine1,
                            addressLine2: addressLine2,
                            contact: contact.isEmpty ? null : contact,
                            invoiceNumber: sale.id,
                            gstRate: gstRateVal > 1 ? gstRateVal / 100.0 : gstRateVal,
                            customHeader: customHeader,
                            customFooter: footer.isEmpty ? customFooter : footer,
                            headerFontSize: headerFontSize,
                            footerFontSize: footerFontSize,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok ? 'Receipt sent to printer' : 'Failed to print receipt')),
                            );
                          }
                        },
                        child: const Icon(Icons.print, color: Colors.blueGrey, size: 20),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Items List
                          const Text(
                            "Items:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...sale.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text("${item.itemName} (${item.category})"),
                                ),
                                Text("${item.quantity} × ₹${item.price}"),
                                Text("₹${item.totalPrice.toStringAsFixed(2)}"),
                              ],
                            ),
                          )),
                          
                          const Divider(),
                          
                          // Payment Details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Payment Mode:"),
                              Text(sale.paymentMode),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Payment Status:"),
                              Text(
                                sale.paymentReceived ? "Paid" : "Pending",
                                style: TextStyle(
                                  color: sale.paymentReceived ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          if (!sale.paymentReceived && sale.billingTerm != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Billing Term:"),
                                Text(sale.billingTerm!),
                              ],
                            ),
                            if (sale.billDueDate != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Due Date:"),
                                  Text(sale.billDueDate.toString().split(' ')[0]),
                                ],
                              ),
                          ],
                          
                          const Divider(),
                          
                          // Financial Summary
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Subtotal:"),
                              Text("₹${sale.subtotal.toStringAsFixed(2)}"),
                            ],
                          ),
                          if (sale.discount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Discount:"),
                                Text("-₹${(sale.subtotal * sale.discount / 100).toStringAsFixed(2)}"),
                              ],
                            ),
                          if (sale.serviceCharge > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Service Charge:"),
                                Text("+₹${sale.serviceCharge.toStringAsFixed(2)}"),
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
                                "₹${sale.totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Amount Received:"),
                              Text("₹${sale.amountReceived.toStringAsFixed(2)}"),
                            ],
                          ),
                          if (sale.totalAmount > sale.amountReceived)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Amount Due:",
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "₹${(sale.totalAmount - sale.amountReceived).toStringAsFixed(2)}",
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          
                          if (sale.note != null && sale.note!.isNotEmpty) ...[
                            const Divider(),
                            const Text(
                              "Note:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(sale.note!),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Implement edit functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Edit functionality coming soon!')),
                                  );
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Sale'),
                                      content: const Text(
                                        'Are you sure you want to delete this sale? This will restore the stock quantities.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirm == true) {
                                    try {
                                      await FirestoreService.instance.deleteSalesTransaction(sale.id!);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Sale deleted successfully')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error deleting sale: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}