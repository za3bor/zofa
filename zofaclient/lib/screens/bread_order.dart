import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zofa_client/models/bread.dart';
import 'package:zofa_client/screens/checkout_bread.dart';
import 'package:zofa_client/widgets/bread_quantity_row.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';

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

  @override
  void initState() {
    super.initState();
    fetchBreadData(); // Call the function to fetch bread data when the screen loads
    checkTime();
  }

void checkTime() {
  final now = DateTime.now();
  final currentDay = now.weekday;
  final currentTime = TimeOfDay.fromDateTime(now);

  // Define restriction times for easier comparisons
  const startRestrictionTime = TimeOfDay(hour: 20, minute: 5);
  const endRestrictionTime = TimeOfDay(hour: 20, minute: 0);

  bool isWithinRestriction(TimeOfDay current) {
    return (current.hour == startRestrictionTime.hour && current.minute >= startRestrictionTime.minute) ||
           (current.hour == endRestrictionTime.hour && current.minute < endRestrictionTime.minute);
  }

  setState(() {
    if (isWithinRestriction(currentTime)) {
      // Restriction time, set button disabled and message
      day = '';
      isButtonEnabled = false;
      buttonText = 'המתן ל 8:05 כדי להזמין';
    } else if (currentDay == DateTime.monday || currentDay == DateTime.tuesday ||
               currentDay == DateTime.wednesday || (currentDay == DateTime.thursday && !isWithinRestriction(currentTime))) {
      // Days when orders are open for 'שלישי'
      day = 'שישי';
      isButtonEnabled = true;
      buttonText = 'הוסף לסל';
    } else if ((currentDay == DateTime.thursday && isWithinRestriction(currentTime)) ||
               currentDay == DateTime.friday || currentDay == DateTime.saturday || currentDay == DateTime.sunday) {
      // Days when orders are open for 'שישי'
      day = 'שלישי';
      isButtonEnabled = true;
      buttonText = 'הוסף לסל';
    } else {
      // Default to restriction if none matched
      day = '';
      isButtonEnabled = false;
      buttonText = 'המתן ל 8:05 כדי להזמין';
    }

    // Debugging prints to verify each variable's state
    print('Day set to: $day');
    print('Button Enabled: $isButtonEnabled');
    print('Button Text: $buttonText');
  });
}



  Future<void> fetchBreadData() async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress:3000/api/showAllBreadTypes'));
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
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'הזמנת לחם ליום $day',
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
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
                    const SizedBox(height: 16.0),
                  ],
                );
              })
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: isButtonEnabled
              ? () {
                  addToCart(context);
                }
              : null,
          child: Text(
            buttonText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
