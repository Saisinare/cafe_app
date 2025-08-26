import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/razorpay_service.dart';
import '../../services/firestore_service.dart';
import '../../models/premium_subscription.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  final RazorpayService _razorpayService = RazorpayService();
  final FirestoreService _firestoreService = FirestoreService.instance;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';
  PremiumSubscription? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      _razorpayService.initialize();
      _setupPaymentCallbacks();
      await _checkCurrentSubscription();
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = 'Failed to initialize services: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupPaymentCallbacks() {
    _razorpayService.onPaymentSuccess = (message) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh subscription status
        _checkCurrentSubscription();
      }
    };

    _razorpayService.onPaymentError = (message) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
  }

  Future<void> _checkCurrentSubscription() async {
    try {
      final subscriptionStream = _firestoreService.streamCurrentUserSubscription();
      subscriptionStream.listen((subscription) {
        if (mounted) {
          setState(() {
            _currentSubscription = subscription;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Error checking subscription: $error';
          });
        }
        print('Error checking subscription: $error');
      });
    } catch (e) {
      print('Error checking subscription: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error checking subscription: $e';
        });
      }
    }
  }

  Future<void> _startSubscription(String planType, double amount) async {
    setState(() => _isLoading = true);

    try {
      await _razorpayService.startPremiumSubscription(
        planType: planType,
        amount: amount,
        onSuccess: (subscription) {
          // This callback is not used anymore as we use the service callbacks
        },
        onError: (error) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _retryInitialization() {
    setState(() {
      _isInitializing = true;
      _hasError = false;
      _errorMessage = '';
    });
    _initializeServices();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Premium Subscription'),
          backgroundColor: const Color(0xFF6F4E37),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing services...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Premium Subscription'),
          backgroundColor: const Color(0xFF6F4E37),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _retryInitialization,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F4E37),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        backgroundColor: const Color(0xFF6F4E37),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing payment...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Subscription Status
                  if (_currentSubscription != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Premium Active',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Plan: ${_currentSubscription!.planType.toUpperCase()}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Valid until: ${_currentSubscription!.endDate.toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Premium Features
                  const Text(
                    'Premium Features',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _featureItem(Icons.receipt_long, 'Professional Sales Invoices', 'Create GST-compliant invoices with your business branding'),
                  _featureItem(Icons.analytics, 'Advanced Analytics', 'Detailed sales reports and business insights'),
                  _featureItem(Icons.backup, 'Data Backup', 'Secure cloud backup of all your business data'),
                  _featureItem(Icons.support_agent, 'Priority Support', '24/7 customer support'),
                  _featureItem(Icons.security, 'Enhanced Security', 'Advanced security features and data protection'),

                  const SizedBox(height: 32),

                  // Subscription Plans
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Monthly Plan
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Monthly Plan',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹99/month',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6F4E37),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _currentSubscription?.isValid == true
                                  ? null
                                  : () => _startSubscription('monthly', 99),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6F4E37),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _currentSubscription?.isValid == true ? 'Current Plan' : 'Subscribe Monthly',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Yearly Plan
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Yearly Plan',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'SAVE 17%',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '₹990/year',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6F4E37),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹82.5/month',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _currentSubscription?.isValid == true
                                  ? null
                                  : () => _startSubscription('yearly', 990),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6F4E37),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _currentSubscription?.isValid == true ? 'Current Plan' : 'Subscribe Yearly',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Information',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('• Secure payment via Razorpay'),
                        const Text('• Multiple payment options: UPI, Cards, Net Banking'),
                        const Text('• Instant activation after successful payment'),
                        const Text('• Cancel anytime, no questions asked'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _featureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6F4E37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF6F4E37)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
