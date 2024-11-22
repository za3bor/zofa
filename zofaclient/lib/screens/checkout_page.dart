import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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

    // Loop through the cart box data
    Map cartData = box.get('cart', defaultValue: {}); // Get cart data
    print('Cart Data: $cartData'); // Log cart data for debugging

    // Ensure cart data is in the correct format and handle type casting properly
    cartData.forEach((dynamic productId, dynamic quantity) async {
      try {
        // Ensure productId is treated as an int and quantity is handled as an int as well
        int id = (productId is String)
            ? int.tryParse(productId) ?? 0
            : productId as int;
        int qty = (quantity is String)
            ? int.tryParse(quantity) ?? 0
            : quantity as int;

        // Fetch product details (replace with actual product fetching logic)
        var product = await _getProductDetails(id);
        if (product != null) {
          loadedCartItems.add({
            'id': id,
            'name': product['name'],
            'quantity': qty,
            'price': product['price'],
            'imageUrl': 'https://f003.backblazeb2.com/file/zofapic/$id.jpeg',
          });
        }
      } catch (e) {
        print('Error loading cart item: $e');
      }
    });

    setState(() {
      cartItems = loadedCartItems;
    });
  }

  // Replace with actual logic to fetch product details based on product ID
  Future<Map<String, dynamic>?> _getProductDetails(int productId) async {
    // Example of fetching product from an API or database
    // Replace this with actual API or database call
    return {
      'name': 'Product $productId', // Product name
      'price': 10.0 * productId, // Price calculation (example)
    };
  }

  double getTotalPrice() {
    return cartItems.fold(
        0, (sum, item) => sum + (item['quantity'] * item['price']));
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
                // Scrollable Product List
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
                                // Product Details
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
                                          // Display Quantity
                                          Text(
                                            'Quantity: ${item['quantity']}',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 10),
                                          // Product Price
                                          Text(
                                            '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}', // Price * Quantity
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
                                // Product Image
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
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(),
                // Fixed Total and Checkout Button
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
                        // Proceed to checkout functionality
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
