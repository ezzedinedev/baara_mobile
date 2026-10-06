// Configuration Firebase générée manuellement depuis
// android/app/google-services.json et ios/Runner/GoogleService-Info.plist.
// Projet : flutter-ai-playground-e84b5 (à remplacer par le projet prod Baara
// avant publication store si besoin).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions ne supporte pas le web — configurez Firebase '
        'pour cette plateforme.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions n\'a pas été configuré pour macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions n\'a pas été configuré pour Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions n\'a pas été configuré pour Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne supporte pas cette plateforme.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAd9ZXjxb9TZqZQgCXi73DrXnvpzW-TdJQ',
    appId: '1:474816588506:android:f832f8fa9bbcf4d45613e3',
    messagingSenderId: '474816588506',
    projectId: 'flutter-ai-playground-e84b5',
    storageBucket: 'flutter-ai-playground-e84b5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDdqh8w9sxi3NQZma02znEZA_tOSjDeLgY',
    appId: '1:474816588506:ios:d74b661af5cbdc845613e3',
    messagingSenderId: '474816588506',
    projectId: 'flutter-ai-playground-e84b5',
    storageBucket: 'flutter-ai-playground-e84b5.firebasestorage.app',
    iosBundleId: 'com.stratetix.baara',
  );
}
