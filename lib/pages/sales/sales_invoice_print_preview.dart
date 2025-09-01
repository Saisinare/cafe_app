import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/sales_invoice.dart';
import 'package:intl/intl.dart';

class SalesInvoicePrintPreview extends StatelessWidget {
  final SalesInvoice invoice;
  final Map<String, dynamic> businessInfo;

  const SalesInvoicePrintPreview({
    super.key,
    required this.invoice,
    required this.businessInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Print Preview'),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareInvoice(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Print Preview
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildInvoicePreview(),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _printInvoice(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F4E37),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.print),
                    label: const Text('Print Invoice'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareInvoice(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicePreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Header
          Center(
            child: Column(
              children: [
                Text(
                  businessInfo['cafeName'] ?? 'Business Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  businessInfo['address'] ?? 'Business Address',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contact: ${businessInfo['phone'] ?? 'Phone Number'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black,
            width: double.infinity,
          ),
          
          const SizedBox(height: 20),
          
          // Invoice Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice No: ${invoice.invoiceNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('dd-MMM-yyyy').format(invoice.invoiceDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time: ${DateFormat('hh:mm a').format(invoice.invoiceDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Customer: ${invoice.customerName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (invoice.customerPhone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Phone: ${invoice.customerPhone}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  if (invoice.customerAddress != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Address: ${invoice.customerAddress}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black,
            width: double.infinity,
          ),
          
          const SizedBox(height: 20),
          
          // Items Table Header
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Item',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Qty',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Rate',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black,
            width: double.infinity,
          ),
          
          const SizedBox(height: 16),
          
          // Items
          ...invoice.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${item.unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black,
            width: double.infinity,
          ),
          
          const SizedBox(height: 20),
          
          // Summary
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '₹${invoice.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (invoice.discount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discount',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '-₹${invoice.discount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GST (${(invoice.cgstRate + invoice.sgstRate).toStringAsFixed(0)}%)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '₹${invoice.totalTax.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Divider
              Container(
                height: 1,
                color: Colors.black,
                width: double.infinity,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '₹${invoice.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black,
            width: double.infinity,
          ),
          
          const SizedBox(height: 20),
          
          // Footer
          Center(
            child: Column(
              children: [
                const Text(
                  'Thank you for shopping!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Visit again soon.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Generated on: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Preparing invoice for printing...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildPdfInvoice(),
        ),
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${invoice.invoiceNumber}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice sent to printer successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print invoice: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _printInvoice(context),
            ),
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfInvoice() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Business Header
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                businessInfo['cafeName'] ?? 'Business Name',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                businessInfo['address'] ?? 'Business Address',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Contact: ${businessInfo['phone'] ?? 'Phone Number'}',
                style: const pw.TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // Divider
        pw.Divider(thickness: 1),
        
        pw.SizedBox(height: 20),
        
        // Invoice Details
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Invoice No: ${invoice.invoiceNumber}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Date: ${DateFormat('dd-MMM-yyyy').format(invoice.invoiceDate)}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Time: ${DateFormat('hh:mm a').format(invoice.invoiceDate)}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Customer: ${invoice.customerName}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (invoice.customerPhone != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Phone: ${invoice.customerPhone}',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ],
                if (invoice.customerAddress != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Address: ${invoice.customerAddress}',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Divider
        pw.Divider(thickness: 1),
        
        pw.SizedBox(height: 20),
        
        // Items Table Header
        pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                'Item',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                'Qty',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Rate',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Amount',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        pw.SizedBox(height: 16),
        
        // Divider
        pw.Divider(thickness: 1),
        
        pw.SizedBox(height: 16),
        
        // Items
        ...invoice.items.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  item.itemName,
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  '${item.quantity}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  '₹${item.unitPrice.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  '₹${item.totalPrice.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        )).toList(),
        
        pw.SizedBox(height: 16),
        
        // Divider
        pw.Divider(thickness: 1),
        
        pw.SizedBox(height: 20),
        
        // Summary
        pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '₹${invoice.subtotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            if (invoice.discount > 0) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Discount',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.Text(
                    '-₹${invoice.discount.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
            ],
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'GST (${(invoice.cgstRate + invoice.sgstRate).toStringAsFixed(0)}%)',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  '₹${invoice.totalTax.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            
            // Divider
            pw.Divider(thickness: 1),
            
            pw.SizedBox(height: 16),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Grand Total',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '₹${invoice.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Divider
        pw.Divider(thickness: 1),
        
        pw.SizedBox(height: 20),
        
        // Footer
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Thank you for shopping!',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Visit again soon.',
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Generated on: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _shareInvoice(BuildContext context) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Preparing invoice for sharing...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Generate PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildPdfInvoice(),
        ),
      );

      // Save PDF to temporary file
      final bytes = await pdf.save();
      
      // Show sharing options
      if (context.mounted) {
        _showSharingOptions(context, bytes);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare invoice for sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSharingOptions(BuildContext context, List<int> pdfBytes) {
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
            const Text(
              'Share Invoice',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.download, color: Color(0xFF6F4E37)),
              title: const Text('Save to Device'),
              subtitle: const Text('Download PDF to your device'),
              onTap: () {
                Navigator.pop(context);
                _savePdfToDevice(context, pdfBytes);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF6F4E37)),
              title: const Text('Send via Email'),
              subtitle: const Text('Open email app with PDF attached'),
              onTap: () {
                Navigator.pop(context);
                _sendViaEmail(context, pdfBytes);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF6F4E37)),
              title: const Text('Share via Apps'),
              subtitle: const Text('Use system share sheet'),
              onTap: () {
                Navigator.pop(context);
                _shareViaSystem(context, pdfBytes);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _savePdfToDevice(BuildContext context, List<int> pdfBytes) {
    // TODO: Implement PDF saving to device
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF saving functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _sendViaEmail(BuildContext context, List<int> pdfBytes) {
    // TODO: Implement email sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email sharing functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareViaSystem(BuildContext context, List<int> pdfBytes) {
    // TODO: Implement system share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('System sharing functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
