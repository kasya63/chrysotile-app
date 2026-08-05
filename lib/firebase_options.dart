// Generated from google-services.json / GoogleService-Info.plist.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static bool get isConfigured => true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for Chrysotile.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBw1DN4yKzaHOlVQbGBWxCCUbOl1UulLv4',
    appId: '1:763809316429:android:63dcd9d19613c39b312604',
    messagingSenderId: '763809316429',
    projectId: 'chrysotile-app',
    storageBucket: 'chrysotile-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCOxpu7M8OXIW7VdPzV2m7EcOPpe2VZWPE',
    appId: '1:763809316429:ios:26e083ec429b400a312604',
    messagingSenderId: '763809316429',
    projectId: 'chrysotile-app',
    storageBucket: 'chrysotile-app.firebasestorage.app',
    iosBundleId: 'kz.chrysotile.chrysotileApp',
  );
}
