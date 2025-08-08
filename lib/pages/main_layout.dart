import 'package:flutter/material.dart';
import 'home_page.dart';
import 'products_page.dart';
import 'invoices_page.dart';
import 'subscription_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    ProductsScreen(),
    InvoicesScreen(),
    SubscriptionScreen(),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.coffee), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoices'),
          BottomNavigationBarItem(icon: Icon(Icons.star_border), label: 'Subscription'),
        ],
      ),
    );
  }
}
