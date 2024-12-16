import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Function to check notification permission
  Future<void> checkNotificationPermission(BuildContext context) async {
    // Check the notification permission status
    NotificationSettings settings = await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permission granted');
      _showSnackbar(context, 'ההיתר להודעות ניתן');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('Provisional permission granted');
      _showSnackbar(context, 'ההיתר הזמני להודעות ניתן');
    } else {
      // Permission denied, prompt user to open settings
      print('Permission denied');
      _showSnackbar(context, 'לא ניתן היתר להודעות');
      //_askUserToEnableNotifications(context);
    }
  }

  // Method to show a Snackbar
  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Prompt user to enable notifications manually by opening app settings
  Future<void> _askUserToEnableNotifications(BuildContext context) async {
    bool canOpenSettings = await openAppSettings();

    if (canOpenSettings) {
      _showSnackbar(context, 'כדי לקבל הודעות, אנא הפעל את ההתראות בהגדרות');
    } else {
      _showSnackbar(context, 'לא ניתן לפתוח את ההגדרות');
    }
  }
}
