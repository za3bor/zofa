import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:hive/hive.dart';
import 'package:zofa_client/global.dart'; // Adjust the path accordingly
import 'package:zofa_client/customer/tabs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final url = Uri.parse('http://$ipAddress/api/validateCoupon');
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
    // Get the user's phone number from FirebaseAuth
    String? userPhoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;

    if (_nameController.text.trim().isEmpty ||
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

    final url = Uri.parse('http://$ipAddress/api/addNewProductOrder');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _nameController.text,
        'phoneNumber': userPhoneNumber,
        'orderDetails': orderDetails,
        'totalPrice': _discountedPrice,
        'status': 'Received',
        'email': _emailController.text,
        'couponCode': _couponController.text,
      }),
    );

    if (response.statusCode == 201) {
      _nameController.clear();
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TabsScreen()),
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
    _nameController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent resizing when keyboard appears
      appBar: const CustomAppBar(
        title: 'Checkout',
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // Background Image
            SizedBox(
              height: double
                  .infinity, // Ensures the background image fills the whole screen
              width: double.infinity,
              child: Image.asset(
                'assets/background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Foreground Content
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 20.0.h),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section
                    Center(
                      child: Text(
                        'הזן את פרטיך',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24.sp,
                            ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Name Input
                    _buildInputField(
                      controller: _nameController,
                      label: 'שם',
                      icon: Icons.person,
                    ),
                    SizedBox(height: 16.h),

                    // Email Input
                    _buildInputField(
                      controller: _emailController,
                      label: 'אימייל',
                      icon: Icons.email,
                      inputType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16.h),

                    // Coupon Section
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _couponController,
                            label: 'קוד קופון',
                            borderColor: _couponColor,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        ElevatedButton.icon(
                          onPressed: _applyCoupon,
                          icon: const Icon(
                            Icons.discount,
                            color: Colors.white,
                          ),
                          label: const Text('החל'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: 10.h,
                              horizontal: 16.w,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _couponMessage,
                      style: TextStyle(
                        color: _couponColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Product Section
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(12.0.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Text
                            Text(
                              'מוצרים נבחרים:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.sp,
                                  ),
                            ),
                            const Divider(
                              thickness: 1.5,
                              color: Colors.black,
                            ),
                            SizedBox(height: 12.h),

                            // List of Products with Dividers
                            ...widget.cartItems.asMap().entries.map((entry) {
                              int index = entry.key;
                              var item = entry.value;

                              return Column(
                                children: [
                                  // Product Row
                                  Row(
                                    children: [
                                      // Product Icon
                                      const Icon(
                                        Icons.shopping_cart,
                                        color: Color(0xFF7A6244),
                                        size: 24,
                                      ),
                                      SizedBox(width: 12.w),

                                      // Product Name and Quantity
                                      Expanded(
                                        child: Text(
                                          item['name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),

                                      // Quantity Badge
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 4.h, horizontal: 8.w),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7A6244),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'x${item['quantity']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Add Divider Below Except for Last Item
                                  if (index < widget.cartItems.length - 1) ...[
                                    SizedBox(height: 8.h),
                                    const Divider(
                                      thickness: 1,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 8.h),
                                  ],
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Price Section
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: EdgeInsets.all(16.0.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isCouponApplied) ...[
                                  Text(
                                    'סך הכל: ₪ ${widget.totalPrice.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'מחיר לאחר הנחה: ₪ ${_discountedPrice.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ] else ...[
                                  Text(
                                    'סך הכל: ₪ ${widget.totalPrice.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Pay Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProductOrder,
                        child: const Text(
                          'תשלום',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
    IconData? icon,
    Color borderColor = Colors.grey,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
