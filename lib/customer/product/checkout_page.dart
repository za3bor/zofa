import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:zofa/constant.dart';
import 'package:zofa/customer/product/empty_cart.dart';
import 'package:zofa/customer/product/f_checkout_products.dart';
import 'package:zofa/customer/product/guest_cart.dart';
import 'package:zofa/global.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckoutPageScreen extends StatefulWidget {
  const CheckoutPageScreen({super.key});

  @override
  State<CheckoutPageScreen> createState() {
    return _CheckoutPageScreenState();
  }
}

class _CheckoutPageScreenState extends State<CheckoutPageScreen> {
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> saleCartItems = [];
  List<Map<String, dynamic>> seedCartItems = [];

  @override
  void initState() {
    super.initState();
    _loadSaleCartItems();
    _loadCartItems();
    _loadSeedCartItems();
  }

  Future<void> _loadSaleCartItems() async {
    var box = await Hive.openBox('salecart');
    Map saleCartData = box.get('salecart', defaultValue: {});
    List<Map<String, dynamic>> loadedSaleDeals = [];

    for (var entry in saleCartData.entries) {
      try {
        Map<String, dynamic> deal = Map<String, dynamic>.from(entry.value);
        deal['key'] = entry.key; // add the key here

        loadedSaleDeals.add(deal);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading sale deal: $e')),
          );
        }
      }
    }

    setState(() {
      saleCartItems = loadedSaleDeals;
    });
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading cart item: $e')),
          );
        }
      }
    }

    setState(() {
      cartItems = loadedCartItems;
    });
    sendSaleItemsToBackend(cartItems);
  }

  Future<void> sendSaleItemsToBackend(List<Map<String, dynamic>> items) async {
    final url = Uri.parse(
      'http://$ipAddress/api/checkItems',
    ); // Replace with your server IP or domain
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(items),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final List<dynamic> notFoundItemsRaw = data['notFoundItems'] ?? [];
        final List<dynamic> matchedSalesRaw = data['matchedSales'] ?? [];

        // Convert to List<Map<String, dynamic>>
        final List<Map<String, dynamic>> notFoundItems =
            notFoundItemsRaw.map((item) {
              final map = Map<String, dynamic>.from(item);
              if (map.containsKey('price')) {
                map['price'] = (map['price'] as num).toDouble();
              }
              return map;
            }).toList();

        final List<Map<String, dynamic>> matchedSales =
            matchedSalesRaw
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

        if (matchedSales.isNotEmpty) {
          updateCarts(matchedSales);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exception while sending sale items: $e')),
        );
      }
    }
  }

  Future<void> updateCarts(List<Map<String, dynamic>> matchSale) async {
    // 1) Open both Hive boxes
    final saleBox = await Hive.openBox('salecart');
    final cartBox = await Hive.openBox('cart');

    // 2) Load or initialize salecart
    final Map<String, dynamic> savedDeals =
        saleBox.get('salecart')?.cast<String, dynamic>() ?? {};

    // 3) Load or initialize cart as Map<int, Map<String, dynamic>>
    final rawCart =
        cartBox.get('cart', defaultValue: <int, Map<String, dynamic>>{})
            as Map<dynamic, dynamic>;
    final cartData = <int, Map<String, dynamic>>{
      for (final entry in rawCart.entries)
        (entry.key is int ? entry.key : int.parse(entry.key.toString())):
            Map<String, dynamic>.from(entry.value as Map),
    };

    // UUID generator
    final uuid = Uuid();

    // 4) Process each matched sale entry
    for (final sale in matchSale) {
      final saleIdStr = sale['saleId'].toString();
      final saleIdInt = int.parse(saleIdStr);
      final dealType = sale['deal_type'] as String?;
      final matchedQty = sale['matchedQuantity'] as int? ?? 1;
      final products = sale['products'] as List<dynamic>;
      // Expect each p in products: {'id': int, 'quantity': int}
      final salePricePerBundle = (sale['price'] as num).toDouble();
      final originalPricePerBundle = (sale['original_price'] as num).toDouble();
      final chooseCountRaw = sale['choose_count'];
      final int? chooseCount =
          chooseCountRaw is num ? chooseCountRaw.toInt() : null;

      // We'll determine the dealKey:
      // - If matching existing, reuse its key.
      // - Else generate new key using UUID.
      String? matchingKey;
      int groupCount =
          matchedQty; // for non-choose deals, matchedQty is the number of bundles

      // Build a normalized list for comparison if chooseXofN:
      List<Map<String, dynamic>> bundlePattern = [];

      if (dealType == 'chooseXofN' && chooseCount != null && chooseCount > 0) {
        // matchedQty is assumed number of bundles (groupCount)
        groupCount = matchedQty;

        // Build bundlePattern as List<Map{id, quantity}> for comparison:
        // Already given by `products`, but make a deep-copied normalized list:
        final Map<int, Map<String, dynamic>> normalizedProducts = {};

        for (final p in products) {
          final int id = p['id'] as int;
          final int quantity = p['quantity'] as int;
          final String? name = p['name'];
          final double? price = (p['price'] as num?)?.toDouble();

          if (normalizedProducts.containsKey(id)) {
            normalizedProducts[id]!['quantity'] += quantity;
          } else {
            final int perBundleQty = quantity ~/ groupCount;

            normalizedProducts[id] = {
              'id': id,
              'name': name,
              'price': price,
              'quantity': perBundleQty, // ✅ now per bundle
            };
          }
        }

        bundlePattern = normalizedProducts.values.toList();
      } else {
        // Always populate bundlePattern for non-chooseXofN
        bundlePattern =
            products.map<Map<String, dynamic>>((p) {
              final int totalQty = p['quantity'] as int;
              final int perBundleQty = totalQty ~/ groupCount;

              return {
                'id': p['id'] as int,
                'name': p['name'],
                'price': (p['price'] as num?)?.toDouble(),
                'quantity': perBundleQty,
              };
            }).toList();
      }

      // 2) Try to find existing deal in savedDeals
      // Iterate over savedDeals.entries; compare saleId, dealType, and for chooseXofN compare product lists
      for (final entry in savedDeals.entries) {
        final key = entry.key;
        final existing = entry.value as Map<dynamic, dynamic>;

        // Check saleId match
        if ((existing['saleId'] as int) != saleIdInt) continue;
        // Check dealType match
        final existingDealType = existing['dealType'] as String?;
        if (existingDealType != dealType) continue;

        // If not chooseXofN, and key pattern is simply 'deal_<saleId>',
        // you might decide that any non-choose deal for same saleId merges.
        // If you want more differentiation, include extra checks here.
        if (dealType != 'chooseXofN') {
          // Found an existing non-choose deal for same saleId: match
          matchingKey = key;
          break;
        }

        // For chooseXofN, compare product lists:
        // existing['products'] should be List<Map<String, dynamic>>
        final existingProductsRaw = existing['products'] as List<dynamic>;
        final existingProducts =
            existingProductsRaw
                .map(
                  (p) => {
                    'id': (p as Map)['id'] as int,
                    'quantity': (p)['quantity'] as int,
                  },
                )
                .toList();

        // Sort both lists by id for comparison
        existingProducts.sort(
          (a, b) => (a['id'] as int).compareTo(b['id'] as int),
        );
        bundlePattern.sort(
          (a, b) => (a['id'] as int).compareTo(b['id'] as int),
        );

        if (existingProducts.length != bundlePattern.length) {
          continue;
        }
        bool allMatch = true;
        for (int i = 0; i < existingProducts.length; i++) {
          if (existingProducts[i]['id'] != bundlePattern[i]['id'] ||
              existingProducts[i]['quantity'] != bundlePattern[i]['quantity']) {
            allMatch = false;
            break;
          }
        }
        if (allMatch) {
          matchingKey = key;
          break;
        }
      }

      // 3) Determine dealKey to use
      String dealKey;
      if (matchingKey != null) {
        dealKey = matchingKey;
      } else {
        dealKey =
            dealType != 'chooseXofN'
                ? 'deal_$saleIdStr' // ✅ fixed for single/bundle/etc.
                : 'deal_${saleIdStr}_${uuid.v4()}'; // ✅ use UUID only for chooseXofN
      }

      // 4) Update or insert in savedDeals
      if (matchingKey != null) {
        // Existing entry: increment quantity
        final existingDeal = Map<String, dynamic>.from(savedDeals[dealKey]!);

        // Increase quantity by groupCount
        existingDeal['quantity'] =
            (existingDeal['quantity'] as int) + groupCount;

        // Update savedAmount: assume stored as total saved so far
        final perBundleSaving = (originalPricePerBundle - salePricePerBundle);
        final additionalSaving = perBundleSaving * groupCount;
        if (existingDeal.containsKey('savedAmount')) {
          existingDeal['savedAmount'] =
              (existingDeal['savedAmount'] as num).toDouble() +
              additionalSaving;
        } else {
          existingDeal['savedAmount'] = additionalSaving;
        }

        savedDeals[dealKey] = existingDeal;
      } else {
        // New entry
        final perBundleSaving = (originalPricePerBundle - salePricePerBundle);
        final totalSaving = perBundleSaving * groupCount;
        final newDeal = <String, dynamic>{
          'saleId': saleIdInt,
          'name': sale['name'],
          'dealType': dealType,
          'products':
              bundlePattern, // keep as-is; UI/display logic will read id & quantity
          'salePricePerBundle': salePricePerBundle,
          'originalPricePerBundle': originalPricePerBundle,
          'quantity': groupCount,
          'savedAmount': totalSaving,
        };
        if (dealType == 'chooseXofN' && chooseCount != null) {
          newDeal['chooseCount'] = chooseCount;
        }
        savedDeals[dealKey] = newDeal;
      }

      // 5) Reduce quantities in cartData for each product in this sale
      // For chooseXofN: remove groupCount * perBundleQty; for non-choose: matchedQty * perBundleQty (matchedQty == groupCount)
      for (final p in products) {
        final pid = p['id'] as int;
        final removeQty = p['quantity'] as int;

        if (cartData.containsKey(pid)) {
          final currentQty = cartData[pid]!['quantity'] as int;
          final updatedQty = currentQty - removeQty;
          if (updatedQty > 0) {
            cartData[pid]!['quantity'] = updatedQty;
          } else {
            cartData.remove(pid);
          }
        }
      }
    }

    // 6) Persist both boxes
    await saleBox.put('salecart', savedDeals);
    await cartBox.put('cart', cartData);

    // 7) Refresh UI/state
    if (mounted) {
      await _loadSaleCartItems();
      await _loadCartItems();
    }
  }

  Future<void> _loadSeedCartItems() async {
    var box = await Hive.openBox('seedscart');
    List<Map<String, dynamic>> loadedSeedItems = [];
    Map seedCartData = box.get('seedscart', defaultValue: {});

    for (var entry in seedCartData.entries) {
      try {
        int id = int.tryParse(entry.key.toString()) ?? 0;
        var value = entry.value;

        double grams = 0.0;
        double price = 0.0;

        if (value is Map) {
          grams =
              (value['weight'] is num)
                  ? (value['weight'] as num).toDouble()
                  : 0.0;
          price =
              (value['price'] is num)
                  ? (value['price'] as num).toDouble()
                  : 0.0;
        }

        var product = await _getProductDetails(id);
        if (product != null) {
          loadedSeedItems.add({
            'id': id,
            'name': product['name'],
            'weight': grams, // still calling it "weight" for UI consistency
            'price': price,
            'imageUrl': 'https://d1qq705dywrog2.cloudfront.net/images/$id.jpeg',
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading seed cart item: $e')),
          );
        }
      }
    }
    setState(() {
      seedCartItems = loadedSeedItems;
    });
  }

  Future<Map<String, dynamic>?> _getProductDetails(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/getProductDetails/$productId'),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> productData = json.decode(response.body);
        double price = double.tryParse(productData['price'].toString()) ?? 0.0;

        return {'name': productData['name'], 'price': price};
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching product details: $e')),
        );
      }
    }
    return null;
  }

  double getTotalPrice() {
    return getSalesTotalPrice() + getRegularTotalPrice() + getSeedsTotalPrice();
  }

  double getSalesTotalPrice() {
    double total = 0;

    // Sale cart items (deals)
    for (var deal in saleCartItems) {
      double salePricePerBundle = deal['salePricePerBundle'] ?? 0;
      int quantity = deal['quantity'] ?? 1;
      total += salePricePerBundle * quantity;
    }

    return total;
  }

  double getSeedsTotalPrice() {
    double total = 0;

    for (var seedItem in seedCartItems) {
      // seedItem is a Map<String, dynamic> with keys: 'price', 'weight', etc.
      double weight = seedItem['weight'] ?? 0;
      double price = seedItem['price'] ?? 0;
      total += price * (weight / 1000); // Convert grams to kg if needed
    }

    return total;
  }

  double getRegularTotalPrice() {
    double total = 0;

    // Regular cart items
    for (var item in cartItems) {
      double price = item['price'] ?? 0;
      int quantity = item['quantity'] ?? 1;
      total += price * quantity;
    }

    return total;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item from cart: $e')),
        );
      }
    }
  }

  Future<void> _deleteSeedCartItem(int productId) async {
    try {
      var box = await Hive.openBox('seedscart');
      Map seedCartData = box.get('seedscart', defaultValue: {});

      if (seedCartData.containsKey(productId)) {
        seedCartData.remove(productId);
        await box.put('seedscart', seedCartData);

        // Update the local seedCartItems list in the UI
        setState(() {
          seedCartItems.removeWhere((item) => item['id'] == productId);
        });

        // Recalculate total seeds and update notifier/UI
        _updateCartItemCount(); // or a separate method like _updateSeedItemCount()
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה במחיקת מוצר מהעגלה: $e')));
      }
    }
  }

  Future<void> _deleteSaleFromCart(String dealKey) async {
    try {
      var saleCartBox = await Hive.openBox('salecart');
      Map saleCartData = saleCartBox.get('salecart', defaultValue: {});

      if (saleCartData.containsKey(dealKey)) {
        saleCartData.remove(dealKey);
        await saleCartBox.put('salecart', saleCartData);

        // Update the local saleCartItems list in the UI
        setState(() {
          saleCartItems.removeWhere((item) => item['key'] == dealKey);
        });

        // Recalculate cart item count and notify listeners
        _updateCartItemCount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה במחיקת המבצע מהעגלה: $e')),
        );
      }
    }
  }

  void _updateCartItemCount() async {
    var box = await Hive.openBox('cart');
    var saleCartBox = await Hive.openBox('salecart');
    var seedsBox = await Hive.openBox('seedscart');

    Map<dynamic, dynamic> seedsCartData = seedsBox.get(
      'seedscart',
      defaultValue: <int, Map<String, dynamic>>{},
    );

    Map cartData = box.get('cart', defaultValue: {});
    Map saleCartData = saleCartBox.get('salecart', defaultValue: {});

    int totalQuantity = cartData.values.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] ?? 0) as int),
    );
    int totalSaleItems = saleCartData.values.fold<int>(0, (sum, item) {
      int dealQuantity = (item['quantity'] ?? 0) as int;
      List<dynamic> products = item['products'] as List<dynamic>;

      int totalItemsInDeal = products.fold<int>(0, (pSum, p) {
        return pSum + ((p['quantity'] ?? 0) as int);
      });

      return sum + (dealQuantity * totalItemsInDeal);
    });
    int totalSeedsAsUnits = seedsCartData.length;

    // Update the global cart item count
    cartItemCountNotifier.value =
        totalQuantity + totalSaleItems + totalSeedsAsUnits;
  }

  bool isFoldableDevice(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Foldable devices tend to have a very wide aspect ratio when unfolded
    final aspectRatio = screenWidth / screenHeight;

    // Define a threshold for foldable device detection
    return aspectRatio > 2.0 || screenWidth > 500;
  }

  Widget _buildSaleDealCard(BuildContext context, Map<String, dynamic> deal) {
    List products = deal['products'];
    double salePrice = (deal['salePricePerBundle'] ?? 0.0).toDouble();
    double originalPrice = (deal['originalPricePerBundle'] ?? 0.0).toDouble();
    int quantity = deal['quantity'];
    String key = deal['key'];
    String? dealName = deal['name'];

    double screenWidth = MediaQuery.of(context).size.width;

    bool isFoldableDevice(BuildContext context) {
      // Replace with your actual foldable device detection logic
      return false;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + delete icon row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Text(
                    dealName ?? 'מבצע',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteSaleFromCart(key),
                ),
              ],
            ),

            // List of products
            Padding(
              padding: EdgeInsets.only(right: 12.w, left: 12.w),
              child: Column(
                children:
                    products.map<Widget>((p) {
                      int qty = p['quantity'] ?? 1;
                      String? id = p['id']?.toString();
                      String imageUrl =
                          'https://d1qq705dywrog2.cloudfront.net/images/$id.jpeg';
                      double imageSize =
                          isFoldableDevice(context)
                              ? screenWidth * 0.24.w
                              : screenWidth * 0.30.w;


                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        elevation: 0,
                        margin: EdgeInsets.symmetric(vertical: 8.h),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  const Color.fromARGB(
                                    255,
                                    121,
                                    85,
                                    72,
                                  ).withAlpha(64), // 0.25 opacity approx
                                  BlendMode.darken,
                                ),
                                child: Image.network(
                                  imageUrl,
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        width: imageSize,
                                        height: imageSize,
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 50.h,
                                          color: Colors.black,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.h),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['name'] ?? '',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                    SizedBox(height: 5.h),
                                    Text(
                                      'כמות: $qty',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                    SizedBox(height: 5.h),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
            // Price summary
            Padding(
              padding: EdgeInsets.only(bottom: 12.w, left: 12.w, right: 12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'כמות חבילות: $quantity',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                  ),
                  Text(
                    'מחיר מקורי: ₪${(originalPrice * quantity).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    'מחיר עסקה: ₪${(salePrice * quantity).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'חסכת: ₪${((originalPrice - salePrice) * quantity).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final userStatusBox = Hive.box('userStatus');
    final isGuest = userStatusBox.get('isGuest', defaultValue: false);
    final allItemsCount =
        cartItems.length + saleCartItems.length + seedCartItems.length;

    return Scaffold(
      appBar: const CustomAppBar(title: 'העגלה שלי'),
      body:
          isGuest
              ? const EmptyGuestCartWidget() // If it's a guest, show the custom widget.
              : cartItems.isEmpty &&
                  saleCartItems.isEmpty &&
                  seedCartItems.isEmpty
              ? const EmptyCartWidget() // If it's not a guest and the cart is empty, show empty cart.
              : Stack(
                children: [
                  // Background image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/background.jpg', // Path to your background image
                      fit:
                          BoxFit
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
                            itemCount: allItemsCount,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              if (index < cartItems.length) {
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
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            const Color.fromARGB(
                                              255,
                                              121,
                                              85,
                                              72,
                                            ).withValues(
                                              alpha: 0.25,
                                            ), // Set the desired color with opacity
                                            BlendMode.darken,
                                          ),
                                          child: Image.network(
                                            item['imageUrl'],
                                            width:
                                                isFoldableDevice(context)
                                                    ? screenWidth * 0.24.w
                                                    : screenWidth * 0.30.w,
                                            height:
                                                isFoldableDevice(context)
                                                    ? screenWidth * 0.24.w
                                                    : screenWidth * 0.30.w,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
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
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                            SizedBox(height: 5.h),
                                            Text(
                                              'כמות: ${item['quantity']}',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                            SizedBox(height: 5.h),
                                            Directionality(
                                              textDirection: TextDirection.ltr,
                                              child: Text(
                                                '${item['quantity']} X ${item['price'].toStringAsFixed(2)} = ${totalPrice.toStringAsFixed(2)}₪',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                              ),
                                            ),
                                            SizedBox(height: 5.h),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 15.w),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          _deleteCartItem(item['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              } else if (index <
                                  cartItems.length + saleCartItems.length) {
                                int saleIndex = index - cartItems.length;
                                var deal = saleCartItems[saleIndex];
                                // existing sale deal card
                                return _buildSaleDealCard(context, deal);
                              } else {
                                int seedIndex =
                                    index -
                                    cartItems.length -
                                    saleCartItems.length;
                                var seedItem = seedCartItems[seedIndex];
                                double price = seedItem['price'] ?? 0.0;
                                double grams = seedItem['weight'] ?? 0.0;

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.r),
                                  ),
                                  elevation: 5,
                                  margin: EdgeInsets.symmetric(vertical: 8.0.h),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            const Color.fromARGB(
                                              255,
                                              121,
                                              85,
                                              72,
                                            ).withValues(
                                              alpha: 0.25,
                                            ), // Set the desired color with opacity
                                            BlendMode.darken,
                                          ),
                                          child: Image.network(
                                            seedItem['imageUrl'],
                                            width:
                                                isFoldableDevice(context)
                                                    ? screenWidth * 0.24.w
                                                    : screenWidth * 0.30.w,
                                            height:
                                                isFoldableDevice(context)
                                                    ? screenWidth * 0.24.w
                                                    : screenWidth * 0.30.w,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
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
                                              seedItem['name'],
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                            SizedBox(height: 5.h),
                                            Text(
                                              'כמות: ${grams.toStringAsFixed(1)} גרם',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                            SizedBox(height: 5.h),
                                            Directionality(
                                              textDirection: TextDirection.ltr,
                                              child: Text(
                                                '${grams.toString()} × ${price.toStringAsFixed(2)} = ${((grams / 1000) * price).toStringAsFixed(2)} ₪',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                              ),
                                            ),
                                            SizedBox(height: 5.h),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 15.w),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          _deleteSeedCartItem(seedItem['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
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
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₪${getTotalPrice().toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 16.0.h,
                            horizontal: 16.0.w,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ProductCheckoutPage(
                                          salesTotalPrice: getSalesTotalPrice(),
                                          regularTotalPrice:
                                              getRegularTotalPrice(),
                                          seedsTotalPrice: getSeedsTotalPrice(),
                                          cartItems: cartItems,
                                          saleCartItems: saleCartItems,
                                          seedsCartItems: seedCartItems,
                                        ),
                                  ),
                                );
                              },
                              child: const Text('לסיום תהליך ההזמנה'),
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
