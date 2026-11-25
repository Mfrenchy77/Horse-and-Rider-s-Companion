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

  /// Lists published curriculum revisions (newest first).
  Future<List<CurriculumRevisionSummary>> fetchRevisions();

  /// Loads and reconstructs the complete snapshot for [revisionId].
  Future<CurriculumRevisionSnapshot?> fetchRevisionSnapshot(String revisionId);

  /// Fetches the current publication status and recovery state.
  Future<CurriculumPublicationStatus> fetchPublicationStatus();

  /// Publishes the currently saved draft as a new immutable revision.
  Future<CurriculumRevisionSummary> publishDraft({
    String? notes,
    bool resumeFailedPublication = false,
    String? requestId,
  });

  /// Discards an interrupted, unpublished curriculum publication attempt.
  Future<void> discardFailedPublication();

  /// Restores [targetRevisionId] as a new forward revision (history intact).
  Future<CurriculumRevisionSummary> rollbackToRevision({
    required String targetRevisionId,
    String? notes,
    String? requestId,
  });
}

/// In-memory [SkillTreeDraftStore] for tests and Firebase-free environments.
class InMemorySkillTreeDraftStore implements SkillTreeDraftStore {
  /// Creates an [InMemorySkillTreeDraftStore].
  InMemorySkillTreeDraftStore({
    SkillTreeCurriculumDraft? initialDraft,
    List<CurriculumRevisionSnapshot> initialRevisions = const [],
    CurriculumPublicationStatus initialPublicationStatus =
        CurriculumPublicationStatus.idle,
    this.actorIsAdmin = true,
    this.actorUid = 'admin-1',
    this.actorName = 'Administrator',
    this.publishingEnabled = false,
  })  : _draft = initialDraft,
        _revisions = List<CurriculumRevisionSnapshot>.from(initialRevisions),
        _publicationStatus = initialPublicationStatus;

  SkillTreeCurriculumDraft? _draft;
  final List<CurriculumRevisionSnapshot> _revisions;
  CurriculumPublicationStatus _publicationStatus;

  /// Simulated admin claim for tests.
  bool actorIsAdmin;

  /// Simulated actor UID.
  String actorUid;

  /// Simulated actor display name.
  String actorName;

  /// Whether publishing/rollback is enabled in this store.
  bool publishingEnabled;

  @override
  Future<CurriculumPublicationStatus> fetchPublicationStatus() async {
    if (!actorIsAdmin) return CurriculumPublicationStatus.idle;
    return _publicationStatus;
  }

  @override
  Future<void> discardFailedPublication() async {
    if (!actorIsAdmin) {
      throw SkillTreeDraftException(
        'Administrator privileges are required.',
        code: 'permission-denied',
      );
    }
    if (!publishingEnabled) {
      throw SkillTreeDraftException(
        'Curriculum publishing controls are currently disabled.',
        code: 'failed-precondition',
      );
    }
    if (_publicationStatus.isAlreadyActive) {
      throw SkillTreeDraftException(
        'This curriculum update is already live and cannot be discarded.',
        code: 'failed-precondition',
      );
    }
    _publicationStatus = CurriculumPublicationStatus(
      currentRevisionId: _publicationStatus.currentRevisionId,
      currentRevisionNumber: _publicationStatus.currentRevisionNumber,
    );
  }

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

  @override
  Future<List<CurriculumRevisionSummary>> fetchRevisions() async {
    if (!actorIsAdmin) return const [];
    final list = _revisions.map((r) => r.summary).toList()
      ..sort((a, b) => b.revisionNumber.compareTo(a.revisionNumber));
    return list;
  }

  @override
  Future<CurriculumRevisionSnapshot?> fetchRevisionSnapshot(
    String revisionId,
  ) async {
    if (!actorIsAdmin) return null;
    for (final rev in _revisions) {
      if (rev.summary.id == revisionId) return rev;
    }
    return null;
  }

