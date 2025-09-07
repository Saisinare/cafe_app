import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_models.dart';
import '../models/sales.dart';
import '../models/expense.dart';
import '../models/purchase.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Daily Sales Report
  Future<SalesReport> getDailySalesReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final salesQuery = await _firestore
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return _generateSalesReport(salesQuery.docs, date);
  }

  // Monthly Sales Report
  Future<SalesReport> getMonthlySalesReport(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);

    final salesQuery = await _firestore
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    return _generateSalesReport(salesQuery.docs, startOfMonth);
  }

  // Custom Date Range Sales Report
  Future<SalesReport> getSalesReportByDateRange(DateTime startDate, DateTime endDate) async {
    final salesQuery = await _firestore
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThan: Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .get();

    return _generateSalesReport(salesQuery.docs, startDate);
  }

  // Generate Sales Report from documents
  SalesReport _generateSalesReport(List<QueryDocumentSnapshot> docs, DateTime date) {
    double totalSales = 0;
    int totalTransactions = docs.length;
    Map<String, int> itemQuantities = {};
    Map<String, double> itemRevenues = {};
    Map<String, double> paymentModes = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final sales = SalesTransaction.fromMap(data);
      
      totalSales += sales.totalAmount;
      
      // Payment mode breakdown
      final paymentMode = sales.paymentMode ?? 'Cash';
      paymentModes[paymentMode] = (paymentModes[paymentMode] ?? 0) + sales.totalAmount;
      
      // Item analysis
      for (var item in sales.items) {
        itemQuantities[item.name] = (itemQuantities[item.name] ?? 0) + item.quantity;
        itemRevenues[item.name] = (itemRevenues[item.name] ?? 0) + (item.price * item.quantity);
      }
    }

    // Generate top items
    List<SalesItemReport> topItems = [];
    itemQuantities.forEach((itemName, quantity) {
      final revenue = itemRevenues[itemName] ?? 0;
      topItems.add(SalesItemReport(
        itemName: itemName,
        quantitySold: quantity,
        totalRevenue: revenue,
        averagePrice: quantity > 0 ? revenue / quantity : 0,
      ));
    });

    // Sort by revenue
    topItems.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return SalesReport(
      date: date,
      totalSales: totalSales,
      totalTransactions: totalTransactions,
      averageOrderValue: totalTransactions > 0 ? totalSales / totalTransactions : 0,
      topItems: topItems.take(10).toList(),
      paymentModeBreakdown: paymentModes,
    );
  }

  // Profit & Loss Report
  Future<ProfitLossReport> getProfitLossReport(DateTime startDate, DateTime endDate) async {
    // Get sales data
    final salesQuery = await _firestore
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThan: Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .get();

    // Get expenses data
    final expensesQuery = await _firestore
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThan: Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .get();

    // Get purchases data for COGS
    final purchasesQuery = await _firestore
        .collection('purchases')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThan: Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .get();

    return _generateProfitLossReport(salesQuery.docs, expensesQuery.docs, purchasesQuery.docs, startDate, endDate);
  }

  ProfitLossReport _generateProfitLossReport(
    List<QueryDocumentSnapshot> salesDocs,
    List<QueryDocumentSnapshot> expenseDocs,
    List<QueryDocumentSnapshot> purchaseDocs,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Calculate total revenue
    double totalRevenue = 0;
    for (var doc in salesDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final sales = SalesTransaction.fromMap(data);
      totalRevenue += sales.totalAmount;
    }

    // Calculate total cost of goods sold (COGS)
    double totalCostOfGoods = 0;
    for (var doc in purchaseDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final purchase = Purchase.fromMap(data);
      totalCostOfGoods += purchase.totalAmount;
    }

    // Calculate total expenses
    double totalExpenses = 0;
    Map<String, double> expenseCategories = {};
    
    for (var doc in expenseDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final expense = Expense.fromMap(data);
      totalExpenses += expense.amount;
      
      final category = expense.category ?? 'Other';
      expenseCategories[category] = (expenseCategories[category] ?? 0) + expense.amount;
    }

    // Calculate profit metrics
    double grossProfit = totalRevenue - totalCostOfGoods;
    double netProfit = grossProfit - totalExpenses;
    double profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;

    // Generate expense breakdown
    List<ExpenseCategory> expenseBreakdown = [];
    expenseCategories.forEach((category, amount) {
      expenseBreakdown.add(ExpenseCategory(
        category: category,
        amount: amount,
        percentage: totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0,
      ));
    });

    // Sort by amount
    expenseBreakdown.sort((a, b) => b.amount.compareTo(a.amount));

    return ProfitLossReport(
      startDate: startDate,
      endDate: endDate,
      totalRevenue: totalRevenue,
      totalCostOfGoods: totalCostOfGoods,
      grossProfit: grossProfit,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      profitMargin: profitMargin,
      expenseBreakdown: expenseBreakdown,
    );
  }

  // GST Report
  Future<GSTReport> getGSTReport(DateTime startDate, DateTime endDate) async {
    // Get sales data for output GST
    final salesQuery = await _firestore
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThan: Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .get();

    // Get purchases data for input GST
    final purchasesQuery = await _firestore
        .collection('purchases')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThan: Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .get();

    return _generateGSTReport(salesQuery.docs, purchasesQuery.docs, startDate, endDate);
  }

  GSTReport _generateGSTReport(
    List<QueryDocumentSnapshot> salesDocs,
    List<QueryDocumentSnapshot> purchaseDocs,
    DateTime startDate,
    DateTime endDate,
  ) {
    double totalSales = 0;
    double totalPurchases = 0;
    double outputGST = 0;
    double inputGST = 0;
    List<GSTItem> gstItems = [];

    // Process sales (output GST)
    for (var doc in salesDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final sales = SalesTransaction.fromMap(data);
      totalSales += sales.totalAmount;
      
      // Assuming 18% GST rate - you can make this configurable
      const double gstRate = 18.0;
      final taxableAmount = sales.totalAmount / (1 + gstRate / 100);
      final gstAmount = sales.totalAmount - taxableAmount;
      outputGST += gstAmount;

      // Add GST items for sales
      for (var item in sales.items) {
        final itemTaxableAmount = (item.price * item.quantity) / (1 + gstRate / 100);
        final itemGSTAmount = (item.price * item.quantity) - itemTaxableAmount;
        
        gstItems.add(GSTItem(
          itemName: item.name,
          taxableAmount: itemTaxableAmount,
          gstRate: gstRate,
          gstAmount: itemGSTAmount,
          type: 'sale',
        ));
      }
    }

    // Process purchases (input GST)
    for (var doc in purchaseDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final purchase = Purchase.fromMap(data);
      totalPurchases += purchase.totalAmount;
      
      // Assuming 18% GST rate
      const double gstRate = 18.0;
      final taxableAmount = purchase.totalAmount / (1 + gstRate / 100);
      final gstAmount = purchase.totalAmount - taxableAmount;
      inputGST += gstAmount;

      // Add GST items for purchases
      for (var item in purchase.items) {
        final itemTaxableAmount = (item.price * item.quantity) / (1 + gstRate / 100);
        final itemGSTAmount = (item.price * item.quantity) - itemTaxableAmount;
        
        gstItems.add(GSTItem(
          itemName: item.name,
          taxableAmount: itemTaxableAmount,
          gstRate: gstRate,
          gstAmount: itemGSTAmount,
          type: 'purchase',
        ));
      }
    }

    double netGST = outputGST - inputGST;

    return GSTReport(
      startDate: startDate,
      endDate: endDate,
      totalSales: totalSales,
      totalPurchases: totalPurchases,
      outputGST: outputGST,
      inputGST: inputGST,
      netGST: netGST,
      gstItems: gstItems,
    );
  }

  // Get sales data for charts
  Future<List<Map<String, dynamic>>> getSalesChartData(DateTime startDate, DateTime endDate) async {
    final salesQuery = await _firestore
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThan: Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .orderBy('timestamp')
        .get();

    Map<String, double> dailySales = {};
    
    for (var doc in salesQuery.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final sales = SalesTransaction.fromMap(data);
      final date = sales.timestamp.toDate();
      final dateKey = '${date.day}/${date.month}';
      
      dailySales[dateKey] = (dailySales[dateKey] ?? 0) + sales.totalAmount;
    }

    return dailySales.entries.map((entry) => {
      'date': entry.key,
      'amount': entry.value,
    }).toList();
  }
}
