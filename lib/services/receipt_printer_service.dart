import 'dart:async';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import '../models/sales.dart';

class ReceiptPrinterService {
  ReceiptPrinterService._();
  static final instance = ReceiptPrinterService._();

  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> scanDevices() async {
    try {
      final bonded = await _printer.getBondedDevices();
      return bonded;
    } catch (_) {
      return <BluetoothDevice>[];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      final isConnected = await _printer.isConnected ?? false;
      if (isConnected) return true;
      await _printer.connect(device);
      return await _printer.isConnected ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _printer.disconnect();
    } catch (_) {}
  }

  Future<bool> printSaleReceipt(
    SalesTransaction sale, {
    String businessName = 'Cafe',
    String? addressLine1,
    String? addressLine2,
    String? contact,
    String? invoiceNumber,
    double gstRate = 0.0, // e.g., 0.05 for 5%
  }) async {
    try {
      final connected = await _printer.isConnected ?? false;
      if (!connected) return false;

      // Helpers for 58mm (~32 chars per line at font size 0)
      const int lineWidth = 32;
      String line([String ch = '-']) => List.filled(lineWidth, ch).join();

      String center(String text) {
        final t = text.trim();
        if (t.length >= lineWidth) return t.substring(0, lineWidth);
        final pad = (lineWidth - t.length) ~/ 2;
        return ' ' * pad + t;
      }

      String col4(String c1, String c2, String c3, String c4) {
        // widths tuned for 58mm: item 12, qty 3, rate 7, amt 8
        String t1 = c1.length > 12 ? c1.substring(0, 12) : c1.padRight(12);
        String t2 = c2.padLeft(3);
        String t3 = c3.padLeft(7);
        String t4 = c4.padLeft(8);
        final s = '$t1$t2$t3$t4';
        return s.length > lineWidth ? s.substring(0, lineWidth) : s;
      }

      String money(double v) => v.toStringAsFixed(2);
      final dateStr = DateFormat('dd-MMM-yyyy').format(sale.createdAt);
      final timeStr = DateFormat('h:mm a').format(sale.createdAt);
      final inv = invoiceNumber ?? (sale.id ?? '');

      // Header
      _printer.printCustom(center(businessName), 1, 1);
      if (addressLine1 != null && addressLine1.trim().isNotEmpty) {
        _printer.printCustom(center(addressLine1), 0, 1);
      }
      if (addressLine2 != null && addressLine2.trim().isNotEmpty) {
        _printer.printCustom(center(addressLine2), 0, 1);
      }
      if (contact != null && contact.trim().isNotEmpty) {
        _printer.printCustom(center('Contact: $contact'), 0, 1);
      }
      _printer.printCustom(line(), 0, 1);

      // Invoice meta
      if (inv.isNotEmpty) _printer.printCustom('Invoice No: $inv', 0, 0);
      _printer.printCustom('Date: $dateStr  Time: $timeStr', 0, 0);
      _printer.printCustom(line(), 0, 1);

      // Items Header
      _printer.printCustom(col4('Item', 'Qty', 'Rate', 'Amount'), 0, 0);
      _printer.printCustom(line(), 0, 0);
      for (final it in sale.items) {
        _printer.printCustom(
          col4(
            it.itemName,
            it.quantity.toString(),
            money(it.price),
            money(it.totalPrice),
          ),
          0,
          0,
        );
      }
      _printer.printCustom(line(), 0, 0);

      // Totals
      // Show Subtotal -> Discount -> Service -> Total
      _printer.printCustom(col4('', '', 'Total', money(sale.subtotal)), 0, 0);
      if (sale.discount > 0) {
        _printer.printCustom(col4('', '', 'Discount', money(sale.discount)), 0, 0);
      }
      if (gstRate > 0) {
        final gstAmount = (sale.subtotal - sale.discount + sale.serviceCharge) * gstRate;
        final pct = (gstRate * 100).toStringAsFixed(0);
        _printer.printCustom(col4('', '', 'GST ($pct%)', money(gstAmount)), 0, 0);
      }
      if (sale.serviceCharge > 0) {
        _printer.printCustom(col4('', '', 'Service', money(sale.serviceCharge)), 0, 0);
      }
      _printer.printCustom(line(), 0, 0);
      _printer.printCustom(col4('', '', 'Grand Total', money(sale.totalAmount)), 1, 0);
      _printer.printCustom(line(), 0, 0);

      // Footer
      _printer.printCustom(center('Thank you for shopping!'), 0, 1);
      _printer.printCustom(center('Visit again soon.'), 0, 1);
      _printer.printNewLine();
      _printer.paperCut();

      return true;
    } catch (_) {
      return false;
    }
  }
}


