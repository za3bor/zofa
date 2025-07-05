import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zofa/admin/admin_main_page.dart';
import 'package:zofa/customer/signup.dart';
import 'package:zofa/customer/tabs.dart';
import 'package:zofa/firebase_options.dart';
import 'package:zofa/force_update.dart';
import 'package:zofa/notification_service.dart';
import 'package:zofa/theme_data.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:zofa/constant.dart';
import 'package:zofa/welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize Hive
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path); // Set the path where Hive stores data
  // Open boxes to store user login and admin status
  await Hive.openBox('userStatus');
  await Hive.openBox('cart'); // You can still keep the cart box open
  await Hive.openBox('salecart'); // You can still keep the cart box open
  await Hive.openBox('seedscart'); // You can still keep the cart box open

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildThemeData(),
          home: child,
        );
      },
      child: AnimatedSplashScreen(
        splash: 'assets/splash.gif',
        backgroundColor: const Color(0xFFDFCAAF),
        nextScreen: const ForceUpdateWrapper(child: MainScreen()),
        splashIconSize: MediaQuery.of(context).size.height,
        duration: 2000,
        centered: true,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Ask for permission (only during first few launches)
      await NotificationService.checkAndRequestPermission(context);

      // Get user's phone number from Hive
      final phone = Hive.box('userStatus').get('phoneNumber', defaultValue: '');
      if (phone.isEmpty) return;

      // Get the current FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      // Send token to backend
      await _sendTokenToServer(phone, fcmToken);

      // Listen for token refresh and update backend
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _sendTokenToServer(phone, newToken);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('אירעה שגיאה בהפעלת ההתראות. נסה שוב מאוחר יותר.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _sendTokenToServer(String phone, String token) async {
    try {
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/updateFcmToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phone, 'fcm_token': token}),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('עדכון האסימון נכשל: נסה שוב מאוחר יותר.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בעדכון אסימון ההתראות. נסה שוב מאוחר יותר.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Function to check if the user is an admin by phone number
  Future<bool> _checkAdmin(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/checkAdmin/$phone'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists']; // Return true or false
      } else {
        return false; // Return false if the API call fails
      }
    } catch (e) {
      return false; // Return false if there's an error during the request
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStatusBox = Hive.box('userStatus');
    final isLoggedIn = userStatusBox.get('isLoggedIn', defaultValue: false);

    if (!isLoggedIn) {
      // User is not logged in, navigate to SignupScreen
      return const WelcomeScreen();
    }

    // User is logged in, check if the user is an admin
    return FutureBuilder<bool>(
      future: _getAdminStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (snapshot.hasData) {
          bool isAdmin = snapshot.data!;
          // Store admin status in Hive
          userStatusBox.put('isAdmin', isAdmin);

          // Navigate to the appropriate screen based on admin status
          if (isAdmin) {
            return const AdminMainPageScreen();
          } else {
            return const TabsScreen();
          }
        }

        // Default fallback if no data is returned
        return const SignupScreen();
      },
    );
  }

  // Function to get the admin status using the phone number
  Future<bool> _getAdminStatus() async {
    final userStatusBox = Hive.box('userStatus');
    final phone = userStatusBox.get('phoneNumber', defaultValue: '');

    if (phone.isEmpty) {
      return false; // Return false if phone number is empty or not set
    }

    // Call the API to check admin status
    return await _checkAdmin(phone);
  }
}
