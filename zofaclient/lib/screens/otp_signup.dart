import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import for FCM
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/admin/screens/admin_main_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OtpSignupScreen extends StatefulWidget {
  final String phoneNumber;
  final String name;

  const OtpSignupScreen(
      {required this.phoneNumber, required this.name, super.key});

  @override
  State<OtpSignupScreen> createState() => _OtpSignupScreenState();
}

class _OtpSignupScreenState extends State<OtpSignupScreen> {
  final _otpController = TextEditingController();
  String verificationId = ''; // Store the verification ID
  bool _isSendingOtp = false; // Loading indicator for sending OTP
  bool _isVerifyingOtp = false; // Loading indicator for verifying OTP

  Future<void> _saveNewUser(String fcmToken) async {
    try {
      const String backendUrl =
          'http://$ipAddress:3000/api/addNewUser'; // Replace with your backend endpoint

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': widget.name,
          'phoneNumber': widget.phoneNumber,
          'FCMtoken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print('User data sent successfully!');
      } else {
        print('Failed to send user data: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error sending user data: $e');
    }
  }

  // Function to send OTP
  Future<void> _sendOtp() async {
    setState(() {
      _isSendingOtp = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          print('Verified and signed in automatically!');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP: ${e.message}')),
          );
        },
        codeSent: (String verId, int? resendToken) {
          setState(() {
            verificationId = verId;
          });
          print('OTP sent to ${widget.phoneNumber}');
        },
        codeAutoRetrievalTimeout: (String verId) {
          setState(() {
            verificationId = verId;
          });
          print('Auto retrieval timeout');
        },
      );
    } finally {
      setState(() {
        _isSendingOtp = false;
      });
    }
  }

  // Function to verify OTP
  Future<void> _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP.')),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      print('OTP verified!');

      // Get FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _saveNewUser(fcmToken); // Send user data to the backend
      } else {
        print('Failed to retrieve FCM token');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminMainPageScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
      print('Error verifying OTP: $e');
    } finally {
      setState(() {
        _isVerifyingOtp = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A verification code has been sent to ${widget.phoneNumber}.'),
            SizedBox(height: 10.h),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.h),
            _isVerifyingOtp
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text('Verify OTP'),
                  ),
          ],
        ),
      ),
    );
  }
}
