import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_store.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/firebase_dictionary_store.dart';

export 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_store.dart';

/// Provider-independent facade and reactive cache for the Equestrian
/// Dictionary.
///
/// Delegates persistence and server actions to a [DictionaryStore] (defaulting
/// to [FirebaseDictionaryStore] when no custom store is configured).
class DictionaryRepository {
  DictionaryRepository({
    DictionaryStore? store,
    FirebaseFirestore? firestore,
    AssetBundle? bundle,
  }) : firestore = firestore,
       bundle = bundle,
       _store =
           store ??
           (firestore == null && bundle == null && defaultStore != null
               ? defaultStore!
               : FirebaseDictionaryStore(firestore: firestore, bundle: bundle));

  /// Convenience constructor accepting an untyped legacy Firestore reference so
  /// UI screens do not need to import `cloud_firestore`.
  factory DictionaryRepository.withLegacyFirestore(
    Object? firestore, {
    AssetBundle? bundle,
  }) => DictionaryRepository(
    store: FirebaseDictionaryStore.fromLegacyFirestore(
      firestore,
      bundle: bundle,
    ),
  );

  final FirebaseFirestore? firestore;
  final AssetBundle? bundle;
  final DictionaryStore _store;

  /// Optional backend-neutral default store (e.g., an alternative backend
  /// adapter or [InMemoryDictionaryStore] in tests). When `null`, defaults to
  /// [FirebaseDictionaryStore].
  static DictionaryStore? defaultStore;

  static Future<List<DictionaryEntry>>? _cachedEntriesFuture;
  static Future<List<DictionaryEntry>>? _refreshingFuture;
  static List<DictionaryEntry>? _resolvedCachedEntries;
  static DateTime? _cachedAt;

  /// How long cached published entries remain fresh before a single
  /// deduplicated background refresh runs on next access.
  static Duration cacheTtl = const Duration(minutes: 10);

  /// Clock hook for deterministic TTL testing.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  /// Reactive notifier updated whenever the shared published Dictionary
  /// catalogue is loaded or refreshed. Mounted `ContextualDictionaryText`
  /// widgets listen to this so already-open screens update without restart.
  static final ValueNotifier<List<DictionaryEntry>?> entriesNotifier =
      ValueNotifier<List<DictionaryEntry>?>(null);

  /// Synchronously returns cached entries if already loaded in this session.
  static List<DictionaryEntry>? get peekCachedEntries => _resolvedCachedEntries;

  /// Whether this repository instance is backed by the shared default store
  /// (and should keep the global reactive cache synchronized).
  bool get usesDefaultBackend {
    if (defaultStore != null) {
      return identical(_store, defaultStore);
    }
    return _store is FirebaseDictionaryStore && _store.usesDefaultBackend;
  }

  /// Returns whether the in-memory cache is missing or past [cacheTtl].
  static bool get isCacheStale {
    final cachedAt = _cachedAt;
    if (_resolvedCachedEntries == null || cachedAt == null) return true;
    return clock().difference(cachedAt) >= cacheTtl;
  }

  static List<DictionaryEntry> _storeCache(List<DictionaryEntry> items) {
    final publishedOnly = List<DictionaryEntry>.unmodifiable(
      items.where((entry) => entry.published),
    );
    _resolvedCachedEntries = publishedOnly;
    _cachedAt = clock();
    entriesNotifier.value = publishedOnly;
    return publishedOnly;
  }

  /// Returns published Dictionary entries cached in memory for contextual
  /// highlighting across Skill Tree and Resources without repeated network or
  /// asset reads.
  ///
  /// Uses a stale-while-revalidate strategy: if cached entries are older than
  /// [cacheTtl], returns the current entries immediately while triggering one
  /// deduplicated background refresh that notifies [entriesNotifier].
  static Future<List<DictionaryEntry>> cachedEntries({
    DictionaryStore? store,
    FirebaseFirestore? firestore,
    AssetBundle? bundle,
    bool forceRefresh = false,
  }) {
    if (store != null || firestore != null || bundle != null) {
      return DictionaryRepository(
        store: store,
        firestore: firestore,
        bundle: bundle,
      ).load();
    }
    if (forceRefresh) {
      return refreshCachedEntries();
    }
    if (_resolvedCachedEntries != null) {
      if (isCacheStale) {
        unawaited(refreshCachedEntries());
      }
      return Future.value(_resolvedCachedEntries!);
    }
    return _cachedEntriesFuture ??= DictionaryRepository()
        .load()
        .then(_storeCache)
        .catchError((Object _) {
          _cachedEntriesFuture = null;
          return _resolvedCachedEntries ?? const <DictionaryEntry>[];
        });
  }