  @override
  Future<CurriculumRevisionSummary> publishDraft({
    String? notes,
    bool resumeFailedPublication = false,
    String? requestId,
  }) async {
    if (!actorIsAdmin) {
      throw SkillTreeDraftException(
        'Administrator privileges are required.',
        code: 'permission-denied',
      );
    }
    if (!publishingEnabled) {
      throw SkillTreeDraftException(
        'Curriculum publishing is currently disabled.',
        code: 'failed-precondition',
      );
    }
    if (resumeFailedPublication &&
        _publicationStatus.needsAttention &&
        _publicationStatus.isAlreadyActive &&
        _revisions.isNotEmpty) {
      final active = _revisions.last.summary;
      _publicationStatus = CurriculumPublicationStatus(
        currentRevisionId: active.id,
        currentRevisionNumber: active.revisionNumber,
      );
      _draft = null;
      return active;
    }
    final draft = _draft;
    if (draft == null) {
      throw SkillTreeDraftException(
        'No saved curriculum draft exists to publish.',
        code: 'failed-precondition',
      );
    }
    final nextNum = _revisions.isEmpty
        ? 1
        : _revisions
                .map((r) => r.summary.revisionNumber)
                .reduce((a, b) => a > b ? a : b) +
            1;
    final prevId = _revisions.isEmpty ? null : _revisions.last.summary.id;
    final now = DateTime.now().toUtc();
    final summary = CurriculumRevisionSummary(
      id: 'rev_${nextNum.toString().padLeft(6, '0')}',
      revisionNumber: nextNum,
      kind: 'publish',
      status: 'completed',
      previousRevisionId: prevId,
      createdAt: now,
      publishedAt: now,
      publishedByUid: actorUid,
      publishedByName: actorName,
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      checksum: 'inmem-$nextNum',
      chunkCount: 1,
      snapshotByteLength: 0,
      familyCount: draft.families.length,
      skillCount: draft.skills.length,
      totalLevels: draft.skills.fold<int>(
        0,
        (total, s) => total + s.availableLevels.length,
      ),
    );
    _revisions.add(
      CurriculumRevisionSnapshot(
        summary: summary,
        families: List<SkillFamily>.unmodifiable(draft.families),
        skills: List<CurriculumSkill>.unmodifiable(draft.skills),
      ),
    );
    _publicationStatus = CurriculumPublicationStatus(
      currentRevisionId: summary.id,
      currentRevisionNumber: summary.revisionNumber,
    );
    _draft = null;
    return summary;
  }

  @override
  Future<CurriculumRevisionSummary> rollbackToRevision({
    required String targetRevisionId,
    String? notes,
    String? requestId,
  }) async {
    if (!actorIsAdmin) {
      throw SkillTreeDraftException(
        'Administrator privileges are required.',
        code: 'permission-denied',
      );
    }
    if (!publishingEnabled) {
      throw SkillTreeDraftException(
        'Curriculum rollback is currently disabled.',
        code: 'failed-precondition',
      );
    }
    final target = await fetchRevisionSnapshot(targetRevisionId);
    if (target == null) {
      throw SkillTreeDraftException(
        'Revision $targetRevisionId was not found.',
        code: 'not-found',
      );
    }
    final nextNum = _revisions
            .map((r) => r.summary.revisionNumber)
            .reduce((a, b) => a > b ? a : b) +
        1;
    final prevId = _revisions.last.summary.id;
    final now = DateTime.now().toUtc();
    final summary = CurriculumRevisionSummary(
      id: 'rev_${nextNum.toString().padLeft(6, '0')}',
      revisionNumber: nextNum,
      kind: 'rollback',
      status: 'completed',
      previousRevisionId: prevId,
      rollbackOfRevisionId: targetRevisionId,
      createdAt: now,
      publishedAt: now,
      publishedByUid: actorUid,
      publishedByName: actorName,
      notes: notes?.trim().isEmpty ?? true
          ? 'Restored from revision #${target.summary.revisionNumber}.'
          : notes!.trim(),
      checksum: target.summary.checksum,
      chunkCount: 1,
      snapshotByteLength: target.summary.snapshotByteLength,
      familyCount: target.families.length,
      skillCount: target.skills.length,
      totalLevels: target.summary.totalLevels,
    );
    _revisions.add(
      CurriculumRevisionSnapshot(
        summary: summary,
        families: target.families,
        skills: target.skills,
      ),
    );
    _publicationStatus = CurriculumPublicationStatus(
      currentRevisionId: summary.id,
      currentRevisionNumber: summary.revisionNumber,
    );
    return summary;
  }
}

