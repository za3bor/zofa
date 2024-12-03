import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:hive/hive.dart';
import 'package:zofa_client/global.dart'; // Adjust the path accordingly
import 'package:zofa_client/widgets/snow_layer.dart';

class ProductCheckoutPage extends StatefulWidget {
  final double totalPrice;
  final List<Map<String, dynamic>> cartItems;

  const ProductCheckoutPage(
      {super.key, required this.totalPrice, required this.cartItems});

  @override
  State<ProductCheckoutPage> createState() {
    return _CheckoutPageState();
  }
}

class _CheckoutPageState extends State<ProductCheckoutPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _couponController = TextEditingController();

  double _discountedPrice = 0.0;
  bool _isCouponApplied = false;

  // New variables for the coupon validation state
  Color _couponColor = Colors.black;
  String _couponMessage = '';

  @override
  void initState() {
    super.initState();
    _discountedPrice = widget.totalPrice;
  }

  void _applyCoupon() async {
    if (_couponController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא הזן קוד קופון', textDirection: TextDirection.rtl),
        ),
      );
      return;
    }

    // Call the backend to validate the coupon
    final url = Uri.parse('http://$ipAddress:3000/api/validateCoupon');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': _couponController.text}),
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      final data = jsonDecode(response.body);
      final discountPercentage =
          double.tryParse(data['percentage'].toString()) ?? 0.0;

      setState(() {
        _discountedPrice = widget.totalPrice *
            (1 - discountPercentage / 100); // Apply percentage discount
        _isCouponApplied = true;
        _couponColor = Colors.green; // Change color to green
        _couponMessage = 'קופון יושם בהצלחה!'; // Success message
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('קופון יושם בהצלחה!', textDirection: TextDirection.rtl),
          ),
        );
      }
    } else {
      setState(() {
        _couponColor = Colors.red; // Change color to red
        _couponMessage = 'קוד קופון לא תקף'; // Invalid coupon message

        // Reset the price to the original price when the coupon is invalid
        _discountedPrice = widget.totalPrice;
        _isCouponApplied = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('קוד קופון לא תקף', textDirection: TextDirection.rtl),
          ),
        );
      }
    }
  }

  void _loadInitialCartItemCount() async {
    var box = await Hive.openBox('cart');
    Map cartData = box.get('cart', defaultValue: {});

    cartItemCountNotifier.value = cartData.values.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] ?? 0) as int),
    );
  }

  void _saveProductOrder() async {
    String orderDetails = widget.cartItems
        .map((item) => '${item['id']}:${item['quantity']}\n')
        .join();

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _phoneController.text.length != 10 ||
        _emailController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('לא תקין', textDirection: TextDirection.rtl),
          content: const Text('אנא מלא את כל השדות בצורה נכונה',
              textDirection: TextDirection.rtl),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('אוקי', textDirection: TextDirection.rtl),
            )
          ],
        ),
      );
      return;
    }

    final url = Uri.parse('http://$ipAddress:3000/api/addNewProductOrder');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _nameController.text,
        'phoneNumber': _phoneController.text,
        'orderDetails': orderDetails,
        'totalPrice': _discountedPrice,
        'status': 'Received',
        'email': _emailController.text,
        'couponCode': _couponController.text,
      }),
    );

    if (response.statusCode == 201) {
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _couponController.clear();

      var box = await Hive.openBox('cart');
      await box.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('ההזמנה נשלחה בהצלחה', textDirection: TextDirection.rtl),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('יש בעיה נא להתקשר', textDirection: TextDirection.rtl),
          ),
        );
      }
      print(response.body);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const SnowLayer(),
        title: const Text('Checkout'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Enter your details',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        labelText: 'Coupon Code',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _couponColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _couponColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyCoupon,
                    child: const Text('Apply'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _couponMessage,
                style: TextStyle(
                  color: _couponColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selected Products:',
              ),
              const SizedBox(height: 8),
              Column(
                children: widget.cartItems.map((item) {
                  return Text('${item['name']} x${item['quantity']}');
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Display the old price with a strikethrough and the new price
              _isCouponApplied
                  ? Row(
                      children: [
                        Text(
                          'Total Price: \$${widget.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'New Price: \$${_discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Total Price: \$${widget.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              const SizedBox(height: 16),
              SizedBox(
                child: ElevatedButton(
                  onPressed: _saveProductOrder,
                  child: const Text('Pay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
