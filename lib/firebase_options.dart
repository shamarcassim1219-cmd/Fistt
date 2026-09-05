import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvZlqUl0xyRJTVZEhorDNGoDjfLRAue8U',
    appId: '1:431075850007:android:68e46503e3f46da7f2041a',
    messagingSenderId: '431075850007',
    projectId: 'game-store-61a66',
    storageBucket: 'game-store-61a66.firebasestorage.app',
  );
}
