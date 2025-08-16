import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/pages/inventory/add_item_screen.dart';
import 'package:my_app/pages/sales/sales_entry_screen.dart';
import 'package:my_app/pages/sales/sales_history_screen.dart';
import 'package:my_app/pages/settings/settings_page.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
  final List<Map<String, dynamic>> _fabOptions = [
    {"icon": Icons.shopping_cart, "label": "New Sale"},
    {"icon": Icons.history, "label": "Sales History"},
    {"icon": Icons.shopping_bag, "label": "Purchase"},
    {"icon": Icons.arrow_downward, "label": "Money In"},
    {"icon": Icons.arrow_upward, "label": "Money Out"},
    {"icon": Icons.receipt_long, "label": "Expense"},
    {"icon": Icons.group, "label": "Party"},
    {"icon": Icons.inventory, "label": "Item"},
  ];

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
      onTap: () {
        if (option["label"] == "Item") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddItemScreen(),
            ),
          );
        } else if (option["label"] == "New Sale") {   // 👈 open sales entry page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SalesScreen(),
            ),
          );
        } else if (option["label"] == "Sales History") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SalesHistoryScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${option["label"]} clicked")),
          );
        }
      },
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
            ],
          )
        ],
      ),
    );
  }
}
