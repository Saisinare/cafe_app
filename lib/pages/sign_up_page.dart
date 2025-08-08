import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final cafeNameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _signUp() {
    // Handle sign-up logic here
    print("Cafe Name: ${cafeNameController.text}");
    print("Owner Name: ${ownerNameController.text}");
    print("Phone: ${phoneController.text}");
    print("Address: ${addressController.text}");
    print("Email: ${emailController.text}");
    print("Password: ${passwordController.text}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign Up clicked')),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
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
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Register Your Café",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                _buildTextField(
                  controller: cafeNameController,
                  hintText: "Café Name",
                  prefixIcon: Icons.storefront,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: ownerNameController,
                  hintText: "Owner Name",
                  prefixIcon: Icons.person,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: phoneController,
                  hintText: "Phone Number",
                  prefixIcon: Icons.phone,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: addressController,
                  hintText: "Address",
                  prefixIcon: Icons.location_on,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: emailController,
                  hintText: "Email",
                  prefixIcon: Icons.email,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: passwordController,
                  hintText: "Password",
                  prefixIcon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      child: Text('Sign Up', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to login
                  },
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
