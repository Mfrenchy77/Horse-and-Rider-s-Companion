import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;

/// Error thrown when saving, loading, or discarding a curriculum draft fails.
class SkillTreeDraftException implements Exception {
  /// Creates a [SkillTreeDraftException].
  SkillTreeDraftException(this.message, {this.code});

  /// Human-readable error description.
  final String message;

  /// Optional Cloud Functions error code.
  final String? code;

  @override
  String toString() => message;
}

/// Administrator-only working draft of the Skill Tree 2.0 curriculum.
class SkillTreeCurriculumDraft {
  /// Creates a [SkillTreeCurriculumDraft].
  const SkillTreeCurriculumDraft({
    required this.families,
    required this.skills,
    this.updatedByUid,
    this.updatedByName,
    this.updatedAt,
  });

  /// Parses a [SkillTreeCurriculumDraft] from a raw map.
  factory SkillTreeCurriculumDraft.fromMap(Map<String, dynamic> data) {
    final rawFamilies = data['families'] as List<dynamic>? ?? const [];
    final rawSkills = data['skills'] as List<dynamic>? ?? const [];
    return SkillTreeCurriculumDraft(
      families: rawFamilies
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => SkillFamily.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      skills: rawSkills
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => CurriculumSkill.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      updatedByUid: data['updatedByUid'] as String?,
      updatedByName: data['updatedByName'] as String?,
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Draft skill families.
  final List<SkillFamily> families;

  /// Draft curriculum skills.
  final List<CurriculumSkill> skills;

  /// UID of the administrator who last saved this draft.
  final String? updatedByUid;

  /// Display name of the administrator who last saved this draft.
  final String? updatedByName;

  /// Timestamp of the last save.
  final DateTime? updatedAt;
}

DateTime? _parseTimestamp(Object? raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

/// Store abstraction for Skill Tree 2.0 administrator curriculum drafts.
abstract class SkillTreeDraftStore {
  /// Fetches the current working draft, or `null` if none exists.
  Future<SkillTreeCurriculumDraft?> fetchDraft();

  /// Validates and saves [draft] on the backend (never publishes).
  Future<SkillTreeCurriculumDraft> saveDraft(
    SkillTreeCurriculumDraft draft, {
    String? note,
  });

  /// Discards the working draft without modifying published curriculum.
  Future<void> discardDraft();
}

/// In-memory [SkillTreeDraftStore] for tests and Firebase-free environments.
class InMemorySkillTreeDraftStore implements SkillTreeDraftStore {
  /// Creates an [InMemorySkillTreeDraftStore].
  InMemorySkillTreeDraftStore({
    SkillTreeCurriculumDraft? initialDraft,
    this.actorIsAdmin = true,
    this.actorUid = 'admin-1',
    this.actorName = 'Administrator',
  }) : _draft = initialDraft;

  SkillTreeCurriculumDraft? _draft;

  /// Simulated admin claim for tests.
  bool actorIsAdmin;

  /// Simulated actor UID.
  String actorUid;

  /// Simulated actor display name.
  String actorName;

  @override
  Future<SkillTreeCurriculumDraft?> fetchDraft() async {
    if (!actorIsAdmin) return null;
    return _draft;
  }

  @override
  Future<SkillTreeCurriculumDraft> saveDraft(
    SkillTreeCurriculumDraft draft, {
    String? note,
  }) async {
    if (!actorIsAdmin) {
      throw SkillTreeDraftException(
        'Administrator privileges are required.',
        code: 'permission-denied',
      );
    }
    _draft = SkillTreeCurriculumDraft(
      families: List<SkillFamily>.unmodifiable(draft.families),
      skills: List<CurriculumSkill>.unmodifiable(draft.skills),
      updatedByUid: actorUid,
      updatedByName: actorName,
      updatedAt: DateTime.now(),
    );
    return _draft!;
  }

  @override
  Future<void> discardDraft() async {
    if (!actorIsAdmin) {
      throw SkillTreeDraftException(
        'Administrator privileges are required.',
        code: 'permission-denied',
      );
    }
    _draft = null;
  }
}

/// Production Cloud Functions + Firestore [SkillTreeDraftStore].
class CloudSkillTreeDraftStore implements SkillTreeDraftStore {
  /// Creates a [CloudSkillTreeDraftStore].
  CloudSkillTreeDraftStore({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
    http.Client? httpClient,
    this._tokenProvider,
    this._saveEndpoint,
    this._discardEndpoint,
    this._projectId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  static const _collection = 'SkillTreeCurriculumDrafts';
  static const _defaultDocId = 'default';

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;
  final http.Client _httpClient;
  final Future<String?> Function()? _tokenProvider;
  final Uri? _saveEndpoint;
  final Uri? _discardEndpoint;
  final String? _projectId;

  Uri _endpoint(String name, Uri? override) {
    if (override != null) return override;
    final projectId =
        _projectId ?? _firestore.app.options.projectId;
    return Uri.https('us-central1-$projectId.cloudfunctions.net', '/$name');
  }

  Future<Map<String, dynamic>> _callFunction(
    Uri endpoint,
    Map<String, dynamic> payload,
  ) async {
    final token = _tokenProvider != null
        ? await _tokenProvider()
        : await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw SkillTreeDraftException(
        'Please sign in with an administrator account.',
        code: 'unauthenticated',
      );
    }

    final http.Response response;
    try {
      response = await _httpClient.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'data': payload}),
      );
    } catch (_) {
      throw SkillTreeDraftException(
        'Unable to reach the curriculum draft service.',
        code: 'unavailable',
      );
    }

    var body = const <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      body = const <String, dynamic>{};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final err = body['error'];
      final message = err is Map<String, dynamic>
          ? err['message'] as String? ?? 'Draft request failed.'
          : 'Draft request failed.';
      final code =
          err is Map<String, dynamic> ? err['status'] as String? : null;
      throw SkillTreeDraftException(message, code: code);
    }

    final result = body['result'];
    if (result is Map<String, dynamic>) return result;
    return body;
  }

