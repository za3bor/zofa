import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/admin/sales/selected_products_screen.dart';
import 'package:zofa/models/product.dart';
import 'package:zofa/models/sale_item.dart';
import 'package:zofa/constant.dart';

class ProductSelectionPage extends StatefulWidget {
  const ProductSelectionPage({super.key});

  @override
  State<ProductSelectionPage> createState() => _ProductSelectionPageState();
}

class _ProductSelectionPageState extends State<ProductSelectionPage> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<SaleItem> selectedItems = [];
  int flag = 0;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
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

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/getAllProducts'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          _products =
              jsonData.map((item) {
                return Product(
                  id: item['id'],
                  name: item['name'],
                  price: double.parse(item['price'].toString()),
                  stock: item['in_stock'] == 1,
                );
              }).toList();

          _filteredProducts = List.from(_products);
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'אין מוצרים זמינים.';
          _products = [];
          _filteredProducts = [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch products.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'שגיאה בטעינת המוצרים.';
        _isLoading = false;
      });
    }
  }

  void selectProduct(Product product) {
    final idx = selectedItems.indexWhere((e) => e.product.id == product.id);
    setState(() {
      if (idx == -1) {
        selectedItems.add(
          SaleItem(saleItemId: 0, product: product, quantity: 1),
        );
      } else {
        selectedItems[idx].quantity++;
      }
    });
  }

  void goToSelectedProductsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SelectedProductsScreen(
              items: selectedItems,
              onUpdate: (updatedList, bundlePrice, startDate, endDate, name) {
                setState(() {
                  selectedItems = updatedList;
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'בחר מוצרים למבצע'),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Directionality(
                textDirection: TextDirection.rtl,
                child: Center(child: Text(_errorMessage!)),
              )
              : Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    child: LayoutGrid(
                      columnSizes: List.generate(
                        _getCrossAxisCount(),
                        (_) => 1.fr,
                      ),
                      rowSizes: List.generate(
                        (_filteredProducts.length / _getCrossAxisCount())
                            .ceil(),
                        (_) => auto,
                      ),
                      rowGap: 12,
                      columnGap: 12,
                      children: List.generate(_filteredProducts.length, (
                        index,
                      ) {
                        final product = _filteredProducts[index];
                        final imageUrl =
                            'https://d1qq705dywrog2.cloudfront.net/images/${product.id}.jpeg';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      const Color.fromARGB(
                                        255,
                                        148,
                                        105,
                                        90,
                                      ).withAlpha(76),
                                      BlendMode.darken,
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      height: 150,
                                      width: double.infinity,
                                      placeholder:
                                          (context, url) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Image.asset(
                                            'assets/noimage.jpg',
                                            fit: BoxFit.cover,
                                            height: 150,
                                            width: double.infinity,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${product.price} ₪',
                                  style: TextStyle(color: Colors.brown[700]),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () => selectProduct(product),
                                    child: const Text('בחר'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
      bottomNavigationBar:
          selectedItems.isNotEmpty
              ? Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  color: Colors.brown[50],
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('נבחרו ${selectedItems.length} מוצרים'),
                      ElevatedButton(
                        onPressed: goToSelectedProductsScreen,
                        child: const Text('למסך המבצע'),
                      ),
                    ],
                  ),
                ),
              )
              : const SizedBox.shrink(),
    );
  }
}
