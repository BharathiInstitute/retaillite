/// Firebase configuration options
///
/// IMPORTANT: This is a placeholder. To use Firebase:
/// 1. Create a Firebase project at https://console.firebase.google.com
/// 2. Run: flutterfire configure
/// 3. This will generate the actual firebase_options.dart
///
/// For now, disable Firebase initialization to test the UI.
library;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  // TODO: Replace these with your actual Firebase project values
  // Run 'flutterfire configure' to generate these automatically

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAA5Y-43RM2IItOsWpbygeHQhVbU2zFe48',
    appId: '1:576503526807:web:23cf36d320396b512300d2',
    messagingSenderId: '576503526807',
    projectId: 'login-radha',
    authDomain: 'login-radha.firebaseapp.com',
    storageBucket: 'login-radha.firebasestorage.app',
    measurementId: 'G-WXNLFN8HEB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBqOxCE0Pzdkuwdb-cXOJ6qLBSzIAQVkqk',
    appId: '1:576503526807:android:8b01290c6a28c6c32300d2',
    messagingSenderId: '576503526807',
    projectId: 'login-radha',
    storageBucket: 'login-radha.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBWXVr6Y2Q73x9y6SueItUfie5H7r2NCAU',
    appId: '1:576503526807:ios:9ecf2c3027a9fe362300d2',
    messagingSenderId: '576503526807',
    projectId: 'login-radha',
    storageBucket: 'login-radha.firebasestorage.app',
    iosBundleId: 'com.example.retaillite',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: '1:000000000000:macos:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    iosBundleId: 'com.example.retaillite',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAA5Y-43RM2IItOsWpbygeHQhVbU2zFe48',
    appId: '1:576503526807:web:23cf36d320396b512300d2',
    messagingSenderId: '576503526807',
    projectId: 'login-radha',
    authDomain: 'login-radha.firebaseapp.com',
    storageBucket: 'login-radha.firebasestorage.app',
  );
}
