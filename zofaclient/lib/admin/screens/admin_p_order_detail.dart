import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/models/product_orders.dart'; // Import your model
import 'package:zofa_client/constant.dart';

class OrderDetailsScreen extends StatefulWidget {
  final ProductOrders order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() {
    return _OrderDetailsScreenState();
  }
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  List<Map<String, dynamic>> productDetailsList =
      []; // List to store product details

  // Fetch product details by product ID
  Future<Map<String, dynamic>> fetchProductDetails(int productId) async {
    final response = await http.get(
        Uri.parse('http://$ipAddress:3000/api/getProductDetails/$productId'));

    if (response.statusCode == 200) {
      // Assuming the API returns a JSON object with product details
      return json.decode(response.body); // Return product details as a Map
    } else {
      throw Exception('Failed to load product details');
    }
  }

  // Parse the order details and fetch details for each product
  Future<void> getProductDetails() async {
    try {
      // Split the order details string (e.g., "1:2 3:4") and process each part
      List<String> orderItems = widget.order.orderDetails.split(' ');
      print('Parsed order items: $orderItems'); // Debugging log

      // List to hold the futures for fetching product details
      List<Future<Map<String, dynamic>>> fetchFutures = [];

      // Create a list of futures to fetch all product details
      for (var item in orderItems) {
        // Split product ID and quantity by ':'
        List<String> productData = item.split(':');
        int productId = int.parse(productData[0]);
        String quantity = productData[1]; // Keep the quantity as a String

        // Add future to the list for each product
        fetchFutures.add(fetchProductDetails(productId).then((productDetails) {
          // Map the product details and quantity for display
          return {
            'name': productDetails[
                'name'], // Assuming the response has a 'name' field
            'quantity': quantity, // The quantity comes from the order
          };
        }));
      }

      // Wait for all the futures to complete and update the UI
      List<Map<String, dynamic>> fetchedProducts =
          await Future.wait(fetchFutures);
      print('Fetched product details: $fetchedProducts'); // Debugging log

      // Update the UI with the fetched product details
      setState(() {
        productDetailsList = fetchedProducts;
      });
    } catch (error) {
      print('Error fetching product details: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בטעינת פרטי המוצרים. אנא נסה שוב מאוחר יותר.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getProductDetails(); // Fetch product details when the screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('פרטי הזמנה ${widget.order.id}')),
      body: Directionality(
        textDirection:
            TextDirection.rtl, // Set the text direction to right-to-left
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.end, // Align text to the right
            children: [
              Text(
                'מספר הזמנה: ${widget.order.id}',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'שם הלקוח: ${widget.order.userName}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'טלפון: ${widget.order.phoneNumber}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'סטטוס: ${widget.order.status}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'סך הכל: ₪${widget.order.totalPrice.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'פרטי ההזמנה:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              // Display product details
              productDetailsList.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator()) // Show loading until data is fetched
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: productDetailsList.map((product) {
                        return Text(
                          '${product['name']} - כמות: ${product['quantity']}',
                          style: const TextStyle(fontSize: 16),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
