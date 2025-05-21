import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const _launchCountKey = 'launchCount';
  static const _maxPromptCount = 2; // Allow prompting max 2 times

  static Future<void> checkAndRequestPermission(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int launchCount = prefs.getInt(_launchCountKey) ?? 0;

      if (launchCount < _maxPromptCount) {
        final granted = await _requestNotificationPermission();
        if (granted) {
          await FirebaseMessaging.instance.subscribeToTopic("customers");
          await FirebaseMessaging.instance.subscribeToTopic("sales");
        }
        await prefs.setInt(_launchCountKey, launchCount + 1);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('אירעה שגיאה בבקשת הרשאות. אנא נסה שוב מאוחר יותר.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static Future<bool> _requestNotificationPermission() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
