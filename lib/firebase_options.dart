import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web configuration is not set up.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBu5rAU96DRkWMD3UISpHx4yADFWFpRR_E',
    appId: '1:873208891729:android:72129081db496546d4eb70',
    messagingSenderId: '873208891729',
    projectId: 'mw-projects-ecfc4',
    storageBucket: 'mw-projects-ecfc4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUx28wcQrkxQGjqVlYomRJdP8ED1T_L4I',
    appId: '1:873208891729:ios:15f09556879e9db8d4eb70',
    messagingSenderId: '873208891729',
    projectId: 'mw-projects-ecfc4',
    storageBucket: 'mw-projects-ecfc4.firebasestorage.app',
    iosBundleId: 'com.mw.barbershop.dev',
  );
}
