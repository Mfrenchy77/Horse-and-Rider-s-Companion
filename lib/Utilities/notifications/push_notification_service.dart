/// Backend-neutral interface for registering a device for push notifications.
// ignore: one_member_abstracts
abstract interface class PushNotificationService {
  /// Registers the current device for push notifications for [userEmail].
  Future<void> ensureRegistered(String userEmail);
}
