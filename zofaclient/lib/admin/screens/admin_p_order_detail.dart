import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:zofa_client/models/product_orders.dart'; // Import your model
import 'package:zofa_client/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  void sendWhatsApp(String phoneNumber, String message) async {
    final uri = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not send WhatsApp message';
    }
  }

  // Function to send notification to backend
  Future<void> sendNotification(
      String phoneNumber, String title, String body) async {
    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress:3000/api/sendNotification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackbar('ההודעה נשלחה בהצלחה');
      } else {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      _showSnackbar('שגיאה בשליחת ההודעה: ${e.toString()}');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Function to delete bread order
  Future<void> deleteOrder(int orderId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://$ipAddress:3000/api/deleteProductOrder/$orderId'),
      );

      if (response.statusCode == 200) {
        _showSnackbar('ההזמנה נמחקה בהצלחה.');
        Navigator.pop(
            context); // Go back to the previous screen after successful deletion
      } else {
        throw Exception('Failed to delete bread order.');
      }
    } catch (e) {
      _showSnackbar('שגיאה במחיקת ההזמנה.');
    }
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
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align text to the right
            children: [
              Text(
                'מספר הזמנה: ${widget.order.id}',
              ),
              SizedBox(height: 10.h),
              Text(
                'שם הלקוח: ${widget.order.userName}',
              ),
              SizedBox(height: 10.h),
              Text(
                'טלפון: ${widget.order.phoneNumber}',
              ),
              SizedBox(height: 10.h),
              Text(
                'סטטוס: ${widget.order.status}',
              ),
              SizedBox(height: 10.h),
              Text(
                'סך הכל: ₪${widget.order.totalPrice.toStringAsFixed(2)}',
              ),
              SizedBox(height: 20.h),
              const Text(
                'פרטי ההזמנה:',
              ),
              SizedBox(height: 10.h),
              productDetailsList.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    ) // Show loading until data is fetched
                  : Expanded(
                      child: Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(10.0.w),
                          itemCount: productDetailsList.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            var product = productDetailsList[index];
                            final imageUrl =
                                'https://f003.backblazeb2.com/file/zofapic/${product['id']}.jpg';

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              elevation: 5,
                              margin: EdgeInsets.symmetric(vertical: 8.0.h),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        const Color.fromARGB(255, 121, 85, 72)
                                            .withOpacity(0.25),
                                        BlendMode.darken,
                                      ),
                                      child: Image.network(
                                        imageUrl,
                                        width: 100.w,
                                        height: 100.h,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(
                                            Icons.broken_image,
                                            size: 50.h,
                                            color: Colors.black,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 5.h),
                                        Text(
                                          product['name'],
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'כמות: ${product['quantity']}',
                                        ),
                                        Text(
                                          'ברקוד: ${product['id']}',
                                        ),
                                        SizedBox(height: 5.h),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 15.w),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      sendNotification(
                          widget.order.phoneNumber,
                          'ההזמנה שלך יצאה למשלוח',
                          'שלום ${widget.order.userName}, ההזמנה שלך יצאה למשלוח');
                      sendWhatsApp(widget.order.phoneNumber, 'ההזמנה מוכנה');
                    },
                    child: const Text('שלח'),
                  ),
                  SizedBox(width: 8.0.w),
                  ElevatedButton(
                    onPressed: () {
                      _confirmDeleteOrder(
                          widget.order.id); // Show confirmation before delete
                    },
                    child: const Text('מחק הזמנה'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
