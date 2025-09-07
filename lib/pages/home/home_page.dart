import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/pages/inventory/add_item_screen.dart';
import 'package:my_app/pages/party/add_party_screen.dart';
import 'package:my_app/pages/sales/sales_entry_screen.dart';
import 'package:my_app/pages/sales/sales_history_screen.dart';
// Removed invoice screens from FAB options to avoid duplication
import 'package:my_app/pages/finance/money_in_screen.dart';
import 'package:my_app/pages/finance/money_out_screen.dart';
import 'package:my_app/pages/finance/receipts_center_screen.dart';
import 'package:my_app/pages/finance/expense_screen.dart';
import 'package:my_app/pages/settings/settings_page.dart';
import 'package:my_app/pages/premium/premium_subscription_screen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:my_app/pages/purchase/purchase_screen.dart';
import 'package:my_app/services/firestore_service.dart';
import 'package:my_app/models/premium_subscription.dart';
 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PremiumSubscription? _currentSubscription;
  bool _isLoadingPremium = true;
  
  // Live data streams
  late Stream<double> _monthlySalesStream;
  late Stream<List<Map<String, dynamic>>> _topSellingProductsStream;
  late Stream<List<Map<String, dynamic>>> _stockAlertsStream;
  late Stream<List<Map<String, dynamic>>> _weeklySalesDataStream;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _initializeDataStreams();
  }

  void _initializeDataStreams() {
    _monthlySalesStream = FirestoreService.instance.streamMonthlySales();
    _topSellingProductsStream = FirestoreService.instance.streamTopSellingProducts(limit: 3);
    _stockAlertsStream = FirestoreService.instance.streamStockAlerts(threshold: 10);
    _weeklySalesDataStream = FirestoreService.instance.streamWeeklySalesData();
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

  // Removed unused bottom nav tap handler

  // removed unused nav labels

  // Options for the floating action menu
  List<Map<String, dynamic>> get _fabOptions {
    final baseOptions = [
      {"icon": Icons.history, "label": "Sales History"},
      {"icon": Icons.receipt_long, "label": "Receipts"},
      {"icon": Icons.shopping_bag, "label": "Purchase"},
      {"icon": Icons.arrow_downward, "label": "Money In"},
      {"icon": Icons.arrow_upward, "label": "Money Out"},
      {"icon": Icons.receipt_long, "label": "Expense"},
      {"icon": Icons.group, "label": "Party"},
      {"icon": Icons.inventory, "label": "Item"},
    ];

    // Removed Sales Invoice options to prevent duplication with Sales History receipts

    return baseOptions;
  }

  void _handleFabOptionTap(String label) {
    switch (label) {
      case "Item":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddItemScreen()),
        );
        break;
      case "Sales History":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
        );
        break;
      case "Receipts":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReceiptsCenterScreen()),
        );
        break;
      // Removed Sales Invoice and Invoice List cases
      case "Purchase":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PurchaseScreen()),
        );
        break;
      case "Money In":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MoneyInScreen()),
        );
        break;
      case "Money Out":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MoneyOutScreen()),
        );
        break;
      case "Expense":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExpenseScreen()),
        );
        break;
      case "Party":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddPartyScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${label} clicked")),
        );
    }
  }

  // Removed unused premium upgrade dialog (invoice feature removed)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Premium Status Indicator
          if (_currentSubscription?.isValid == true)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            )
          else if (!_isLoadingPremium)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_border, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Free',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {
                _initializeDataStreams();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing data...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<double>(
                    stream: _monthlySalesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return _dashboardCard(
                          title: 'Monthly Sales',
                          value: '₹${snapshot.data!.toStringAsFixed(0)}',
                        );
                      }
                      return _dashboardCard(
                        title: 'Monthly Sales',
                        value: '₹0',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _topSellingProductsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return _dashboardCard(
                          title: 'Top Product',
                          value: snapshot.data!.first['name'] ?? 'None',
                        );
                      }
                      return _dashboardCard(
                        title: 'Top Product',
                        value: 'None',
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stockAlertsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _dashboardCard(
                    title: 'Stock Alerts',
                    value: '${snapshot.data!.length} Items',
                  );
                }
                return _dashboardCard(
                  title: 'Stock Alerts',
                  value: '0 Items',
                );
              },
            ),
            
            // Premium Features Preview
            if (_currentSubscription?.isValid != true && !_isLoadingPremium) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6F4E37), Color(0xFFB77B57)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Get access to Sales Invoices, Advanced Analytics & more',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PremiumSubscriptionScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6F4E37),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Upgrade'),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),

            const Text('Sales Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Sales Trend', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            StreamBuilder<double>(
              stream: _monthlySalesStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    '₹ ${snapshot.data!.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                  );
                }
                return const Text(
                  '₹ 0',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                );
              },
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 120,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _weeklySalesDataStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final data = snapshot.data!;
                    return LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: data.asMap().entries.map((entry) {
                              return FlSpot(
                                entry.key.toDouble(),
                                entry.value['amount']?.toDouble() ?? 0.0,
                              );
                            }).toList(),
                            isCurved: true,
                            color: Colors.blue,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < data.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      data[value.toInt()]['label'] ?? '',
                                      style: const TextStyle(fontSize: 12)
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              interval: 1,
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    );
                  }
                  return Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('No sales data available'),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            const Text('Top Selling Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _topSellingProductsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Column(
                    children: snapshot.data!.map((product) {
                      return _productItem(
                        Icons.local_cafe,
                        product['name'] ?? '',
                        product['label'] ?? '',
                      );
                    }).toList(),
                  );
                }
                return const Text('No sales data available', style: TextStyle(color: Colors.grey));
              },
            ),

            const SizedBox(height: 24),
            const Text('Stock Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stockAlertsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Column(
                    children: snapshot.data!.map((item) {
                      IconData icon;
                      if (item['name'].toString().toLowerCase().contains('coffee') || 
                          item['name'].toString().toLowerCase().contains('bean')) {
                        icon = Icons.bubble_chart;
                      } else if (item['name'].toString().toLowerCase().contains('milk')) {
                        icon = Icons.local_drink;
                      } else {
                        icon = Icons.inventory;
                      }
                      
                      return _productItem(
                        icon,
                        item['name'] ?? '',
                        item['label'] ?? '',
                      );
                    }).toList(),
                  );
                }
                return const Text('No stock alerts', style: TextStyle(color: Colors.grey));
              },
            ),
          ],
        ),
      ),

      
      // Floating Action Buttons
      floatingActionButton: Positioned(
               bottom: 10,
      right: 20,
        child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // New Item Button - Centered horizontally, closer to bottom

          const SizedBox(height: 8),
          // Main Add Button with Menu - Positioned to the right
          Align(
            alignment: Alignment.centerRight,
            child: SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: Colors.blue,
              overlayColor: Colors.black,
              overlayOpacity: 0.4,
              spacing: 10,
              spaceBetweenChildren: 8,
              // Fix positioning for smaller devices
              childMargin: const EdgeInsets.only(bottom: 16),
              childPadding: const EdgeInsets.only(bottom: 16),
              // Ensure proper positioning and prevent overflow
              buttonSize: const Size(56.0, 56.0),
              childrenButtonSize: const Size(56.0, 56.0),
              tooltip: 'Quick Actions',
              children: _fabOptions.map((option) {
                return SpeedDialChild(
                  child: Icon(option["icon"], color: Colors.white),
                  backgroundColor: Colors.blue,
                  label: option["label"],
                  labelStyle: const TextStyle(fontSize: 16),
                  onTap: () => _handleFabOptionTap(option["label"]),
                );
              }).toList(),
            ),
          ),
        ],
      ),  
      ) 
    );
  }

  Widget _dashboardCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _productItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 30),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ]
          )
        ],
      ),
    );
  }
}
