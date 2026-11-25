import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/skill_tree_suggestion.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;

/// Backend-neutral store interface for Skill Tree curriculum suggestions.
abstract interface class SkillTreeSuggestionsStore {
  /// Submits a new curriculum suggestion on behalf of the signed-in user.
  Future<SkillTreeSuggestion> submitSuggestion(SkillTreeSuggestionDraft draft);

  /// Fetches suggestions submitted by [submitterUid], newest first.
  Future<List<SkillTreeSuggestion>> fetchMySuggestions({
    required String submitterUid,
  });

  /// Fetches suggestions for the staff inbox, optionally filtered by status.
  Future<List<SkillTreeSuggestion>> fetchInboxSuggestions({
    SuggestionStatus? statusFilter,
  });

  /// Fetches private audit events for [suggestionId] (staff-only).
  Future<List<SuggestionAuditEvent>> fetchAuditEvents(String suggestionId);

  /// Applies a staff review update (status, assignment, notes) atomically.
  Future<SkillTreeSuggestion> reviewSuggestion(SuggestionReviewUpdate update);

  /// Fetches consented public contributor display names (no emails or UIDs).
  Future<List<String>> fetchPublicContributorNames();
}

/// Deterministic in-memory [SkillTreeSuggestionsStore] for unit/widget tests
/// and offline preview without touching Firestore.
class InMemorySkillTreeSuggestionsStore implements SkillTreeSuggestionsStore {
  /// Creates an [InMemorySkillTreeSuggestionsStore].
  InMemorySkillTreeSuggestionsStore({
    List<SkillTreeSuggestion> initialSuggestions = const [],
    Map<String, List<SuggestionAuditEvent>> initialAuditEvents = const {},
    List<String> initialContributorNames = const [],
    this.actorUid = 'local-user',
    this.actorEmail = 'local@example.com',
    this.actorName = 'Local User',
    this.actorEmailVerified = true,
    this.actorIsAdmin = false,
    this.actorIsModerator = false,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc()) {
    for (final s in initialSuggestions) {
      _suggestions[s.id] = s;
    }
    for (final entry in initialAuditEvents.entries) {
      _auditEvents[entry.key] = List<SuggestionAuditEvent>.from(entry.value);
    }
    _contributorNames.addAll(initialContributorNames);
  }

  /// Maximum submissions allowed per 24 hours per user.
  static const int maxSubmissionsPer24Hours = 10;

  final Map<String, SkillTreeSuggestion> _suggestions = {};
  final Map<String, List<SuggestionAuditEvent>> _auditEvents = {};
  final Set<String> _contributorNames = {};
  final DateTime Function() _now;
  int _counter = 0;

  /// Active actor UID for in-memory authorization and attribution.
  String actorUid;

  /// Active actor email.
  String actorEmail;

  /// Active actor display name.
  String actorName;

  /// Whether the active actor's email is verified.
  bool actorEmailVerified;

  /// Whether the active actor has the `admin` role.
  bool actorIsAdmin;

  /// Whether the active actor has the `moderator` role.
  bool actorIsModerator;

  @override
  Future<SkillTreeSuggestion> submitSuggestion(
    SkillTreeSuggestionDraft draft,
  ) async {
    if (actorUid.isEmpty) {
      throw const SkillTreeSuggestionException(
        'Sign in to submit a suggestion.',
        code: 'unauthenticated',
      );
    }
    if (!actorEmailVerified) {
      throw const SkillTreeSuggestionException(
        'Verify your email address before submitting a suggestion.',
        code: 'failed-precondition',
      );
    }
    final title = draft.title.trim();
    final description = draft.description.trim();
    if (title.length < 5 || title.length > 120) {
      throw const SkillTreeSuggestionException(
        'Title must be between 5 and 120 characters.',
        code: 'invalid-argument',
      );
    }
    if (description.length < 10 || description.length > 2000) {
      throw const SkillTreeSuggestionException(
        'Description must be between 10 and 2000 characters.',
        code: 'invalid-argument',
      );
    }

    final current = _now();
    final cutoff = current.subtract(const Duration(hours: 24));
    final recentCount = _suggestions.values
        .where(
          (s) =>
              s.submittedByUid == actorUid && !s.createdAt.isBefore(cutoff),
        )
        .length;
    if (recentCount >= maxSubmissionsPer24Hours) {
      throw const SkillTreeSuggestionException(
        'Rate limit exceeded: maximum 10 suggestions per 24 hours.',
        code: 'resource-exhausted',
      );
    }

    final id = 'sug-${++_counter}';
    final eventId = 'evt-${++_counter}';
    final suggestion = SkillTreeSuggestion(
      id: id,
      submittedByUid: actorUid,
      submitterEmail: actorEmail.toLowerCase(),
      submitterName: actorName,
      contributionCategory: draft.contributionCategory,
      subject: draft.subject,
      realm: draft.realm,
      familyId: draft.familyId,
      targetSkillId: draft.targetSkillId,
      targetSkillName: draft.targetSkillName,
      targetLevel: draft.targetLevel,
      title: title,
      description: description,
      rationale: draft.rationale?.trim().isEmpty ?? true
          ? null
          : draft.rationale!.trim(),
      proposedAlias: draft.proposedAlias?.trim().isEmpty ?? true
          ? null
          : draft.proposedAlias!.trim(),
      creditConsent: draft.creditConsent,
      status: SuggestionStatus.submitted,
      createdAt: current,
      updatedAt: current,
    );
    _suggestions[id] = suggestion;
    _auditEvents[id] = [
      SuggestionAuditEvent(
        id: eventId,
        type: 'submitted',
        actorUid: actorUid,
        actorName: actorName,
        actorRole: 'submitter',
        toStatus: SuggestionStatus.submitted,
        at: current,
      ),
    ];
    return suggestion;
  }

  @override
  Future<List<SkillTreeSuggestion>> fetchMySuggestions({
    required String submitterUid,
  }) async {
    final items = _suggestions.values
        .where((s) => s.submittedByUid == submitterUid)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<List<SkillTreeSuggestion>> fetchInboxSuggestions({
    SuggestionStatus? statusFilter,
  }) async {
    if (!actorIsAdmin && !actorIsModerator) {
      throw const SkillTreeSuggestionException(
        'Staff privileges required.',
        code: 'permission-denied',
      );
    }
    final items = _suggestions.values
        .where((s) => statusFilter == null || s.status == statusFilter)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<List<SuggestionAuditEvent>> fetchAuditEvents(
    String suggestionId,
  ) async {
    if (!actorIsAdmin && !actorIsModerator) {
      throw const SkillTreeSuggestionException(
        'Staff privileges required.',
        code: 'permission-denied',
      );
    }
    final events = List<SuggestionAuditEvent>.from(
      _auditEvents[suggestionId] ?? const [],
    )..sort((a, b) => b.at.compareTo(a.at));
    return events;
  }

  @override
  Future<SkillTreeSuggestion> reviewSuggestion(
    SuggestionReviewUpdate update,
  ) async {
    if (!actorIsAdmin && !actorIsModerator) {
      throw const SkillTreeSuggestionException(
        'Administrator or moderator privileges required.',
        code: 'permission-denied',
      );
    }
    if (update.status != null && update.status!.isAdminOnly && !actorIsAdmin) {
      throw const SkillTreeSuggestionException(
        'Only administrators may approve, decline, or publish suggestions.',
        code: 'permission-denied',
      );
    }
    if (update.grantPublicCredit != null && !actorIsAdmin) {
      throw const SkillTreeSuggestionException(
        'Only administrators may manage contributor recognition.',
        code: 'permission-denied',
      );
    }
    final existing = _suggestions[update.suggestionId];
    if (existing == null) {
      throw const SkillTreeSuggestionException(
        'Suggestion not found.',
        code: 'not-found',
      );
    }
    if ((update.grantPublicCredit ?? false) && !existing.creditConsent) {
      throw const SkillTreeSuggestionException(
        'Contributor did not opt into public credit for this suggestion.',
        code: 'failed-precondition',
      );
    }

    final current = _now();
    final nextStatus = update.status ?? existing.status;
    final nextCreditGranted =
        update.grantPublicCredit ?? existing.creditGranted;
    if (update.grantPublicCredit ?? false) {
      final candidate = existing.submitterName.trim();
      if (candidate.isNotEmpty && !candidate.contains('@')) {
        _contributorNames.add(candidate);
      }
    }
    final updated = SkillTreeSuggestion(
      id: existing.id,
      submittedByUid: existing.submittedByUid,
      submitterEmail: existing.submitterEmail,
      submitterName: existing.submitterName,
      contributionCategory: existing.contributionCategory,
      subject: existing.subject,
      realm: existing.realm,
      familyId: existing.familyId,
      targetSkillId: existing.targetSkillId,
      targetSkillName: existing.targetSkillName,
      targetLevel: existing.targetLevel,
      title: existing.title,
      description: existing.description,
      rationale: existing.rationale,
      proposedAlias: existing.proposedAlias,
      creditConsent: existing.creditConsent,
      creditGranted: nextCreditGranted,
      status: nextStatus,
      assignedToUid: update.includeAssignedToUid
          ? update.assignedToUid
          : existing.assignedToUid,
      publicResolutionNote: update.includePublicResolutionNote
          ? update.publicResolutionNote
          : existing.publicResolutionNote,
      reviewedByUid: update.status != null ? actorUid : existing.reviewedByUid,
      reviewedByName:
          update.status != null ? actorName : existing.reviewedByName,
      createdAt: existing.createdAt,
      updatedAt: current,
      reviewedAt: update.status != null ? current : existing.reviewedAt,
      incorporatedAt: nextStatus == SuggestionStatus.incorporated
          ? (existing.incorporatedAt ?? current)
          : existing.incorporatedAt,
    );
    _suggestions[existing.id] = updated;

    _auditEvents.putIfAbsent(existing.id, () => []).add(
      SuggestionAuditEvent(
        id: 'evt-${++_counter}',
        type: nextStatus != existing.status ? 'status_changed' : 'note_added',
        actorUid: actorUid,
        actorName: actorName,
        actorRole: actorIsAdmin ? 'admin' : 'moderator',
        fromStatus: existing.status,
        toStatus: nextStatus,
        privateNote: update.privateNote?.trim().isEmpty ?? true
            ? null
            : update.privateNote!.trim(),
        publicNote: update.includePublicResolutionNote
            ? update.publicResolutionNote
            : null,
        at: current,
      ),
    );
    return updated;
  }

  @override
  Future<List<String>> fetchPublicContributorNames() async {
    final names = _contributorNames.toList()..sort();
    return names;
  }
}

/// Production Cloud Functions + Firestore [SkillTreeSuggestionsStore].
class CloudSkillTreeSuggestionsStore implements SkillTreeSuggestionsStore {
  /// Creates a [CloudSkillTreeSuggestionsStore].
  CloudSkillTreeSuggestionsStore({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
    http.Client? httpClient,
    this._tokenProvider,
    this._submitEndpoint,
    this._reviewEndpoint,
    this._projectId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  static const _collection = 'SkillTreeSuggestions';
  static const _auditSubcollection = 'AuditEvents';

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;
  final http.Client _httpClient;
  final Future<String?> Function()? _tokenProvider;
  final Uri? _submitEndpoint;
  final Uri? _reviewEndpoint;
  final String? _projectId;

  Uri _resolveEndpoint(Uri? override, String functionName) {
    if (override != null) return override;
    final project = _projectId ?? _auth.app.options.projectId;
    return Uri.https(
      'us-central1-$project.cloudfunctions.net',
      '/$functionName',
    );
  }

  Future<Map<String, dynamic>> _callFunction(
    Uri endpoint,
    Map<String, dynamic> data,
  ) async {
    final token = _tokenProvider != null
        ? await _tokenProvider()
        : await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw const SkillTreeSuggestionException(
        'Sign in to continue.',
        code: 'unauthenticated',
      );
    }

    final http.Response response;
    try {
      response = await _httpClient
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'data': data}),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const SkillTreeSuggestionException(
        'The request timed out. Please try again.',
        code: 'deadline-exceeded',
      );
    } on http.ClientException {
      throw const SkillTreeSuggestionException(
        'Unable to reach the server. Check your connection and try again.',
        code: 'unavailable',
      );
    }

    var body = const <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {
      body = const <String, dynamic>{};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final err = body['error'];
      final message = err is Map<String, dynamic>
          ? err['message'] as String? ?? 'Request failed.'
          : 'Request failed.';
      final code =
          err is Map<String, dynamic> ? err['status'] as String? : null;
      throw SkillTreeSuggestionException(message, code: code);
    }

    final result = body['result'];
    if (result is Map<String, dynamic>) return result;
    return body;
  }

  @override
  Future<SkillTreeSuggestion> submitSuggestion(
    SkillTreeSuggestionDraft draft,
  ) async {
    final result = await _callFunction(
      _resolveEndpoint(_submitEndpoint, 'submitSkillTreeSuggestion'),
      draft.toPayload(),
    );
    final raw = result['suggestion'];
    if (raw is! Map<String, dynamic>) {
      throw const SkillTreeSuggestionException(
        'Unexpected server response.',
        code: 'internal',
      );
    }
    return SkillTreeSuggestion.fromMap(raw);
  }

  @override
  Future<List<SkillTreeSuggestion>> fetchMySuggestions({
    required String submitterUid,
  }) async {
    final snap = await _firestore
        .collection(_collection)
        .where('submittedByUid', isEqualTo: submitterUid)
        .get();
    final list = [
      for (final doc in snap.docs)
        SkillTreeSuggestion.fromMap({'id': doc.id, ...doc.data()}),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<SkillTreeSuggestion>> fetchInboxSuggestions({
    SuggestionStatus? statusFilter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(_collection);
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.value);
    }
    final snap = await query.get();
    final list = [
      for (final doc in snap.docs)
        SkillTreeSuggestion.fromMap({'id': doc.id, ...doc.data()}),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<List<SuggestionAuditEvent>> fetchAuditEvents(
    String suggestionId,
  ) async {
    final snap = await _firestore
        .collection(_collection)
        .doc(suggestionId)
        .collection(_auditSubcollection)
        .get();
    final list = [
      for (final doc in snap.docs)
        SuggestionAuditEvent.fromMap({'id': doc.id, ...doc.data()}),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  @override
  Future<SkillTreeSuggestion> reviewSuggestion(
    SuggestionReviewUpdate update,
  ) async {
    final result = await _callFunction(
      _resolveEndpoint(_reviewEndpoint, 'reviewSkillTreeSuggestion'),
      update.toPayload(),
    );
    final raw = result['suggestion'];
    if (raw is! Map<String, dynamic>) {
      throw const SkillTreeSuggestionException(
        'Unexpected server response.',
        code: 'internal',
      );
    }
    return SkillTreeSuggestion.fromMap(raw);
  }

  @override
  Future<List<String>> fetchPublicContributorNames() async {
    try {
      final snap = await _firestore
          .collection('SkillTreeCurriculumPublic')
          .doc('contributors')
          .get();
      final data = snap.data();
      if (!snap.exists || data == null) return const [];
      final raw = data['names'];
      if (raw is! List) return const [];
      final names = raw
          .whereType<String>()
          .map((n) => n.trim())
          .where((n) => n.isNotEmpty && !n.contains('@'))
          .toList()
        ..sort();
      return names;
    } catch (_) {
      return const [];
    }
  }
}

/// Repository facade for Skill Tree curriculum suggestions and staff review.
class SkillTreeSuggestionsRepository {
  /// Creates a [SkillTreeSuggestionsRepository].
  SkillTreeSuggestionsRepository({SkillTreeSuggestionsStore? store})
      : _store = store ?? InMemorySkillTreeSuggestionsStore();

  final SkillTreeSuggestionsStore _store;

  /// Submits a new curriculum suggestion.
  Future<SkillTreeSuggestion> submitSuggestion(
    SkillTreeSuggestionDraft draft,
  ) =>
      _store.submitSuggestion(draft);

  /// Fetches suggestions submitted by [submitterUid].
  Future<List<SkillTreeSuggestion>> fetchMySuggestions({
    required String submitterUid,
  }) =>
      _store.fetchMySuggestions(submitterUid: submitterUid);

  /// Fetches staff inbox suggestions.
  Future<List<SkillTreeSuggestion>> fetchInboxSuggestions({
    SuggestionStatus? statusFilter,
  }) =>
      _store.fetchInboxSuggestions(statusFilter: statusFilter);

  /// Fetches private audit history for [suggestionId].
  Future<List<SuggestionAuditEvent>> fetchAuditEvents(String suggestionId) =>
      _store.fetchAuditEvents(suggestionId);

  /// Submits a staff review decision or note.
  Future<SkillTreeSuggestion> reviewSuggestion(SuggestionReviewUpdate update) =>
      _store.reviewSuggestion(update);

  /// Fetches consented public contributor display names (no emails or UIDs).
  Future<List<String>> fetchPublicContributorNames() =>
      _store.fetchPublicContributorNames();
}
