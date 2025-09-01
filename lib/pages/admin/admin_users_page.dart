import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      // fetch users
      final userSnap = await FirebaseFirestore.instance.collection('users').get();
      final subSnap = await FirebaseFirestore.instance.collection('premium_subscriptions').get();

      final users = userSnap.docs.map((doc) => {
        "id": doc.id,    // <-- take Firestore docId as userId
        ...doc.data(),
      }).toList();

      final subscriptions = subSnap.docs.map((doc) => {
        "id": doc.id,
        ...doc.data(),
      }).toList();

      final mergedUsers = users.map((user) {
        final sub = subscriptions.firstWhere(
          (s) => s['userId'] == user['id'],   // match doc.id with subscription.userId
          orElse: () => {},
        );

        final bool isPremium = sub.isNotEmpty && (sub['isActive'] ?? false);

        return {
          ...user,
          'isPremium': isPremium,
          'premiumPlan': isPremium ? sub['planType'] : null,
          'subscriptionId': sub.isNotEmpty ? sub['id'] : null,
        };
      }).toList();

      setState(() {
        _users = mergedUsers;
        _subscriptions = subscriptions;
        _filteredUsers = mergedUsers;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredUsers = _users.where((user) {
        final name = (user['ownerName'] ?? user['name'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        return name.contains(_searchQuery) || email.contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _togglePremiumStatus(
      String userId, String? subscriptionId, bool currentlyPremium) async {
    try {
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + 1, now.day);

      if (currentlyPremium) {
        // deactivate subscription
        if (subscriptionId != null) {
          await _firestore
              .collection('premium_subscriptions')
              .doc(subscriptionId)
              .update({"isActive": false, "updatedAt": now});
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium removed successfully')),
        );
      } else {
        if (subscriptionId != null) {
          // reactivate
          await _firestore
              .collection('premium_subscriptions')
              .doc(subscriptionId)
              .update({
            "isActive": true,
            "planType": "monthly",
            "startDate": now,
            "endDate": endDate,
            "updatedAt": now,
          });
        } else {
          // create new subscription
          await _firestore.collection('premium_subscriptions').add({
            "userId": userId,
            "isActive": true,
            "planType": "monthly",
            "startDate": now,
            "endDate": endDate,
            "paymentStatus": "manual_by_admin",
            "currency": "INR",
            "amount": 0,
            "createdAt": now,
            "updatedAt": now,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium added successfully')),
        );
      }

      // reload users so UI updates
      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Admin Users"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers, // Refresh functionality
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: "Search users by name or email...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F4E37)),
                    ),
                  )
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _filteredUsers.isEmpty
                        ? const Center(child: Text("No Users Found"))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              final isPremium = user['isPremium'] ?? false;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isPremium
                                          ? Colors.amber.shade100
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isPremium
                                          ? Icons.star_rounded
                                          : Icons.person_rounded,
                                      color: isPremium
                                          ? Colors.amber.shade700
                                          : Colors.grey.shade600,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    user['ownerName'] ??
                                        user['name'] ??
                                        'Unknown User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        user['email'] ?? 'No email',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isPremium
                                                  ? Colors.amber.shade100
                                                  : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isPremium
                                                    ? Colors.amber.shade300
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              isPremium ? 'Premium' : 'Free',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isPremium
                                                    ? Colors.amber.shade700
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          if (isPremium) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Plan: ${user['premiumPlan'] ?? 'monthly'}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Switch(
                                    value: isPremium,
                                    onChanged: (value) => _togglePremiumStatus(
                                      user['id'],
                                      user['subscriptionId'],
                                      isPremium,
                                    ),
                                    activeColor: Colors.amber.shade600,
                                    activeTrackColor: Colors.amber.shade200,
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
