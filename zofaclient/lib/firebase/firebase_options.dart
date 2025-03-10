// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDbwSkC3fr6SIBt1FlHo8zG6nZrpkbiLBs',
    appId: '1:1013991760042:web:5aee9cdd3cd65af2fe70d3',
    messagingSenderId: '1013991760042',
    projectId: 'zofa-5c07c',
    authDomain: 'zofa-5c07c.firebaseapp.com',
    storageBucket: 'zofa-5c07c.firebasestorage.app',
    measurementId: 'G-VTFXJF51GR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAxIvTOueEVVqgmHI6eX10w3OaZxUkYuDo',
    appId: '1:1013991760042:android:8068d65f0df6f05ffe70d3',
    messagingSenderId: '1013991760042',
    projectId: 'zofa-5c07c',
    storageBucket: 'zofa-5c07c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBOfRnQPOspu5kromi8lKqzDmOEInT_pNY',
    appId: '1:1013991760042:ios:7fc326e6bc6becb6fe70d3',
    messagingSenderId: '1013991760042',
    projectId: 'zofa-5c07c',
    storageBucket: 'zofa-5c07c.firebasestorage.app',
    iosBundleId: 'com.example.zofaClient',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBOfRnQPOspu5kromi8lKqzDmOEInT_pNY',
    appId: '1:1013991760042:ios:7fc326e6bc6becb6fe70d3',
    messagingSenderId: '1013991760042',
    projectId: 'zofa-5c07c',
    storageBucket: 'zofa-5c07c.firebasestorage.app',
    iosBundleId: 'com.example.zofaClient',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDbwSkC3fr6SIBt1FlHo8zG6nZrpkbiLBs',
    appId: '1:1013991760042:web:c2693eb0f8b073f7fe70d3',
    messagingSenderId: '1013991760042',
    projectId: 'zofa-5c07c',
    authDomain: 'zofa-5c07c.firebaseapp.com',
    storageBucket: 'zofa-5c07c.firebasestorage.app',
    measurementId: 'G-CRR4M9FB5S',
  );
}