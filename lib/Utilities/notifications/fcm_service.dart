import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:horseandriderscompanion/Utilities/notifications/push_notification_service.dart';

class FcmService implements PushNotificationService {
  const FcmService();

  static StreamSubscription<String>? _onRegisteredSubscription;

  @override
  Future<void> ensureRegistered(String userEmail) {
    return FcmService.registerDevice(userEmail);
  }

  /// Returns the normalized platform identifier for FCM token records.
  @visibleForTesting
  static String platformName([TargetPlatform? platform]) {
    final target = platform ?? defaultTargetPlatform;
    return switch (target) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };
  }

  /// Request permission, get token, and store it under
  /// `RiderProfiles/<email>/tokens/<token>`.
  static Future<void> registerDevice(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (kIsWeb || normalizedEmail.isEmpty) return;

      final messaging = FirebaseMessaging.instance;
      final db = FirebaseFirestore.instance;

      // Request permissions on iOS
      await messaging.requestPermission();

      await _onRegisteredSubscription?.cancel();
      _onRegisteredSubscription = messaging.onRegistered.listen((token) async {
        if (token.isEmpty) return;

        final doc = db
            .collection('RiderProfiles')
            .doc(normalizedEmail)
            .collection('tokens')
            .doc(token);

        await doc.set(
          {
            'token': token,
            'platform': platformName(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      await messaging.register();
    } catch (_) {
      // Silently ignore; notifications are best-effort
    }
  }
}
