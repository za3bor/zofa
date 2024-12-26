import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zofa_client/admin/screens/admin_main_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OtpLoginScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpLoginScreen({required this.phoneNumber, super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _otpController = TextEditingController();
  String verificationId = ''; // Store the verification ID
  bool _isSendingOtp = false; // Loading indicator for sending OTP
  bool _isVerifyingOtp = false; // Loading indicator for verifying OTP

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
