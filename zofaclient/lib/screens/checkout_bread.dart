import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zofa_client/models/bread.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/widgets/snow_layer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckoutBreadScreen extends StatefulWidget {
  final List<MapEntry<Bread, int>> selectedItems;
  final String day;

  const CheckoutBreadScreen({
    required this.selectedItems,
    required this.day,
    super.key,
  });

  @override
  State<CheckoutBreadScreen> createState() {
    return _CheckoutBreadScreenState();
  }
}

class _CheckoutBreadScreenState extends State<CheckoutBreadScreen> {
  final _nameController = TextEditingController();

  double totalPrice() {
    return widget.selectedItems.fold(0.0, (sum, entry) {
      return sum + (entry.key.price * entry.value);
    });
  }

  void _saveBreadOrder() async {
    String result = widget.selectedItems
        .map((entry) => '${entry.key.name}:${entry.value}\n')
        .join();
    double totalSum = totalPrice();

    // Get the user's phone number from FirebaseAuth
    String? userPhoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;

    if (_nameController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('לא תקין', textDirection: TextDirection.rtl),
          content: const Text('אנא מלא את כל השדות בצורה נכונה',
              textDirection: TextDirection.rtl),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('אוקי', textDirection: TextDirection.rtl),
            )
          ],
        ),
      );
      return;
    }

    final url = Uri.parse('http://$ipAddress:3000/api/addNewBreadOrder');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _nameController.text,
        'phoneNumber': userPhoneNumber,
        'orderDetails': result,
        'totalPrice': totalSum,
        'status': 'התקבל',
        'day': widget.day, // Add 'day' to the request body
      }),
    );

    if (response.statusCode == 201) {
      _nameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ההזמנה נשלחה בהצלחה',
                  textDirection: TextDirection.rtl)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('יש בעיה נא להתקשר', textDirection: TextDirection.rtl)),
        );
      }
      print(response.body);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const SnowLayer(), // Snow falling in the appBar
        title: const Text(
          'ביקורת הזמנה',
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/background.jpg', // Path to your background image
                fit: BoxFit.cover, // Cover the entire screen
              ),
            ),
            // Foreground Content
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context)
                      .size
                      .height, // Ensure it fills the screen
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.only(bottom: 16.h),
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            children: [
                              const Text(
                                'פריטים שנבחרו:',
                              ),
                              SizedBox(height: 8.h),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: widget.selectedItems.map((entry) {
                                  double itemTotal =
                                      entry.key.price * entry.value;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 8.w),
                                        child: Text(
                                          entry.key
                                              .name, // Directly using the variable
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: Text(
                                              '${entry.value} X ${entry.key.price.toStringAsFixed(2)} = ${itemTotal.toStringAsFixed(2)} ₪',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        color: Colors.grey,
                                        thickness: 1.h,
                                        height: 20.h,
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                'סה"כ: ₪ ${totalPrice().toStringAsFixed(2)}',
                              ),
                              SizedBox(height: 5.h),
                              const Text(
                                'תשלום וקבלה רק בחנות',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'שם',
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _saveBreadOrder,
                        child: const Text(
                          'שלח',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
