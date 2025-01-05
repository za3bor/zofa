import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/admin/screens/admin_p_order_detail.dart'; // Import your details screen
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/models/product_orders.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductOrdersScreen extends StatefulWidget {
  const ProductOrdersScreen({super.key});

  @override
  State<ProductOrdersScreen> createState() {
    return _ProductOrdersScreenState();
  }
}

class _ProductOrdersScreenState extends State<ProductOrdersScreen> {
  List<ProductOrders> _productOrders = []; // List to store orders

  Future<void> getOrders() async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/api/getAllProductOrders'));

      // Check status code and print the response body for debugging
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          _productOrders = jsonData.map((item) {
            return ProductOrders(
              id: item['id'],
              userName: item['username'],
              phoneNumber: item['phone_number'],
              orderDetails: item['order_details'],
              totalPrice: double.parse(item['total_price'].toString()),
              status: item['status'],
              email: item['email'],
            );
          }).toList();
        });
      } else {
        print('Failed to load orders. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print('Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בטעינת ההזמנות. אנא נסה שוב מאוחר יותר.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הזמנות'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: _productOrders.isEmpty
              ? const Center(
                  child: Text(
                    'אין הזמנות זמינות.',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _productOrders.length,
                  itemBuilder: (context, index) {
                    final order = _productOrders[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0.h),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(
                                  order:
                                      order), // Pass selected order to details screen
                            ),
                          );
                        },
                        child: Text('הזמנה ${order.id}'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