  @override
  Future<SkillTreeCurriculumDraft?> fetchDraft() async {
    final snap =
        await _firestore.collection(_collection).doc(_defaultDocId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return SkillTreeCurriculumDraft.fromMap(data);
  }

  @override
  Future<SkillTreeCurriculumDraft> saveDraft(
    SkillTreeCurriculumDraft draft, {
    String? note,
  }) async {
    final result = await _callFunction(
      _endpoint('saveSkillTreeCurriculumDraft', _saveEndpoint),
      {
        'families': draft.families.map((f) => f.toMap()).toList(),
        'skills': draft.skills.map((s) => s.toMap()).toList(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    final raw = result['draft'];
    if (raw is Map<String, dynamic>) {
      return SkillTreeCurriculumDraft.fromMap(raw);
    }
    return draft;
  }

  @override
  Future<void> discardDraft() async {
    await _callFunction(
      _endpoint('discardSkillTreeCurriculumDraft', _discardEndpoint),
      const {},
    );
  }
}

/// Repository facade for Skill Tree 2.0 administrator curriculum drafts.
class SkillTreeDraftRepository {
  /// Creates a [SkillTreeDraftRepository].
  SkillTreeDraftRepository({SkillTreeDraftStore? store})
      : _store = store ?? InMemorySkillTreeDraftStore();

  final SkillTreeDraftStore _store;

  /// Fetches the current working draft, or `null` if none exists.
  Future<SkillTreeCurriculumDraft?> fetchDraft() => _store.fetchDraft();

  /// Validates and saves [draft] on the backend (never publishes).
  Future<SkillTreeCurriculumDraft> saveDraft(
    SkillTreeCurriculumDraft draft, {
    String? note,
  }) =>
      _store.saveDraft(draft, note: note);

  /// Discards the working draft without modifying published curriculum.
  Future<void> discardDraft() => _store.discardDraft();
}
