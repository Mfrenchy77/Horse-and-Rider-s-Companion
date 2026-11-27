import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local, Firebase-free repository persisting Dictionary entry IDs that
/// an authenticated user has marked as already understood ("I know this term").
///
/// Known terms are stored strictly on the local device/browser via
/// [SharedPreferences], namespaced by authenticated Firebase user UID
/// (`dictionary_known_terms_v1_<uid>`). Guests cannot mark terms as known and
/// always see normal contextual highlighting. Account switches clear in-memory
/// state immediately and load only the newly signed-in account's local
/// preferences without altering or exposing other accounts' stored data.
class KnownTermsRepository extends ChangeNotifier {
  KnownTermsRepository({
    SharedPreferences? preferences,
    Future<SharedPreferences> Function()? preferencesLoader,
    String? initialUserId,
  }) : _injectedPreferences = preferences,
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       _activeUserId = _normalizeUserId(initialUserId),
       _loaded = _normalizeUserId(initialUserId) == null;

  /// SharedPreferences key prefix storing each signed-in user's local
  /// JSON-encoded list of canonical Dictionary entry IDs.
  static const String storageKeyPrefix = 'dictionary_known_terms_v1_';

  /// Returns the UID-namespaced [SharedPreferences] key for [uid].
  static String storageKeyForUser(String uid) =>
      '$storageKeyPrefix${uid.trim()}';

  /// Default application-wide instance backed by [SharedPreferences].
  static final KnownTermsRepository instance = KnownTermsRepository();

  final SharedPreferences? _injectedPreferences;
  final Future<SharedPreferences> Function() _preferencesLoader;

  final Set<String> _knownTermIds = <String>{};
  String? _activeUserId;
  int _loadGeneration = 0;
  bool _loaded;
  Future<void>? _loadingFuture;

