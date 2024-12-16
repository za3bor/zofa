import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zofa_client/admin/screens/admin_main_page.dart';
import 'package:zofa_client/notificationservise.dart';
import 'package:zofa_client/screens/login.dart';
import 'package:zofa_client/screens/tabs.dart';
import 'package:zofa_client/theme_data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

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
    return const MaterialApp(
      title: 'Zofa',
      //theme: buildThemeData(), // Use your custom ThemeData
      home: MainScreen(),
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

  final List<String> adminPhoneNumbers = [
    '+972525707415', // Example admin phone numbers
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRequestNotificationPermission();
  }

  // Function to check and request notification permission
  Future<void> _checkAndRequestNotificationPermission() async {
    final status = await Permission.notification.status;

    // If permission is denied or permanently denied, show the dialog
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog();
    } else {
      _notificationService.checkNotificationPermission(context);
    }
  }

  // Function to show a dialog asking the user to enable notifications
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text('Would you like to enable notifications for this app?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog

                // After closing the dialog, open app settings
                await _openAppSettings();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // Function to open app settings
  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    // Request notification permission when the app starts
    _notificationService.checkNotificationPermission(context);
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User is not logged in, show phone authentication screen
      return const LoginPage();
    }

    // Check if the logged-in user is an admin
    bool isAdmin = adminPhoneNumbers.contains(user.phoneNumber);

    return Scaffold(
      body: isAdmin
          ? const AdminMainPageScreen() // Show admin screen for admin devices
          : const AdminMainPageScreen(), // Show non-admin screen for non-admin devices
    );
  }
}
