import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7aPMD23kKoOe3aCI5HEG5MgxXRJ21hZg',
    appId: '1:412357819576:android:a06eeee71561b5178a084d',
    messagingSenderId: '412357819576',
    projectId: 'orushops-110',
    storageBucket: 'orushops-110.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_GCM_SENDER_ID',
    projectId: 'REPLACE_WITH_FIREBASE_PROJECT_ID',
    databaseURL: 'https://REPLACE_WITH_FIREBASE_PROJECT_ID.firebaseio.com',
    storageBucket: 'REPLACE_WITH_FIREBASE_PROJECT_ID.appspot.com',
    iosBundleId: 'com.retaildost.orushops',
  );
}
