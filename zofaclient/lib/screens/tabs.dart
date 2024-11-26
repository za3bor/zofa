import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zofa_client/screens/about_app.dart';
import 'package:zofa_client/screens/bread_order.dart';
import 'package:zofa_client/screens/checkout_page.dart';
import 'package:zofa_client/screens/contact_us.dart';
import 'package:zofa_client/screens/products.dart';
import 'package:zofa_client/screens/rate_app.dart';
import 'package:zofa_client/screens/share_app.dart';
import 'package:zofa_client/screens/term_of_use.dart';
import 'package:badges/badges.dart' as badges;
import 'package:hive/hive.dart';
import 'package:zofa_client/global.dart'; // Adjust the path accordingly

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedPageIndex = 0;
  int cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartItemCount();
  }

  /// Load the cart item count from Hive storage.
  Future<void> _loadCartItemCount() async {
    var box = await Hive.openBox('cart');
    Map cartData = box.get('cart', defaultValue: {});

    // Ensure the sum is cast to an int
    int count = cartData.values.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] ?? 0) as int),
    );

    setState(() {
      cartItemCount = count;
    });
  }

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  void _navigateToDrawerPage(Widget page) {
    Navigator.pop(context); // Close the drawer
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

   @override
  Widget build(BuildContext context) {
    // Access theme properties
    final theme = Theme.of(context);

    // Set custom brown color for the background
    const brownColor = Color(0xFF7A6244);

    // Set active page and title based on selected tab
    Widget activePage = const ProductsScreen();
    var activePageTitle = 'מוצרים';

    if (_selectedPageIndex == 1) {
      activePage = const BreadOrderScreen();
      activePageTitle = 'לחם';
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          activePageTitle,
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true, // This will center the title on both platforms

        leading:
            _selectedPageIndex == 0 // Only show the cart icon on the first tab
                ? ValueListenableBuilder<int>(
                    valueListenable: cartItemCountNotifier,
                    builder: (context, cartCount, child) {
                      return IconButton(
                        icon: Stack(
                          children: [
                            const Icon(Icons.shopping_cart),
                            if (cartCount > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Colors.red,
                                  child: Text(
                                    '$cartCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        color: Colors.white, // Make icon white
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckoutPageScreen(),
                            ),
                          );
                        },
                      );
                    },
                  )
                : null, // If not on the first tab, don't show the cart icon

        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: Colors.white, // Make icon white
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        currentIndex: _selectedPageIndex,
        selectedItemColor: Colors.white, // White icons for selected tab
        unselectedItemColor: Colors.white, // White icons for unselected tab
        backgroundColor: brownColor, // Set background to brown color
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'מוצרים',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.breadSlice),
            label: 'לחם',
          ),
        ],
      ),
      endDrawer: Directionality(
        textDirection: TextDirection.rtl, // Set text direction to RTL
        child: Drawer(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image:
                    AssetImage('assets/background2.jpg'), // Use your image path
                fit: BoxFit.cover, // Ensure the image covers the whole drawer
                opacity: 0.78,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                const DrawerHeader(
                  child: Text(
                    'ניווט',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text(
                    'צור קשר',
                  ),
                  onTap: () {
                    _navigateToDrawerPage(ContactUsScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text(
                    'אודות האפליקציה',
                  ),
                  onTap: () {
                    _navigateToDrawerPage(const AboutAppScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text(
                    'הגדרות',
                  ),
                  onTap: () {
                    _navigateToDrawerPage(const ShareAppScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('הערות'),
                  onTap: () {
                    _navigateToDrawerPage(const RateAppScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text(
                    'תנאי שימוש',
                  ),
                  onTap: () {
                    _navigateToDrawerPage(const TermOfUseScreen());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}