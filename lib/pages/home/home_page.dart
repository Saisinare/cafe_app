import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/pages/inventory/add_item_screen.dart';
import 'package:my_app/pages/party/add_party_screen.dart';
import 'package:my_app/pages/party/party_page.dart';
import 'package:my_app/pages/sales/sales_entry_screen.dart';
import 'package:my_app/pages/sales/sales_history_screen.dart';
import 'package:my_app/pages/sales/sales_invoice_screen.dart';
import 'package:my_app/pages/sales/sales_invoice_list_screen.dart';
import 'package:my_app/pages/finance/money_in_screen.dart';
import 'package:my_app/pages/finance/money_out_screen.dart';
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
  int _selectedIndex = 0;
  PremiumSubscription? _currentSubscription;
  bool _isLoadingPremium = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
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

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tapped: ${_navLabels[index]}")),
    );
  }

  static const List<String> _navLabels = ['Home', 'Products', 'Invoices', 'Subscription'];

  // Options for the floating action menu
  List<Map<String, dynamic>> get _fabOptions {
    final baseOptions = [
      {"icon": Icons.shopping_cart, "label": "New Sale"},
      {"icon": Icons.history, "label": "Sales History"},
      {"icon": Icons.shopping_bag, "label": "Purchase"},
      {"icon": Icons.arrow_downward, "label": "Money In"},
      {"icon": Icons.arrow_upward, "label": "Money Out"},
      {"icon": Icons.receipt_long, "label": "Expense"},
      {"icon": Icons.group, "label": "Party"},
      {"icon": Icons.inventory, "label": "Item"},
    ];

    // Add Sales Invoice options for premium users
    if (_currentSubscription?.isValid == true) {
      baseOptions.insert(2, {"icon": Icons.receipt, "label": "Sales Invoice"});
      baseOptions.insert(3, {"icon": Icons.list_alt, "label": "Invoice List"});
    }

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
      case "New Sale":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SalesScreen()),
        );
        break;
      case "Sales History":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
        );
        break;
      case "Sales Invoice":
        if (_currentSubscription?.isValid == true) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SalesInvoiceScreen()),
          );
        } else {
          _showPremiumUpgradeDialog();
        }
        break;
      case "Invoice List":
        if (_currentSubscription?.isValid == true) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SalesInvoiceListScreen()),
          );
        } else {
          _showPremiumUpgradeDialog();
        }
        break;
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

  void _showPremiumUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'This is a premium feature. Upgrade to premium to create professional GST-compliant invoices with your business branding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumSubscriptionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6F4E37),
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }

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
                Expanded(child: _dashboardCard(title: 'Total Sales', value: '₹12,500')),
                const SizedBox(width: 12),
                Expanded(child: _dashboardCard(title: 'Top Selling Product', value: 'Espresso')),
              ],
            ),
            const SizedBox(height: 12),
            _dashboardCard(title: 'Stock Alerts', value: '3 Items'),
            
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
            const Text('₹ 12,500', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 5),
                        FlSpot(1, 6),
                        FlSpot(2, 5.8),
                        FlSpot(3, 6.2),
                        FlSpot(4, 5.2),
                        FlSpot(5, 7),
                        FlSpot(6, 6.8),
                      ],
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
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.toInt()], style: const TextStyle(fontSize: 12)),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Top Selling Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _productItem(Icons.local_cafe, 'Espresso', '120 units sold'),
            _productItem(Icons.local_cafe, 'Latte', '100 units sold'),
            _productItem(Icons.local_cafe, 'Cappuccino', '80 units sold'),

            const SizedBox(height: 24),
            const Text('Stock Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _productItem(Icons.bubble_chart, 'Coffee Beans', '5 units remaining'),
            _productItem(Icons.local_drink, 'Milk', '2 units remaining'),
            _productItem(Icons.cake, 'Sugar', '10 units remaining'),
          ],
        ),
      ),

      // Floating Action Button with Menu
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spacing: 10,
        spaceBetweenChildren: 8,
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