/// Production Cloud Functions + Firestore [SkillTreeDraftStore].
class CloudSkillTreeDraftStore implements SkillTreeDraftStore {
  /// Creates a [CloudSkillTreeDraftStore].
  CloudSkillTreeDraftStore({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
    http.Client? httpClient,
    Future<String?> Function()? tokenProvider,
    Uri? saveEndpoint,
    Uri? discardEndpoint,
    Uri? publishEndpoint,
    Uri? rollbackEndpoint,
    Uri? abortEndpoint,
    String? projectId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client(),
        // ignore: prefer_initializing_formals
        _tokenProvider = tokenProvider,
        // ignore: prefer_initializing_formals
        _saveEndpoint = saveEndpoint,
        // ignore: prefer_initializing_formals
        _discardEndpoint = discardEndpoint,
        // ignore: prefer_initializing_formals
        _publishEndpoint = publishEndpoint,
        // ignore: prefer_initializing_formals
        _rollbackEndpoint = rollbackEndpoint,
        // ignore: prefer_initializing_formals
        _abortEndpoint = abortEndpoint,
        // ignore: prefer_initializing_formals
        _projectId = projectId;

  static const _collection = 'SkillTreeCurriculumDrafts';
  static const _revisionsCollection = 'SkillTreeCurriculumRevisions';
  static const _chunksSubcollection = 'Chunks';
  static const _metaCollection = 'SkillTreeCurriculumMeta';
  static const _metaDocId = 'current';
  static const _defaultDocId = 'default';

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;
  final http.Client _httpClient;
  final Future<String?> Function()? _tokenProvider;
  final Uri? _saveEndpoint;
  final Uri? _discardEndpoint;
  final Uri? _publishEndpoint;
  final Uri? _rollbackEndpoint;
  final Uri? _abortEndpoint;
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
    return SkillTreeCurriculumDraft.fromMap(normalizeFirestoreTimestamps(data));
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

  @override
  Future<List<CurriculumRevisionSummary>> fetchRevisions() async {
    final snap = await _firestore
        .collection(_revisionsCollection)
        .orderBy('revisionNumber', descending: true)
        .get();
    return snap.docs
        .map(
          (d) => CurriculumRevisionSummary.fromMap(
            normalizeFirestoreTimestamps({'id': d.id, ...d.data()}),
          ),
        )
        .toList();
  }

  @override
  Future<CurriculumRevisionSnapshot?> fetchRevisionSnapshot(
    String revisionId,
  ) async {
    final revRef = _firestore.collection(_revisionsCollection).doc(revisionId);
    final headerSnap = await revRef.get();
    final headerData = headerSnap.data();
    if (!headerSnap.exists || headerData == null) return null;

    final summary = CurriculumRevisionSummary.fromMap(
      normalizeFirestoreTimestamps({'id': headerSnap.id, ...headerData}),
    );
    final chunksSnap = await revRef
        .collection(_chunksSubcollection)
        .orderBy('index')
        .get();
    final serialized = chunksSnap.docs
        .map((d) => d.data()['payload'] as String? ?? '')
        .join();
    final decoded = jsonDecode(serialized);
    if (decoded is! Map<String, dynamic>) {
      throw SkillTreeDraftException(
        'Revision snapshot could not be decoded.',
        code: 'data-loss',
      );
    }
    final rawFamilies = decoded['families'] as List<dynamic>? ?? const [];
    final rawSkills = decoded['skills'] as List<dynamic>? ?? const [];
    return CurriculumRevisionSnapshot(
      summary: summary,
      families: rawFamilies
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => SkillFamily.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      skills: rawSkills
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => CurriculumSkill.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  @override
  Future<CurriculumPublicationStatus> fetchPublicationStatus() async {
    final snap = await _firestore
        .collection(_metaCollection)
        .doc(_metaDocId)
        .get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      return CurriculumPublicationStatus.idle;
    }
    return CurriculumPublicationStatus.fromMap(
      normalizeFirestoreTimestamps(data),
    );
  }

  @override
  Future<CurriculumRevisionSummary> publishDraft({
    String? notes,
    bool resumeFailedPublication = false,
    String? requestId,
  }) async {
    final result = await _callFunction(
      _endpoint('publishSkillTreeCurriculumDraft', _publishEndpoint),
      {
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (resumeFailedPublication) 'resumeFailedPublication': true,
        if (requestId != null && requestId.trim().isNotEmpty)
          'requestId': requestId.trim(),
      },
    );
    final raw = result['revision'];
    if (raw is! Map<String, dynamic>) {
      throw SkillTreeDraftException(
        'Unexpected server response while publishing.',
        code: 'internal',
      );
    }
    return CurriculumRevisionSummary.fromMap(raw);
  }

  @override
  Future<void> discardFailedPublication() async {
    await _callFunction(
      _endpoint('abortSkillTreeCurriculumPublication', _abortEndpoint),
      const {},
    );
  }

  @override
  Future<CurriculumRevisionSummary> rollbackToRevision({
    required String targetRevisionId,
    String? notes,
    String? requestId,
  }) async {
    final result = await _callFunction(
      _endpoint('rollbackSkillTreeCurriculumRevision', _rollbackEndpoint),
      {
        'targetRevisionId': targetRevisionId,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (requestId != null && requestId.trim().isNotEmpty)
          'requestId': requestId.trim(),
      },
    );
    final raw = result['revision'];
    if (raw is! Map<String, dynamic>) {
      throw SkillTreeDraftException(
        'Unexpected server response while restoring revision.',
        code: 'internal',
      );
    }
    return CurriculumRevisionSummary.fromMap(raw);
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

  /// Lists published curriculum revisions (newest first).
  Future<List<CurriculumRevisionSummary>> fetchRevisions() =>
      _store.fetchRevisions();

  /// Loads and reconstructs the complete snapshot for [revisionId].
  Future<CurriculumRevisionSnapshot?> fetchRevisionSnapshot(
    String revisionId,
  ) =>
      _store.fetchRevisionSnapshot(revisionId);

  /// Fetches the current publication status and recovery state.
  Future<CurriculumPublicationStatus> fetchPublicationStatus() =>
      _store.fetchPublicationStatus();

  /// Publishes the saved draft as a new immutable revision.
  Future<CurriculumRevisionSummary> publishDraft({
    String? notes,
    bool resumeFailedPublication = false,
    String? requestId,
  }) =>
      _store.publishDraft(
        notes: notes,
        resumeFailedPublication: resumeFailedPublication,
        requestId: requestId,
      );

  /// Discards an interrupted, unpublished curriculum publication attempt.
  Future<void> discardFailedPublication() => _store.discardFailedPublication();

  /// Restores [targetRevisionId] as a new forward revision.
  Future<CurriculumRevisionSummary> rollbackToRevision({
    required String targetRevisionId,
    String? notes,
    String? requestId,
  }) =>
      _store.rollbackToRevision(
        targetRevisionId: targetRevisionId,
        notes: notes,
        requestId: requestId,
      );
}
