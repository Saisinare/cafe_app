import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/admin_service.dart';
import '../../models/admin.dart';
import '../login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();

  Map<String, dynamic> _userStats = {};
  Map<String, dynamic> _incomeStats = {};
  List<Map<String, dynamic>> _monthlyIncomeData = [];
  List<Map<String, dynamic>> _users = [];

  bool _isLoading = true;
  String _selectedTab = 'overview';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> userStats = {};
      Map<String, dynamic> incomeStats = {};
      List<Map<String, dynamic>> monthlyIncomeData = [];
      List<Map<String, dynamic>> users = [];

      try {
        userStats = await _adminService.getUserStatistics();
      } catch (e) {
        print('Error loading user stats: $e');
        userStats = {
          'totalUsers': 0,
          'premiumUsers': 0,
          'freeUsers': 0,
          'newUsersThisMonth': 0,
          'premiumPercentage': '0',
          'error': 'Could not load user statistics',
        };
      }

      try {
        incomeStats = await _adminService.getIncomeStatistics();
      } catch (e) {
        print('Error loading income stats: $e');
        incomeStats = {
          'totalIncome': 0.0,
          'monthlyIncome': 0.0,
          'yearlyIncome': 0.0,
          'currency': 'INR',
          'error': 'Could not load income statistics',
        };
      }

      try {
        monthlyIncomeData = await _adminService.getMonthlyIncomeData();
      } catch (e) {
        print('Error loading monthly income data: $e');
        monthlyIncomeData = [];
      }

      try {
        users = await _adminService.getAllUsers();
      } catch (e) {
        print('Error loading users: $e');
        users = [];
      }

      setState(() {
        _userStats = userStats;
        _incomeStats = incomeStats;
        _monthlyIncomeData = monthlyIncomeData;
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Critical error in dashboard: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dashboard error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F4E37)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Tab Bar
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      _buildTab('overview', 'Overview'),
                      _buildTab('users', 'Users'),
                      _buildTab('analytics', 'Analytics'),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: _buildTabContent(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTab(String tabId, String label) {
    final isSelected = _selectedTab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tabId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF6F4E37) : Colors.transparent,
                width: 3,
              ),
            ),
            color: isSelected ? const Color(0xFF6F4E37).withOpacity(0.05) : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF6F4E37) : Colors.grey.shade600,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'overview':
        return _buildOverviewTab();
      case 'users':
        return _buildUsersTab();
      case 'analytics':
        return _buildAnalyticsTab();
      default:
        return _buildOverviewTab();
    }
  }

  /// 🔹 Modified Overview Tab
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error indicator if data couldn't be loaded
          if (_userStats.containsKey('error') || _incomeStats.containsKey('error'))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.warning_rounded, color: Colors.orange.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Some data could not be loaded. This may be due to Firestore permissions.',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _loadDashboardData,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Deploy Firestore rules to fix this issue',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 🔹 Stats as vertical cards (not grid anymore)
          _buildStatCard(
            'Total Users',
            '${_userStats['totalUsers'] ?? 0}',
            Icons.people_alt_rounded,
            Colors.blue.shade100,
            Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Premium Users',
            '${_userStats['premiumUsers'] ?? 0}',
            Icons.star_rounded,
            Colors.amber.shade100,
            Colors.amber.shade700,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Monthly Income',
            '₹${_incomeStats['monthlyIncome']?.toStringAsFixed(0) ?? '0'}',
            Icons.trending_up_rounded,
            Colors.green.shade100,
            Colors.green.shade700,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Premium Rate',
            '${_userStats['premiumPercentage'] ?? '0'}%',
            Icons.analytics_rounded,
            Colors.purple.shade100,
            Colors.purple.shade700,
          ),

          const SizedBox(height: 32),

          // Income Chart
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Monthly Income Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_monthlyIncomeData.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _monthlyIncomeData.asMap().entries.map((entry) {
                              return FlSpot(entry.key.toDouble(), entry.value['income']?.toDouble() ?? 0);
                            }).toList(),
                            isCurved: true,
                            color: Colors.green.shade600,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.shade50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, color: Colors.grey, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'No income data available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Rest of your tabs remain the same ---

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    // Implement search functionality
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement add premium dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add Premium functionality coming soon!')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F4E37),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Users List
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return _buildUserCard(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Growth',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildUserGrowthChart(),
          ),
          const SizedBox(height: 24),
          const Text(
            'User Distribution',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildUserDistributionChart(),
          ),
        ],
      ),
    );
  }

  // --- Widgets (unchanged) ---
  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      width: double.infinity, // full width card
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyIncomeChart() {
    if (_monthlyIncomeData.isEmpty) {
      return const Center(child: Text('No income data available'));
    }
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: _monthlyIncomeData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value['income'].toDouble());
            }).toList(),
            isCurved: true,
            color: const Color(0xFF6F4E37),
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return const Center(child: Text('User Growth Chart - Coming Soon'));
  }

  Widget _buildUserDistributionChart() {
    final premiumUsers = _userStats['premiumUsers'] ?? 0;
    final freeUsers = _userStats['freeUsers'] ?? 0;

    if (premiumUsers + freeUsers == 0) {
      return const Center(child: Text('No user data available'));
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: premiumUsers.toDouble(),
            title: 'Premium\n$premiumUsers',
            color: Colors.amber,
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: freeUsers.toDouble(),
            title: 'Free\n$freeUsers',
            color: Colors.blue,
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user['isPremium'] ? Colors.amber : Colors.grey,
          child: Icon(
            user['isPremium'] ? Icons.star : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(user['name'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? ''),
            Text(
              user['isPremium']
                  ? 'Premium: ${user['premiumPlan']} (Expires: ${user['premiumExpiry']})'
                  : 'Free User',
              style: TextStyle(
                color: user['isPremium'] ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'remove_premium':
                _removePremium(user);
                break;
              case 'add_premium':
                _addPremium(user);
                break;
              case 'view':
                _showUserDetails(user);
                break;
            }
          },
          itemBuilder: (context) => [
            if (user['isPremium'])
              const PopupMenuItem(
                value: 'remove_premium',
                child: Text('Remove Premium'),
              ),
            if (!user['isPremium'])
              const PopupMenuItem(
                value: 'add_premium',
                child: Text('Add Premium'),
              ),
            const PopupMenuItem(
              value: 'view',
              child: Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }

  void _removePremium(Map<String, dynamic> user) {
    // Call AdminService to update Firestore
    print("Removing premium from ${user['email']}");
    // TODO: implement actual update
  }

  void _addPremium(Map<String, dynamic> user) {
    print("Adding premium to ${user['email']}");
    // TODO: implement actual update
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user['name'] ?? 'User Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Email: ${user['email'] ?? 'N/A'}"),
              Text("Premium: ${user['isPremium'] ? 'Yes' : 'No'}"),
              if (user['isPremium']) ...[
                Text("Plan: ${user['premiumPlan']}"),
                Text("Expiry: ${user['premiumExpiry']}"),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}