import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Replace the placeholder values below with your Firebase project settings.
///
/// To get the correct values, create a Firebase project and add an Android app
/// with package name `com.example.unikam_survey`, then use the values from
/// the `google-services.json` file or the Firebase console.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDezKiJigbx2r80yRbXLqNf_3v_6ryZuFQ',
    appId: '1:864892696379:android:31ae644ef45a001d29a91e',
    messagingSenderId: '864892696379',
    projectId: 'unikam-survey',
    storageBucket: 'unikam-survey.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.unikam_survey',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDezKiJigbx2r80yRbXLqNf_3v_6ryZuFQ',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'unikam-survey',
    authDomain: 'YOUR_AUTH_DOMAIN',
    storageBucket: 'unikam-survey.firebasestorage.app',
    measurementId: 'YOUR_MEASUREMENT_ID',
  );
}
