import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:zofa/constant.dart';
import 'package:zofa/customer/sales/sale_details_screen.dart';
import 'package:zofa/models/group.dart';
import 'package:zofa/models/group_sale.dart';
import 'package:zofa/models/product.dart';
import 'package:zofa/models/regular_sale.dart';
import 'package:zofa/models/sale_bundle.dart';
import 'package:zofa/models/sale_display_item.dart';
import 'package:zofa/models/sale_item.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  List<BundleSale> bundles = [];
  List<RegularSale> regularSales = [];
  List<GroupSale> groupSales = [];
  bool isLoading = true;
  final String baseUrl = "http://$ipAddress"; // Update this
  int flag = 0;
  @override
  void initState() {
    super.initState();
    fetchSales();
  }

  Future<void> fetchSales() async {
    setState(() {
      isLoading = true;
      bundles.clear();
      regularSales.clear();
      groupSales.clear();
    });

    try {
      final bundleResponse = await http.get(
        Uri.parse("$baseUrl/api/getBundleProducts"),
      );
      final regularResponse = await http.get(
        Uri.parse("$baseUrl/api/getRegularSales"),
      );
      final groupResponse = await http.get(
        Uri.parse("$baseUrl/api/getGroupSales"),
      );

      if (bundleResponse.statusCode == 200) {
        final List bundleJson = jsonDecode(
          utf8.decode(bundleResponse.bodyBytes),
        );
        bundles = bundleJson.map((e) => buildBundleSale(e)).toList();
      }

      if (regularResponse.statusCode == 200) {
        final List regularJson = jsonDecode(
          utf8.decode(regularResponse.bodyBytes),
        );
        regularSales = regularJson.map((e) => buildRegularSale(e)).toList();
      }

      if (groupResponse.statusCode == 200) {
        final List groupJson = jsonDecode(utf8.decode(groupResponse.bodyBytes));
        groupSales = groupJson.map((e) => buildGroupSale(e)).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching sales: $e')));
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Product buildProduct(Map json) => Product(
    id: json['id'],
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    stock: json['stock'],
  );

  SaleItem buildSaleItem(Map json) => SaleItem(
    saleItemId: json['saleItemId'],
    quantity: json['quantity'],
    product: buildProduct(json['product']),
  );

  BundleSale buildBundleSale(Map json) => BundleSale(
    saleId: json['saleId'],
    saleName: json['saleName'],
    totalPrice: (json['totalPrice'] as num).toDouble(),
    oldPrice: (json['oldPrice'] as num).toDouble(),
    items: (json['items'] as List).map((e) => buildSaleItem(e)).toList(),
    active: json['active'],
  );

  RegularSale buildRegularSale(Map json) => RegularSale(
    saleId: json['saleId'],
    saleName: json['saleName'],
    totalPrice: (json['totalPrice'] as num).toDouble(),
    oldPrice: (json['oldPrice'] as num).toDouble(),
    items: (json['items'] as List).map((e) => buildSaleItem(e)).toList(),
    active: json['active'],
  );

  Group buildGroup(Map json) => Group(
    groupId: json['groupId'],
    groupPrice: (json['groupPrice'] as num).toDouble(),
    oldPrice: (json['oldPrice'] as num).toDouble(),
    requiredQuantity: json['requiredQuantity'],
    items: (json['items'] as List).map((e) => buildSaleItem(e)).toList(),
  );

  GroupSale buildGroupSale(Map json) => GroupSale(
    saleId: json['saleId'],
    saleName: json['saleName'],
    groups: (json['groups'] as List).map((e) => buildGroup(e)).toList(),
    active: json['active'],
  );

  List<SaleDisplayItem> get unifiedSales {
    final List<SaleDisplayItem> all = [];

    for (final b in bundles) {
      all.add(
        SaleDisplayItem(
          id: b.saleId.toString(),
          name: b.saleName,
          oldPrice: b.oldPrice,
          newPrice: b.totalPrice,
          productNames: b.items.map((e) => e.product.name).toList(),
          productIds: b.items.map((e) => e.product.id.toString()).toList(),
          active: b.active,
        ),
      );
    }

    for (final r in regularSales) {
      all.add(
        SaleDisplayItem(
          id: r.saleId.toString(),
          name: r.saleName,
          oldPrice: r.oldPrice,
          newPrice: r.totalPrice,
          productNames: r.items.map((e) => e.product.name).toList(),
          productIds: r.items.map((e) => e.product.id.toString()).toList(),
          active: r.active,
        ),
      );
    }

    for (final g in groupSales) {
      for (final group in g.groups) {
        all.add(
          SaleDisplayItem(
            id: g.saleId.toString(),
            name: "${g.saleName} - Group ${group.groupId}",
            oldPrice: group.oldPrice,
            newPrice: group.groupPrice,
            productNames: group.items.map((e) => e.product.name).toList(),
            productIds:
                group.items.map((e) => e.product.id.toString()).toList(),
            active: g.active,
          ),
        );
      }
    }

    return all;
  }

  bool _isFoldable() {
    double width = ScreenUtil().screenWidth;
    double height = ScreenUtil().screenHeight;
    double aspectRatio = width / height;
    return aspectRatio >= 0.75;
  }

  int _getCrossAxisCount() {
    double width = ScreenUtil().screenWidth;

    if (width > 1000) {
      return 5;
    } else if (_isFoldable()) {
      if (width > 650) {
        flag = 1;
        return 4;
      } else {
        flag = 0;
        return 3;
      }
    }
    return (ScreenUtil().screenWidth ~/ 200).clamp(2, 4);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sales = unifiedSales;
    if (sales.isEmpty) {
      return const Center(child: Text('אין מבצעים זמינים כרגע'));
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/background.jpg', fit: BoxFit.cover),
          ),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: LayoutGrid(
                  columnSizes: List.generate(_getCrossAxisCount(), (_) => 1.fr),
                  rowSizes: List.generate(
                    (sales.length / _getCrossAxisCount()).ceil(),
                    (_) => auto,
                  ),
                  rowGap: 10.h,
                  columnGap: 10.w,
                  children: sales.map(buildSaleCard).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSaleCard(SaleDisplayItem sale) {
    final pageController = PageController();
    final discount = ((1 - sale.newPrice / sale.oldPrice) * 100).round();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SaleDetailsScreen(saleId: int.parse(sale.id)),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Opacity(
          opacity: sale.active ? 1.0 : 0.6, // Dim inactive cards
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 120,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: pageController,
                            itemCount: sale.productNames.length,
                            itemBuilder: (context, index) {
                              final productId = sale.productIds?[index] ?? '';
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    const Color.fromARGB(
                                      255,
                                      148,
                                      105,
                                      90,
                                    ).withAlpha(75),
                                    BlendMode.darken,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        'https://d1qq705dywrog2.cloudfront.net/images/$productId.jpeg',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder:
                                        (context, url) =>
                                            Container(color: Colors.grey[300]),
                                    errorWidget:
                                        (context, url, error) =>
                                            const Icon(Icons.error),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Discount badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$discount% הנחה',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          // Page indicator
                          Positioned(
                            bottom: 4,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: pageController,
                                count: sale.productNames.length,
                                effect: WormEffect(
                                  dotColor: Colors.white54,
                                  activeDotColor: Colors.white,
                                  dotHeight: 8,
                                  dotWidth: 8,
                                ),
                              ),
                            ),
                          ),
                          // "Inactive" banner
                          if (!sale.active)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'המבצע לא פעיל',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sale.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "₪${sale.oldPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₪${sale.newPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
