import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zofa_client/admin/screens/admin_main_page.dart';
import 'package:zofa_client/screens/tabs.dart'; // Ensure this import is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  String? deviceId;
  final List<String> adminDeviceIds = [
    'SP1A.210812.016'
  ]; // Add allowed device IDs

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String? id;

    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      id = androidInfo.id; // Unique device ID for Android
    } else if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      id = iosInfo.identifierForVendor; // Unique device ID for iOS
    }

    setState(() {
      deviceId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (deviceId == null) {
      // Show a loading indicator while device ID is being fetched
      return const Center(child: CircularProgressIndicator());
    }

    // Check if the current device ID matches the admin devices list
    bool isAdmin = adminDeviceIds.contains(deviceId);

    return MaterialApp(
      theme: ThemeData(
        // Define a custom theme for your app
        primaryColor: Colors.brown[600], // Main color for AppBar and buttons
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.brown[600], // AppBar background color
          foregroundColor: Colors.white, // Text and icon color in the AppBar
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Assistant',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.brown[600], // Default button background color
            foregroundColor: Colors.white, // Default button text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        cardColor: const Color.fromARGB(
            255, 222, 210, 206), // Default card background color
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Colors.black, // Text color for cards and other content
            fontFamily: 'Assistant',
            fontSize: 16,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.brown[600], // Default icon color
        ),
      ),
      home: Scaffold(
        body: isAdmin
            ? const AdminMainPageScreen() // Show admin screen for admin devices
            : const TabsScreen(), // Show non-admin screen for non-admin devices
      ),
    );
  }
}
