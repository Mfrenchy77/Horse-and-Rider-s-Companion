import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:horseandriderscompanion/Initialization/firebase_emulators.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:http/http.dart' as http;

/// One meaning. Synonyms resolve to this entry rather than creating copies.
class DictionaryEntry {
  DictionaryEntry(this.data, {this.bundled = false});

  final bool bundled;

  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get slug => data['slug'] as String;
  String get term => data['term'] as String;
  String get definition => data['definition'] as String;
  String get explanation => data['explanation'] as String? ?? '';
  bool get published => data['status'] == 'published';
  bool get contextual => data['contextual'] == true;
  List<String> strings(String field) =>
      (data[field] as List<dynamic>? ?? []).cast<String>();
  String text(String field) => data[field] as String? ?? '';
}

class DictionaryRepository {
  DictionaryRepository({this.firestore, this.bundle});

  final FirebaseFirestore? firestore;
  final AssetBundle? bundle;
  static bool _appCheckActivated = false;
  static Future<List<DictionaryEntry>>? _cachedEntriesFuture;
  static List<DictionaryEntry>? _resolvedCachedEntries;

  /// Synchronously returns cached entries if already loaded in this session.
  static List<DictionaryEntry>? get peekCachedEntries => _resolvedCachedEntries;

  /// Returns published Dictionary entries cached in memory for contextual
  /// highlighting across Skill Tree and Resources without repeated network or
  /// asset reads.
  static Future<List<DictionaryEntry>> cachedEntries({
    FirebaseFirestore? firestore,
    AssetBundle? bundle,
  }) {
    if (firestore != null || bundle != null) {
      return DictionaryRepository(firestore: firestore, bundle: bundle).load();
    }
    if (_resolvedCachedEntries != null) {
      return Future.value(_resolvedCachedEntries!);
    }
    return _cachedEntriesFuture ??= DictionaryRepository()
        .load()
        .then((items) => _resolvedCachedEntries = items)
        .catchError((Object _) => const <DictionaryEntry>[]);
  }

  /// Clears the session cache (used after admin publication or in tests).
  static void invalidateCache() {
    _cachedEntriesFuture = null;
    _resolvedCachedEntries = null;
  }

  Future<Map<String, String>> skillLabels() async {
    final skills = await AssetCurriculumV2Loader(bundle: bundle).loadSkills();
    return {
      for (final skill in skills)
        skill.id:
            '${skill.subject.name == 'horse' ? 'Horse' : 'Rider'} · '
            '${skill.name}',
    };
  }

  Future<List<DictionaryEntry>> load() async {
    if (firestore != null || Firebase.apps.isNotEmpty) {
      final db = firestore ?? FirebaseFirestore.instance;
      // A manifest distinguishes an intentionally empty catalogue from the
      // initial bundled collection before server publication begins.
      final manifest = await db
          .collection('DictionaryPublic')
          .doc('catalogue')
          .get();
      if (manifest.exists) {
        final docs = await db
            .collection('DictionaryEntries')
            .where('status', isEqualTo: 'published')
            .get();
        return docs.docs.map((doc) => DictionaryEntry(doc.data())).toList();
      }
    }
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

  /// Uses the same authenticated callable protocol as curriculum suggestions.
  Future<void> call(String function, Map<String, dynamic> data) async {
    const emulator = FirebaseEmulators.enabled;
    final projectId = Firebase.app().options.projectId;
    final uri = emulator
        ? Uri.http('127.0.0.1:5001', '/demo-horse-rules/us-central1/$function')
        : Uri.https('us-central1-$projectId.cloudfunctions.net', '/$function');
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    String? appCheck;
    if (!emulator && function == 'submitDictionarySuggestion') {
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

  static String newSubmissionId() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
