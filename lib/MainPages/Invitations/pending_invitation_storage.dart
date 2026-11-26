import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

/// Persists an incoming invitation token across authentication flows, email
/// verification, page refreshes, and browser restarts without relying solely on
/// in-memory state.
class PendingInvitationStorage {
  PendingInvitationStorage._();

  static const String _tokenKey = 'PendingInvitationToken';
  static const String _savedAtKey = 'PendingInvitationSavedAtMs';
  static const Duration _maxAge = Duration(days: 7);
  static final RegExp _tokenRegex = RegExp(r'^[A-Za-z0-9_-]{16,128}$');

  /// Optional in-memory override map for pure unit/widget tests that do not
  /// initialize [SharedPrefs].
  static Map<String, String>? debugOverride;

  /// Guards against redirect loops within an active session when restoring a
  /// pending invitation for a given `(uid, token)` pair.
  static String? _lastAutoRedirectedKey;

  /// Returns `true` when [token] matches the expected URL-safe token format.
  static bool isValidTokenFormat(String? token) {
    if (token == null) return false;
    return _tokenRegex.hasMatch(token.trim());
  }

  /// Saves [token] persistently so it survives registration, sign-in, email
  /// verification, and page reloads.
  static Future<void> saveToken(String token, {DateTime? now}) async {
    final trimmed = token.trim();
    if (!isValidTokenFormat(trimmed)) return;
    final nowMs = (now ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    final override = debugOverride;
    if (override != null) {
      override[_tokenKey] = trimmed;
      override[_savedAtKey] = '$nowMs';
      return;
    }
    try {
      await SharedPrefs().setString(_tokenKey, trimmed);
      await SharedPrefs().setString(_savedAtKey, '$nowMs');
    } catch (_) {
      // Fall back quietly if SharedPrefs was not initialized in a test harness.
    }
  }

  /// Reads the stored pending invitation token if present and not expired.
  static String? readToken({DateTime? now}) {
    String? rawToken;
    String? rawSavedAt;
    final override = debugOverride;
    if (override != null) {
      rawToken = override[_tokenKey];
      rawSavedAt = override[_savedAtKey];
    } else {
      try {
        rawToken = SharedPrefs().getString(_tokenKey);
        rawSavedAt = SharedPrefs().getString(_savedAtKey);
      } catch (_) {
        return null;
      }
    }

    if (!isValidTokenFormat(rawToken)) {
      return null;
    }
    final savedAtMs = int.tryParse(rawSavedAt ?? '');
    if (savedAtMs != null) {
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        savedAtMs,
        isUtc: true,
      );
      final current = now ?? DateTime.now().toUtc();
      if (current.difference(savedAt) > _maxAge) {
        return null;
      }
    }
    return rawToken!.trim();
  }

  /// Clears any saved pending invitation token and resets session loop guards.
  static Future<void> clearToken() async {
    _lastAutoRedirectedKey = null;
    final override = debugOverride;
    if (override != null) {
      override
        ..remove(_tokenKey)
        ..remove(_savedAtKey);
      return;
    }
    try {
      await SharedPrefs().remove(_tokenKey);
      await SharedPrefs().remove(_savedAtKey);
    } catch (_) {
      // Ignore if SharedPrefs is uninitialized in a test harness.
    }
  }

  /// Returns `true` if automatic post-auth restoration should navigate `(uid,
  /// token)` back to `/invite/<token>`.
  static bool shouldAutoRedirect({required String uid, required String token}) {
    if (uid.isEmpty || !isValidTokenFormat(token)) return false;
    return _lastAutoRedirectedKey != '$uid:${token.trim()}';
  }

  /// Marks `(uid, token)` as having triggered its automatic redirect this
  /// session so it will not loop repeatedly.
  static void markAutoRedirected({required String uid, required String token}) {
    if (uid.isEmpty || !isValidTokenFormat(token)) return;
    _lastAutoRedirectedKey = '$uid:${token.trim()}';
  }

  /// Resets in-memory loop guards (for tests or sign-out).
  static void resetSessionGuards() {
    _lastAutoRedirectedKey = null;
  }
}
