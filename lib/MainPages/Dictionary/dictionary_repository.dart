import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_local_cache.dart';
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
  static int? _cachedVersion;
  static int? _cachedUpdatedAtMs;
  static DateTime? _cachedAt;

  /// How long cached published entries remain fresh before a single
  /// deduplicated background refresh runs on next access.
  static Duration cacheTtl = const Duration(minutes: 30);

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

  static List<DictionaryEntry> _storeCache(
    List<DictionaryEntry> items, {
    int? version,
    int? updatedAtMs,
    bool persist = false,
  }) {
    final publishedOnly = List<DictionaryEntry>.unmodifiable(
      items.where((entry) => entry.published),
    );
    _resolvedCachedEntries = publishedOnly;
    if (version != null) _cachedVersion = version;
    if (updatedAtMs != null) _cachedUpdatedAtMs = updatedAtMs;
    _cachedAt = clock();
    entriesNotifier.value = publishedOnly;
    if (persist) {
      unawaited(
        DictionaryLocalCache.write(
          entries: publishedOnly,
          version: version,
          updatedAtMs: updatedAtMs,
        ),
      );
    }
    return publishedOnly;
  }

  Future<List<DictionaryEntry>> _loadVersionAware({
    bool forceServer = false,
  }) async {
    final store = _store;
    if (store is FirebaseDictionaryStore) {
      var seedEntries = _resolvedCachedEntries;
      var seedVersion = _cachedVersion;
      var seedUpdatedAtMs = _cachedUpdatedAtMs;
      if (!forceServer && seedEntries == null && usesDefaultBackend) {
        final local = await DictionaryLocalCache.read();
        if (local != null) {
          seedEntries = local.entries;
          seedVersion = local.version;
          seedUpdatedAtMs = local.updatedAtMs;
          _resolvedCachedEntries ??= local.entries;
          entriesNotifier.value ??= local.entries;
        }
      }
      final result = await store.loadPublishedEntriesVersioned(
        cachedEntries: seedEntries,
        cachedVersion: seedVersion,
        cachedUpdatedAtMs: seedUpdatedAtMs,
        forceServer: forceServer,
      );
      if (usesDefaultBackend) {
        return _storeCache(
          result.entries,
          version: result.version,
          updatedAtMs: result.updatedAtMs,
          persist: result.version != null || result.updatedAtMs != null,
        );
      }
      return result.entries;
    }
    return load();
  }

  /// Returns published Dictionary entries cached in memory and persisted
  /// locally for contextual highlighting across Skill Tree, Dictionary, and
  /// Resources without repeated network or asset reads.
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
        ._loadVersionAware()
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
    final repo = DictionaryRepository(
      store: store,
      firestore: firestore,
      bundle: bundle,
    );
    final loader = repo.usesDefaultBackend
        ? repo._loadVersionAware()
        : repo.load().then(_storeCache);
    return _refreshingFuture ??= loader
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
    _cachedVersion = null;
    _cachedUpdatedAtMs = null;
    _cachedAt = null;
    entriesNotifier.value = null;
    unawaited(DictionaryLocalCache.clear());
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

  Future<void> approveAndPublishImages({
    required String suggestionId,
    required int expectedRevision,
    required List<Map<String, dynamic>> imageDecisions,
    String? heroImageId,
    String note = '',
  }) => _store.executeAction('editDictionary', {
    'action': 'approve_and_publish',
    'id': suggestionId,
    'expectedRevision': expectedRevision,
    'imageDecisions': imageDecisions,
    if (heroImageId != null && heroImageId.isNotEmpty)
      'heroImageId': heroImageId,
    'note': note,
  });

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

  Future<Map<String, Map<String, dynamic>>> resolveContributorIdentities(
    List<String> uids,
  ) => _store.resolveContributorIdentities(uids);

  Future<Map<String, Map<String, dynamic>>> loadContributorModerationStatuses(
    List<String> uids,
  ) => _store.loadContributorModerationStatuses(uids);

  Future<List<Map<String, dynamic>>> loadContributorModerationHistory(
    String uid, {
    int limit = 30,
  }) => _store.loadContributorModerationHistory(uid, limit: limit);

  Future<void> suspendContributor({
    required String uid,
    required String reason,
  }) => _store.executeAction('editDictionary', {
    'action': 'suspend_contributor',
    'uid': uid,
    'reason': reason,
  });

  Future<void> restoreContributor({required String uid, String reason = ''}) =>
      _store.executeAction('editDictionary', {
        'action': 'restore_contributor',
        'uid': uid,
        'reason': reason,
      });

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
