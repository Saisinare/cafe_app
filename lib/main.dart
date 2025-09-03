import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'pages/main_layout.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure correct Firebase project/bucket on desktop & web by passing options
  const options = FirebaseOptions(
    apiKey: 'AIzaSyDWSt4AE_WTdmBc79kY0rSVGJzT1L2-E84',
    appId: '1:107350228532:android:61f9a7de28142f459a9461',
    messagingSenderId: '107350228532',
    projectId: 'cafe-app-project-13361',
    storageBucket: 'cafe-app-project-13361.firebasestorage.app',
  );

  if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await Firebase.initializeApp(options: options);
  } else {
    await Firebase.initializeApp();
  }
  
  // Initialize Razorpay
  try {
    Razorpay razorpay = Razorpay();
    print('Razorpay initialized successfully');
  } catch (e) {
    print('Razorpay initialization failed: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafe App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is authenticated, show main layout
        if (snapshot.hasData && snapshot.data != null) {
          print('AuthWrapper: User authenticated, showing MainLayout for ${snapshot.data!.email}');
          return const MainLayout();
        }

        // If user is not authenticated, show login page
        print('AuthWrapper: No user authenticated, showing LoginPage');
        return const LoginPage();
      },
    );
  }
}