  static String? _normalizeUserId(String? userId) {
    final trimmed = userId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  /// Authenticated UID currently bound to this repository, or `null` for
  /// guests / signed-out sessions.
  String? get activeUserId => _activeUserId;

  /// Whether known-term personalization is enabled for the active session
  /// (requires an authenticated, non-guest user UID).
  bool get isEnabled => _activeUserId != null;

  /// The [SharedPreferences] key for the active user, or `null` in guest mode.
  String? get currentStorageKey =>
      _activeUserId == null ? null : storageKeyForUser(_activeUserId!);

  /// Whether the local preference store has completed its initial load for the
  /// active user (always `true` in guest mode).
  bool get isLoaded => _loaded;

  /// Number of known canonical Dictionary entry IDs for the active user.
  int get count => _activeUserId == null ? 0 : _knownTermIds.length;

  /// Switches the active account context without deleting stored preferences
  /// for previously signed-in accounts.
  ///
  /// Passing `null` or an empty string enters guest mode synchronously,
  /// clearing in-memory state so normal highlighting returns immediately.
  Future<void> setActiveUserId(String? userId) async {
    final normalized = _normalizeUserId(userId);
    if (normalized == _activeUserId) {
      if (normalized == null) {
        _knownTermIds.clear();
        _loaded = true;
        return;
      }
      await ensureLoaded();
      return;
    }

    _loadGeneration++;
    _activeUserId = normalized;
    _knownTermIds.clear();
    _loadingFuture = null;

    if (normalized == null) {
      _loaded = true;
      notifyListeners();
      return;
    }

    _loaded = false;
    notifyListeners();
    await load();
  }

  /// Loads stored known terms from local preferences for the active signed-in
  /// user into memory.
  ///
  /// In guest mode this is a no-op so guests cannot inherit local state.
  /// Malformed or non-string stored values are ignored without throwing.
  Future<void> load() async {
    final uid = _activeUserId;
    if (uid == null) {
      _knownTermIds.clear();
      _loaded = true;
      return;
    }
    final generation = _loadGeneration;
    final pending = _loadingFuture ??= _readFromPrefs(generation, uid);
    await pending;
  }

  /// Ensures preferences have been loaded once for the active signed-in user
  /// without re-reading disk on every contextual match.
  Future<void> ensureLoaded() {
    if (_activeUserId == null) {
      _loaded = true;
      return Future<void>.value();
    }
    if (_loaded) return Future<void>.value();
    return load();
  }

  /// Returns whether canonical Dictionary entry [termId] is marked as known
  /// for the active signed-in user (always `false` in guest mode).
  bool isKnown(String termId) {
    if (_activeUserId == null) return false;
    final normalized = termId.trim();
    if (normalized.isEmpty) return false;
    return _knownTermIds.contains(normalized);
  }

  /// Returns an unmodifiable snapshot of all known canonical term IDs for the
  /// active signed-in user (always empty in guest mode).
  Set<String> getKnownTerms() {
    if (_activeUserId == null) return const <String>{};
    return Set<String>.unmodifiable(_knownTermIds);
  }

  /// Marks canonical [termId] as known for the active signed-in user and
  /// notifies listeners immediately. No-op in guest mode.
  Future<void> markKnown(String termId) async {
    final uid = _activeUserId;
    if (uid == null) return;
    await ensureLoaded();
    if (_activeUserId != uid) return;
    final normalized = termId.trim();
    if (normalized.isEmpty) return;
    if (!_knownTermIds.add(normalized)) return;
    final snapshot = _knownTermIds.toList()..sort();
    notifyListeners();
    await _persistToPrefs(uid, snapshot);
  }

  /// Removes canonical [termId] from the active signed-in user's known set
  /// and notifies listeners. No-op in guest mode.
  Future<void> markUnknown(String termId) async {
    final uid = _activeUserId;
    if (uid == null) return;
    await ensureLoaded();
    if (_activeUserId != uid) return;
    final normalized = termId.trim();
    if (normalized.isEmpty) return;
    if (!_knownTermIds.remove(normalized)) return;
    final snapshot = _knownTermIds.toList()..sort();
    notifyListeners();
    await _persistToPrefs(uid, snapshot);
  }

  /// Toggles known status for canonical [termId] when signed in. No-op for
  /// guests.
  Future<void> toggleKnown(String termId) {
    if (_activeUserId == null) return Future<void>.value();
    if (isKnown(termId)) {
      return markUnknown(termId);
    }
    return markKnown(termId);
  }

  /// Clears all locally stored known terms for the active signed-in account
  /// only and notifies listeners immediately. Leaves other accounts' keys
  /// untouched. No-op in guest mode.
  Future<void> clearKnownTerms() async {
    final uid = _activeUserId;
    if (uid == null) return;
    await ensureLoaded();
    if (_activeUserId != uid) return;
    if (_knownTermIds.isNotEmpty) {
      _knownTermIds.clear();
      notifyListeners();
    }
    try {
      final prefs = _injectedPreferences ?? await _preferencesLoader();
      if (_activeUserId != uid) return;
      await prefs.remove(storageKeyForUser(uid));
    } catch (_) {
      // Ignore storage unavailability in restricted or headless environments.
    }
  }

  /// Resets in-memory state for deterministic unit and widget tests.
  @visibleForTesting
  void resetForTest({String? activeUserId}) {
    _loadGeneration++;
    _activeUserId = _normalizeUserId(activeUserId);
    _knownTermIds.clear();
    _loaded = _activeUserId == null;
    _loadingFuture = null;
    notifyListeners();
  }

  Future<void> _readFromPrefs(int generation, String uid) async {
    var shouldNotify = false;
    try {
      final prefs = _injectedPreferences ?? await _preferencesLoader();
      if (_loadGeneration != generation || _activeUserId != uid) return;
      final parsed = _extractIds(prefs, storageKeyForUser(uid));
      _knownTermIds
        ..clear()
        ..addAll(parsed);
      _loaded = true;
      shouldNotify = _knownTermIds.isNotEmpty;
    } catch (_) {
      if (_loadGeneration != generation || _activeUserId != uid) return;
      _loaded = true;
    } finally {
      if (_loadGeneration == generation && _activeUserId == uid) {
        _loadingFuture = null;
        if (shouldNotify) {
          notifyListeners();
        }
      }
    }
  }

  Future<void> _persistToPrefs(String uid, List<String> sortedIds) async {
    try {
      final prefs = _injectedPreferences ?? await _preferencesLoader();
      if (_activeUserId != uid) return;
      await prefs.setString(storageKeyForUser(uid), jsonEncode(sortedIds));
    } catch (_) {
      // In-memory state stays updated even if disk persistence fails.
    }
  }

  static Iterable<String> _extractIds(SharedPreferences prefs, String key) {
    final raw = prefs.get(key);
    if (raw == null) return const <String>[];

    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return const <String>[];
      final decoded = jsonDecode(trimmed);
      if (decoded is! List) return const <String>[];
      return _normalizeList(decoded);
    }
    if (raw is List) {
      return _normalizeList(raw);
    }
    return const <String>[];
  }

  static Iterable<String> _normalizeList(List<dynamic> items) sync* {
    for (final item in items) {
      if (item is! String) continue;
      final normalized = item.trim();
      if (normalized.isNotEmpty) {
        yield normalized;
      }
    }
  }
}
