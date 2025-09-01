import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/sales_invoice.dart';
import 'sales_invoice_screen.dart';
import 'sales_invoice_print_preview.dart';
import 'sales_invoice_details_screen.dart';
import 'sales_invoice_edit_screen.dart';

class SalesInvoiceListScreen extends StatelessWidget {
  const SalesInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Invoices"),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalesInvoiceScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<SalesInvoice>>(
        stream: FirestoreService.instance.streamSalesInvoices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final invoices = snapshot.data ?? [];

          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No invoices yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first invoice to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalesInvoiceScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F4E37),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create Invoice'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(invoice.status),
                    child: Icon(
                      _getStatusIcon(invoice.status),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        invoice.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Due: ${_formatDate(invoice.dueDate)}',
                        style: TextStyle(
                          color: invoice.dueDate.isBefore(DateTime.now()) && invoice.status != 'paid'
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        'Status: ${invoice.status.toUpperCase()}',
                        style: TextStyle(
                          color: _getStatusColor(invoice.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${invoice.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${invoice.items.length} items',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    _showInvoiceOptions(context, invoice);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showInvoiceOptions(BuildContext context, SalesInvoice invoice) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility, color: Color(0xFF6F4E37)),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _viewInvoiceDetails(context, invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Color(0xFF6F4E37)),
              title: const Text('Print Preview'),
              onTap: () {
                Navigator.pop(context);
                _showPrintPreview(context, invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF6F4E37)),
              title: const Text('Edit Invoice'),
              onTap: () {
                Navigator.pop(context);
                _editInvoice(context, invoice);
              },
            ),
            if (invoice.status == 'draft') ...[
              ListTile(
                leading: const Icon(Icons.send, color: Colors.blue),
                title: const Text('Mark as Sent'),
                onTap: () {
                  Navigator.pop(context);
                  _updateInvoiceStatus(context, invoice, 'sent');
                },
              ),
            ],
            if (invoice.status == 'sent') ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Paid'),
                onTap: () {
                  Navigator.pop(context);
                  _updateInvoiceStatus(context, invoice, 'paid');
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _viewInvoiceDetails(BuildContext context, SalesInvoice invoice) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirestoreService.instance.getUserData(user.uid);
        final businessInfo = {
          'cafeName': userDoc?['cafeName'] ?? 'Business Name',
          'address': userDoc?['address'] ?? 'Business Address',
          'phone': userDoc?['phone'] ?? 'Phone Number',
        };

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalesInvoiceDetailsScreen(
                invoice: invoice,
                businessInfo: businessInfo,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load business info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrintPreview(BuildContext context, SalesInvoice invoice) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirestoreService.instance.getUserData(user.uid);
        final businessInfo = {
          'cafeName': userDoc?['cafeName'] ?? 'Business Name',
          'address': userDoc?['address'] ?? 'Business Address',
          'phone': userDoc?['phone'] ?? 'Phone Number',
        };

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalesInvoicePrintPreview(
                invoice: invoice,
                businessInfo: businessInfo,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load business info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editInvoice(BuildContext context, SalesInvoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesInvoiceEditScreen(
          invoice: invoice,
        ),
      ),
    );
  }

  Future<void> _updateInvoiceStatus(BuildContext context, SalesInvoice invoice, String newStatus) async {
    try {
      await FirestoreService.instance.updateInvoiceStatus(invoice.id!, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update invoice status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit;
      case 'sent':
        return Icons.send;
      case 'paid':
        return Icons.check;
      case 'overdue':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }
}
