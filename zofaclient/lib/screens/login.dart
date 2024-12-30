import 'package:flutter/material.dart';
import 'package:zofa_client/screens/otp_login.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false; // Loading indicator for sending OTP

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Function to navigate to OTP Page
  void _proceedToOtp() {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isNotEmpty && phone.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      // Format the phone number
      phone = _formatPhoneNumber(phone);
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpLoginScreen(
                phoneNumber: phone,
              ),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both name and phone number.'),
        ),
      );
    }
  }

  String _formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    phone = phone.replaceAll(RegExp(r'\D'), '');

    // Check if phone starts with '0' (local format)
    if (phone.startsWith('0')) {
      return '+972${phone.substring(1)}'; // Use string interpolation to build the string
    }

    // If phone starts with '972', it's already in international format, just prepend '+'
    if (phone.startsWith('972')) {
      return '+972${phone.substring(3)}'; // Use string interpolation
    }

    // If phone doesn't start with '0' or '972', assume it's already in the correct international format
    if (!phone.startsWith('+972')) {
      return '+972$phone'; // Use string interpolation to prepend '+972'
    }

    return phone; // Return as is if already in correct format
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your name and phone number:'),
            SizedBox(height: 10.h),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.h),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _proceedToOtp,
                    child: const Text('Proceed to OTP'),
                  ),
          ],
        ),
      ),
    );
  }
}
