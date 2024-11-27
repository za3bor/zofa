import 'package:flutter/material.dart';
import 'package:zofa_client/models/bread.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';

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
  final _phoneController = TextEditingController();

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

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _phoneController.text.length != 10) {
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
        'phoneNumber': _phoneController.text,
        'orderDetails': result,
        'totalPrice': totalSum,
        'status': 'התקבל',
        'day': widget.day, // Add 'day' to the request body
      }),
    );

    if (response.statusCode == 201) {
      _nameController.clear();
      _phoneController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('ההזמנה נשלחה בהצלחה', textDirection: TextDirection.rtl)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('יש בעיה נא להתקשר', textDirection: TextDirection.rtl)),
      );
      print(response.body);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ביקורת הזמנה',
          style: TextStyle(fontFamily: 'Heebo'),
          textDirection: TextDirection.rtl,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 3.0,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'פריטים שנבחרו:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.selectedItems.map((entry) {
                            double itemTotal = entry.key.price * entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    '${entry.key.name}', // Only bread name
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${entry.value}x${entry.key.price.toStringAsFixed(2)}=${itemTotal.toStringAsFixed(2)}₪',
                                      style: const TextStyle(fontSize: 16.0),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  color: Colors.grey,
                                  thickness: 1,
                                  height: 20,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          'סה"כ: ₪ ${totalPrice().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Add the payment info here
                const Text(
                  'תשלום וקבלה רק בחנות',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'שם',
                    border: OutlineInputBorder(),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'טלפון',
                    border: OutlineInputBorder(),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _saveBreadOrder,
                  child: const Text(
                    'שלח',
                    style: TextStyle(fontSize: 18.0),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
