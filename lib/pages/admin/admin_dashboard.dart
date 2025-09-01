import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int totalUsers = 0;
  int premiumUsers = 0;
  double totalEarnings = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);

    try {
      // Fetch total users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      int usersCount = usersSnapshot.size;

      // Fetch active premium subscriptions
      final premiumSnapshot = await FirebaseFirestore.instance
          .collection('premium_subscriptions')
          .where('isActive', isEqualTo: true)
          .get();
      int premiumCount = premiumSnapshot.size;

      // Calculate total earnings (only active subscriptions)
      double earnings = 0.0;
      for (var doc in premiumSnapshot.docs) {
        earnings += (doc['amount'] ?? 0).toDouble();
      }

      setState(() {
        totalUsers = usersCount;
        premiumUsers = premiumCount;
        totalEarnings = earnings;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
      setState(() => isLoading = false);
    }
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart() {
    int freeUsers = totalUsers - premiumUsers;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 400,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "User Distribution",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        value: premiumUsers.toDouble(),
                        color: Colors.blue,
                        title: '$premiumUsers',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: freeUsers.toDouble(),
                        color: Colors.grey.shade400,
                        title: '$freeUsers',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegend(Colors.blue, "Premium"),
                  const SizedBox(width: 20),
                  _buildLegend(Colors.grey, "Free"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatCard(
                    Icons.people,
                    "Total Users",
                    "$totalUsers",
                    Colors.blue,
                  ),
                  _buildStatCard(
                    Icons.star,
                    "Premium Users",
                    "$premiumUsers",
                    Colors.amber,
                  ),
                  _buildStatCard(
                    Icons.attach_money,
                    "Total Earnings",
                    "₹${totalEarnings.toStringAsFixed(2)}",
                    Colors.green,
                  ),
                  _buildDonutChart(),
                ],
              ),
            ),
    );
  }
}
