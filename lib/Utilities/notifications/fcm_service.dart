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

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final doc = _db
          .collection('RiderProfiles')
          .doc(email.toLowerCase())
          .collection('tokens')
          .doc(token);

      await doc.set(
        {
          'token': token,
          'platform': kIsWeb
              ? 'web'
              : Platform.isAndroid
                  ? 'android'
                  : Platform.isIOS
                      ? 'ios'
                      : 'other',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Keep Firestore up to date on rotation
      _messaging.onTokenRefresh.listen((newToken) async {
        final td = _db
            .collection('RiderProfiles')
            .doc(email.toLowerCase())
            .collection('tokens')
            .doc(newToken);
        await td.set(
          {
            'token': newToken,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (_) {
      // Silently ignore; notifications are best-effort
    }
  }
}
