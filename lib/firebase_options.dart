import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDldtjCAzG1OibYw9t2aaG72rGfDi1_G08',
    appId: '1:354593690287:android:9ab9bc9500460aca1a3a5a',
    messagingSenderId: '354593690287',
    projectId: 'mygame-b087a',
    storageBucket: 'mygame-b087a.firebasestorage.app',
  );
}
