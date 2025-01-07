import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zofa_client/admin/screens/admin_main_page.dart';
import 'package:zofa_client/notificationservise.dart';
import 'package:zofa_client/screens/signup.dart';
import 'package:zofa_client/screens/tabs.dart';
import 'package:zofa_client/theme_data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:zofa_client/constant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path); // Set the path where Hive stores data

  // Open a box to store cart items
  await Hive.openBox('cart');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Base size of the design
      minTextAdapt: true, // Enable font scaling
      splitScreenMode: true, // Support for split screens
      builder: (context, child) {
        return MaterialApp(
          theme: buildThemeData(),
          home: child,
        );
      },
      child: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
  }

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
    // Request notification permission when the app starts
    _notificationService.checkNotificationPermission(context);
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User is not logged in, show phone authentication screen
      return const SignupScreen();
    }

    // Use FutureBuilder to handle async operation and show loading state
    return FutureBuilder<bool>(
      future: _checkAdmin(user.phoneNumber ?? ''),
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

        if (snapshot.hasData && snapshot.data == true) {
          // If the phone number belongs to an admin
          return const AdminMainPageScreen();
        } else {
          // If the phone number does not belong to an admin
          return const TabsScreen();
        }
      },
    );
  }
}
