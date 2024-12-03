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

  Future<void> getProductDetails() async {
    try {
      // Clean up the order details string to handle newlines
      String cleanedOrderDetails =
          widget.order.orderDetails.replaceAll('\n', ' ').trim();

      // Log cleaned order details
      print('Cleaned Order Details: $cleanedOrderDetails');

      // Split the cleaned order details string
      List<String> orderItems = cleanedOrderDetails.split(' ');

      // Log parsed items
      print('Parsed Order Items: $orderItems');

      // Create a list of futures to fetch all product details
      List<Future<Map<String, dynamic>>> fetchFutures = [];
      for (var item in orderItems) {
        try {
          List<String> productData = item.split(':');
          int productId = int.parse(productData[0]);
          String quantity = productData[1];

          // Log each product ID and quantity
          print('Product ID: $productId, Quantity: $quantity');

          // Fetch product details
          fetchFutures
              .add(fetchProductDetails(productId).then((productDetails) {
            // Log fetched product details
            print('Fetched details for product ID $productId: $productDetails');

            return {
              'id': productId,
              'name': productDetails['name'],
              'quantity': quantity,
            };
          }));
        } catch (e) {
          print('Error parsing product item: $item, Error: $e');
        }
      }

      // Wait for all fetch operations to complete
      List<Map<String, dynamic>> fetchedProducts =
          await Future.wait(fetchFutures);

      // Update state with fetched products
      setState(() {
        productDetailsList = fetchedProducts;
      });

      // Log final product details list
      print('Final Product Details List: $productDetailsList');
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
  // Function to delete bread order
  Future<void> deleteOrder(int orderId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://$ipAddress:3000/api/deleteProductOrder/$orderId'),
      );

      if (response.statusCode == 200) {
        _showSnackbar('ההזמנה נמחקה בהצלחה.');
        Navigator.pop(context); // Go back to the previous screen after successful deletion
      } else {
        throw Exception('Failed to delete bread order.');
      }
    } catch (e) {
      _showSnackbar('שגיאה במחיקת ההזמנה.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Function to show a confirmation dialog before deletion
  void _confirmDeleteOrder(int orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('האם אתה בטוח?'),
          content: const Text('האם אתה בטוח שברצונך למחוק את ההזמנה הזו?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('לא'),
            ),
            TextButton(
              onPressed: () {
                deleteOrder(orderId); // Call the delete function
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('כן'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getProductDetails(); // Fetch product details when the screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('פרטי הזמנה ${widget.order.id}'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align text to the right
            children: [
              Text(
                'מספר הזמנה: ${widget.order.id}',
              ),
              const SizedBox(height: 10),
              Text(
                'שם הלקוח: ${widget.order.userName}',
              ),
              const SizedBox(height: 10),
              Text(
                'טלפון: ${widget.order.phoneNumber}',
              ),
              const SizedBox(height: 10),
              Text(
                'סטטוס: ${widget.order.status}',
              ),
              const SizedBox(height: 10),
              Text(
                'סך הכל: ₪${widget.order.totalPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 20),
              const Text(
                'פרטי ההזמנה:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              productDetailsList.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    ) // Show loading until data is fetched
                  : Expanded(
                      child: ListView.builder(
                        itemCount: productDetailsList.length,
                        itemBuilder: (context, index) {
                          final product = productDetailsList[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              'מזהה: ${product['id']} | שם: ${product['name']} | כמות: ${product['quantity']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _confirmDeleteOrder(widget.order.id); // Show confirmation before delete
                },
                child: const Text('מחק הזמנה'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}