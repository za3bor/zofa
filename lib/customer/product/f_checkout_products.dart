import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';
import 'package:hive/hive.dart';
import 'package:zofa/customer/tabs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductCheckoutPage extends StatefulWidget {
  final double salesTotalPrice;
  final double regularTotalPrice;
  final double seedsTotalPrice;
  final List<Map<String, dynamic>> cartItems;
  final List<Map<String, dynamic>> saleCartItems;
  final List<Map<String, dynamic>> seedsCartItems;

  const ProductCheckoutPage({
    super.key,
    required this.salesTotalPrice,
    required this.regularTotalPrice,
    required this.seedsTotalPrice,

    required this.cartItems,
    required this.saleCartItems,
    required this.seedsCartItems,
  });

  @override
  State<ProductCheckoutPage> createState() {
    return _CheckoutPageState();
  }
}

class _CheckoutPageState extends State<ProductCheckoutPage> {
  final _nameController = TextEditingController();
  final _couponController = TextEditingController();

  double _discountedPrice = 0.0;
  bool _isCouponApplied = false;

  // New variables for the coupon validation state
  Color _couponColor = Colors.black;
  String _couponMessage = '';
  late FocusNode _couponFocus;
  late FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _couponFocus = FocusNode();
    _nameFocus = FocusNode();
    _discountedPrice = price();
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

