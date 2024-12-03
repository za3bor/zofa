import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zofa_client/admin/screens/admin_main_page.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final String name;

  const OtpPage({required this.phoneNumber, required this.name, super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  String verificationId = '';  // Store the verification ID

  // Function to send OTP
  Future<void> _sendOtp() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // If verification is successful, sign in directly
        await FirebaseAuth.instance.signInWithCredential(credential);
        print('Verified and signed in!');
      },
      verificationFailed: (FirebaseAuthException e) {
        // Handle error if verification fails
        print('Verification failed: ${e.message}');
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
  }

  // Function to verify OTP
  Future<void> _verifyOtp() async {
    String otp = _otpController.text;
    if (otp.isNotEmpty) {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      try {
        // Sign in with the OTP
        await FirebaseAuth.instance.signInWithCredential(credential);
        print('OTP verified!');

        // Navigate to the HomePage after successful OTP verification
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminMainPageScreen()),
        );
      } catch (e) {
        // Handle error if OTP is invalid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
        print('Error verifying OTP: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Send OTP when the page is loaded
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A verification code has been sent to ${widget.phoneNumber}.'),
            const SizedBox(height: 10),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
