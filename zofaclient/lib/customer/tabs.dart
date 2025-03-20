import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:zofa_client/customer/about_app.dart';
import 'package:zofa_client/firebase/auth_service.dart';
import 'package:zofa_client/customer/bread/bread_order.dart';
import 'package:zofa_client/customer/product/checkout_page.dart';
import 'package:zofa_client/customer/contact_us.dart';
import 'package:zofa_client/customer/login.dart';
import 'package:zofa_client/customer/product/products.dart';
import 'package:zofa_client/customer/rate_app.dart';
import 'package:zofa_client/customer/share_app.dart';
import 'package:zofa_client/customer/term_of_use.dart';
import 'package:hive/hive.dart';
import 'package:zofa_client/global.dart';
import 'package:zofa_client/widgets/christmas/snow_layer.dart';
import 'package:zofa_client/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:zofa_client/widgets/easter/easter_layer.dart';
import 'package:zofa_client/widgets/ramadan/ramadan_layer.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() {
    return TabsScreenState();
  }
}

class TabsScreenState extends State<TabsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedPageIndex = 0;
  int cartItemCount = 0;
  // AnimationController for the spin effect
  late AnimationController _controller;
  late Animation<double> _rotation;
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadInitialCartItemCount();

    // Initialize the animation controller and rotation animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _rotation = Tween(begin: 0.0, end: 2 * 3.1416).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  /// Directly read `cartItemCountNotifier.value` on load
  void _loadInitialCartItemCount() async {
    var box = await Hive.openBox('cart');
    Map cartData = box.get('cart', defaultValue: {});

    cartItemCountNotifier.value = cartData.values.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] ?? 0) as int),
    );
  }

  /// Trigger the cart spin animation from the "Add to Cart" action
  void triggerCartSpin() {
    _controller.forward(from: 0.0); // Start the spin animation
  }

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDrawerPage(Widget page) {
    Navigator.pop(context); // Close the drawer
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error logging out: ${e.toString()}"),
          ),
        );
      }
    }
  }

  double convexAppBarTop(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 800) {
      return -30.0.h;
    } else if (screenWidth >= 700) {
      return -28.0.h;
    } else if (screenWidth >= 600) {
      return -25.0.h;
    } else if (screenWidth >= 500) {
      return -20.0.h;
    } else if (screenWidth >= 360) {
      return -17.0.h;
    } else {
      return -15.0.h;
    }
  }

  double convexAppBarcurveSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 800) {
      return 180.0.w;
    } else if (screenWidth >= 700) {
      return 170.0.w;
    } else if (screenWidth >= 600) {
      return 170.0.w;
    } else if (screenWidth >= 500) {
      return 140.0.w;
    } else if (screenWidth >= 360) {
      return 130.0.w;
    } else {
      return 120.0.w;
    }
  }

  bool checkRamadan() {
    // Get the current date in the Islamic calendar
    HijriCalendar today = HijriCalendar.now();

    // Check if the current month is Ramadan (the 9th month in the Hijri calendar)
    if (today.hMonth == 8) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage = const ProductsScreen();
    var activePageTitle = 'מוצרים';
    DateTime currentDate = DateTime.now();
    bool isEaster = currentDate.month == 4;
    bool isChristmas = currentDate.month == 12;
    bool isRamadan = checkRamadan();

    if (_selectedPageIndex == 1) {
      // Active page for BreadOrderScreen (as an example)
      activePage = const BreadOrderScreen();
      activePageTitle = 'לחם';
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        flexibleSpace: isEaster
            ? const EasterLayer()
            : isChristmas
                ? const SnowLayer()
                : isRamadan
                    ? const RamadanLayer()
                    : null,
        title: Text(
          activePageTitle,
        ),
        leading: _selectedPageIndex == 0
            ? ValueListenableBuilder<int>(
                valueListenable: cartItemCountNotifier,
                builder: (context, cartCount, child) {
                  return IconButton(
                    icon: Stack(
                      children: [
                        if (isChristmas)
                          AnimatedBuilder(
                            animation: _rotation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotation.value,
                                child: child,
                              );
                            },
                            child: Image.asset(
                              'assets/christmas/candy-cane.png',
                              width: 30,
                              height: 30,
                            ),
                          )
                        else if (isEaster)
                          AnimatedBuilder(
                            animation: _rotation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotation.value,
                                child: child,
                              );
                            },
                            child: Image.asset(
                              'assets/easter/easter.png',
                              width: 30,
                              height: 30,
                            ),
                          )
                        else if (isRamadan)
                          AnimatedBuilder(
                            animation: _rotation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotation.value,
                                child: child,
                              );
                            },
                            child: Image.asset(
                              'assets/ramadan/ramadan_cart.png',
                              width: 30,
                              height: 30,
                            ),
                          )
                        else
                          AnimatedBuilder(
                            animation: _rotation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotation.value,
                                child: child,
                              );
                            },
                            child: const Icon(Icons.shopping_cart),
                          ),
                        if (cartCount > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.red,
                              child: Text(
                                '$cartCount',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
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
            : null,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0.w), // Adjust padding if needed
            child: isChristmas
                ? Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                      ),
                      Positioned(
                        top: -7, // Adjust the position of the hat image
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationZ(-0.1)
                              ..scale(-1.0, 1.0, 1.0),
                            child: Image.asset(
                              'assets/christmas/hat.png', // Christmas hat image
                              width: 40.0,
                              height: 35.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : isEaster
                    ? IconButton(
                        icon: Image.asset(
                          'assets/easter/easter.png', // Easter icon
                          width: 30,
                          height: 30,
                        ),
                        onPressed: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                      )
                    : isRamadan
                        ? IconButton(
                            icon: Image.asset(
                              'assets/ramadan/ramadan_drawer.png', // Ramadan icon
                              width: 30,
                              height: 30,
                            ),
                            onPressed: () {
                              _scaffoldKey.currentState?.openEndDrawer();
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.menu), // Default drawer icon
                            onPressed: () {
                              _scaffoldKey.currentState?.openEndDrawer();
                            },
                          ),
          ),
        ],
      ),
      body: activePage,
      bottomNavigationBar: ConvexAppBar(
        elevation: 10.0, // Adjust the shadow beneath the convex shape
        curveSize: 120.h, // Adjust the size of the convex shape
        top: -15.h, // Adjust the position of the convex shape
        style: TabStyle.flip,
        backgroundColor: Theme.of(context).primaryColor,
        color: Theme.of(context).colorScheme.secondary,
        activeColor: Theme.of(context).colorScheme.secondary,
        items: [
          TabItem(
            icon: isChristmas
                ? Image.asset('assets/christmas/market.png',
                    width: 24, height: 24)
                : isEaster
                    ? Image.asset('assets/easter/shopping-bag.png',
                        width: 24, height: 24)
                    : isRamadan
                        ? Image.asset('assets/ramadan/market.png',
                            width: 24, height: 24)
                        : Icon(
                            Icons.storefront,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 30.sp,
                          ),
            title: 'מוצרים',
          ),
          TabItem(
            icon: isChristmas
                ? Image.asset('assets/christmas/bread.png',
                    width: 24, height: 24)
                : isEaster
                    ? Image.asset('assets/easter/bread.png',
                        width: 24, height: 24)
                    : isRamadan
                        ? Image.asset('assets/easter/bread.png',
                            width: 24, height: 24)
                        : Icon(
                            FontAwesomeIcons.breadSlice,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 30.sp,
                          ),
            title: 'לחם',
          ),
        ],
        initialActiveIndex: _selectedPageIndex,
        onTap: _selectPage,
      ),
      endDrawer: Drawer(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            color: Theme.of(context)
                .scaffoldBackgroundColor, // Set your desired background color here
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                const DrawerHeader(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/drawer.jpeg',
                      ), // Use your image path
                      fit: BoxFit
                          .cover, // Ensures the image fills the DrawerHeader
                    ),
                  ),
                  child: Align(),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: Text('צור קשר',
                      style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () {
                    _navigateToDrawerPage(ContactUsScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('אודות האפליקציה',
                      style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () {
                    _navigateToDrawerPage(const AboutAppScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text('הגדרות',
                      style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () {
                    _navigateToDrawerPage(const ShareAppScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text('הערות',
                      style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () {
                    _navigateToDrawerPage(const RateAppScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text('תנאי שימוש',
                      style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () {
                    _navigateToDrawerPage(const TermOfUseScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text('יציאה',
                      style: Theme.of(context).textTheme.bodyLarge),
                  onTap: _logout, // Call the logout method
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: Text('מחק חשבון',
                      style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () async {
                    await authService.deleteAccount(context, ipAddress);
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
