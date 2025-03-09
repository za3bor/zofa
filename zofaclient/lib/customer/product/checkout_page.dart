import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/customer/product/f_checkout_products.dart';
import 'package:zofa_client/global.dart'; // Adjust the path accordingly
import 'package:zofa_client/widgets/christmas/snow_layer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckoutPageScreen extends StatefulWidget {
  const CheckoutPageScreen({super.key});

  @override
  State<CheckoutPageScreen> createState() {
    return _CheckoutPageScreenState();
  }
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
            'imageUrl': 'https://d1qq705dywrog2.cloudfront.net/images/$id.jpeg',
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
      final response = await http
          .get(Uri.parse('http://$ipAddress/api/getProductDetails/$productId'));
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

  bool isFoldableDevice(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Foldable devices tend to have a very wide aspect ratio when unfolded
    final aspectRatio = screenWidth / screenHeight;

    // Define a threshold for foldable device detection
    print('Aspect ratio: $aspectRatio' 'Screen width: $screenWidth');
    return aspectRatio > 2.0 || screenWidth > 500;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const SnowLayer(),
        title: const Text('העגלה שלי'),
      ),
      body: cartItems.isEmpty
          ? Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined, // Icon for an empty cart
                      size: 150.h, // Adjust the size to your preference
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'העגלה שלך ריקה!',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 10.h),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'חזור לחנות',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/background.jpg', // Path to your background image
                    fit: BoxFit
                        .cover, // Makes sure the image covers the whole screen
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(10.0.w),
                          itemCount: cartItems.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            var item = cartItems[index];
                            double totalPrice =
                                item['price'] * item['quantity'];

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
                                            .withValues(
                                                alpha:
                                                    0.25), // Set the desired color with opacity
                                        BlendMode.darken,
                                      ),
                                      child: Image.network(
                                        item['imageUrl'],
                                        width: isFoldableDevice(context)
                                            ? screenWidth * 0.24.w
                                            : screenWidth * 0.30.w,
                                        height: isFoldableDevice(context)
                                            ? screenWidth * 0.24.w
                                            : screenWidth * 0.30.w,
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
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 5.h),
                                        Text(
                                          item['name'],
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          'כמות: ${item['quantity']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        SizedBox(height: 5.h),
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            '${item['quantity']} X ${item['price'].toStringAsFixed(2)} = ${totalPrice.toStringAsFixed(2)}₪',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                        SizedBox(height: 5.h),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 15.w),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                    ),
                                    onPressed: () {
                                      _deleteCartItem(item['id']);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Divider(
                        color: const Color.fromRGBO(109, 76, 65, 1),
                        thickness: 1.5.h,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'סה״כ:',
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '₪${getTotalPrice().toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 16.0.h, horizontal: 16.0.w),
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
                            child: const Text(
                              'לסיום תהליך ההזמנה',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
