import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/report_models.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // Export Sales Report to Excel
  Future<String> exportSalesReportToExcel(SalesReport report) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sales Report'];

    // Add headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Sales Report');
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Date: ${_formatDate(report.date)}');
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Total Sales: ₹${report.totalSales.toStringAsFixed(2)}');
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Total Transactions: ${report.totalTransactions}');
    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Average Order Value: ₹${report.averageOrderValue.toStringAsFixed(2)}');

    // Add top items
    sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue('Top Selling Items');
    sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Item Name');
    sheet.cell(CellIndex.indexByString('B8')).value = TextCellValue('Quantity Sold');
    sheet.cell(CellIndex.indexByString('C8')).value = TextCellValue('Total Revenue');
    sheet.cell(CellIndex.indexByString('D8')).value = TextCellValue('Average Price');

    int row = 9;
    for (var item in report.topItems) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(item.itemName);
      sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(item.quantitySold);
      sheet.cell(CellIndex.indexByString('C$row')).value = DoubleCellValue(item.totalRevenue);
      sheet.cell(CellIndex.indexByString('D$row')).value = DoubleCellValue(item.averagePrice);
      row++;
    }

    // Add payment mode breakdown
    row += 2;
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Payment Mode Breakdown');
    row++;
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Payment Mode');
    sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue('Amount');

    row++;
    report.paymentModeBreakdown.forEach((mode, amount) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(mode);
      sheet.cell(CellIndex.indexByString('B$row')).value = DoubleCellValue(amount);
      row++;
    });

    return await _saveExcelFile(excel, 'sales_report_${_formatDateForFile(report.date)}.xlsx');
  }

  // Export Profit & Loss Report to Excel
  Future<String> exportProfitLossReportToExcel(ProfitLossReport report) async {
    final excel = Excel.createExcel();
    final sheet = excel['Profit & Loss Report'];

    // Add headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Profit & Loss Report');
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Period: ${_formatDate(report.startDate)} to ${_formatDate(report.endDate)}');
    
    // Add financial summary
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Total Revenue');
    sheet.cell(CellIndex.indexByString('B4')).value = DoubleCellValue(report.totalRevenue);
    
    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Cost of Goods Sold');
    sheet.cell(CellIndex.indexByString('B5')).value = DoubleCellValue(report.totalCostOfGoods);
    
    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Gross Profit');
    sheet.cell(CellIndex.indexByString('B6')).value = DoubleCellValue(report.grossProfit);
    
    sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue('Total Expenses');
    sheet.cell(CellIndex.indexByString('B7')).value = DoubleCellValue(report.totalExpenses);
    
    sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Net Profit');
    sheet.cell(CellIndex.indexByString('B8')).value = DoubleCellValue(report.netProfit);
    
    sheet.cell(CellIndex.indexByString('A9')).value = TextCellValue('Profit Margin (%)');
    sheet.cell(CellIndex.indexByString('B9')).value = DoubleCellValue(report.profitMargin);

    // Add expense breakdown
    sheet.cell(CellIndex.indexByString('A11')).value = TextCellValue('Expense Breakdown');
    sheet.cell(CellIndex.indexByString('A12')).value = TextCellValue('Category');
    sheet.cell(CellIndex.indexByString('B12')).value = TextCellValue('Amount');
    sheet.cell(CellIndex.indexByString('C12')).value = TextCellValue('Percentage');

    int row = 13;
    for (var expense in report.expenseBreakdown) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(expense.category);
      sheet.cell(CellIndex.indexByString('B$row')).value = DoubleCellValue(expense.amount);
      sheet.cell(CellIndex.indexByString('C$row')).value = DoubleCellValue(expense.percentage);
      row++;
    }

    return await _saveExcelFile(excel, 'profit_loss_report_${_formatDateForFile(report.startDate)}.xlsx');
  }

  // Export GST Report to Excel
  Future<String> exportGSTReportToExcel(GSTReport report) async {
    final excel = Excel.createExcel();
    final sheet = excel['GST Report'];

    // Add headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('GST Report');
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Period: ${_formatDate(report.startDate)} to ${_formatDate(report.endDate)}');
    
    // Add GST summary
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Total Sales');
    sheet.cell(CellIndex.indexByString('B4')).value = DoubleCellValue(report.totalSales);
    
    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Total Purchases');
    sheet.cell(CellIndex.indexByString('B5')).value = DoubleCellValue(report.totalPurchases);
    
    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Output GST');
    sheet.cell(CellIndex.indexByString('B6')).value = DoubleCellValue(report.outputGST);
    
    sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue('Input GST');
    sheet.cell(CellIndex.indexByString('B7')).value = DoubleCellValue(report.inputGST);
    
    sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Net GST');
    sheet.cell(CellIndex.indexByString('B8')).value = DoubleCellValue(report.netGST);

    // Add GST items
    sheet.cell(CellIndex.indexByString('A10')).value = TextCellValue('GST Items');
    sheet.cell(CellIndex.indexByString('A11')).value = TextCellValue('Item Name');
    sheet.cell(CellIndex.indexByString('B11')).value = TextCellValue('Type');
    sheet.cell(CellIndex.indexByString('C11')).value = TextCellValue('Taxable Amount');
    sheet.cell(CellIndex.indexByString('D11')).value = TextCellValue('GST Rate (%)');
    sheet.cell(CellIndex.indexByString('E11')).value = TextCellValue('GST Amount');

    int row = 12;
    for (var item in report.gstItems) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(item.itemName);
      sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(item.type);
      sheet.cell(CellIndex.indexByString('C$row')).value = DoubleCellValue(item.taxableAmount);
      sheet.cell(CellIndex.indexByString('D$row')).value = DoubleCellValue(item.gstRate);
      sheet.cell(CellIndex.indexByString('E$row')).value = DoubleCellValue(item.gstAmount);
      row++;
    }

    return await _saveExcelFile(excel, 'gst_report_${_formatDateForFile(report.startDate)}.xlsx');
  }

  // Export Sales Report to PDF
  Future<String> exportSalesReportToPDF(SalesReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Date: ${_formatDate(report.date)}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Total Sales: ₹${report.totalSales.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Total Transactions: ${report.totalTransactions}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Average Order Value: ₹${report.averageOrderValue.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                child: pw.Text('Top Selling Items', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Revenue', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Avg Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...report.topItems.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.itemName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.quantitySold.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${item.totalRevenue.toStringAsFixed(2)}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${item.averagePrice.toStringAsFixed(2)}'),
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                child: pw.Text('Payment Mode Breakdown', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Payment Mode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...report.paymentModeBreakdown.entries.map((entry) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(entry.key),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${entry.value.toStringAsFixed(2)}'),
                      ),
                    ],
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );

    return await _savePDFFile(pdf, 'sales_report_${_formatDateForFile(report.date)}.pdf');
  }

  // Export Profit & Loss Report to PDF
  Future<String> exportProfitLossReportToPDF(ProfitLossReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Profit & Loss Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Period: ${_formatDate(report.startDate)} to ${_formatDate(report.endDate)}', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total Revenue', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${report.totalRevenue.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Cost of Goods Sold', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${report.totalCostOfGoods.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Gross Profit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${report.grossProfit.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total Expenses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${report.totalExpenses.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Net Profit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${report.netProfit.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Profit Margin (%)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${report.profitMargin.toStringAsFixed(2)}%'),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                child: pw.Text('Expense Breakdown', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Percentage', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...report.expenseBreakdown.map((expense) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(expense.category),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${expense.amount.toStringAsFixed(2)}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${expense.percentage.toStringAsFixed(2)}%'),
                      ),
                    ],
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );

    return await _savePDFFile(pdf, 'profit_loss_report_${_formatDateForFile(report.startDate)}.pdf');
  }

  // Export GST Report to PDF
  Future<String> exportGSTReportToPDF(GSTReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('GST Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Period: ${_formatDate(report.startDate)} to ${_formatDate(report.endDate)}', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total Sales', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${report.totalSales.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total Purchases', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${report.totalPurchases.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Output GST', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${report.outputGST.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Input GST', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${report.inputGST.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Net GST', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${report.netGST.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return await _savePDFFile(pdf, 'gst_report_${_formatDateForFile(report.startDate)}.pdf');
  }

  // Helper methods
  Future<String> _saveExcelFile(Excel excel, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
      return file.path;
    }
    throw Exception('Failed to save Excel file');
  }

  Future<String> _savePDFFile(pw.Document pdf, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)]);
    return file.path;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateForFile(DateTime date) {
    return '${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';
  }
}
