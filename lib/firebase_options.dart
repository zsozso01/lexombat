// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyA4y7fhM1_sejjcAfOowiXtaX56wQrKUpM',
    appId: '1:207503016913:web:f5a02f95a9cfa4345d56f0',
    messagingSenderId: '207503016913',
    projectId: 'lexombat-754cf',
    authDomain: 'lexombat-754cf.firebaseapp.com',
    databaseURL: 'https://lexombat-754cf-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'lexombat-754cf.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7iDzlU4QPkbePnJAh-BiFHgG6SfgQgBE',
    appId: '1:207503016913:android:690e610fa89ad9025d56f0',
    messagingSenderId: '207503016913',
    projectId: 'lexombat-754cf',
    databaseURL: 'https://lexombat-754cf-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'lexombat-754cf.appspot.com',
  );
}
