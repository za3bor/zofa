import 'package:flutter/material.dart';
import 'package:zofa_client/models/category.dart';
import 'package:zofa_client/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/screens/product_details.dart';
import 'package:hive/hive.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() {
    return _ProductsScreenState();
  }
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final Map<int, bool> _categorySelections = {};
  bool _selectAll = true; // "All" is selected by default
  bool _categoriesError =
      false; // To track if there's a problem with categories
  final TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController =
      ScrollController(); // ScrollController for SingleChildScrollView
  final Map<int, int> _productQuantities =
      {}; // Map to store product quantities

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(() {
      _filterProducts();
    });
  }

  @override
  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress:3000/api/getAllCategories'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          _categoriesError = false; // Reset error state
          _categories = jsonData.map((item) {
            return Category(id: item['id'], name: item['name']);
          }).toList();

          // Initialize category selections
          for (var category in _categories) {
            _categorySelections[category.id] = false;
          }
        });

        _fetchProducts(); // Fetch products once categories are loaded
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      setState(() {
        _categoriesError = true; // Set error state
      });
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchProducts() async {
    List<int> selectedCategoryIds = _selectAll
        ? []
        : _categorySelections.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress:3000/api/getProductsByCategory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'categoryIds': selectedCategoryIds}),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        setState(() {
          _products = jsonData.map((item) {
            return Product(
              id: item['id'],
              name: item['name'],
              price: (item['price'] is String)
                  ? double.parse(item['price'])
                  : item['price'],
              stock: item['in_stock'] == 1, // Convert TINYINT to bool
            );
          }).toList();
          _filteredProducts = List.from(_products);
          // Initialize product quantities to 0
          for (var product in _products) {
            _productQuantities[product.id] = 0;
          }
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _incrementQuantity(int productId) {
    setState(() {
      _productQuantities[productId] = (_productQuantities[productId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(int productId) {
    setState(() {
      if ((_productQuantities[productId] ?? 0) > 0) {
        _productQuantities[productId] =
            (_productQuantities[productId] ?? 0) - 1;
      }
    });
  }

  Future<void> _addToCart(int productId) async {
    var box = await Hive.openBox('cart');
    int quantity = _productQuantities[productId] ?? 0;

    if (quantity > 0) {
      // Get the existing cart data (it should be a Map<int, int>)
      Map<dynamic, dynamic> cartData =
          box.get('cart', defaultValue: <int, int>{});

      // Ensure productId is treated as an int and quantity is also an int
      if (cartData.containsKey(productId)) {
        int existingQuantity = cartData[productId] ?? 0;
        cartData[productId] = existingQuantity + quantity; // Update quantity
      } else {
        cartData[productId] = quantity; // Add new product
      }

      // Save the updated cart data directly to the box
      await box.put('cart', cartData);

      // Show a snackbar with the product name
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_filteredProducts.firstWhere((p) => p.id == productId).name} added to cart!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_categoriesError) {
      // Display error message if categories failed to load
      return const Center(
        child: Text(
          'שגיאה בטעינת הקטגוריות, נסה שוב מאוחר יותר',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '...חיפוש מוצר',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),

        // Dynamic Filter Chips for categories with 'All' option
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          controller: _scrollController,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            textDirection: TextDirection.rtl,
            children: [
              // 'All' Filter Chip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: FilterChip(
                  label: const Text('הכל'),
                  selected: _selectAll,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectAll = true;
                      _categorySelections.forEach((key, value) {
                        _categorySelections[key] = false;
                      });
                    });
                    _fetchProducts();
                    if (_selectAll) {
                      _scrollController.jumpTo(0);
                    }
                  },
                ),
              ),
              // Other category Filter Chips
              ..._categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: FilterChip(
                    label: Text(category.name),
                    selected: _categorySelections[category.id] ?? false,
                    onSelected: (bool selected) {
                      setState(() {
                        _categorySelections[category.id] = selected;

                        if (selected) {
                          _selectAll = false;
                        }

                        if (!_categorySelections.containsValue(true)) {
                          _selectAll = true;
                        }
                      });
                      _fetchProducts();
                      if (_selectAll) {
                        _scrollController.jumpTo(0);
                      }
                    },
                  ),
                );
              })
            ],
          ),
        ),

        // Products display or error message
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isNotEmpty
                        ? 'אין מוצרים להצגה' // No products match the search
                        : _products.isEmpty
                            ? 'אין מוצרים להצגה' // No products available
                            : 'שגיאה בטעינת המוצרים, נסה שוב מאוחר יותר', // Error loading products
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                )
              : Padding(
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

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(
                                productId: product.id,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
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
                                                color: Colors.grey);
                                          },
                                        )
                                      : const Icon(Icons.broken_image,
                                          size: 50, color: Colors.grey),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Center(
                                  child: Text(
                                    '₪ ${product.price.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                if (!product.stock) ...[
                                  const SizedBox(height: 5),
                                  const Center(
                                    child: Text(
                                      'המוצר אזל מהמלאי',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Text(
                                        'Sold Out',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          _decrementQuantity(product.id);
                                        },
                                      ),
                                      Text(
                                        '${_productQuantities[product.id] ?? 0}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          _incrementQuantity(product.id);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () => _addToCart(product.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Text(
                                        'Add to Cart',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
