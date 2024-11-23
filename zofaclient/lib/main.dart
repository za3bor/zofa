import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zofa_client/admin/screens/admin_main_page.dart';
import 'package:zofa_client/screens/tabs.dart';  // Ensure this import is correct

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
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/background.jpg'), // Ensure the image is in your assets folder
              fit: BoxFit.cover,
              opacity: 0.8,
            ),
          ),
          child: isAdmin
              ? const AdminMainPageScreen() // Show admin screen for admin devices
              : const AdminMainPageScreen(), // Show non-admin screen for non-admin devices
        ),
      ),
    );
  }
}
