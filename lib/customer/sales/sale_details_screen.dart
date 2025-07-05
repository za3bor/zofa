import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import 'package:zofa/constant.dart';
import 'package:zofa/customer/product/product_details.dart';
import 'package:zofa/customer/tabs.dart';
import 'package:zofa/global.dart';
import 'package:zofa/models/sale_display_item.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SaleDetailsScreen extends StatefulWidget {
  final int saleId;

  const SaleDetailsScreen({super.key, required this.saleId});

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  final PageController _pageController = PageController();
  SaleDisplayItem? sale;
  bool _loading = true;
  String? _error;
  DateTime? startDate;
  DateTime? endDate;
  Map<String, int> selectedProductCounts = {};
  late IO.Socket socket;
  Map<int, int> _productStock = {}; // Map productId -> stock count

  // Additional fields for chooseXofN
  String? dealType;
  int? chooseCount;
  double? groupPrice;

  @override
  void initState() {
    super.initState();
    fetchSaleDetails();
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io(
      'http://$ipAddress', // Replace with your backend URL
      IO.OptionBuilder().setTransports([
        'websocket',
      ]) // Use WebSocket for the connection
      .build(),
    );
    socket.connect();

    socket.onConnect((_) {});

    // Listen for order updates (or you can define a specific event for stock update)
    socket.on('orderUpdate', (data) {
      if (data is Map) {
        // Single update example:
        final productId = int.tryParse(data['productId'].toString());
        final stock = int.tryParse(data['stock'].toString());

        if (productId != null && stock != null) {
          setState(() {
            _productStock[productId] = stock;
          });
        }
      } else if (data is List) {
        // Multiple updates
        setState(() {
          for (var item in data) {
            final productId = int.tryParse(item['productId'].toString());
            final stock = int.tryParse(item['stock'].toString());

            if (productId != null && stock != null) {
              _productStock[productId] = stock;
            }
          }
        });
      }
    });

    socket.onDisconnect((_) {});
  }

  Future<void> fetchSaleDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/getSaleDetails/${widget.saleId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        List<int> productIds =
            items.map((item) => item['productId'] as int).toList();
        // Fetch stock for these products
        Map<int, int> stockMap = await fetchStockForProducts(productIds);
        setState(() {
          dealType = data['dealType'];
          if (dealType == "chooseXofN") {
            chooseCount = data['chooseCount'];
            groupPrice = (data['groupPrice'] ?? 0).toDouble();
          }
          startDate = data['startDate'] = DateTime.parse(data['startDate']);

          endDate = data['endDate'] = DateTime.parse(data['endDate']);
          sale = SaleDisplayItem(
            id: data['saleId'].toString(),
            name: data['name'] ?? '',
            oldPrice: (data['oldPrice'] ?? 0).toDouble(),
            newPrice: (data['newPrice'] ?? 0).toDouble(),
            productIds:
                items.map((item) => item['productId'].toString()).toList(),
            productNames:
                items.map((item) => item['productName'].toString()).toList(),
            productPrices: List<double>.from(
              items.map((item) => (item['productPrice'] ?? 0).toDouble()),
            ),
            quantities:
                items.map((item) => (item['quantity'] ?? 1) as int).toList(),
            active: data['active'],
          );
          _productStock = stockMap; // Add this variable to your State class

          _loading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load sale details.";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  Future<Map<int, int>> fetchStockForProducts(List<int> productIds) async {
    final url = Uri.parse('http://$ipAddress/api/getStock');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'productIds': productIds}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final stockRaw = data['stock'];

      if (stockRaw == null || stockRaw is! Map) {
        return {};
      }

      Map<String, dynamic> stockMapStringKeys = Map<String, dynamic>.from(
        stockRaw,
      );

      final Map<int, int> parsedStock = {};

      stockMapStringKeys.forEach((key, value) {
        final parsedKey = int.tryParse(key);
        final parsedValue =
            value is int ? value : int.tryParse(value.toString());

        if (parsedKey != null && parsedValue != null) {
          parsedStock[parsedKey] = parsedValue;
        } else {}
      });

      return parsedStock;
    } else {
      throw Exception('Failed to load stock data');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _addSelectedProductsToSaleCart({
    required int saleId,
    required String name,
    required double salePricePerBundle,
    required double originalPricePerBundle,
    required String? dealType,
    required List<int> productIds,
    required List<String> productNames,
    required List<double> productPrices,
    required List<int> productQuantities,
    required String dealKey,
    int? chooseCount,
  }) async {
    var userBox = await Hive.openBox('userStatus');
    bool isGuest = userBox.get('isGuest', defaultValue: false);

    if (isGuest) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('עליך להירשם כדי להוסיף מוצרים לעגלה')),
        );
      }
      return; // Exit early — guest users can't add to cart
    }
    var box = await Hive.openBox('salecart');
    int groupCount = 0;
    if (chooseCount != null) {
      double totalSelected = 0;
      for (int i = 0; i < productQuantities.length; i++) {
        totalSelected += productQuantities[i];
      }
      groupCount = totalSelected ~/ chooseCount;
    }

    Map<dynamic, dynamic> saleCartData = box.get(
      'salecart',
      defaultValue: <dynamic, dynamic>{},
    );

    // Build the selected products list
    List<Map<String, dynamic>> selectedProducts = [];
    for (int i = 0; i < productIds.length; i++) {
      if (productQuantities[i] > 0) {
        selectedProducts.add({
          'id': productIds[i],
          'name': productNames[i],
          'price': productPrices[i],
          'quantity': productQuantities[i],
        });
      }
    }

    // Try to find an existing deal with same saleId and same products
    String? matchingKey;
    for (var entry in saleCartData.entries) {
      var existing = entry.value;
      // if (entry.key == 'deal_$saleId') {
      //   bool allMatch = true;
      // }
      if (existing['saleId'] != saleId) continue;

      List<Map<String, dynamic>> existingProducts =
          List<Map<String, dynamic>>.from(existing['products']);

      // Sort both lists to compare easily
      existingProducts.sort((a, b) => a['id'].compareTo(b['id']));
      selectedProducts.sort((a, b) => a['id'].compareTo(b['id']));

      if (existingProducts.length != selectedProducts.length) continue;

      bool allMatch = true;
      for (int i = 0; i < existingProducts.length; i++) {
        var a = existingProducts[i];
        var b = selectedProducts[i];

        if (a['id'] != b['id'] || a['quantity'] != b['quantity']) {
          allMatch = false;
          break;
        }
      }

      if (allMatch) {
        matchingKey = entry.key;
        break;
      }
    }

    if (matchingKey != null) {
      // Matching deal found – increase quantity
      if (chooseCount != null) {
        double totalSelected = 0;
        for (int i = 0; i < productQuantities.length; i++) {
          totalSelected += productQuantities[i];
        }
        groupCount = totalSelected ~/ chooseCount;
        saleCartData[matchingKey]['quantity'] += groupCount;
      } else {
        saleCartData[matchingKey]['quantity'] += 1;
      }
    } else {
      if (chooseCount != null && groupCount > 0) {
        // Make a copy of remaining quantities
        Map<int, int> remaining = {
          for (int i = 0; i < productIds.length; i++)
            productIds[i]: productQuantities[i],
        };

        for (int g = 0; g < groupCount; g++) {
          int filled = 0;
          List<Map<String, dynamic>> bundle = [];

          for (int i = 0; i < productIds.length && filled < chooseCount; i++) {
            final id = productIds[i];
            final int available = remaining[id] ?? 0;

            if (available > 0) {
              int take = (chooseCount - filled).clamp(1, available);

              bundle.add({
                'id': id,
                'name': productNames[i],
                'price': productPrices[i],
                'quantity': take,
              });

              remaining[id] = available - take;
              filled += take;
            }
          }

          if (filled == chooseCount) {
            // Sort bundle by ID for consistent comparison
            bundle.sort((a, b) => a['id'].compareTo(b['id']));

            // Try to find existing identical deal
            String? matchingDealKey;
            for (final entry in saleCartData.entries) {
              final existing = entry.value;
              if (existing['saleId'] != saleId ||
                  existing['dealType'] != dealType) {
                continue;
              }

              final existingProducts = List<Map<String, dynamic>>.from(
                existing['products'],
              );
              existingProducts.sort((a, b) => a['id'].compareTo(b['id']));

              if (existingProducts.length != bundle.length) continue;

              bool matches = true;
              for (int i = 0; i < bundle.length; i++) {
                if (existingProducts[i]['id'] != bundle[i]['id'] ||
                    existingProducts[i]['quantity'] != bundle[i]['quantity']) {
                  matches = false;
                  break;
                }
              }

              if (matches) {
                matchingDealKey = entry.key;
                break;
              }
            }

            if (matchingDealKey != null) {
              // Found matching bundle: increase quantity
              saleCartData[matchingDealKey]['quantity'] += 1;
              saleCartData[matchingDealKey]['savedAmount'] +=
                  originalPricePerBundle - salePricePerBundle;
            } else {
              // No match – create new deal
              final uniqueKey = 'deal_${saleId}_${const Uuid().v4()}';
              saleCartData[uniqueKey] = {
                'saleId': saleId,
                'name': name,
                'dealType': dealType,
                'products': bundle,
                'salePricePerBundle': salePricePerBundle,
                'originalPricePerBundle': originalPricePerBundle,
                'quantity': 1,
                'savedAmount': originalPricePerBundle - salePricePerBundle,
                'chooseCount': chooseCount,
              };
            }
          }
        }
      } else {
        // Non-chooseXofN logic
        saleCartData[dealKey] = {
          'saleId': saleId,
          'name': name,
          'dealType': dealType,
          'products': selectedProducts,
          'salePricePerBundle': salePricePerBundle,
          'originalPricePerBundle': originalPricePerBundle,
          'quantity': 1,
          'savedAmount': originalPricePerBundle - salePricePerBundle,
        };
      }
    }

    // Save the updated sale cart
    await box.put('salecart', saleCartData);

    // Recalculate total cart item count (cart + salecart)
    final regularCartBox = await Hive.openBox('cart');
    final regularCart = regularCartBox.get(
      'cart',
      defaultValue: <dynamic, dynamic>{},
    );
    var seedsBox = await Hive.openBox('seedscart');

    Map<dynamic, dynamic> seedsCartData = seedsBox.get(
      'seedscart',
      defaultValue: <int, Map<String, dynamic>>{},
    );
    int totalSeedsAsUnits = seedsCartData.length;

    final totalRegularItems = regularCart.values.fold<int>(0, (
      int sum,
      dynamic item,
    ) {
      return sum + (item['quantity'] as int? ?? 0);
    });

    final totalSaleItems = saleCartData.values.fold<int>(0, (sum, item) {
      final saleQuantity = item['quantity'] as int;
      final products = item['products'] as List<dynamic>;

      final totalProductUnits = products.fold<int>(0, (productSum, product) {
        return productSum + (product['quantity'] as int);
      });

      return sum + (totalProductUnits * saleQuantity);
    });

    cartItemCountNotifier.value =
        totalRegularItems + totalSaleItems + totalSeedsAsUnits;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("המבצע נוסף לסל בהצלחה!"),
          backgroundColor: Colors.green,
        ),
      );

      final tabsScreenState =
          context.findAncestorStateOfType<TabsScreenState>();
      tabsScreenState?.triggerCartSpin();
    }
  }

  Widget _buildDiscountBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.redAccent.shade700,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool anyOutOfStock = _productStock.values.any((stock) => stock == 0);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("פרטי מבצע")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("פרטי מבצע")),
        body: Center(
          child: Text(
            _error!,
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final s = sale!;
    final discountPercent = ((1 - s.newPrice / s.oldPrice) * 100).round();

    return Scaffold(
      appBar: CustomAppBar(title: s.name),
      body: Stack(
        children: [
          Container(
            color: const Color.fromARGB(
              255,
              222,
              210,
              206,
            ), // Set the background color
          ),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image carousel (unchanged)
                    if (s.productIds != null && s.productIds!.isNotEmpty)
                      SizedBox(
                        height: 280,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: s.productIds!.length,
                              itemBuilder: (context, index) {
                                final productId = s.productIds![index];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          const Color.fromARGB(
                                            255,
                                            121,
                                            85,
                                            72,
                                          ).withValues(alpha: 0.25),
                                          BlendMode.darken,
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              'https://d1qq705dywrog2.cloudfront.net/images/$productId.jpeg',
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  Container(
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.red,
                                                        size: 48,
                                                      ),
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: _buildDiscountBadge("-$discountPercent%"),
                            ),
                          ],
                        ),
                      ),

                    if (s.productIds != null && s.productIds!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: s.productIds!.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor:
                                Theme.of(context).colorScheme.primary,
                            dotColor: Colors.grey.shade400,
                            dotHeight: 10,
                            dotWidth: 10,
                            expansionFactor: 3,
                            spacing: 8,
                          ),
                        ),
                      ),
                    ],

                    if (startDate != null && endDate != null) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          "המבצע בתוקף מ־${_formatDate(startDate!)} עד ${_formatDate(endDate!)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    if (sale?.active == false) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          "המבצע אינו פעיל כרגע",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),

                    Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₪${s.oldPrice.toStringAsFixed(2)}",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 22,
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "₪${s.newPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        _buildDiscountBadge("-$discountPercent%"),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // --- Card with only products ---
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Colors.grey, // Bezel (border) color
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'מוצרים כלולים:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (dealType == "chooseXofN") ...[
                              Text(
                                "בחר $chooseCount מתוך ${s.productIds?.length ?? 0}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.brown,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: s.productIds?.length ?? 0,
                              itemBuilder: (context, index) {
                                final productId = s.productIds![index];
                                final name = s.productNames[index];
                                final price = s.productPrices?[index] ?? 0;
                                final quantity = s.quantities?[index] ?? 1;
                                final stock =
                                    _productStock[int.parse(productId)];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ProductDetailsScreen(
                                              productId: int.parse(productId),
                                            ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    color: const Color.fromARGB(
                                      255,
                                      222,
                                      210,
                                      206,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          // Product image
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: ColorFiltered(
                                              colorFilter: ColorFilter.mode(
                                                const Color.fromARGB(
                                                  255,
                                                  121,
                                                  85,
                                                  72,
                                                ).withValues(alpha: 0.25),
                                                BlendMode.darken,
                                              ),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    'https://d1qq705dywrog2.cloudfront.net/images/$productId.jpeg',
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (context, url) => Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                          width: 60,
                                                          height: 60,
                                                          color:
                                                              Colors.grey[300],
                                                          child: const Icon(
                                                            Icons.error,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Info and quantity
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text('כמות:'),
                                                    const SizedBox(width: 8),
                                                    dealType == "chooseXofN"
                                                        ? SizedBox(
                                                          width: 50,
                                                          height: 32,
                                                          child: TextFormField(
                                                            initialValue:
                                                                (selectedProductCounts[productId] ??
                                                                        0)
                                                                    .toString(),
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            decoration: InputDecoration(
                                                              contentPadding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 4,
                                                                    horizontal:
                                                                        8,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                              ),
                                                            ),
                                                            onChanged: (v) {
                                                              final val =
                                                                  int.tryParse(
                                                                    v,
                                                                  ) ??
                                                                  0;
                                                              setState(() {
                                                                selectedProductCounts[productId] =
                                                                    val;
                                                              });
                                                            },
                                                          ),
                                                        )
                                                        : Text(
                                                          quantity.toString(),
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Price
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₪${price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.brown,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                "מחיר רגיל",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              if (stock == 0)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'אזל מהמלאי',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed:
                                    sale?.active == false || anyOutOfStock
                                        ? null // כפתור לא פעיל
                                        : () {
                                          if (dealType == "chooseXofN") {
                                            final totalSelected =
                                                selectedProductCounts.values
                                                    .fold<int>(
                                                      0,
                                                      (
                                                        previousValue,
                                                        element,
                                                      ) =>
                                                          previousValue +
                                                          (element),
                                                    );

                                            if (totalSelected == 0) {
                                              // Show "must choose at least one product" dialog
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => Directionality(
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      child: AlertDialog(
                                                        title: const Text(
                                                          "שגיאה",
                                                        ),
                                                        content: const Text(
                                                          "יש לבחור לפחות מוצר אחד",
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(),
                                                            child: const Text(
                                                              "אישור",
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                              );
                                              return;
                                            } else if (totalSelected %
                                                    chooseCount! !=
                                                0) {
                                              // Show "must choose in multiples of X" dialog
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => Directionality(
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      child: AlertDialog(
                                                        title: const Text(
                                                          "שגיאה",
                                                        ),
                                                        content: Text(
                                                          "יש לבחור מספר מוצרים שהוא כפולה של $chooseCount",
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(),
                                                            child: const Text(
                                                              "אישור",
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                              );
                                              return;
                                            }

                                            // Create lists for selected products only
                                            final selectedProductIds = <int>[];
                                            final selectedProductNames =
                                                <String>[];
                                            final selectedProductPrices =
                                                <double>[];
                                            final selectedProductQuantities =
                                                <int>[];

                                            for (
                                              int i = 0;
                                              i < s.productIds!.length;
                                              i++
                                            ) {
                                              final productIdStr =
                                                  s.productIds![i];
                                              final productId = int.parse(
                                                productIdStr,
                                              );
                                              final selectedCount =
                                                  selectedProductCounts[productIdStr] ??
                                                  0;

                                              if (selectedCount > 0) {
                                                selectedProductIds.add(
                                                  productId,
                                                );
                                                selectedProductNames.add(
                                                  s.productNames[i],
                                                );
                                                selectedProductPrices.add(
                                                  s.productPrices![i],
                                                );
                                                selectedProductQuantities.add(
                                                  selectedCount,
                                                );
                                              }
                                            }
                                            String uniqueId = const Uuid().v4();
                                            String dealKey =
                                                'deal_${widget.saleId}_$uniqueId';

                                            // Now call with filtered lists
                                            _addSelectedProductsToSaleCart(
                                              saleId: widget.saleId,
                                              name: s.name,
                                              salePricePerBundle: s.newPrice,
                                              originalPricePerBundle:
                                                  s.oldPrice,
                                              dealType: dealType,
                                              productIds: selectedProductIds,
                                              productNames:
                                                  selectedProductNames,
                                              productPrices:
                                                  selectedProductPrices,
                                              productQuantities:
                                                  selectedProductQuantities,
                                              dealKey: dealKey,
                                              chooseCount: chooseCount,
                                            );
                                          } else {
                                            _addSelectedProductsToSaleCart(
                                              saleId: widget.saleId,
                                              name: s.name,
                                              salePricePerBundle: s.newPrice,
                                              originalPricePerBundle:
                                                  s.oldPrice,
                                              dealType: dealType,
                                              productIds:
                                                  s.productIds!
                                                      .map((i) => int.parse(i))
                                                      .toList(),
                                              productNames: s.productNames,
                                              productPrices: s.productPrices!,
                                              productQuantities: s.quantities!,
                                              dealKey: 'deal_${widget.saleId}',
                                              chooseCount: null,
                                            );
                                          }
                                        },
                                icon: const Icon(
                                  Icons.shopping_cart_checkout,
                                  size: 22,
                                ),
                                label: Text(
                                  sale?.active == false || anyOutOfStock
                                      ? "המבצע אינו פעיל כרגע"
                                      : "הוסף לסל",
                                  style: const TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 36,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 4,
                                  backgroundColor:
                                      sale?.active == false
                                          ? Colors.grey
                                          : null,
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
            ),
          ),
        ],
      ),
    );
  }
}
