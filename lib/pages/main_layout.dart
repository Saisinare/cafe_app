import 'package:flutter/material.dart';
import 'package:my_app/pages/sales/sales_entry_screen.dart';
import 'package:my_app/pages/settings/settings_page.dart';
import 'package:my_app/pages/premium/premium_subscription_screen.dart';
import 'home/home_page.dart';
import 'inventory/inventory_page.dart';
import 'party/party_page.dart';
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    PartyScreen(),
    InventoryScreen(),
    PremiumSubscriptionScreen()
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

floatingActionButton: FloatingActionButton.extended(
  heroTag: "new_sale_fab",
  backgroundColor: Colors.green,
  tooltip: 'Create New Sale',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SalesScreen()),
    );
  },
  icon: const Icon(Icons.point_of_sale, color: Colors.white), // sale icon
  label: const Text(
    "New Sale",
    style: TextStyle(color: Colors.white),
  ),
),
floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,



      // ✅ Keep normal BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Party'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Premium'),
        ],
      ),
    );
  }
}

