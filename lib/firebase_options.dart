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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYp3W28qFEqvcG5EemTyL2rlf0Crar4II',
    appId: '1:386089956000:android:f6a9cfa54599383e0a0fc5',
    messagingSenderId: '386089956000',
    projectId: 'byte-and-bite-1f169',
    storageBucket: 'byte-and-bite-1f169.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAYp3W28qFEqvcG5EemTyL2rlf0Crar4II',
    appId: '1:386089956000:web:000000000000000000000000', 
    messagingSenderId: '386089956000',
    projectId: 'byte-and-bite-1f169',
    storageBucket: 'byte-and-bite-1f169.firebasestorage.app',
    authDomain: 'byte-and-bite-1f169.firebaseapp.com',
  );
}