import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/screens/f_checkout_products.dart';

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
    print('Loading Cart Data: $cartData');

    for (var entry in cartData.entries) {
      try {
        int id = int.tryParse(entry.key.toString()) ?? 0;
        dynamic qty =
            entry.value['quantity']; // Access quantity directly from the map

        // Ensure that quantity is a valid integer
        int parsedQty = (qty is int) ? qty : 0;

        print('Parsed quantity for product ID $id: $parsedQty');

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
      print(response.body); // Print the full response to check the data

      if (response.statusCode == 200) {
        Map<String, dynamic> productData = json.decode(response.body);
        print('Product Data: $productData'); // Check the price here

        // Ensure 'price' is parsed correctly as a double
        double price = double.tryParse(productData['price'].toString()) ?? 0.0;

        return {
          'name': productData['name'],
          'price': price, // Store the price as a double
        };
      } else {
        print('Failed to load product details for ID $productId');
        return null;
      }
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }

  double getTotalPrice() {
    double total = cartItems.fold(0.0, (sum, item) {
      double price = item['price'] ?? 0.0; // Fallback to 0.0 if price is null
      int quantity = item['quantity'] ?? 0; // Fallback to 0 if quantity is null

      print(
          'Calculating price for ${item['name']}: $price, Quantity: $quantity'); // Debug log
      return sum + (quantity * price); // Multiply price by quantity
    });

    print('Total Price: $total'); // Final total debug log
    return total;
  }

  Future<void> _deleteCartItem(int productId) async {
    try {
      var box = await Hive.openBox('cart');
      Map cartData = box.get('cart', defaultValue: {});

      // Debug: Print cart data before deletion
      print('Cart Data Before Deletion: $cartData');
      print('Attempting to delete product with key: $productId');

      if (cartData.containsKey(productId)) {
        // Use `int` key directly
        cartData.remove(productId); // Remove the item
        await box.put('cart', cartData); // Save updated cart

        setState(() {
          cartItems.removeWhere((item) => item['id'] == productId);
        });

        // Debug: Print updated cart data
        print('Deleted product $productId. Updated cart: ${box.get('cart')}');
      } else {
        print(
            'Product $productId not found in cart. Available keys: ${cartData.keys}');
      }
    } catch (e) {
      print('Error deleting item from cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: cartItems.map((item) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item['name'],
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Quantity: ${item['quantity']}',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '\$${double.tryParse(item['price'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: Image.network(
                                      item['imageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image,
                                            size: 50, color: Colors.grey);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _deleteCartItem(item['id']);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${getTotalPrice().toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                      child: const Text('Proceed to Checkout'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
