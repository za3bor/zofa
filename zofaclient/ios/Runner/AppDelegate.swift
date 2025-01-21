import UIKit
import FirebaseCore
import FirebaseMessaging
import FirebaseAuth
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()

    // Configure Phone Authentication
    self.setupPhoneAuth()

    // Register for remote notifications
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // Set the Messaging delegate to self
    Messaging.messaging().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Configure Firebase Phone Authentication
  private func setupPhoneAuth() {
    // Ensure that the app supports reCAPTCHA verification
    let settings = Auth.auth().settings
    settings?.isAppVerificationDisabledForTesting = false // Disable for production use
  }

  // This method will be called when the app receives a push notification in the foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Show notification even when app is in foreground
    completionHandler([.alert, .badge, .sound])
  }

  // This method is called when the app opens from a notification tap
  override func application(_ application: UIApplication,
                            didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler(UIBackgroundFetchResult.newData)
  }

  // Implement this method to receive the FCM token
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    if let fcmToken = fcmToken {
      print("FCM token received: \(fcmToken)")
      // You can save the FCM token to your server or use it as needed
    }
  }
}
