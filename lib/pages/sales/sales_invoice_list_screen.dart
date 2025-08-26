import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/sales_invoice.dart';
import 'sales_invoice_screen.dart';

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
                      Text(invoice.customerName),
                      Text(
                        'Due: ${invoice.dueDate.toString().split(' ')[0]}',
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
                    // Navigate to invoice details or edit screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SalesInvoiceScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
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
