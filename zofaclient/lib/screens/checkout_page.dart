import 'package:flutter/material.dart';

class CheckoutPageScreen extends StatelessWidget {
  CheckoutPageScreen({super.key});

  final List<Map<String, dynamic>> cartItems = [
    {
      'name': 'Product 1',
      'quantity': 2,
      'price': 10.0,
      'imageUrl': 'https://via.placeholder.com/120',
    },
    {
      'name': 'Product 2',
      'quantity': 1,
      'price': 15.0,
      'imageUrl': 'https://via.placeholder.com/120',
    },
    {
      'name': 'Product 3',
      'quantity': 3,
      'price': 7.5,
      'imageUrl': 'https://via.placeholder.com/120',
    },
        {
      'name': 'Product 3',
      'quantity': 3,
      'price': 7.5,
      'imageUrl': 'https://via.placeholder.com/120',
    },
        {
      'name': 'Product 3',
      'quantity': 3,
      'price': 7.5,
      'imageUrl': 'https://via.placeholder.com/120',
    },
    
  ];

  double getTotalPrice() {
    return cartItems.fold(0, (sum, item) => sum + (item['quantity'] * item['price']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: Column(
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
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Display Quantity
                                    Text(
                                      'Quantity: ${item['quantity']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    // Product Price
                                    Text(
                                      '\$${item['price'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
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
                                errorBuilder: (context, error, stackTrace) {
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
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${getTotalPrice().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
