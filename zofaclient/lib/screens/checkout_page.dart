import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/screens/f_checkout_products.dart';
import 'package:zofa_client/global.dart'; // Adjust the path accordingly

class CheckoutPageScreen extends StatefulWidget {
  const CheckoutPageScreen({super.key});

  @override
  State<CheckoutPageScreen> createState() => _CheckoutPageScreenState();
}

class _CheckoutPageScreenState extends State<CheckoutPageScreen> {
  late Box cartBox;
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    var box = await Hive.openBox('cart');
    List<Map<String, dynamic>> loadedCartItems = [];
    Map cartData = box.get('cart', defaultValue: {});

    for (var entry in cartData.entries) {
      try {
        int id = int.tryParse(entry.key.toString()) ?? 0;
        dynamic qty = entry.value['quantity'];
        int parsedQty = (qty is int) ? qty : 0;

        var product = await _getProductDetails(id);
        if (product != null) {
          loadedCartItems.add({
            'id': id,
            'name': product['name'],
            'quantity': parsedQty,
            'price': product['price'],
            'imageUrl': 'https://f003.backblazeb2.com/file/zofapic/$id.jpeg',
          });
        }
      } catch (e) {
        print('Error loading cart item: $e');
      }
    }

    setState(() {
      cartItems = loadedCartItems;
    });
  }

  Future<Map<String, dynamic>?> _getProductDetails(int productId) async {
    try {
      final response = await http.get(
          Uri.parse('http://$ipAddress:3000/api/getProductDetails/$productId'));
      if (response.statusCode == 200) {
        Map<String, dynamic> productData = json.decode(response.body);
        double price = double.tryParse(productData['price'].toString()) ?? 0.0;

        return {
          'name': productData['name'],
          'price': price,
        };
      }
    } catch (e) {
      print('Error fetching product details: $e');
    }
    return null;
  }

  double getTotalPrice() {
    return cartItems.fold(0.0, (sum, item) {
      double price = item['price'] ?? 0.0;
      int quantity = item['quantity'] ?? 0;
      return sum + (quantity * price);
    });
  }

  Future<void> _deleteCartItem(int productId) async {
    try {
      var box = await Hive.openBox('cart');
      Map cartData = box.get('cart', defaultValue: {});

      if (cartData.containsKey(productId)) {
        cartData.remove(productId);
        await box.put('cart', cartData);

        // Update the local cartItems list in the UI
        setState(() {
          cartItems.removeWhere((item) => item['id'] == productId);
        });

        // Recalculate cart item count and notify listeners
        _updateCartItemCount();
      }
    } catch (e) {
      print('Error deleting item from cart: $e');
    }
  }

  void _updateCartItemCount() async {
    var box = await Hive.openBox('cart');
    Map cartData = box.get('cart', defaultValue: {});

    int totalQuantity = cartData.values.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] ?? 0) as int),
    );

    // Update the global cart item count
    cartItemCountNotifier.value = totalQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('העגלה שלי'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image:
                  AssetImage('assets/background.jpg'), // Set background image
              fit: BoxFit.cover, // Make sure it covers the entire screen
            ),
          ),
          child: cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined, // Icon for an empty cart
                        size: 150, // Adjust the size to your preference
                        color: Colors
                            .black, // Color of the icon (you can change this)
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'העגלה שלך ריקה!',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Assistant'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'חזור לחנות',
                          style: TextStyle(
                              fontFamily: 'Assistant',
                              fontSize: 16,
                              color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: cartItems.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          var item = cartItems[index];
                          double totalPrice = item['price'] * item['quantity'];

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            color: const Color.fromARGB(
                                255, 222, 210, 206), // Light Beige: #99521C
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        const Color.fromARGB(255, 121, 85, 72)
                                            .withOpacity(
                                                0.25), // Set the desired color with opacity
                                        BlendMode.darken,
                                      ),
                                      child: Image.network(
                                        item['imageUrl'],
                                        width: screenWidth * 0.25,
                                        height: screenWidth * 0.25,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.black,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 5),
                                        Text(
                                          item['name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.visible,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'כמות: ${item['quantity']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontSize: 15,
                                              ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '₪${item['quantity']}*${item['price'].toStringAsFixed(2)}=${totalPrice.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 5),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Theme.of(context)
                                          .iconTheme
                                          .color, // Use color from ThemeData
                                    ),
                                    onPressed: () {
                                      _deleteCartItem(item['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(
                      color: Color.fromRGBO(109, 76, 65, 1),
                      thickness: 1.5,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'סה״כ:',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Assistant'),
                          ),
                          Text(
                            '₪${getTotalPrice().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Dark Brown: #7D3F0F
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductCheckoutPage(
                                  totalPrice: getTotalPrice(),
                                  cartItems: cartItems,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'לסיום תהליך ההזמנה',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontFamily: 'Assistant',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
