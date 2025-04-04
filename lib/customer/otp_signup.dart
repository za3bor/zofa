import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';
import 'package:zofa/admin/admin_main_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zofa/customer/tabs.dart';
import 'package:hive/hive.dart';

class OtpSignupScreen extends StatefulWidget {
  final String phoneNumber;
  final String name;

  const OtpSignupScreen({
    required this.phoneNumber,
    required this.name,
    super.key,
  });

  @override
  State<OtpSignupScreen> createState() => _OtpSignupScreenState();
}

class _OtpSignupScreenState extends State<OtpSignupScreen> {
  final _otpController = TextEditingController();
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  Future<bool> _checkAdmin(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/checkAdmin/$phone'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'];
      }
    } catch (e) {
      print('Error checking admin: $e');
    }
    return false;
  }

  // Function to send OTP using Twilio Verify Service
  Future<void> _sendOtp() async {
    setState(() {
      _isSendingOtp = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/sendOTP'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': widget.phoneNumber}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('OTP נשלח בהצלחה!')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שליחת OTP נכשלה: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בשליחת OTP: $e')));
      }
    } finally {
      setState(() {
        _isSendingOtp = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('אנא הכנס את הקוד.')));
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/verifyOTP'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': widget.phoneNumber,
          'otpEntered': otp,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['verified'] == true) {
          bool isAdmin = await _checkAdmin(widget.phoneNumber);

          // Add new user to database
          final addUserResponse = await http.post(
            Uri.parse('http://$ipAddress/api/addNewUser'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': widget.name,
              'phoneNumber': widget.phoneNumber,
              'FCMtoken': 'empty', // Keeping it empty for now
            }),
          );
          if (addUserResponse.statusCode == 201 ||
              addUserResponse.statusCode == 409) {
            final userStatusBox = Hive.box('userStatus');
            userStatusBox.put('isLoggedIn', true);
            userStatusBox.put('phoneNumber', widget.phoneNumber);
            userStatusBox.put('isAdmin', isAdmin);

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          isAdmin
                              ? const AdminMainPageScreen()
                              : const TabsScreen(),
                ),
                (Route<dynamic> route) => false,
              );
            }
            return;
          }
        }
      }

      // Show error message if verification failed
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OTP שגוי. נסה שוב.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה באימות OTP: $e')));
      }
    } finally {
      setState(() {
        _isVerifyingOtp = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _sendOtp(); // Send OTP when screen loads
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'הכנס קוד אימות'),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('קוד אימות נשלח למספר ${widget.phoneNumber.replaceFirst('+972', '0')} בוואטסאפ.'),
              SizedBox(height: 10.h),
              Directionality(
                textDirection: TextDirection.ltr,
                child: PinCodeTextField(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  obscureText: false,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.underline,
                    borderRadius: BorderRadius.zero,
                    fieldHeight: 50.h,
                    fieldWidth: 40.w,
                    activeColor: Theme.of(context).colorScheme.primary,
                    selectedColor: Theme.of(context).colorScheme.secondary,
                    inactiveColor: Theme.of(context).primaryColor,
                    activeFillColor: Theme.of(context).scaffoldBackgroundColor,
                    selectedFillColor:
                        Theme.of(context).scaffoldBackgroundColor,
                    inactiveFillColor:
                        Theme.of(context).scaffoldBackgroundColor,
                  ),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  animationDuration: const Duration(milliseconds: 300),
                  enableActiveFill: true,
                  onChanged: (value) {},
                  onCompleted: (value) {},
                ),
              ),
              SizedBox(height: 20.h),
              _isVerifyingOtp
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text('אמת את הקוד'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
