import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin.dart';
import '../models/premium_subscription.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Admin? _currentAdmin;
  bool get isAdminLoggedIn => _currentAdmin != null;
  Admin? get currentAdmin => _currentAdmin;
  
  // Initialize admin service
  void initialize() {
    // This method can be used for future initialization
    print('AdminService initialized');
  }

  // Admin credentials
  static const String _adminEmail = 'admin123@gmail.com';
  static const String _adminPassword = 'admin1991';

  // Check if user is admin
  bool isAdminUser(String email) {
    return email == _adminEmail;
  }

  // Admin login
  Future<Admin?> loginAsAdmin(String email, String password) async {
    try {
      if (email != _adminEmail || password != _adminPassword) {
        throw Exception('Invalid admin credentials');
      }

      // Create admin locally
      Admin admin = Admin(
        id: _adminEmail,
        email: _adminEmail,
        name: 'System Administrator',
        role: 'admin',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
      );

      _currentAdmin = admin;
      
      // Don't try to access Firestore during login to avoid crashes
      // Firestore access will be handled when needed in dashboard
      
      return admin;
    } catch (e) {
      print('Admin login error: $e');
      rethrow;
    }
  }

  // Logout admin
  Future<void> logoutAdmin() async {
    _currentAdmin = null;
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      // Check if admin is logged in
      if (_currentAdmin == null) {
        return {
          'totalUsers': 0,
          'premiumUsers': 0,
          'freeUsers': 0,
          'newUsersThisMonth': 0,
          'premiumPercentage': '0',
        };
      }

      // Try to access Firestore, but handle permission errors gracefully
      try {
        final usersSnapshot = await _firestore.collection('users').get();
        final premiumSnapshot = await _firestore.collection('premium_subscriptions').get();
        
        final totalUsers = usersSnapshot.docs.length;
        final premiumUsers = premiumSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['isActive'] == true && data['paymentStatus'] == 'completed';
        }).length;
        
        final freeUsers = totalUsers - premiumUsers;
        
        // Get new users this month
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final newUsersThisMonth = usersSnapshot.docs.where((doc) {
          final data = doc.data();
          final createdAt = data['createdAt'] != null 
              ? DateTime.parse(data['createdAt']) 
              : DateTime.now();
          return createdAt.isAfter(startOfMonth);
        }).length;

        return {
          'totalUsers': totalUsers,
          'premiumUsers': premiumUsers,
          'freeUsers': freeUsers,
          'newUsersThisMonth': newUsersThisMonth,
          'premiumPercentage': totalUsers > 0 ? (premiumUsers / totalUsers * 100).toStringAsFixed(1) : '0',
        };
      } catch (firestoreError) {
        print('Firestore access error: $firestoreError');
        // Return error data to show in UI
        return {
          'totalUsers': 0,
          'premiumUsers': 0,
          'freeUsers': 0,
          'newUsersThisMonth': 0,
          'premiumPercentage': '0',
          'error': 'Firestore permission denied. Please deploy security rules.',
        };
      }
    } catch (e) {
      print('Error getting user statistics: $e');
      // Return default values if any other error occurs
      return {
        'totalUsers': 0,
        'premiumUsers': 0,
        'freeUsers': 0,
        'newUsersThisMonth': 0,
        'premiumPercentage': '0',
        'error': 'Could not fetch data from database',
      };
    }
  }

  // Get income statistics
  Future<Map<String, dynamic>> getIncomeStatistics() async {
    try {
      if (_currentAdmin == null) {
        return {
          'totalIncome': 0.0,
          'monthlyIncome': 0.0,
          'yearlyIncome': 0.0,
          'currency': 'INR',
        };
      }

      // Try to access Firestore, but handle permission errors gracefully
      try {
        final premiumSnapshot = await _firestore.collection('premium_subscriptions').get();
        
        double totalIncome = 0;
        double monthlyIncome = 0;
        double yearlyIncome = 0;
        
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final startOfYear = DateTime(now.year, 1, 1);

        for (final doc in premiumSnapshot.docs) {
          final data = doc.data();
          if (data['paymentStatus'] == 'completed' && data['isActive'] == true) {
            final amount = (data['amount'] ?? 0).toDouble();
            totalIncome += amount;
            
            final createdAt = data['createdAt'] != null 
                ? DateTime.parse(data['createdAt']) 
                : DateTime.now();
            
            if (createdAt.isAfter(startOfMonth)) {
              monthlyIncome += amount;
            }
            
            if (createdAt.isAfter(startOfYear)) {
              yearlyIncome += amount;
            }
          }
        }

        return {
          'totalIncome': totalIncome,
          'monthlyIncome': monthlyIncome,
          'yearlyIncome': yearlyIncome,
          'currency': 'INR',
        };
      } catch (firestoreError) {
        print('Firestore access error in income stats: $firestoreError');
        return {
          'totalIncome': 0.0,
          'monthlyIncome': 0.0,
          'yearlyIncome': 0.0,
          'currency': 'INR',
          'error': 'Firestore permission denied. Please deploy security rules.',
        };
      }
    } catch (e) {
      print('Error getting income statistics: $e');
      return {
        'totalIncome': 0.0,
        'monthlyIncome': 0.0,
        'yearlyIncome': 0.0,
        'currency': 'INR',
        'error': 'Could not fetch income data',
      };
    }
  }

  // Get monthly income data for charts
  Future<List<Map<String, dynamic>>> getMonthlyIncomeData() async {
    try {
      // Try to access Firestore, but handle permission errors gracefully
      try {
        final premiumSnapshot = await _firestore.collection('premium_subscriptions').get();
        final Map<String, double> monthlyData = {};
        
        for (final doc in premiumSnapshot.docs) {
          final data = doc.data();
          if (data['paymentStatus'] == 'completed' && data['isActive'] == true) {
            final createdAt = data['createdAt'] != null 
                ? DateTime.parse(data['createdAt']) 
                : DateTime.now();
            
            final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
            final amount = (data['amount'] ?? 0).toDouble();
            
            monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + amount;
          }
        }

        // Sort by month and return last 12 months
        final sortedMonths = monthlyData.keys.toList()..sort();
        final last12Months = sortedMonths.length > 12 
            ? sortedMonths.sublist(sortedMonths.length - 12) 
            : sortedMonths;
        
        return last12Months.map((month) {
          return {
            'month': month,
            'income': monthlyData[month] ?? 0,
          };
        }).toList();
      } catch (firestoreError) {
        print('Firestore access error in monthly income data: $firestoreError');
        return [];
      }
    } catch (e) {
      print('Error getting monthly income data: $e');
      return [];
    }
  }

  // Get all users with premium status
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      // Try to access Firestore, but handle permission errors gracefully
      try {
        final usersSnapshot = await _firestore.collection('users').get();
        final premiumSnapshot = await _firestore.collection('premium_subscriptions').get();
        
        final List<Map<String, dynamic>> users = [];
        
        for (final userDoc in usersSnapshot.docs) {
          final userData = userDoc.data();
          final userId = userDoc.id;
          
          // Find premium subscription for this user
          final premiumDoc = premiumSnapshot.docs.firstWhere(
            (doc) => doc.data()['userId'] == userId,
            orElse: () => premiumSnapshot.docs.first,
          );
          
          Map<String, dynamic> premiumData = {};
          if (premiumDoc.exists && premiumDoc.data()['userId'] == userId) {
            premiumData = premiumDoc.data();
          }
          
          users.add({
            'id': userId,
            'email': userData['email'] ?? '',
            'name': userData['displayName'] ?? 'Unknown',
            'createdAt': userData['createdAt'] ?? DateTime.now().toIso8601String(),
            'isPremium': premiumData['isActive'] == true && premiumData['paymentStatus'] == 'completed',
            'premiumPlan': premiumData['planType'] ?? 'none',
            'premiumExpiry': premiumData['endDate'] ?? '',
            'subscriptionId': premiumDoc.exists ? premiumDoc.id : null,
          });
        }
        
        return users;
      } catch (firestoreError) {
        print('Firestore access error in getAllUsers: $firestoreError');
        return [];
      }
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Remove premium from user
  Future<bool> removePremiumFromUser(String userId) async {
    try {
      // Find the user's premium subscription
      final premiumSnapshot = await _firestore.collection('premium_subscriptions')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (premiumSnapshot.docs.isNotEmpty) {
        final subscriptionId = premiumSnapshot.docs.first.id;
        await _firestore.collection('premium_subscriptions')
            .doc(subscriptionId)
            .update({
          'isActive': false,
          'paymentStatus': 'cancelled',
          'updatedAt': DateTime.now().toIso8601String(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing premium from user: $e');
      return false;
    }
  }

  // Add premium to user
  Future<bool> addPremiumToUser(String userId, String planType, int days) async {
    try {
      final subscription = PremiumSubscription(
        userId: userId,
        planType: planType,
        amount: planType == 'monthly' ? 99.0 : 990.0,
        currency: 'INR',
        paymentStatus: 'completed',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: days)),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('premium_subscriptions').add(subscription.toMap());
      return true;
    } catch (e) {
      print('Error adding premium to user: $e');
      return false;
    }
  }
}
