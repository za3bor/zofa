import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Function to check notification permission
  Future<void> checkNotificationPermission(BuildContext context) async {
    // Check the notification permission status
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (context.mounted) {
        _showSnackbar(context, 'ההיתר להודעות ניתן');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (context.mounted) {
        _showSnackbar(context, 'ההיתר הזמני להודעות ניתן');
      }
    } else {
      // Permission denied, prompt user to open settings
      if (context.mounted) {
        _showSnackbar(context, 'לא ניתן היתר להודעות');
        _askUserToEnableNotifications(context);
      }
    }
    _initializeFirebaseMessaging();
  }

  // Method to show a Snackbar
  void _showSnackbar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Prompt user to enable notifications manually by opening app settings
  Future<void> _askUserToEnableNotifications(BuildContext context) async {
    bool canOpenSettings = await openAppSettings();

    if (canOpenSettings) {
      if (context.mounted) {
        _showSnackbar(context, 'כדי לקבל הודעות, אנא הפעל את ההתראות בהגדרות');
      }
    } else {
      if (context.mounted) {
        _showSnackbar(context, 'לא ניתן לפתוח את ההגדרות');
      }
    }
  }

  void _initializeFirebaseMessaging() {
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {}
    });
  }
}
