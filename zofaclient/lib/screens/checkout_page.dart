import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/screens/f_checkout_products.dart';

class CheckoutPageScreen extends StatefulWidget {
  const CheckoutPageScreen({Key? key}) : super(key: key);

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
        setState(() {
          cartItems.removeWhere((item) => item['id'] == productId);
        });
      }
    } catch (e) {
      print('Error deleting item from cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('העגלה שלי'),
          backgroundColor: Colors.green,
        ),
        body: SingleChildScrollView(  // Wrap the entire body in SingleChildScrollView
          child: cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Image(
                        image: AssetImage('assets/emptycart.png'),
                        height: 150,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'העגלה שלך ריקה!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('חזור לחנות'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.all(10.0),
                      itemCount: cartItems.length,
                      shrinkWrap: true,  // To ensure the ListView doesn't take up the entire space
                      itemBuilder: (context, index) {
                        var item = cartItems[index];
                        double totalPrice = item['price'] * item['quantity'];

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item['imageUrl'],
                                    width: screenWidth * 0.25,
                                    height: screenWidth * 0.25,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.visible,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'כמות: ${item['quantity']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        '₪${item['quantity']}*${item['price'].toStringAsFixed(2)}=${totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 15),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
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
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'סה״כ:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₪${getTotalPrice().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
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
                            backgroundColor: Colors.green,
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
                            'המשך לתשלום',
                            style: TextStyle(fontSize: 16),
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
