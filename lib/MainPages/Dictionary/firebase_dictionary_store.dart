import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:horseandriderscompanion/Initialization/firebase_emulators.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_store.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:http/http.dart' as http;

/// Firebase (Cloud Firestore + Cloud Functions + App Check) adapter for
/// [DictionaryStore].
///
/// Isolates all Firebase SDK dependencies for the Equestrian Dictionary so
/// UI widgets, matcher logic, and reactive caching remain backend-neutral.
class FirebaseDictionaryStore implements DictionaryStore {
  FirebaseDictionaryStore({this.firestore, this.bundle});

  /// Convenience factory accepting an untyped legacy `FirebaseFirestore?`
  /// reference without forcing callers to import `cloud_firestore`.
  factory FirebaseDictionaryStore.fromLegacyFirestore(
    Object? firestore, {
    AssetBundle? bundle,
  }) => FirebaseDictionaryStore(
    firestore: firestore is FirebaseFirestore ? firestore : null,
    bundle: bundle,
  );

  final FirebaseFirestore? firestore;
  final AssetBundle? bundle;
  static bool _appCheckActivated = false;

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  bool get usesDefaultBackend => firestore == null && bundle == null;

  @override
  Future<Map<String, String>> loadSkillLabels() async {
    final skills = await AssetCurriculumV2Loader(bundle: bundle).loadSkills();
    return {
      for (final skill in skills)
        skill.id:
            '${skill.subject.name == 'horse' ? 'Horse' : 'Rider'} · '
            '${skill.name}',
    };
  }

  @override
  Future<List<DictionaryEntry>> loadPublishedEntries() async {
    if (firestore != null || Firebase.apps.isNotEmpty) {
      final db = _db;
      // A manifest distinguishes an intentionally empty catalogue from the
      // initial bundled collection before server publication begins.
      final DocumentSnapshot<Map<String, dynamic>> manifest;
      try {
        manifest = await db
            .collection('DictionaryPublic')
            .doc('catalogue')
            .get(const GetOptions(source: Source.server));
      } on FirebaseException catch (error) {
        // Before Dictionary rules are deployed, the existing default-deny
        // rules reject this new path. Only this initialization check may use
        // the approved bundle on denial; published-query failures must surface.
        if (error.code != 'permission-denied') rethrow;
        DocumentSnapshot<Map<String, dynamic>>? cachedManifest;
        try {
          cachedManifest = await db
              .collection('DictionaryPublic')
              .doc('catalogue')
              .get(const GetOptions(source: Source.cache));
        } on FirebaseException {
          // Older deployments have no cached Dictionary initialization record.
        }
        // A previously observed publication must never revert to starters when
        // access is subsequently denied.
        if (cachedManifest?.data()?['initialized'] == true) rethrow;
        return _loadBundledEntries();
      }
      if (manifest.data()?['initialized'] == true) {
        final docs = await db
            .collection('DictionaryEntries')
            .where('status', isEqualTo: 'published')
            .get(const GetOptions(source: Source.server));
        return docs.docs
            .map((doc) => DictionaryEntry(doc.data()))
            .where((entry) => entry.published)
            .toList();
      }
    }
    return _loadBundledEntries();
  }

  Future<List<DictionaryEntry>> _loadBundledEntries() async {
    final json = await (bundle ?? rootBundle).loadString(
      'functions/dictionary_seed.json',
    );
    return (jsonDecode(json) as List<dynamic>)
        .map(
          (item) => DictionaryEntry(
            (item as Map).cast<String, dynamic>(),
            bundled: true,
          ),
        )
        .where((entry) => entry.published)
        .toList();
  }

  /// Uses the same authenticated callable protocol as curriculum suggestions.
  @override
  Future<void> executeAction(
    String actionName,
    Map<String, dynamic> data,
  ) async {
    const emulator = FirebaseEmulators.enabled;
    final projectId = Firebase.app().options.projectId;
    final uri = emulator
        ? Uri.http(
            '127.0.0.1:5001',
            '/demo-horse-rules/us-central1/$actionName',
          )
        : Uri.https(
            'us-central1-$projectId.cloudfunctions.net',
            '/$actionName',
          );
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    String? appCheck;
    if (!emulator && actionName == 'submitDictionarySuggestion') {
      if (!_appCheckActivated) {
        const siteKey = String.fromEnvironment('DICTIONARY_RECAPTCHA_SITE_KEY');
        if (kIsWeb && siteKey.isEmpty) {
          throw StateError(
            'Dictionary submissions are awaiting verification setup. '
            'Please try again later.',
          );
        }
        await FirebaseAppCheck.instance.activate(
          providerWeb: kIsWeb ? ReCaptchaV3Provider(siteKey) : null,
        );
        _appCheckActivated = true;
      }
      appCheck = await FirebaseAppCheck.instance.getToken();
    }
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
            if (appCheck != null) 'X-Firebase-AppCheck': appCheck,
          },
          body: jsonEncode({'data': data}),
        )
        .timeout(const Duration(seconds: 25));
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || result['error'] != null) {
      final error = result['error'] as Map<String, dynamic>?;
      throw StateError(
        error?['message'] as String? ?? 'Could not complete the request.',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadSuggestions({int limit = 100}) async {
    final snap = await _db
        .collection('DictionarySuggestions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> loadMySuggestions(
    String contributorUid, {
    int limit = 50,
  }) async {
    if (contributorUid.trim().isEmpty) return const [];
    final snap = await _db
        .collection('DictionarySuggestions')
        .where('contributorUid', isEqualTo: contributorUid)
        .limit(limit)
        .get();
    final items = snap.docs
        .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
        .toList();
    return items..sort(
      (a, b) => _sortTimestampMs(
        b['createdAt'],
      ).compareTo(_sortTimestampMs(a['createdAt'])),
    );
  }

  static int _sortTimestampMs(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  @override
  Future<List<DictionaryEntry>> loadDrafts() async {
    final snap = await _db.collection('DictionaryDrafts').get();
    return snap.docs
        .map((doc) => DictionaryEntry({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<DictionaryEntry?> loadDraft(String entryId) async {
    final snap = await _db.collection('DictionaryDrafts').doc(entryId).get();
    if (!snap.exists || snap.data() == null) return null;
    return DictionaryEntry({...snap.data()!, 'id': snap.id});
  }

  @override
  Future<List<Map<String, dynamic>>> loadSuggestionHistory(
    String suggestionId, {
    int limit = 30,
  }) async {
    final snap = await _db
        .collection('DictionarySuggestions')
        .doc(suggestionId)
        .collection('AuditEvents')
        .orderBy('at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> loadEntryRevisions(String entryId) async {
    final snap = await _db
        .collection('DictionaryDrafts')
        .doc(entryId)
        .collection('Revisions')
        .get();
    return snap.docs.map((doc) => doc.data()).toList()..sort(
      (a, b) => ((b['revision'] as int?) ?? 0).compareTo(
        (a['revision'] as int?) ?? 0,
      ),
    );
  }
}
