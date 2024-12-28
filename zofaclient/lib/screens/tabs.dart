import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zofa_client/screens/about_app.dart';
import 'package:zofa_client/screens/bread_order.dart';
import 'package:zofa_client/screens/checkout_page.dart';
import 'package:zofa_client/screens/contact_us.dart';
import 'package:zofa_client/screens/login.dart';
import 'package:zofa_client/screens/products.dart';
import 'package:zofa_client/screens/rate_app.dart';
import 'package:zofa_client/screens/share_app.dart';
import 'package:zofa_client/screens/signup.dart';
import 'package:zofa_client/screens/term_of_use.dart';
import 'package:hive/hive.dart';
import 'package:zofa_client/global.dart';
import 'package:zofa_client/widgets/snow_layer.dart'; // Adjust the path accordingly
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: ${e.toString()}")),
      );
    }
  }

  Future<void> _reauthenticateUser(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is currently signed in.')),
        );
        return;
      }

      // Step 1: Start phone number verification
      final PhoneVerificationCompleted verificationCompleted =
          (PhoneAuthCredential phoneAuthCredential) async {
        // Auto-retrieval or instant verification is done, we directly reauthenticate
        await user.reauthenticateWithCredential(phoneAuthCredential);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User reauthenticated successfully')),
        );
      };

      final PhoneVerificationFailed verificationFailed =
          (FirebaseAuthException error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Phone verification failed: ${error.message}')),
        );
      };

      final PhoneCodeSent codeSent = (String verificationId, int? resendToken) {
        // Ask the user to enter the SMS code
        showDialog(
          context: context,
          builder: (context) {
            final TextEditingController codeController =
                TextEditingController();

            return AlertDialog(
              title: const Text('Enter SMS code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'SMS Code'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final smsCode = codeController.text.trim();
                      if (smsCode.isNotEmpty) {
                        final credential = PhoneAuthProvider.credential(
                          verificationId: verificationId,
                          smsCode: smsCode,
                        );
                        try {
                          await user.reauthenticateWithCredential(credential);
                          Navigator.pop(context); // Close the dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Reauthentication successful')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Reauthentication failed: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            );
          },
        );
      };

      // Step 2: Trigger phone number verification
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: user.phoneNumber!,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error re-authenticating user: $e')),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is currently signed in.')),
        );
        return;
      }

      // Re-authenticate the user first
      await _reauthenticateUser(context);

      // Proceed with account deletion after re-authentication
      final response = await http.delete(
        Uri.parse('http://$ipAddress:3000/api/deleteUser/${user.phoneNumber}'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } else {
        final message =
            jsonDecode(response.body)['message'] ?? 'Failed to delete User';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      // Clear Hive data for the user
      await _deleteHiveData();

      // Firebase account deletion
      await user.delete();

      // Navigate to the signup screen and clear the navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignupScreen()),
        (route) => false, // Removes all previous routes
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _deleteHiveData() async {
    try {
      // Get the user's box name or the specific boxes where their data is stored
      // Example: If you have a box named 'userData' for the user's info
      var box = await Hive.openBox('cart');
      await box.clear(); // Clears all data inside the box

      // If you want to delete the box completely, use:
      await Hive.deleteBoxFromDisk('cart');

      // Optionally, if you have multiple boxes, delete them similarly:
      // await Hive.deleteBoxFromDisk('anotherBox');

      print('Hive data deleted successfully.');
    } catch (e) {
      print('Error deleting Hive data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage = const ProductsScreen();
    var activePageTitle = 'מוצרים';

    if (_selectedPageIndex == 1) {
      // Active page for BreadOrderScreen (as an example)
      activePage = const BreadOrderScreen();
      activePageTitle = 'לחם';
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        flexibleSpace:
            const SnowLayer(), // Directly use SnowLayer without Container
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
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
          // Stack to overlay the hat image on the drawer icon
          Padding(
            padding:
                EdgeInsets.only(right: 8.0.w), // Adjust the padding as needed
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                ),
                // The hat image placed on top of the drawer icon
                Positioned(
                  top: -7, // Adjust the position of the hat image vertically
                  right:
                      10, // Move the hat a little bit to the left by increasing the right value
                  child: GestureDetector(
                    onTap: () {
                      // Open the drawer when the hat is tapped
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationZ(-0.1) // Rotate if needed
                        ..scale(-1.0, 1.0, 1.0), // Horizontal flip if needed
                      child: Image.asset(
                        'assets/icons/hat.png', // Path to your hat image
                        width: 40.0, // Adjust the size of the hat
                        height: 35.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        currentIndex: _selectedPageIndex,
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
                          'assets/drawer.jpeg'), // Use your image path
                      fit: BoxFit
                          .cover, // Ensures the image fills the DrawerHeader
                    ),
                  ),
                  child: Align(),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('צור קשר'),
                  onTap: () {
                    _navigateToDrawerPage(ContactUsScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('אודות האפליקציה'),
                  onTap: () {
                    _navigateToDrawerPage(const AboutAppScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('הגדרות'),
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
                  leading: const Icon(Icons.info),
                  title: const Text('תנאי שימוש'),
                  onTap: () {
                    _navigateToDrawerPage(const TermOfUseScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('יציאה'),
                  onTap: _logout, // Call the logout method
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('מחק חשבון'),
                  onTap: () {
                    _deleteAccount(context);
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
