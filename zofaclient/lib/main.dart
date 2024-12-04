import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zofa_client/admin/screens/admin_main_page.dart';
import 'package:zofa_client/screens/login.dart';
import 'package:zofa_client/screens/tabs.dart';
import 'package:zofa_client/theme_data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      return const Center(child: CircularProgressIndicator());
    }
    bool isAdmin = adminDeviceIds.contains(deviceId);

    return MaterialApp(
      title: 'Zofa',
      theme: buildThemeData(), // Use the custom ThemeData
      home: Scaffold(
        body: isAdmin
            ? const LoginPage() // Show admin screen for admin devices
            : const LoginPage(), // Show non-admin screen for non-admin devices
      ),
    );
  }
}
