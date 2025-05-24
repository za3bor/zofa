import 'package:flutter/material.dart';
import 'package:zofa/models/bread.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';

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
      final price = entry.key.salePrice ?? entry.key.price;
      return sum + (price * entry.value);
    });
  }

  void _saveBreadOrder() async {
    FocusScope.of(context).unfocus();
    String result =
        widget.selectedItems
            .map((entry) => '${entry.key.name}:${entry.value}\n')
            .join();
    double totalSum = totalPrice();

    if (_nameController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder:
            (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('שגיאה'),
                content: Text('אנא מלא את כל השדות הנדרשים בצורה נכונה.'),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: const Text('אישור'),
                  ),
                ],
              ),
            ),
      );
      return;
    }

    // Retrieve the phone number from Hive
    var box = await Hive.openBox('userStatus');
    String? userPhoneNumber = box.get(
      'phoneNumber',
    ); // Fetch the stored phone number
    final url = Uri.parse('http://$ipAddress/api/addNewBreadOrder');
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
        showDialog(
          context: context,
          builder:
              (ctx) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('הצלחה'),
                  content: const Text('ההזמנה נשלחה בהצלחה'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('אישור'),
                    ),
                  ],
                ),
              ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'יש בעיה נא להתקשר',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
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
      appBar: const CustomAppBar(title: 'פרטי ההזמנה'),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // Background Image
            SizedBox(
              height:
                  double
                      .infinity, // Ensures the background image fills the whole screen
              width: double.infinity,
              child: Image.asset('assets/background.jpg', fit: BoxFit.cover),
            ),
            // Foreground Content
            SingleChildScrollView(
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
                            Text(
                              'פריטים שנבחרו:',
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.h),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  widget.selectedItems.map((entry) {
                                    double itemTotal =
                                        entry.key.price * entry.value;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8.w,
                                          ),
                                          child: Text(
                                            entry
                                                .key
                                                .name, // Directly using the variable
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                          ),
                                        ),
                                        entry.key.salePrice != null
                                            ? Column(
                                              children: [
                                                Directionality(
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  child: Text(
                                                    '${entry.value} X ${entry.key.price.toStringAsFixed(2)} = ${(entry.key.price * entry.value).toStringAsFixed(2)} ₪',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                          color: Colors.red,
                                                        ),
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                Directionality(
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  child: Text(
                                                    '${entry.value} X ${entry.key.salePrice!.toStringAsFixed(2)} = ${(entry.key.salePrice! * entry.value).toStringAsFixed(2)} ₪',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.green,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            )
                                            : Row(
                                              children: [
                                                Directionality(
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  child: Text(
                                                    '${entry.value} X ${entry.key.price.toStringAsFixed(2)} = ${itemTotal.toStringAsFixed(2)} ₪',
                                                    style:
                                                        Theme.of(
                                                          context,
                                                        ).textTheme.bodyMedium,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'תשלום וקבלה רק בחנות',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                if (widget.selectedItems.any(
                                  (entry) => entry.key.salePrice != null,
                                )) ...[
                                  Text(
                                    'סה"כ לתשלום: ₪ ${widget.selectedItems.fold(0.0, (sum, entry) => sum + (entry.key.price * entry.value)).toStringAsFixed(2)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium!.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'סה"כ לתשלום לאחר הנחה: ₪ ${totalPrice().toStringAsFixed(2)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'סה"כ לתשלום: ₪ ${totalPrice().toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'שם'),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _saveBreadOrder,
                      child: const Text('שלח'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
