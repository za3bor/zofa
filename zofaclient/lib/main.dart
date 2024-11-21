import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zofa_client/admin/screens/admin_main_page.dart';
import 'package:zofa_client/screens/tabs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      return const CircularProgressIndicator();
    }

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
          child: adminDeviceIds.contains(deviceId)
              ? const AdminMainPageScreen()
              : const AdminMainPageScreen(), // Change `AdminMainPageScreen` to `TabsScreen` for non-admin devices
        ),
      ),
    );
  }
}
