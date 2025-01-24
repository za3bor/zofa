import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

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
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error logging out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: ${e.toString()}")),
        );
      }
    }
  }

// Define the verificationCompleted function
  Future<void> verificationCompleted(
      PhoneAuthCredential phoneAuthCredential, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    // Auto-retrieval or instant verification is done
    await user.reauthenticateWithCredential(phoneAuthCredential);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User reauthenticated successfully')),
      );
    }
  }

// Define the verificationFailed function
  void verificationFailed(FirebaseAuthException error, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Phone verification failed: ${error.message}')),
    );
  }

// Define the codeSent function
  void codeSent(String verificationId, int? resendToken, BuildContext context,
      User user) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController codeController = TextEditingController();

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
                      if (context.mounted) {
                        Navigator.pop(context); // Close the dialog
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Reauthentication successful')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Reauthentication failed: $e')),
                        );
                      }
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
  }

  Future<bool> _reauthenticateUser(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is currently signed in.')),
        );
        return false; // Return false if no user is signed in
      }

      // Trigger phone number verification
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: user.phoneNumber!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await user.reauthenticateWithCredential(credential);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Re-authentication successful')),
            );
          }
        },
        verificationFailed: (FirebaseAuthException error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification failed: ${error.message}')),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          final TextEditingController codeController = TextEditingController();

          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Enter SMS code'),
                content: TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'SMS Code'),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final smsCode = codeController.text.trim();
                      if (smsCode.isNotEmpty) {
                        final credential = PhoneAuthProvider.credential(
                          verificationId: verificationId,
                          smsCode: smsCode,
                        );
                        try {
                          await user.reauthenticateWithCredential(credential);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Re-authentication successful')),
                            );
                            Navigator.pop(context); // Close the dialog
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Re-authentication failed: $e')),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      return true; // Return true if re-authentication succeeds
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error re-authenticating user: $e')),
        );
      }
      return false; // Return false if an exception occurs
    }
  }

  Future<void> _deleteFcmToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      print("FCM token deleted successfully.");
    } catch (e) {
      print("Error deleting FCM token: $e");
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.phoneNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is currently signed in.')),
        );
        return;
      }

      // Step 1: Re-authenticate the user
      final isReauthenticated = await _reauthenticateUser(context);
      if (!isReauthenticated) {
        return; // Stop if re-authentication fails
      }

      // Step 2: Delete user data on the server
      final response = await http
          .delete(
        Uri.parse('http://$ipAddress/api/deleteUser/${user.phoneNumber}'),
      )
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('Request timed out');
      });

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        final message = body is Map && body.containsKey('message')
            ? body['message']
            : 'Failed to delete user';
        throw Exception(message);
      }

      // Step 3: Clear Hive data
      await _deleteHiveData();

      // Step 4: Delete FCM token
      await _deleteFcmToken();

      // Step 5: Delete Firebase account
      await user.delete();

      // Step 6: Navigate to the signup screen
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignupScreen()),
          (route) => false,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
                              child: Text('$cartCount',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                        color: Colors.white,
                                      )),
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
      bottomNavigationBar: ConvexAppBar(
        elevation: 10.0, // Adjust the shadow beneath the convex shape
        curveSize: 120.0.w, // Size of the convex shape
        top: -15.0
            .h, // Adjusts the height of the curve apex (negative moves it higher)

        style: TabStyle.flip,
        backgroundColor: Theme.of(context).primaryColor,
        color: Theme.of(context).colorScheme.secondary,
        activeColor: Theme.of(context).colorScheme.secondary,
        items: const [
          TabItem(icon: Icons.storefront, title: 'מוצרים'),
          TabItem(icon: FontAwesomeIcons.breadSlice, title: 'לחם'),
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
                          'assets/drawer.jpeg'), // Use your image path
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
