import 'package:flutter/material.dart';
import 'package:zofa_client/models/category.dart';
import 'package:zofa_client/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/screens/product_details.dart';
import 'package:hive/hive.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:zofa_client/global.dart'; // Adjust the path accordingly
import 'package:zofa_client/screens/tabs.dart'; // Import TabsScreen

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
  late Future<void> combinedFuture; // Combines both future calls
  bool _isLoading = false; // Shared loading state

  late IO.Socket _socket; // Declare the socket instance

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _fetchCategories();
    _searchController.addListener(() {
      _filterProducts();
    });
  }

  void _initializeSocket() {
    // Initialize the socket connection
    _socket = IO.io(
      'http://$ipAddress:3000', // Replace with your backend URL
      IO.OptionBuilder()
          .setTransports(['websocket']) // Use WebSocket for the connection
          .build(),
    );

    // Listen for connection
    _socket.onConnect((_) {
      print('Connected to socket server');
    });

    _socket.on('orderUpdate', (data) {
      int productId = int.tryParse(data['productId'].toString()) ?? 0;
      int newStock = data['stock'];

      setState(() {
        final product = _products.firstWhere((p) => p.id == productId,
            orElse: () => Product(id: -1, name: '', price: 0, stock: false));
        if (product.id != -1) {
          product.stock = newStock > 0;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock updated for product ID $productId!',
          ),
        ),
      );
    });

    // Handle socket disconnection
    _socket.onDisconnect((_) {
      print('Disconnected from socket server');
    });
  }

  @override
  void dispose() {
    _socket
        .dispose(); // Dispose of the socket connection when the screen is disposed
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true; // Start loading
    });
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
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true; // Set loading state to true while fetching
    });
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
              stock: item['in_stock'] > 0, // Update stock handling
            );
          }).toList();
          _filteredProducts = List.from(_products);
          // Initialize product quantities to 0
          for (var product in _products) {
            _productQuantities[product.id] = 0;
          }
          _isLoading = false; // Set loading state to false once data is loaded
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Set loading state to false on error
        _categoriesError = true; // Set error state
      });
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

  void _addToCart(int productId) async {
    var box = await Hive.openBox('cart');
    int quantity = _productQuantities[productId] ?? 0;

    if (quantity > 0) {
      // Get the existing cart data (it should be a Map<int, Map<String, dynamic>>)
      Map<dynamic, dynamic> cartData =
          box.get('cart', defaultValue: <int, Map<String, dynamic>>{});

      // Find the product using its ID
      Product product = _filteredProducts.firstWhere((p) => p.id == productId);

      // Ensure productId is treated as an int and quantity is also an int
      if (cartData.containsKey(productId)) {
        // Update the existing entry for the product
        cartData[productId]['quantity'] += quantity;
      } else {
        // Add new product with name, price, and quantity
        cartData[productId] = {
          'name': product.name,
          'price': product.price,
          'quantity': quantity,
        };
      }

      // Save the updated cart data directly to the box
      await box.put('cart', cartData);

      // Update the global cart count

      // cartItemCountNotifier.value = cartData.values.fold<int>(
      //0,
      // (sum, item) => sum + ((item['quantity'] ?? 0) as int),
      // );
      int newCount = cartData.values.fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int), // Explicit cast to int
      );
      cartItemCountNotifier.value = newCount; // Update the global cart count
      setState(() {
        _productQuantities[productId] = 0;
      });
      // Trigger the cart spin animation in TabsScreen
      final tabsScreenState =
          context.findAncestorStateOfType<TabsScreenState>();
      tabsScreenState?.triggerCartSpin();
      // Show a snackbar with the product name
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} added to cart!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
        ),
      );
    }
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

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.jpg'), // Set background image
          fit: BoxFit.cover, // Make sure it covers the entire screen
        ),
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right, // Right to left text alignment
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '...חיפוש מוצר',
                hintStyle: const TextStyle(color: Colors.black),
                filled: true,
                fillColor: const Color.fromARGB(255, 222, 210, 206),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                // 'All' Filter Chip with Icon and Gradient Background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FilterChip(
                    label: const Row(
                      children: [
                        Icon(Icons.all_inclusive,
                            size: 18, color: Colors.white),
                        SizedBox(width: 5),
                        Text('הכל'),
                      ],
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: _selectAll
                        ? Colors.transparent // Keep transparent if not selected
                        : const Color(
                            0xFFC8A36D), // Light gray for non-selected
                    selectedColor:
                        const Color(0xFF7A6244), // Brown color for selected
                    labelStyle: TextStyle(
                      color: _selectAll ? Colors.white : Colors.black,
                    ),
                    side:
                        const BorderSide(color: Color(0xFF7A6244), width: 1.5),
                  ),
                ),
                // Other category Filter Chips with Icon, Text, and Gradient Background
                ..._categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FilterChip(
                      label: Row(
                        children: [
                          const Icon(Icons.category,
                              size: 18, color: Colors.white), // Category icon
                          const SizedBox(width: 5),
                          Text(category.name), // Category name
                        ],
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: _categorySelections[category.id] == true
                          ? Colors.transparent // Keep transparent if selected
                          : const Color(
                              0xFFC8A36D), // Light gray for non-selected
                      selectedColor:
                          const Color(0xFF7A6244), // Brown color for selected
                      labelStyle: TextStyle(
                        color: _categorySelections[category.id] == true
                            ? Colors.white
                            : Colors.black,
                      ),
                      side: const BorderSide(
                          color: Color(0xFF7A6244), width: 1.5),
                    ),
                  );
                })
              ],
            ),
          ),

          // Products display or error message
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredProducts.isEmpty
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
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width > 600
                                    ? 3
                                    : 2, // Responsive grid
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio:
                                0.52, // Adjust item height/width ratio for better look
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
                                color: Theme.of(context)
                                    .cardColor, // Use cardColor from ThemeData

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Product Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: imageUrl
                                                .isNotEmpty // This is for checking a String (imageUrl)
                                            ? Hero(
                                                tag:
                                                    'imageHero-${product.id}', // Unique tag for Hero animation
                                                child: ColorFiltered(
                                                  colorFilter: ColorFilter.mode(
                                                    const Color.fromARGB(
                                                            255, 121, 85, 72)
                                                        .withOpacity(0.25),
                                                    BlendMode.darken,
                                                  ),
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    height: 150,
                                                    width: double.infinity,
                                                    loadingBuilder: (BuildContext
                                                            context,
                                                        Widget child,
                                                        ImageChunkEvent?
                                                            loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }
                                                      return Center(
                                                        child:
                                                            CircularProgressIndicator(
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
                                                    errorBuilder:
                                                        (BuildContext context,
                                                            Object error,
                                                            StackTrace?
                                                                stackTrace) {
                                                      return Image.asset(
                                                        'assets/noimage.jpg', // Fallback image
                                                        fit: BoxFit.cover,
                                                        height: 150,
                                                        width: double.infinity,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              )
                                            : Image.asset(
                                                'assets/noimage.jpg', // Fallback image if no imageUrl is present
                                                fit: BoxFit.cover,
                                                height: 150,
                                                width: double.infinity,
                                              ),
                                      ),

                                      const SizedBox(height: 10),

                                      // Product Name (Right to Left alignment)
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
                                          textAlign: TextAlign
                                              .right, // Ensuring RTL alignment for product name
                                        ),
                                      ),
                                      const SizedBox(height: 5),

                                      // Product Price
                                      Center(
                                        child: Text(
                                          '₪ ${product.price.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: const Text(
                                              'אזל מהמלאי',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        // Quantity Controls
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                _decrementQuantity(product.id);
                                              },
                                            ),
                                            Text(
                                              '${_productQuantities[product.id] ?? 0}',
                                              style:
                                                  const TextStyle(fontSize: 16),
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

                                        // Add to Cart Button (Hebrew)
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _addToCart(product.id),
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: const Text(
                                              'הוסף לסל', // Hebrew for "Add to Cart"
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
      ),
    );
  }
}
