import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zofa_client/models/bread.dart';
import 'package:zofa_client/customer/bread/checkout_bread.dart';
import 'package:zofa_client/widgets/bread_quantity_row.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BreadOrderScreen extends StatefulWidget {
  const BreadOrderScreen({super.key});

  @override
  State<BreadOrderScreen> createState() {
    return _BreadOrderScreenState();
  }
}

class _BreadOrderScreenState extends State<BreadOrderScreen> {
  List<Bread> breadList = [];
  Map<Bread, int> selectedItems =
      {}; // Map to track selected items and quantities
  bool isButtonEnabled = false; // Variable to track button state
  String day = ''; // Variable to track the day label
  String buttonText = 'הוסף לסל'; // Button text
  bool isLoading = true; // Added variable for loading state
  String? errorMessage; // New variable for error handling

  @override
  void initState() {
    super.initState();
    fetchBreadData(); // Call the function to fetch bread data when the screen loads
    checkTime();
  }

  void checkTime() {
    final now = DateTime.now();
    final currentDay = now.weekday; // Monday = 1, Sunday = 7
    final currentTime = TimeOfDay.fromDateTime(now);

    // Define restriction times
    const startThursdayEvening = TimeOfDay(hour: 20, minute: 15); // 8:15 PM
    const endMondayEvening = TimeOfDay(hour: 20, minute: 0); // 8:00 PM
    const startMondayEvening = TimeOfDay(hour: 20, minute: 15); // 8:15 PM
    const endThursdayEvening = TimeOfDay(hour: 20, minute: 0); // 8:00 PM

    // Helper function to compare times
    bool isAfterOrEqual(TimeOfDay time1, TimeOfDay time2) {
      return time1.hour > time2.hour ||
          (time1.hour == time2.hour && time1.minute >= time2.minute);
    }

    bool isBefore(TimeOfDay time1, TimeOfDay time2) {
      return time1.hour < time2.hour ||
          (time1.hour == time2.hour && time1.minute < time2.minute);
    }

    setState(() {
      if ((currentDay == DateTime.thursday &&
              isAfterOrEqual(currentTime, startThursdayEvening)) ||
          (currentDay == DateTime.friday ||
              currentDay == DateTime.saturday ||
              currentDay == DateTime.sunday ||
              (currentDay == DateTime.monday &&
                  isBefore(currentTime, endMondayEvening)))) {
        day = 'שלישי'; // Tuesday
        isButtonEnabled = true;
        buttonText = 'הוסף לסל';
      } else if ((currentDay == DateTime.monday &&
              isAfterOrEqual(currentTime, startMondayEvening)) ||
          (currentDay == DateTime.tuesday ||
              currentDay == DateTime.wednesday ||
              (currentDay == DateTime.thursday &&
                  isBefore(currentTime, endThursdayEvening)))) {
        day = 'שישי'; // Friday
        isButtonEnabled = true;
        buttonText = 'הוסף לסל';
      } else {
        // Outside ordering hours
        day = '';
        isButtonEnabled = false;
        buttonText = 'הזמנה אינה זמינה כעת';
      }

      // Debugging prints to verify each variable's state
      print('Day set to: $day');
      print('Button Enabled: $isButtonEnabled');
      print('Button Text: $buttonText');
    });
  }

  Future<void> fetchBreadData() async {
    setState(() {
      isLoading = true; // Ensure loading starts when data fetch begins
      errorMessage = null; // Reset error message before fetching data
    });
    try {
      final response =
          await http.get(Uri.parse('http://$ipAddress/api/showAllBreadTypes'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        setState(() {
          breadList = jsonData
              .map((item) => Bread(
                  id: item['id'],
                  name: item['name'],
                  price: double.parse(item['price'].toString()),
                  quantity: int.parse(item['quantity'].toString())))
              .toList();
        });
      } else {
        throw Exception('Failed to load bread data');
      }
    } catch (e) {
      print('Error fetching bread data: $e');
      setState(() {
        errorMessage =
            'שגיאה בטעינת נתונים. נסה שוב מאוחר יותר'; // Error message in Hebrew
      });
    } finally {
      setState(() {
        isLoading = false; // Ensure loading finishes
      });
    }
  }

  void onQuantitySelected(Bread selectedBread, int quantity) {
    setState(() {
      selectedItems[selectedBread] = quantity;
    });
  }

  void addToCart(BuildContext context) {
    final selectedItemsWithQuantity =
        selectedItems.entries.where((entry) => entry.value > 0).toList();
    if (selectedItemsWithQuantity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר לפחות מוצר אחד לפני המעבר לעגלה.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutBreadScreen(
          selectedItems: selectedItemsWithQuantity,
          day: day,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg', // Path to your background image
              fit: BoxFit.cover, // Makes sure the image covers the whole screen
            ),
          ),
          isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(), // Spinner
                      SizedBox(height: 16.h),
                      Text(
                        'טוען נתונים, אנא המתן...', // "Loading data, please wait..."
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(16.0.w),
                          child: Column(
                            children: [
                              Text(
                                'הזמנת לחם ליום $day', // "Bread order for $day"
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              SizedBox(height: 16.h),
                              // Display the bread list with quantity rows
                              ...breadList.map((bread) {
                                return Column(
                                  children: [
                                    BreadQuantityRow(
                                      name: bread.name,
                                      price: bread.price,
                                      onQuantitySelected: (int quantity) {
                                        onQuantitySelected(bread, quantity);
                                      },
                                      quantity: bread.quantity,
                                    ),
                                    SizedBox(height: 7.h),
                                  ],
                                );
                              }),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 6.h,
                                  left: 8.w,
                                  right: 8.w,
                                ),
                                child: SizedBox(
                                  width: double
                                      .infinity, // Makes the button full-width
                                  child: ElevatedButton(
                                    onPressed: isButtonEnabled
                                        ? () {
                                            addToCart(context);
                                          }
                                        : null,
                                    child: Text(
                                      buttonText, // Button text based on the time restriction
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
