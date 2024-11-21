import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/admin/screens/admin_p_order_detail.dart';
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/models/product_orders.dart';

class ProductOrdersScreen extends StatefulWidget {
  const ProductOrdersScreen({super.key});

  @override
  State<ProductOrdersScreen> createState() {
    return _ProductOrdersScreenState();
  }
}

class _ProductOrdersScreenState extends State<ProductOrdersScreen> {
  List<ProductOrders> _productOrders = []; // List to store orders
  Map<String, int> orderQuantityMap =
      {}; // Map to store order types and their total quantities
  bool buttonEnabled =
      true; // Manage the button state (you can use it to enable/disable buttons)

  Future<void> getOrders() async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress:3000/api/getAllProductOrders'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          if (jsonData.isEmpty) {
            _productOrders = []; // No orders found
          } else {
            _productOrders = jsonData.map((item) {
              return ProductOrders(
                id: item['id'] ?? 0,
                userName: item['userName'] ?? '',
                phoneNumber: item['phoneNumber'] ?? '',
                orderDetails: item['orderDetails'] ?? '',
                totalPrice: item['totalPrice'] != null
                    ? double.parse(item['totalPrice'].toString())
                    : 0.0,
                status: item['status'] ?? '',
              );
            }).toList();
          }
        });
      } else {
        throw Exception('Failed to load orders'); // Trigger catch block
      }
    } catch (error) {
      // Display an error message via Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('שגיאה בטעינת ההזמנות. אנא נסה שוב מאוחר יותר.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getOrders(); // Fetch orders when the screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('הזמנות')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _productOrders.isEmpty
            ? Center(
                child: Text(
                  'אין הזמנות זמינות.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              )
            : ListView.builder(
                itemCount: _productOrders.length,
                itemBuilder: (context, index) {
                  final order = _productOrders[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(fontSize: 18),
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        // Navigate to order details screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderDetailsScreen(order: order),
                          ),
                        );
                      },
                      child: Text('הזמנה ${order.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
