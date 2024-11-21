import 'package:flutter/material.dart';
import 'package:zofa_client/models/category.dart';
import 'package:zofa_client/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/screens/product_details.dart';

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

  Future<void> _fetchCategories() async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress:3000/api/getAllCategories'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;

        setState(() {
          _categories = jsonData.map((item) {
            return Category(id: item['id'], name: item['name']);
          }).toList();

          // Initialize category selections
          for (var category in _categories) {
            _categorySelections[category.id] = false;
          }
        });

        _fetchProducts();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            textAlign: TextAlign.right, // Centering the text
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
          reverse: true, // Reverses the scroll direction
          controller: _scrollController, // Use the ScrollController
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            textDirection: TextDirection.rtl,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: FilterChip(
                  label: const Text('הכל'),
                  selected: _selectAll,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectAll = true; // Keep "All" always selected
                      // Deselect all other categories
                      _categorySelections.forEach((key, value) {
                        _categorySelections[key] = false;
                      });
                    });
                    _fetchProducts();
                    // Reset scroll position when "All" is selected
                    if (_selectAll) {
                      _scrollController
                          .jumpTo(0); // Jump to the start (right side)
                    }
                  },
                ),
              ),
              ..._categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: FilterChip(
                    label: Text(category.name),
                    selected: _categorySelections[category.id] ?? false,
                    onSelected: (bool selected) {
                      setState(() {
                        _categorySelections[category.id] = selected;

                        // If any category is selected, deselect "All"
                        if (selected) {
                          _selectAll = false;
                        }

                        // If all categories are deselected, automatically select "All"
                        if (!_categorySelections.containsValue(true)) {
                          _selectAll =
                              true; // Automatically select "All" when all categories are deselected
                        }
                      });
                      _fetchProducts();
                      // If "All" is selected again, reset scroll position
                      if (_selectAll) {
                        _scrollController
                            .jumpTo(0); // Jump to the start (right side)
                      }
                    },
                  ),
                );
              })
            ],
          ),
        ),

        // GridView to display products with padding and centered button
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.all(8.0), // Add padding around the GridView
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two columns in the grid
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.54, // Aspect ratio for each product card
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (ctx, index) {
                final product = _filteredProducts[index];
                final imageUrl =
                    'https://f003.backblazeb2.com/file/zofapic/${product.id}.jpeg';

// Inside the GridView.builder's itemBuilder:

                return GestureDetector(
                  onTap: () {
                    // Allow navigation to the product details screen even if the product is out of stock
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(productId: product.id),
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

                          // Product Image
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
                                        ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
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
                                        Object error, StackTrace? stackTrace) {
                                      return const Icon(Icons.broken_image,
                                          size: 50, color: Colors.grey);
                                    },
                                  )
                                : const Icon(Icons.broken_image,
                                    size: 50, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),

                          // Product Name
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

                          // Product Price
                          Center(
                            child: Text(
                              '\₪${product.price.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),

                          // Out of Stock Indicator
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
                                onPressed:
                                    null, // Disable button when out of stock
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
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
                            // Quantity Controls and Add to Cart Button (only enabled when in stock)
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

                            // Add to Cart Button (only enabled when in stock)
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Implement add to cart logic here
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
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
        )
      ],
    );
  }
}
