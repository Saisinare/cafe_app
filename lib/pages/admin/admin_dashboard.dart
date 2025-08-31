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
      // Load data with error handling for each method
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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _adminService.logoutAdmin();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Bar
                Container(
                  color: Colors.grey.shade100,
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
                  child: _buildTabContent(),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF6F4E37) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF6F4E37) : Colors.grey,
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

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error indicator if data couldn't be loaded
          if (_userStats.containsKey('error') || _incomeStats.containsKey('error'))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Some data could not be loaded. This may be due to Firestore permissions.',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _loadDashboardData,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                      const SizedBox(width: 8),
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
          
          // Stats Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Users', '${_userStats['totalUsers'] ?? 0}', Icons.people, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Premium Users', '${_userStats['premiumUsers'] ?? 0}', Icons.star, Colors.amber)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('New Users (Month)', '${_userStats['newUsersThisMonth'] ?? 0}', Icons.person_add, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Premium %', '${_userStats['premiumPercentage'] ?? 0}%', Icons.percent, Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Income Stats
          const Text(
            'Income Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildIncomeCard('Total Income', '₹${_incomeStats['totalIncome']?.toStringAsFixed(0) ?? '0'}', Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildIncomeCard('Monthly Income', '₹${_incomeStats['monthlyIncome']?.toStringAsFixed(0) ?? '0'}', Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildIncomeCard('Yearly Income', '₹${_incomeStats['yearlyIncome']?.toStringAsFixed(0) ?? '0'}', Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Monthly Income Chart
          const Text(
            'Monthly Income Trend',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildMonthlyIncomeChart(),
          ),
        ],
      ),
    );
  }

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
                onPressed: () => _showAddPremiumDialog(),
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
          // User Growth Chart
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
          
          // Premium vs Free Users Pie Chart
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('₹${value.toInt()}');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _monthlyIncomeData.length) {
                  final monthData = _monthlyIncomeData[value.toInt()];
                  final month = monthData['month'] as String;
                  return Text(month.substring(5)); // Show only month number
                }
                return const Text('');
              },
            ),
          ),
        ),
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
    // This would show user growth over time
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
        trailing: PopupMenuButton(
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
              value: 'view_details',
              child: Text('View Details'),
            ),
          ],
          onSelected: (value) => _handleUserAction(value, user),
        ),
      ),
    );
  }

  void _handleUserAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'remove_premium':
        _showRemovePremiumDialog(user);
        break;
      case 'add_premium':
        _showAddPremiumDialog(userId: user['id']);
        break;
      case 'view_details':
        _showUserDetailsDialog(user);
        break;
    }
  }

  void _showRemovePremiumDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Premium'),
        content: Text('Are you sure you want to remove premium from ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _adminService.removePremiumFromUser(user['id']);
              if (success) {
                _loadDashboardData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium removed successfully'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to remove premium'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddPremiumDialog({String? userId}) {
    String selectedPlan = 'monthly';
    int days = 30;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Premium'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPlan,
                decoration: const InputDecoration(labelText: 'Plan Type'),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedPlan = value!;
                    days = value == 'monthly' ? 30 : 365;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Duration: $days days'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (userId != null) {
                  final success = await _adminService.addPremiumToUser(userId, selectedPlan, days);
                  if (success) {
                    _loadDashboardData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Premium added successfully'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add premium'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37)),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details: ${user['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user['email']}'),
            Text('Created: ${user['createdAt']}'),
            Text('Premium Status: ${user['isPremium'] ? 'Active' : 'Inactive'}'),
            if (user['isPremium']) ...[
              Text('Plan: ${user['premiumPlan']}'),
              Text('Expires: ${user['premiumExpiry']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