      if (widget.cartItems.isNotEmpty || widget.seedsCartItems.isNotEmpty) {
        setState(() {
          _discountedPrice =
              ((widget.regularTotalPrice + widget.seedsTotalPrice) *
                      (1 - (discountPercentage / 100)) +
                  widget.salesTotalPrice); // Apply percentage discount
          _isCouponApplied = true;
          _couponColor = Colors.green; // Change color to green
          _couponMessage = 'קופון יושם בהצלחה!'; // Success message
        });
      } else {
        setState(() {
          _isCouponApplied = false;
          _couponColor = Colors.red; // Change color to green
          _couponMessage = 'קופון לא תקף על מבצעים!'; // Success message
        });
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'קופון יושם בהצלחה!',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    } else {
      setState(() {
        _couponColor = Colors.red; // Change color to red
        _couponMessage = 'קוד קופון לא תקף'; // Invalid coupon message

        // Reset the price to the original price when the coupon is invalid
        _discountedPrice =
            widget.regularTotalPrice +
            widget.salesTotalPrice +
            widget.seedsTotalPrice;
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

  void _saveProductOrder() async {
    final Map<int, double> combinedQuantities = {};

    // Helper function to add products to combinedQuantities
    void addProduct(int id, double quantity) {
      if (combinedQuantities.containsKey(id)) {
        combinedQuantities[id] = combinedQuantities[id]! + quantity;
      } else {
        combinedQuantities[id] = quantity;
      }
    }

    // 1. Flatten products from salesBundles and add them
    for (var sale in widget.saleCartItems) {
      List<dynamic> products = sale['products'] ?? [];
      for (var product in products) {
        int id = product['id'];
        int quantity = product['quantity'];
        addProduct(id, quantity.toDouble());
      }
    }

    // 2. Add products from simpleCart
    for (var product in widget.cartItems) {
      int id = product['id'];
      int quantity = product['quantity'];
      addProduct(id, quantity.toDouble());
    }

    // 2. Add products from simpleCart
    for (var product in widget.seedsCartItems) {
      int id = product['id'];
      double weight = product['weight'];
      addProduct(id, weight);
    }

    String orderDetails = combinedQuantities.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join('\n');

    if (_nameController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('לא תקין', textDirection: TextDirection.rtl),
              content: const Text(
                'אנא מלא את כל השדות בצורה נכונה',
                textDirection: TextDirection.rtl,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text('אוקי', textDirection: TextDirection.rtl),
                ),
              ],
            ),
      );
      return;
    }
    // Retrieve the phone number from Hive
    var box = await Hive.openBox('userStatus');
    String? userPhoneNumber = box.get(
      'phoneNumber',
    ); // Fetch the stored phone number

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
        'email': 'EMPTY',
      }),
    );

    if (response.statusCode == 201) {
      _nameController.clear();
      _couponController.clear();

      var box = await Hive.openBox('cart');
      var salebox = await Hive.openBox('salecart');
      var seedsbox = await Hive.openBox('seedscart');
      await seedsbox.clear();
      await salebox.clear();
      await box.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ההזמנה נשלחה בהצלחה',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const TabsScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'יש בעיה נא להתקשר',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    }
  }

  double price() {
    return widget.regularTotalPrice +
        widget.salesTotalPrice +
        widget.seedsTotalPrice;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _couponController.dispose();
    _nameFocus.dispose(); // important to prevent memory leaks
    _couponFocus.dispose(); // important to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _couponFocus.unfocus();
        _nameFocus.unfocus(); // Dismiss the keyboard when tapping outside
      },
      child: Scaffold(
        appBar: const CustomAppBar(title: 'מעבר לתשלום'),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              // Background Image
              SizedBox(
                height:
                    double
                        .infinity, // Ensures the background image fills the whole screen
                width: double.infinity,
                child: Image.asset('assets/background.jpg', fit: BoxFit.cover),
              ),
              // Foreground Content
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0.w,
                  vertical: 20.0.h,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Section
                      Center(
                        child: Text(
                          'הזן את פרטיך',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge!.copyWith(
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
                        focusNode: _nameFocus,
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
                              focusNode: _couponFocus,
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
                              if (widget.cartItems.isNotEmpty) ...[
                                Text(
                                  'מוצרים שנבחרו:',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.sp,
                                  ),
                                ),
                                const Divider(
                                  thickness: 1.5,
                                  color: Colors.black,
                                ),
                                SizedBox(height: 5.h),

                                // Regular cart items
                                ...widget.cartItems.asMap().entries.map((
                                  entry,
                                ) {
                                  final idx = entry.key;
                                  final item = entry.value;
                                  return Column(
                                    children: [
                                      _buildProductRow(
                                        icon: Icons.shopping_cart,
                                        name: item['name'],
                                        quantity: item['quantity'],
                                        backgroundColor: Colors.brown.shade50,
                                      ),
                                      if (idx <
                                          widget.cartItems.length - 1) ...[
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
                              if (widget.saleCartItems.isNotEmpty &&
                                  widget.cartItems.isEmpty) ...[
                                SizedBox(height: 16.h),
                              ],

                              // Divider before sale bundles
                              if (widget.saleCartItems.isNotEmpty) ...[
                                Text(
                                  'עסקאות במבצע:',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.sp,
                                  ),
                                ),
                                const Divider(
                                  thickness: 1.5,
                                  color: Colors.black,
                                ),
                                SizedBox(height: 5.h),

                                // One card per deal
                                ...widget.saleCartItems.map((deal) {
                                  final products =
                                      deal['products'] as List<dynamic>;
                                  return Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Optional: show the deal name as header
                                        Text(
                                          deal['name'] as String,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium!.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8.h),

                                        // Now list each product in this deal
                                        ...products.map<Widget>((p) {
                                          final prodName = p['name'] as String;
                                          final prodQty =
                                              (p['quantity'] * deal['quantity'])
                                                  as int;
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 4.h,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.local_offer,
                                                  color: Color(0xFF7A6244),
                                                ),
                                                SizedBox(width: 8.w),
                                                Expanded(child: Text(prodName)),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 4.h,
                                                    horizontal: 8.w,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF7A6244),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'x$prodQty',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              if (widget.seedsCartItems.isNotEmpty) ...[
                                SizedBox(height: 5.h),
                                Text(
                                  'זרעים שנבחרו:',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.sp,
                                  ),
                                ),
                                const Divider(
                                  thickness: 1.5,
                                  color: Colors.black,
                                ),
                                SizedBox(height: 5.h),
                                // one row per seed item
                                ...widget.seedsCartItems.map<Widget>((seed) {
                                  final name = seed['name'] as String;
                                  final weight =
                                      (seed['weight'] as num).toDouble();
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 4.h,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.spa,
                                          color: Color(0xFF7A6244),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(child: Text(name)),
                                        // show weight
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4.h,
                                            horizontal: 8.w,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF7A6244),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${weight.toStringAsFixed(0)} גרם',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 17.h),

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
                                      'תשלום וקבלה רק בחנות',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium!.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'סה"כ לתשלום: ₪ ${price().toStringAsFixed(2)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'סה"כ לתשלום לאחר הנחה: ₪ ${_discountedPrice.toStringAsFixed(2)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium!.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'תשלום וקבלה רק בחנות',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium!.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'סה"כ לתשלום: ₪ ${price().toStringAsFixed(2)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium!.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 10.h),

                                  Text(
                                    'קופון תקף רק על מוצרים רגילים ולא על מבצעים',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow({
    required IconData icon,
    required String name,
    required int quantity,
    String? trailingText,
    Color? backgroundColor,
  }) {
    return Padding(
      padding: EdgeInsets.all(13.w),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7A6244), size: 24),
          SizedBox(width: 12.w),
          Expanded(child: Text(name)),
          Container(
            padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF7A6244),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'x$quantity',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (trailingText != null) ...[
            SizedBox(width: 12.w),
            Text(
              trailingText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
    IconData? icon,
    Color borderColor = Colors.grey,
    FocusNode? focusNode,
  }) {
    return TextField(
      focusNode: focusNode,

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
