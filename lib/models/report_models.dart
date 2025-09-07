class SalesReport {
  final DateTime date;
  final double totalSales;
  final int totalTransactions;
  final double averageOrderValue;
  final List<SalesItemReport> topItems;
  final Map<String, double> paymentModeBreakdown;

  SalesReport({
    required this.date,
    required this.totalSales,
    required this.totalTransactions,
    required this.averageOrderValue,
    required this.topItems,
    required this.paymentModeBreakdown,
  });

  factory SalesReport.fromMap(Map<String, dynamic> data) {
    return SalesReport(
      date: (data['date'] as Timestamp).toDate(),
      totalSales: (data['totalSales'] ?? 0).toDouble(),
      totalTransactions: data['totalTransactions'] ?? 0,
      averageOrderValue: (data['averageOrderValue'] ?? 0).toDouble(),
      topItems: (data['topItems'] as List<dynamic>?)
          ?.map((item) => SalesItemReport.fromMap(item))
          .toList() ?? [],
      paymentModeBreakdown: Map<String, double>.from(data['paymentModeBreakdown'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'averageOrderValue': averageOrderValue,
      'topItems': topItems.map((item) => item.toMap()).toList(),
      'paymentModeBreakdown': paymentModeBreakdown,
    };
  }
}

class SalesItemReport {
  final String itemName;
  final int quantitySold;
  final double totalRevenue;
  final double averagePrice;

  SalesItemReport({
    required this.itemName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.averagePrice,
  });

  factory SalesItemReport.fromMap(Map<String, dynamic> data) {
    return SalesItemReport(
      itemName: data['itemName'] ?? '',
      quantitySold: data['quantitySold'] ?? 0,
      totalRevenue: (data['totalRevenue'] ?? 0).toDouble(),
      averagePrice: (data['averagePrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'quantitySold': quantitySold,
      'totalRevenue': totalRevenue,
      'averagePrice': averagePrice,
    };
  }
}

class ProfitLossReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final double totalCostOfGoods;
  final double grossProfit;
  final double totalExpenses;
  final double netProfit;
  final double profitMargin;
  final List<ExpenseCategory> expenseBreakdown;

  ProfitLossReport({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalCostOfGoods,
    required this.grossProfit,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.expenseBreakdown,
  });

  factory ProfitLossReport.fromMap(Map<String, dynamic> data) {
    return ProfitLossReport(
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalRevenue: (data['totalRevenue'] ?? 0).toDouble(),
      totalCostOfGoods: (data['totalCostOfGoods'] ?? 0).toDouble(),
      grossProfit: (data['grossProfit'] ?? 0).toDouble(),
      totalExpenses: (data['totalExpenses'] ?? 0).toDouble(),
      netProfit: (data['netProfit'] ?? 0).toDouble(),
      profitMargin: (data['profitMargin'] ?? 0).toDouble(),
      expenseBreakdown: (data['expenseBreakdown'] as List<dynamic>?)
          ?.map((expense) => ExpenseCategory.fromMap(expense))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalRevenue': totalRevenue,
      'totalCostOfGoods': totalCostOfGoods,
      'grossProfit': grossProfit,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
      'profitMargin': profitMargin,
      'expenseBreakdown': expenseBreakdown.map((expense) => expense.toMap()).toList(),
    };
  }
}

class ExpenseCategory {
  final String category;
  final double amount;
  final double percentage;

  ExpenseCategory({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> data) {
    return ExpenseCategory(
      category: data['category'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      percentage: (data['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'amount': amount,
      'percentage': percentage,
    };
  }
}

class GSTReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalSales;
  final double totalPurchases;
  final double outputGST;
  final double inputGST;
  final double netGST;
  final List<GSTItem> gstItems;

  GSTReport({
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.totalPurchases,
    required this.outputGST,
    required this.inputGST,
    required this.netGST,
    required this.gstItems,
  });

  factory GSTReport.fromMap(Map<String, dynamic> data) {
    return GSTReport(
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalSales: (data['totalSales'] ?? 0).toDouble(),
      totalPurchases: (data['totalPurchases'] ?? 0).toDouble(),
      outputGST: (data['outputGST'] ?? 0).toDouble(),
      inputGST: (data['inputGST'] ?? 0).toDouble(),
      netGST: (data['netGST'] ?? 0).toDouble(),
      gstItems: (data['gstItems'] as List<dynamic>?)
          ?.map((item) => GSTItem.fromMap(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'outputGST': outputGST,
      'inputGST': inputGST,
      'netGST': netGST,
      'gstItems': gstItems.map((item) => item.toMap()).toList(),
    };
  }
}

class GSTItem {
  final String itemName;
  final double taxableAmount;
  final double gstRate;
  final double gstAmount;
  final String type; // 'sale' or 'purchase'

  GSTItem({
    required this.itemName,
    required this.taxableAmount,
    required this.gstRate,
    required this.gstAmount,
    required this.type,
  });

  factory GSTItem.fromMap(Map<String, dynamic> data) {
    return GSTItem(
      itemName: data['itemName'] ?? '',
      taxableAmount: (data['taxableAmount'] ?? 0).toDouble(),
      gstRate: (data['gstRate'] ?? 0).toDouble(),
      gstAmount: (data['gstAmount'] ?? 0).toDouble(),
      type: data['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'taxableAmount': taxableAmount,
      'gstRate': gstRate,
      'gstAmount': gstAmount,
      'type': type,
    };
  }
}

// Import statement for Timestamp
import 'package:cloud_firestore/cloud_firestore.dart';
