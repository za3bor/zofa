import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const _launchCountKey = 'launchCount';

  static Future<void> checkFirstTwoTimesAndRequestPermission() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int launchCount = prefs.getInt(_launchCountKey) ?? 0;

    if (launchCount < 2) {
      await _requestNotificationPermission();
      prefs.setInt(_launchCountKey, launchCount + 1);
    }
  }

  // Request notification permission
  static Future<void> _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
  }
}