  /// Forces a single deduplicated reload of the published Dictionary catalogue
  /// and notifies all listening widgets via [entriesNotifier].
  ///
  /// Preserves existing cached entries if the refresh fails due to a transient
  /// network error.
  static Future<List<DictionaryEntry>> refreshCachedEntries({
    DictionaryStore? store,
    FirebaseFirestore? firestore,
    AssetBundle? bundle,
  }) {
    return _refreshingFuture ??=
        DictionaryRepository(store: store, firestore: firestore, bundle: bundle)
            .load()
            .then(_storeCache)
            .catchError((Object _) {
              return _resolvedCachedEntries ?? const <DictionaryEntry>[];
            })
            .whenComplete(() {
              _refreshingFuture = null;
            });
  }

  /// Clears the session cache (used after admin publication or in tests).
  static void invalidateCache() {
    _cachedEntriesFuture = null;
    _refreshingFuture = null;
    _resolvedCachedEntries = null;
    _cachedAt = null;
    entriesNotifier.value = null;
  }

  Future<Map<String, String>> skillLabels() => _store.loadSkillLabels();

  Future<List<DictionaryEntry>> load() async {
    final entries = await _store.loadPublishedEntries();
    if (usesDefaultBackend) {
      return _storeCache(entries);
    }
    return entries;
  }

  Future<void> call(String function, Map<String, dynamic> data) =>
      _store.executeAction(function, data);

  Future<List<Map<String, dynamic>>> loadSuggestions({int limit = 100}) =>
      _store.loadSuggestions(limit: limit);

  Future<List<Map<String, dynamic>>> loadMySuggestions(
    String contributorUid, {
    int limit = 50,
  }) => _store.loadMySuggestions(contributorUid, limit: limit);

  Future<List<DictionaryEntry>> loadDrafts() => _store.loadDrafts();

  Future<DictionaryEntry?> loadDraft(String entryId) =>
      _store.loadDraft(entryId);

  Future<List<Map<String, dynamic>>> loadSuggestionHistory(
    String suggestionId, {
    int limit = 30,
  }) => _store.loadSuggestionHistory(suggestionId, limit: limit);

  Future<List<Map<String, dynamic>>> loadEntryRevisions(String entryId) =>
      _store.loadEntryRevisions(entryId);

  static DictionaryEntry? resolve(List<DictionaryEntry> entries, String value) {
    final needle = value.toLowerCase().trim();
    final published = entries.where((entry) => entry.published);
    for (final entry in published) {
      if (entry.id == needle || entry.slug == needle) return entry;
    }
    final meanings = published
        .where(
          (entry) => [
            entry.term,
            ...entry.strings('synonyms'),
          ].any((name) => name.toLowerCase() == needle),
        )
        .toList();
    if (meanings.length == 1) return meanings.single;
    return null;
  }

  static List<DictionaryEntry> search(
    List<DictionaryEntry> entries, {
    String query = '',
    String? category,
    String? letter,
  }) {
    final needle = query.trim().toLowerCase();
    return entries.where((entry) {
        return entry.published &&
            (category == null ||
                entry.strings('categories').contains(category)) &&
            (letter == null || entry.term.toUpperCase().startsWith(letter)) &&
            (needle.isEmpty ||
                [
                  entry.term,
                  entry.definition,
                  ...entry.strings('synonyms'),
                ].any((text) => text.toLowerCase().contains(needle)));
      }).toList()
      ..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
  }

  static String newSubmissionId() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
