import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/premium_subscription.dart';
import 'firestore_service.dart';

class RazorpayService {
  // Use test keys for development - replace with live keys for production
  static const String _keyId = 'rzp_live_Q63VRotx1UvmSL'; // Changed to test key
  static const String _merchantId = 'OwDqnKbBwpc01n';
  
  // Set to false to enable real payments
  static const bool _isDevelopmentMode = false;
  
  Razorpay? _razorpay;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  
  // Store pending subscriptions by user ID for payment tracking
  final Map<String, String> _pendingSubscriptions = {};
  
  // Callback functions for payment status updates
  Function(String)? onPaymentSuccess;
  Function(String)? onPaymentError;
  
  // Track initialization status
  bool _isInitialized = false;

  void initialize() {
    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _isInitialized = true;
      print('RazorpayService: Initialized successfully');
    } catch (e) {
      print('RazorpayService: Failed to initialize: $e');
      _isInitialized = false;
      
      // If in development mode, we can still simulate payments
      if (_isDevelopmentMode) {
        print('RazorpayService: Running in development mode - payments will be simulated');
        _isInitialized = true;
      }
    }
  }

  void dispose() {
    try {
      _razorpay?.clear();
    } catch (e) {
      print('RazorpayService: Error disposing: $e');
    }
  }

  Future<void> startPremiumSubscription({
    required String planType,
    required double amount,
    required Function(PremiumSubscription) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        onError('User not authenticated');
        return;
      }

      // Create subscription record in Firestore
      final subscription = PremiumSubscription(
        userId: user.uid,
        planType: planType,
        amount: amount,
        currency: 'INR',
        paymentStatus: 'pending',
        startDate: DateTime.now(),
        endDate: planType == 'monthly' 
            ? DateTime.now().add(const Duration(days: 30))
            : DateTime.now().add(const Duration(days: 365)),
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final subscriptionId = await _firestoreService.createPremiumSubscription(subscription);
      
      // Store the subscription ID for this user to track payment
      _pendingSubscriptions[user.uid] = subscriptionId;

      if (_isDevelopmentMode) {
        // Simulate successful payment for development
        print('Development mode: Simulating successful payment');
        await Future.delayed(const Duration(seconds: 2));
        await _simulatePaymentSuccess(subscriptionId);
        return;
      }

      if (!_isInitialized || _razorpay == null) {
        onError('Payment service not initialized. Please try again.');
        return;
      }

      // Create Razorpay order
      final options = {
        'key': _keyId,
        'amount': (amount * 100).toInt(), // Convert to paise
        'currency': 'INR',
        'name': 'Cafe App Premium',
        'description': '$planType Premium Subscription',
        'prefill': {
          'email': user.email ?? '',
          'contact': user.phoneNumber ?? '',
        },
        'external': {
          'wallets': ['paytm', 'phonepe', 'gpay']
        },
        'theme': {
          'color': '#6F4E37'
        }
      };

      _razorpay!.open(options);
    } catch (e) {
      onError('Failed to start payment: $e');
    }
  }

  Future<void> _simulatePaymentSuccess(String subscriptionId) async {
    try {
      // Update subscription status
      await _firestoreService.updatePremiumSubscriptionStatus(
        subscriptionId: subscriptionId,
        paymentStatus: 'completed',
        razorpayPaymentId: 'dev_${DateTime.now().millisecondsSinceEpoch}',
        isActive: true,
      );
      
      // Notify UI of payment success
      if (onPaymentSuccess != null) {
        onPaymentSuccess!('Payment successful! Premium features activated.');
      }
    } catch (e) {
      print('Error simulating payment success: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final subscriptionId = _pendingSubscriptions[user.uid];
      if (subscriptionId != null) {
        // Update subscription status
        await _firestoreService.updatePremiumSubscriptionStatus(
          subscriptionId: subscriptionId,
          paymentStatus: 'completed',
          razorpayPaymentId: response.paymentId,
          isActive: true,
        );
        
        // Remove from pending subscriptions
        _pendingSubscriptions.remove(user.uid);
        
        print('Payment successful: ${response.paymentId} for subscription: $subscriptionId');
        
        // Notify UI of payment success
        if (onPaymentSuccess != null) {
          onPaymentSuccess!('Payment successful! Premium features activated.');
        }
      } else {
        print('No pending subscription found for user: ${user.uid}');
      }
      
    } catch (e) {
      print('Error handling payment success: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final subscriptionId = _pendingSubscriptions[user.uid];
      if (subscriptionId != null) {
        // Update subscription status to failed
        await _firestoreService.updatePremiumSubscriptionStatus(
          subscriptionId: subscriptionId,
          paymentStatus: 'failed',
          isActive: false,
        );
        
        // Remove from pending subscriptions
        _pendingSubscriptions.remove(user.uid);
        
        print('Payment failed for subscription: $subscriptionId');
      }
      
      print('Payment failed: ${response.message}');
      
      // Notify UI of payment error
      if (onPaymentError != null) {
        onPaymentError!('Payment failed: ${response.message}');
      }
      
    } catch (e) {
      print('Error handling payment failure: $e');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet selected: ${response.walletName}');
  }
}
