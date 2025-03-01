import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zofa_client/models/category.dart';
import 'package:zofa_client/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:zofa_client/screens/product_details.dart';
import 'package:hive/hive.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:zofa_client/global.dart';
import 'package:zofa_client/screens/tabs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({
    super.key,
  });

  @override
  State<ProductsScreen> createState() {
    return _ProductsScreenState();
  }
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final Map<int, bool> _categorySelections = {};
  bool _selectAll = true; // "All" is selected by default
  bool _categoriesError =
      false; // To track if there's a problem with categories
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // ScrollController for SingleChildScrollView
  final Map<int, int> _productQuantities =
      {}; // Map to store product quantities
  late Future<void> combinedFuture; // Combines both future calls
  late AnimationController _animationController;
  late AnimationController _controller;
  late Animation<Offset> _animation;
  late IO.Socket _socket; // Declare the socket instance

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _fetchCategories();
    _animationController = AnimationController(
      vsync: this, // This is where the ticker is used.
      duration: const Duration(seconds: 1),
    );
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.1), // Move up slightly
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _searchController.addListener(() {
      _filterProducts();
    });
  }

  void _initializeSocket() {
    // Initialize the socket connection
    _socket = IO.io(
      'http://$ipAddress', // Replace with your backend URL
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
    _scrollController.dispose();
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _animateButton() async {
    await _controller.forward();
    _controller.reverse();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/getAllCategories'),
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
        Uri.parse('http://$ipAddress/api/getProductsByCategory'),
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
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {
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
      if (mounted) {
        final tabsScreenState =
            context.findAncestorStateOfType<TabsScreenState>();
        tabsScreenState?.triggerCartSpin();
      }
      // Show a snackbar with the product name
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${product.name}המוצר הוסף לעגלה ',
            ),
          ),
        );
      }
    }
  }

  double calculateAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjust the multiplier (0.6) to fine-tune the aspect ratio based on the screen size
    if (screenWidth < 360) {
      // Small devices (e.g., phones with smaller screens)
      return screenWidth / (screenHeight * 0.55);
    } else if (screenWidth < 600) {
      // Medium devices (e.g., standard phones)
      return screenWidth / (screenHeight * 0.6);
    } else {
      // Large devices (e.g., phablets and tablets)
      return screenWidth / (screenHeight * 0.65);
    }
  }

  bool isFoldableDevice(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Foldable devices tend to have a very wide aspect ratio when unfolded
    final aspectRatio = screenWidth / screenHeight;

    // Define a threshold for foldable device detection
    print('Aspect ratio: $aspectRatio, Screen width: $screenWidth');
    return aspectRatio > 2.0 || screenWidth > 500;
  }

  @override
  Widget build(BuildContext context) {
    if (_categoriesError) {
      // Display error message if categories failed to load
      return Center(
        child: Text(
          'שגיאה בטעינת הקטגוריות, נסה שוב מאוחר יותר',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/background.jpg', // Path to your background image
            fit: BoxFit.cover, // Ensures the image covers the entire screen
          ),
        ),
        Column(
          children: [
            // Search bar
            Padding(
              padding: EdgeInsets.all(16.w),
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right, // Right to left text alignment
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: '...חיפוש מוצר',
                  filled: true,
                  fillColor: const Color.fromARGB(255, 222, 210, 206),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 9.h),
                ),
              ),
            ),

            // Dynamic Filter Chips for categories with 'All' option
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              controller: _scrollController,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  // 'All' Filter Chip with Icon and Gradient Background
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: FilterChip(
                      label: Row(
                        children: [
                          Icon(
                            Icons.all_inclusive,
                            color: Colors.white,
                            size: 20.sp, // Adjust icon size
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'הכל',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
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
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      backgroundColor: _selectAll
                          ? Colors
                              .transparent // Keep transparent if not selected
                          : const Color(0xFFC8A36D),
                      selectedColor: const Color(0xFF7A6244),
                      labelStyle: TextStyle(
                        color: _selectAll ? Colors.white : Colors.black,
                      ),
                      side: BorderSide(
                        color: const Color(0xFF7A6244),
                        width: 1.5.w,
                      ),
                    ),
                  ),
                  // Other category Filter Chips
                  ..._categories.map((category) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: FilterChip(
                        label: Row(
                          children: [
                            Icon(
                              Icons.category,
                              color: Colors.white,
                              size: 20.sp, // Adjust icon size
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              category.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
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
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        backgroundColor:
                            _categorySelections[category.id] == true
                                ? Colors.transparent
                                : const Color(0xFFC8A36D),
                        selectedColor: const Color(0xFF7A6244),
                        labelStyle: TextStyle(
                          color: _categorySelections[category.id] == true
                              ? Colors.white
                              : Colors.black,
                        ),
                        side: BorderSide(
                          color: const Color(0xFF7A6244),
                          width: 1.5.w,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Products display or error message
            Directionality(
              textDirection: TextDirection.rtl,
              child: Expanded(
                child: _filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isNotEmpty
                              ? 'אין מוצרים להצגה'
                              : _products.isEmpty
                                  ? 'אין מוצרים להצגה'
                                  : 'שגיאה בטעינת המוצרים, נסה שוב מאוחר יותר',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.all(8.0.w),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10.w,
                            mainAxisSpacing: 10.h,
                            childAspectRatio: isFoldableDevice(context)
                                ? calculateAspectRatio(context) *
                                    0.4.h // Foldable device adjustment
                                : (MediaQuery.of(context).size.width < 360
                                    ? calculateAspectRatio(context) *
                                        0.47.h // Small devices
                                    : calculateAspectRatio(context) *
                                        0.45.h), // Default for medium & large
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (ctx, index) {
                            final product = _filteredProducts[index];
                            final imageUrl =
                                'https://d1qq705dywrog2.cloudfront.net/images/${product.id}.jpeg';

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
                                  borderRadius: BorderRadius.circular(15.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(15.r),
                                        topRight: Radius.circular(15.r),
                                      ),
                                      child: Hero(
                                        tag: 'imageHero-${product.id}',
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            const Color.fromARGB(255, 148, 105, 90)
                                                .withValues(alpha: 0.3),
                                            BlendMode.darken,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.cover,
                                            height: 150.w,
                                            width: double.infinity,
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(),
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
                                    ),
                                    SizedBox(height: 10.h),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: 12.0.w,
                                          right: 12.0.w,
                                          bottom: 8.0.h,
                                          top: 4.0.h),
                                      child: Text(
                                        product.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Center(
                                      child: Text(
                                        '₪ ${product.price.toStringAsFixed(1)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                          ),
                                          onPressed: () =>
                                              _incrementQuantity(product.id),
                                        ),
                                        Text(
                                          '${_productQuantities[product.id] ?? 0}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove,
                                          ),
                                          onPressed: () =>
                                              _decrementQuantity(product.id),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5.h),
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: product.stock
                                            ? () => _addToCart(product.id)
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: product.stock
                                              ? Colors.brown
                                              : Colors.grey,
                                        ),
                                        child: Text(
                                          product.stock
                                              ? 'הוסף לסל'
                                              : 'אזל מהמלאי',
                                          style: TextStyle(fontSize: 14.sp),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
