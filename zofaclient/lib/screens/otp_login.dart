import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zofa_client/admin/screens/admin_main_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:zofa_client/screens/tabs.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';

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

  Future<bool> _checkAdmin(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/checkAdmin/$phone'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists']; // Return true or false
      } else {
        return false; // Return false if the API call fails
      }
    } catch (e) {
      return false; // Return false if there's an error during the request
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
    User? user = FirebaseAuth.instance.currentUser;

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

      // Check if the phone number is an admin
      bool isAdmin = await _checkAdmin(user?.phoneNumber ?? '');
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => isAdmin
                ? const AdminMainPageScreen() // Show admin screen for admin devices
                : const TabsScreen(),
          ),
          (Route<dynamic> route) =>
              false, // This ensures all previous routes are removed
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
        title: const Text('הזן את קוד האימות'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'קוד אימות נשלח למספר ${widget.phoneNumber}.',
                style: Theme.of(context).textTheme.bodyMedium, // Text style
              ),
              SizedBox(height: 20.h),
              Directionality(
                textDirection: TextDirection.ltr,
                child: PinCodeTextField(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  appContext: context,
                  length: 6, // Number of OTP digits
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  obscureText: false,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape
                        .underline, // Use underline shape for lines
                    borderRadius:
                        BorderRadius.zero, // No rounding, keep it a line
                    fieldHeight: 50.h, // Height of each field (line)
                    fieldWidth: 40.w, // Width of each field (line's length)
                    activeColor: Theme.of(context)
                        .colorScheme
                        .primary, // Active underline color
                    selectedColor: Theme.of(context)
                        .colorScheme
                        .secondary, // Selected underline color
                    inactiveColor: Theme.of(context)
                        .primaryColor, // Inactive underline color
                    activeFillColor: Theme.of(context).scaffoldBackgroundColor,
                    selectedFillColor:
                        Theme.of(context).scaffoldBackgroundColor,
                    inactiveFillColor:
                        Theme.of(context).scaffoldBackgroundColor,
                  ),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  animationDuration: const Duration(milliseconds: 300),
                  enableActiveFill: true, // Enable filled style for the input
                  onChanged: (value) {
                    // Handle input changes
                  },
                  onCompleted: (value) {
                    // Optionally handle OTP complete
                    print("Completed OTP: $value");
                  },
                ),
              ),
              SizedBox(height: 20.h),
              _isVerifyingOtp
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _verifyOtp,
                      child: const Text('אמת קוד'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
