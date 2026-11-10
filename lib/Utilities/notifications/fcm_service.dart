import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  /// Request permission, get token, and store it under RiderProfiles/<email>/tokens/<token>
  static Future<void> ensureRegistered(String email) async {
    try {
      // Web support for FCM requires additional setup; skip by default
      if (kIsWeb) return;

      // Request permissions on iOS
      await _messaging.requestPermission();

      _messaging.onRegistered.listen((token) async {
        if (token.isEmpty) return;

        final doc = _db
            .collection('RiderProfiles')
            .doc(email.toLowerCase())
            .collection('tokens')
            .doc(token);

        await doc.set(
          {
            'token': token,
            'platform': Platform.isAndroid
                ? 'android'
                : Platform.isIOS
                    ? 'ios'
                    : 'other',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      await _messaging.register();
    } catch (_) {
      // Silently ignore; notifications are best-effort
    }
  }
}
