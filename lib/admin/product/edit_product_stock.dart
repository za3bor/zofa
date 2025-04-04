import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/models/product.dart';
import 'package:zofa/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditProductStockScreen extends StatefulWidget {
  const EditProductStockScreen({super.key});

  @override
  State<EditProductStockScreen> createState() {
    return _EditProductStockScreenState();
  }
}

class _EditProductStockScreenState extends State<EditProductStockScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true; // Loading indicator
  String? _errorMessage; // Error message
  int flag = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(() {
      _filterProducts();
    });
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      final response = await http
          .delete(Uri.parse('http://$ipAddress/api/deleteProduct/$productId'));

      if (response.statusCode == 200) {
        setState(() {
          _products.removeWhere((p) => p.id == productId);
          _filteredProducts.removeWhere((p) => p.id == productId);
        });
        _showSnackbar('המוצר נמחק בהצלחה.');
      } else {
        throw Exception('Failed to delete product.');
      }
    } catch (e) {
      _showSnackbar('שגיאה במחיקת המוצר.');
    }
  }

  // Fetch products from the API
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
          _products = jsonData.map((item) {
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

  // Update product stock in the database
  Future<void> _updateProductStock(int productId, bool stock) async {
    try {
      final response = await http.patch(
        Uri.parse('http://$ipAddress/api/updateStock/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'stock': stock ? 1 : 0}),
      );

      if (response.statusCode == 200) {
        _showSnackbar('מלאי עודכן בהצלחה.');
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      _showSnackbar('שגיאה בעדכון המלאי.');
      setState(() {
        final product = _products.firstWhere((p) => p.id == productId);
        product.stock = !stock;
      });
    }
  }

  // Show snackbar
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Filter products by search query
  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  double _getChildAspectRatio() {
    double width = ScreenUtil().screenWidth;
    double height = ScreenUtil().screenHeight;
    double aspectRatio = width / height;

    if (width > 1000) {
      return 0.48;
    }
    // Fold phones
    else if (_isFoldable()) {
      if (flag == 1) {
        return 0.41;
      } else {
        return 0.39;
      }
    } else if (aspectRatio > 0.6) {
      // Regular phones or tablets
      return 0.48; // Large screens (tablets, large phones)
    } else if (aspectRatio > 0.55) {
      return 0.41; // Medium screens (like Pixel Fold in portrait mode)
    } else {
      return 0.49; // Small screens (smaller phones)
    }
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
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'ערוך מלאי מוצרים',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 18, color: Colors.red),
                  ),
                )
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: EdgeInsets.all(8.0.w),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: '...חיפוש מוצר',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                          ),
                        ),
                      ),

                      // GridView to display products
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(8.0.w),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getCrossAxisCount(),
                              crossAxisSpacing: 10.w,
                              mainAxisSpacing: 10.h,
                              childAspectRatio:_getChildAspectRatio(),
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (ctx, index) {
                              final product = _filteredProducts[index];
                              final imageUrl =
                                  'https://d1qq705dywrog2.cloudfront.net/images/${product.id}.jpeg';

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.r),
                                ),
                                elevation: 5,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10.h),

                                      // Product Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            const Color.fromARGB(
                                                    255, 148, 105, 90)
                                                .withValues(alpha: 0.3),
                                            BlendMode.darken,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.cover,
                                            height: 150,
                                            width: double.infinity,
                                            placeholder: (context, url) =>
                                                const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                            errorWidget: (context, url, error) {
                                              return Image.asset(
                                                'assets/noimage.jpg',
                                                fit: BoxFit.cover,
                                                height: 150.w,
                                                width: double.infinity,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10.h),

                                      // Product Name
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      SizedBox(height: 5.h),

                                      // Product Price
                                      Center(
                                        child: Text(
                                          '₪${product.price.toStringAsFixed(1)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      SizedBox(height: 5.h),

                                      // Stock status button
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final newStockStatus =
                                                !product.stock;
                                            setState(() {
                                              product.stock = newStockStatus;
                                            });

                                            await _updateProductStock(
                                                product.id, newStockStatus);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: product.stock
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          child: Text(
                                            product.stock
                                                ? 'במלאי'
                                                : 'לא במלאי',
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10.h),

                                      // Delete button
                                      Center(
                                        child: IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () async {
                                            bool confirmDelete =
                                                await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('מחיקת מוצר'),
                                                content: const Text(
                                                    'האם אתה בטוח שברצונך למחוק מוצר זה?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(false),
                                                    child: const Text('ביטול'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true),
                                                    child: const Text('מחיקה'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmDelete) {
                                              await _deleteProduct(product.id);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
