import 'package:flutter/material.dart';
import './sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override 
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true; // <-- Add this in your State

  void _login() {
    String email = emailController.text;
    String password = passwordController.text;

    // Replace this with your login logic
    print('Email: $email');
    print('Password: $password');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login clicked')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Email Input
                TextField(
                  controller: emailController,
                  decoration:  InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),



                // Password Input
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, // <-- Set your custom background color here
                      foregroundColor: Colors.white, 
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), 
                          ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      child: Text('Login', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}