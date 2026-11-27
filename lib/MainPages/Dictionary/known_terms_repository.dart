import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local, Firebase-free repository persisting Dictionary entry IDs that
/// the user has marked as already understood ("I know this term").
///
/// Known terms are stored strictly on the local device/browser via
/// [SharedPreferences] (not synchronized across devices, requires no sign-in,
/// triggers zero Firestore/Cloud Functions operations, and contains zero
/// personal information).
class KnownTermsRepository extends ChangeNotifier {
  KnownTermsRepository({
    SharedPreferences? preferences,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _injectedPreferences = preferences,
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  /// SharedPreferences key storing the local JSON-encoded list of canonical
  /// Dictionary entry IDs.
  static const String storageKey = 'dictionary_known_terms_v1';

  /// Default application-wide instance backed by [SharedPreferences].
  static final KnownTermsRepository instance = KnownTermsRepository();

  final SharedPreferences? _injectedPreferences;
  final Future<SharedPreferences> Function() _preferencesLoader;

  final Set<String> _knownTermIds = <String>{};
  bool _loaded = false;
  Future<void>? _loadingFuture;

  /// Whether the local preference store has completed its initial load.
  bool get isLoaded => _loaded;

  /// Number of known canonical Dictionary entry IDs.
  int get count => _knownTermIds.length;

  /// Loads stored known terms from local preferences into memory.
  ///
  /// Safe to call repeatedly; malformed or non-string stored values are ignored
  /// without throwing.
  Future<void> load() async {
    final pending = _loadingFuture ??= _readFromPrefs();
    await pending;
  }

  /// Ensures preferences have been loaded once without re-reading disk on
  /// every contextual match.
  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return load();
  }

  /// Returns whether canonical Dictionary entry [termId] is marked as known.
  bool isKnown(String termId) {
    final normalized = termId.trim();
    if (normalized.isEmpty) return false;
    return _knownTermIds.contains(normalized);
  }

  /// Returns an unmodifiable snapshot of all known canonical term IDs.
  Set<String> getKnownTerms() => Set<String>.unmodifiable(_knownTermIds);

  /// Marks canonical [termId] as known and notifies listeners immediately.
  Future<void> markKnown(String termId) async {
    await ensureLoaded();
    final normalized = termId.trim();
    if (normalized.isEmpty) return;
    if (!_knownTermIds.add(normalized)) return;
    notifyListeners();
    await _persistToPrefs();
  }

  /// Removes canonical [termId] from the known set and notifies listeners.
  Future<void> markUnknown(String termId) async {
    await ensureLoaded();
    final normalized = termId.trim();
    if (normalized.isEmpty) return;
    if (!_knownTermIds.remove(normalized)) return;
    notifyListeners();
    await _persistToPrefs();
  }

  /// Toggles known status for canonical [termId].
  Future<void> toggleKnown(String termId) {
    if (isKnown(termId)) {
      return markUnknown(termId);
    }
    return markKnown(termId);
  }

  /// Clears all locally stored known terms and notifies listeners immediately.
  Future<void> clearKnownTerms() async {
    await ensureLoaded();
    if (_knownTermIds.isNotEmpty) {
      _knownTermIds.clear();
      notifyListeners();
    }
    try {
      final prefs = _injectedPreferences ?? await _preferencesLoader();
      await prefs.remove(storageKey);
    } catch (_) {
      // Ignore storage unavailability in restricted or headless environments.
    }
  }

  /// Resets in-memory state for deterministic unit and widget tests.
  @visibleForTesting
  void resetForTest() {
    _knownTermIds.clear();
    _loaded = false;
    _loadingFuture = null;
    notifyListeners();
  }

  Future<void> _readFromPrefs() async {
    try {
      final prefs = _injectedPreferences ?? await _preferencesLoader();
      final parsed = _extractIds(prefs);
      _knownTermIds
        ..clear()
        ..addAll(parsed);
      _loaded = true;
    } catch (_) {
      _loaded = true;
    } finally {
      _loadingFuture = null;
      if (_knownTermIds.isNotEmpty) {
        notifyListeners();
      }
    }
  }

  Future<void> _persistToPrefs() async {
    try {
      final prefs = _injectedPreferences ?? await _preferencesLoader();
      final sorted = _knownTermIds.toList()..sort();
      await prefs.setString(storageKey, jsonEncode(sorted));
    } catch (_) {
      // In-memory state stays updated even if disk persistence fails.
    }
  }

  static Iterable<String> _extractIds(SharedPreferences prefs) {
    final raw = prefs.get(storageKey);
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
