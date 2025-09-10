import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_models.dart';
import '../models/sales.dart';
import '../models/expense.dart';
import '../models/purchase.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Daily Sales Report
  Future<SalesReport> getDailySalesReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return SalesReport(
        date: startOfDay,
        totalSales: 0,
        totalTransactions: 0,
        averageOrderValue: 0,
        topItems: const [],
        paymentModeBreakdown: const {},
      );
    }

    // Query user-scoped docs, filter by createdAt in memory to avoid composite index requirement
    final salesSnap = await _firestore
        .collection('sales')
        .where('userId', isEqualTo: userId)
        .get();

    final filteredDocs = salesSnap.docs.where((d) {
      final data = d.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      return createdAt != null &&
          createdAt.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
          createdAt.isBefore(endOfDay);
    }).toList();

    return _generateSalesReport(filteredDocs, date);
  }

  // Monthly Sales Report
  Future<SalesReport> getMonthlySalesReport(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return SalesReport(
        date: startOfMonth,
        totalSales: 0,
        totalTransactions: 0,
        averageOrderValue: 0,
        topItems: const [],
        paymentModeBreakdown: const {},
      );
    }

    final salesSnap = await _firestore
        .collection('sales')
        .where('userId', isEqualTo: userId)
        .get();

    final filteredDocs = salesSnap.docs.where((d) {
      final data = d.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      return createdAt != null &&
          createdAt.isAfter(startOfMonth.subtract(const Duration(milliseconds: 1))) &&
          createdAt.isBefore(endOfMonth);
    }).toList();

    return _generateSalesReport(filteredDocs, startOfMonth);
  }

  // Custom Date Range Sales Report
  Future<SalesReport> getSalesReportByDateRange(DateTime startDate, DateTime endDate) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return SalesReport(
        date: startDate,
        totalSales: 0,
        totalTransactions: 0,
        averageOrderValue: 0,
        topItems: const [],
        paymentModeBreakdown: const {},
      );
    }

    final salesSnap = await _firestore
        .collection('sales')
        .where('userId', isEqualTo: userId)
        .get();

    final inclusiveEnd = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));
    final filteredDocs = salesSnap.docs.where((d) {
      final data = d.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      return createdAt != null &&
          createdAt.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
          createdAt.isBefore(inclusiveEnd);
    }).toList();

    return _generateSalesReport(filteredDocs, startDate);
  }

  // Generate Sales Report from documents
  SalesReport _generateSalesReport(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, DateTime date) {
    double totalSales = 0;
    int totalTransactions = docs.length;
    Map<String, int> itemQuantities = {};
    Map<String, double> itemRevenues = {};
    Map<String, double> paymentModes = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final sales = SalesTransaction.fromMap(doc.id, data);
      
      totalSales += sales.totalAmount;
      
      // Payment mode breakdown
      final paymentMode = sales.paymentMode.isEmpty ? 'Cash' : sales.paymentMode;
      paymentModes[paymentMode] = (paymentModes[paymentMode] ?? 0) + sales.totalAmount;
      
      // Item analysis
      for (var item in sales.items) {
        final name = item.itemName;
        itemQuantities[name] = (itemQuantities[name] ?? 0) + item.quantity;
        // Prefer totalPrice to avoid rounding issues
        final revenueAddition = (item.totalPrice != 0) ? item.totalPrice : (item.price * item.quantity);
        itemRevenues[name] = (itemRevenues[name] ?? 0) + revenueAddition;
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
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return ProfitLossReport(
        startDate: startDate,
        endDate: endDate,
        totalRevenue: 0,
        totalCostOfGoods: 0,
        grossProfit: 0,
        totalExpenses: 0,
        netProfit: 0,
        profitMargin: 0,
        expenseBreakdown: const [],
      );
    }

    final inclusiveEnd = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    // Get user-scoped docs, then filter by date fields in memory
    final salesSnap = await _firestore.collection('sales').where('userId', isEqualTo: userId).get();
    final expenseSnap = await _firestore.collection('expenses').where('userId', isEqualTo: userId).get();
    final purchaseSnap = await _firestore.collection('purchases').where('userId', isEqualTo: userId).get();

    final salesDocs = salesSnap.docs.where((d) {
      final createdAt = (d.data()['createdAt'] as Timestamp?)?.toDate();
      return createdAt != null &&
          createdAt.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
          createdAt.isBefore(inclusiveEnd);
    }).toList();

    final expenseDocs = expenseSnap.docs.where((d) {
      final expenseDate = (d.data()['expenseDate'] as Timestamp?)?.toDate();
      return expenseDate != null &&
          expenseDate.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
          expenseDate.isBefore(inclusiveEnd);
    }).toList();

    final purchaseDocs = purchaseSnap.docs.where((d) {
      final purchaseDate = (d.data()['purchaseDate'] as Timestamp?)?.toDate();
      return purchaseDate != null &&
          purchaseDate.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
          purchaseDate.isBefore(inclusiveEnd);
    }).toList();

    return _generateProfitLossReport(salesDocs, expenseDocs, purchaseDocs, startDate, endDate);
  }

  ProfitLossReport _generateProfitLossReport(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> salesDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> expenseDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> purchaseDocs,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Calculate total revenue
    double totalRevenue = 0;
    for (var doc in salesDocs) {
      final data = doc.data();
      final sales = SalesTransaction.fromMap(doc.id, data);
      totalRevenue += sales.totalAmount;
    }

    // Calculate total cost of goods sold (COGS)
    double totalCostOfGoods = 0;
    for (var doc in purchaseDocs) {
      final data = doc.data();
      final purchase = PurchaseOrder.fromMap(doc.id, data);
      totalCostOfGoods += purchase.totalAmount;
    }

    // Calculate total expenses
    double totalExpenses = 0;
    Map<String, double> expenseCategories = {};
    
    for (var doc in expenseDocs) {
      final data = doc.data();
      final expense = ExpenseEntry.fromMap(doc.id, data);
      totalExpenses += expense.amount;
      
      final category = expense.category;
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
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return GSTReport(
        startDate: startDate,
        endDate: endDate,
        totalSales: 0,
        totalPurchases: 0,
        outputGST: 0,
        inputGST: 0,
        netGST: 0,
        gstItems: const [],
      );
    }

    final inclusiveEnd = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    // Get user-scoped docs, then filter by date fields in memory
    final salesSnap = await _firestore.collection('sales').where('userId', isEqualTo: userId).get();
    final purchaseSnap = await _firestore.collection('purchases').where('userId', isEqualTo: userId).get();

    final salesDocs = salesSnap.docs.where((d) {
      final createdAt = (d.data()['createdAt'] as Timestamp?)?.toDate();
      return createdAt != null &&
          createdAt.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
          createdAt.isBefore(inclusiveEnd);
    }).toList();

    final purchaseDocs = purchaseSnap.docs.where((d) {
      final purchaseDate = (d.data()['purchaseDate'] as Timestamp?)?.toDate();
      return purchaseDate != null &&
          purchaseDate.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
          purchaseDate.isBefore(inclusiveEnd);
    }).toList();

    return _generateGSTReport(salesDocs, purchaseDocs, startDate, endDate);
  }

  GSTReport _generateGSTReport(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> salesDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> purchaseDocs,
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
      final data = doc.data();
      final sales = SalesTransaction.fromMap(doc.id, data);
      totalSales += sales.totalAmount;
      
      // Assuming 18% GST rate - you can make this configurable
      const double gstRate = 18.0;
      final taxableAmount = sales.totalAmount / (1 + gstRate / 100);
      final gstAmount = sales.totalAmount - taxableAmount;
      outputGST += gstAmount;

      // Add GST items for sales
      for (var item in sales.items) {
        final lineTotal = item.totalPrice != 0 ? item.totalPrice : (item.price * item.quantity);
        final itemTaxableAmount = lineTotal / (1 + gstRate / 100);
        final itemGSTAmount = lineTotal - itemTaxableAmount;
        
        gstItems.add(GSTItem(
          itemName: item.itemName,
          taxableAmount: itemTaxableAmount,
          gstRate: gstRate,
          gstAmount: itemGSTAmount,
          type: 'sale',
        ));
      }
    }

    // Process purchases (input GST)
    for (var doc in purchaseDocs) {
      final data = doc.data();
      final purchase = PurchaseOrder.fromMap(doc.id, data);
      totalPurchases += purchase.totalAmount;
      
      // Assuming 18% GST rate
      const double gstRate = 18.0;
      final taxableAmount = purchase.totalAmount / (1 + gstRate / 100);
      final gstAmount = purchase.totalAmount - taxableAmount;
      inputGST += gstAmount;

      // Add GST items for purchases
      for (var item in purchase.items) {
        final lineTotal = item.totalCost;
        final itemTaxableAmount = lineTotal / (1 + gstRate / 100);
        final itemGSTAmount = lineTotal - itemTaxableAmount;
        
        gstItems.add(GSTItem(
          itemName: item.itemName,
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
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final inclusiveEnd = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    final salesSnap = await _firestore
        .collection('sales')
        .where('userId', isEqualTo: userId)
        .get();

    Map<String, double> dailySales = {};
    
    for (var doc in salesSnap.docs) {
      final data = doc.data();
      final sales = SalesTransaction.fromMap(doc.id, data);
      final date = sales.createdAt;
      if (date.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
          date.isBefore(inclusiveEnd)) {
        final dateKey = '${date.day}/${date.month}';
        dailySales[dateKey] = (dailySales[dateKey] ?? 0) + sales.totalAmount;
      }
    }

    return dailySales.entries.map((entry) => {
      'date': entry.key,
      'amount': entry.value,
    }).toList();
  }
}
