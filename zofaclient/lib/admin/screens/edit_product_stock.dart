import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/models/product.dart';
import 'package:zofa_client/constant.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(() {
      _filterProducts();
    });
  }

  // Fetch products from the API
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress:3000/api/getAllProducts'),
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
        Uri.parse('http://$ipAddress:3000/api/updateStock/$productId'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ערוך מלאי מוצרים'),
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
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: '...חיפוש מוצר',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),

                      // GridView to display products
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.54,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (ctx, index) {
                              final product = _filteredProducts[index];
                              final imageUrl =
                                  'https://f003.backblazeb2.com/file/zofapic/${product.id}.jpeg';

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 10),

                                      // Product Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          height: 150,
                                          width: double.infinity,
                                          loadingBuilder: (BuildContext context,
                                              Widget child,
                                              ImageChunkEvent?
                                                  loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        (loadingProgress
                                                                .expectedTotalBytes ??
                                                            1)
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder: (BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace) {
                                            return const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Product Name
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          product.name,
                                          overflow: TextOverflow.clip,
                                        ),
                                      ),
                                      const SizedBox(height: 5),

                                      // Product Price
                                      Center(
                                        child: Text(
                                          '₪${product.price.toStringAsFixed(1)}',
                                        ),
                                      ),
                                      const SizedBox(height: 5),

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
                                      )
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
