import 'dart:async';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../models/sales.dart';

class ReceiptPrinterService {
  ReceiptPrinterService._();
  static final instance = ReceiptPrinterService._();

  Future<List<BluetoothInfo>> scanDevices() async {
    try {
      final hasPermission = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (hasPermission != true) {
        return <BluetoothInfo>[];
      }
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices;
    } catch (_) {
      return <BluetoothInfo>[];
    }
  }

  Future<bool> connect(BluetoothInfo device) async {
    try {
      final connected = await PrintBluetoothThermal.connectionStatus;
      if (connected == true) return true;
      final ok = await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
  }

  Future<bool> printSaleReceipt(
    SalesTransaction sale, {
    String businessName = 'Cafe',
    String? addressLine1,
    String? addressLine2,
    String? contact,
    String? invoiceNumber,
    double gstRate = 0.0,
    String? customFooter,
    String? customHeader,
    double? headerFontSize,
    double? footerFontSize,
  }) async {
    try {
      final isConnected = await PrintBluetoothThermal.connectionStatus;
      if (isConnected != true) return false;

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Helpers for 58mm
      const int lineWidth = 32;
      String line([String ch = '-']) => List.filled(lineWidth, ch).join();
      String center(String text) {
        final t = text.trim();
        if (t.length >= lineWidth) return t.substring(0, lineWidth);
        final pad = (lineWidth - t.length) ~/ 2;
        return ' ' * pad + t;
      }
      String col4(String c1, String c2, String c3, String c4) {
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
      if (customHeader != null && customHeader.trim().isNotEmpty) {
        final headerStyle = PosStyles(
          bold: true, 
          height: PosTextSize.size2, 
          width: PosTextSize.size2,
        );
        bytes += generator.text(center(customHeader), styles: headerStyle, linesAfter: 0);
      } else {
        bytes += generator.text(center(businessName), styles: PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2), linesAfter: 0);
      }
      if (addressLine1 != null && addressLine1.trim().isNotEmpty) {
        bytes += generator.text(center(addressLine1));
      }
      if (addressLine2 != null && addressLine2.trim().isNotEmpty) {
        bytes += generator.text(center(addressLine2));
      }
      if (contact != null && contact.trim().isNotEmpty) {
        bytes += generator.text(center('Contact: $contact'));
      }
      bytes += generator.text(line());

      // Invoice meta
      if (inv.isNotEmpty) bytes += generator.text('Invoice No: $inv');
      bytes += generator.text('Date: $dateStr  Time: $timeStr');
      
      // Customer information
      if (sale.customerName.isNotEmpty) {
        bytes += generator.text('Customer: ${sale.customerName}');
      }
      if (sale.customerPhone != null && sale.customerPhone!.isNotEmpty) {
        bytes += generator.text('Phone: ${sale.customerPhone}');
      }
      bytes += generator.text(line());

      // Items header
      bytes += generator.text(col4('Item', 'Qty', 'Rate', 'Amount'));
      bytes += generator.text(line());
      for (final it in sale.items) {
        bytes += generator.text(
          col4(
            it.itemName,
            it.quantity.toString(),
            money(it.price),
            money(it.totalPrice),
          ),
        );
      }
      bytes += generator.text(line());

      // Totals
      bytes += generator.text(col4('', '', 'Total', money(sale.subtotal)));
      if (sale.discount > 0) {
        bytes += generator.text(col4('', '', 'Discount', money(sale.discount)));
      }
      if (gstRate > 0) {
        final gstAmount = (sale.subtotal - sale.discount + sale.serviceCharge) * gstRate;
        final pct = (gstRate * 100).toStringAsFixed(0);
        bytes += generator.text(col4('', '', 'GST ($pct%)', money(gstAmount)));
      }
      if (sale.serviceCharge > 0) {
        bytes += generator.text(col4('', '', 'Service', money(sale.serviceCharge)));
      }
      bytes += generator.text(line());
      bytes += generator.text(col4('', '', 'Grand Total', money(sale.totalAmount)), styles: PosStyles(bold: true));
      bytes += generator.text(line());

      // Footer
      if (customFooter != null && customFooter.trim().isNotEmpty) {
        final lines = customFooter.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (final l in lines) {
          final footerStyle = PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          );
          bytes += generator.text(center(l), styles: footerStyle);
        }
      } else {
        bytes += generator.text(center('Thank you for shopping!'));
        bytes += generator.text(center('Visit again soon.'));
      }
      bytes += generator.feed(2);
      bytes += generator.cut();

      final ok = await PrintBluetoothThermal.writeBytes(bytes);
      return ok == true;
    } catch (_) {
      return false;
    }
  }
}


