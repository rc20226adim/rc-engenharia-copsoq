// File generated manually with Firebase configuration
// Project: rc-engenharia-psicossocial

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
          'iOS não está configurado. Use Android ou Web.',
        );
      default:
        return web;
    }
  }

  // Configuração Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCdhzFNhrvV3FQ4CH6gNHm6WYuERMxtuDM',
    authDomain: 'rc-engenharia-psicossocial.firebaseapp.com',
    projectId: 'rc-engenharia-psicossocial',
    storageBucket: 'rc-engenharia-psicossocial.firebasestorage.app',
    messagingSenderId: '867553371635',
    appId: '1:867553371635:web:51653696e002881ca81e86',
    measurementId: 'G-X2F2PSLV3R',
  );

  // Configuração Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWb0BMs3LharPQrFMBIWBYuO5qA445ZuI',
    appId: '1:867553371635:android:e4524949127cdc60a81e86',
    messagingSenderId: '867553371635',
    projectId: 'rc-engenharia-psicossocial',
    storageBucket: 'rc-engenharia-psicossocial.firebasestorage.app',
  );
}
