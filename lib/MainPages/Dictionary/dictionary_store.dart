/// Backend-neutral Equestrian Dictionary domain model and persistence contract.
///
/// Contains zero Firebase or provider-specific dependencies so Dictionary
/// features, contextual highlighting, and admin moderation can operate against
/// Firebase, an in-memory store, or any future backend adapter.
library;

/// One canonical Dictionary meaning. Synonyms resolve to this entry rather
/// than creating duplicate entries.
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
  int get publishedRevision {
    if (bundled) return 0;
    final rev = data['revision'] as int? ?? 0;
    if (data['publishedAt'] == null && rev <= 1) return 0;
    return rev;
  }

  List<String> strings(String field) =>
      (data[field] as List<dynamic>? ?? []).cast<String>();
  String text(String field) => data[field] as String? ?? '';
}

/// Backend-agnostic persistence and action boundary for the Equestrian
/// Dictionary.
abstract interface class DictionaryStore {
  /// Loads all published public Dictionary entries.
  Future<List<DictionaryEntry>> loadPublishedEntries();

  /// Loads display labels for linked Skill Tree 2.0 IDs (`skillId -> label`).
  Future<Map<String, String>> loadSkillLabels();

  /// Executes a server-authorized Dictionary operation (such as submitting a
  /// suggestion, reviewing a suggestion, saving a draft, publishing, or
  /// unpublishing).
  Future<void> executeAction(String actionName, Map<String, dynamic> data);

  /// Loads community suggestions for administrator review, newest first.
  Future<List<Map<String, dynamic>>> loadSuggestions({int limit = 100});

  /// Loads suggestions created by [contributorUid] so contributors can view
  /// the status of their own submissions, newest first.
  Future<List<Map<String, dynamic>>> loadMySuggestions(
    String contributorUid, {
    int limit = 50,
  });

  /// Loads administrator draft entries.
  Future<List<DictionaryEntry>> loadDrafts();

  /// Loads a single draft entry by [entryId], or `null` if no draft exists.
  Future<DictionaryEntry?> loadDraft(String entryId);

  /// Loads moderation audit history for a given [suggestionId], newest first.
  Future<List<Map<String, dynamic>>> loadSuggestionHistory(
    String suggestionId, {
    int limit = 30,
  });

  /// Loads immutable editorial revision snapshots for [entryId], newest first.
  Future<List<Map<String, dynamic>>> loadEntryRevisions(String entryId);
}

/// Pure in-memory [DictionaryStore] implementation with zero Firebase
/// dependencies, used for provider-independence testing and offline previews.
class InMemoryDictionaryStore implements DictionaryStore {
  InMemoryDictionaryStore({
    List<DictionaryEntry> publishedEntries = const [],
    Map<String, String> skillLabels = const {},
    List<Map<String, dynamic>> suggestions = const [],
    List<DictionaryEntry> drafts = const [],
  }) : _skillLabels = Map<String, String>.from(skillLabels) {
    for (final entry in publishedEntries) {
      _publishedById[entry.id] = DictionaryEntry(
        Map<String, dynamic>.from(entry.data),
        bundled: entry.bundled,
      );
    }
    for (final draft in drafts) {
      _draftsById[draft.id] = DictionaryEntry(
        Map<String, dynamic>.from(draft.data),
      );
    }
    for (final suggestion in suggestions) {
      final copy = Map<String, dynamic>.from(suggestion);
      final id = (copy['id'] as String?) ?? 'sug-${_suggestions.length + 1}';
      copy['id'] = id;
      _suggestions.add(copy);
    }
  }

  final Map<String, DictionaryEntry> _publishedById = {};
  final Map<String, DictionaryEntry> _draftsById = {};
  final Map<String, String> _skillLabels;
  final List<Map<String, dynamic>> _suggestions = [];
  final Map<String, List<Map<String, dynamic>>> _suggestionHistory = {};
  final Map<String, List<Map<String, dynamic>>> _revisionsByEntryId = {};
  final List<(String, Map<String, dynamic>)> executedActions = [];

  @override
  Future<List<DictionaryEntry>> loadPublishedEntries() async => _publishedById
      .values
      .where((entry) => entry.published)
      .map(
        (entry) => DictionaryEntry(
          Map<String, dynamic>.from(entry.data),
          bundled: entry.bundled,
        ),
      )
      .toList();

  @override
  Future<Map<String, String>> loadSkillLabels() async =>
      Map<String, String>.from(_skillLabels);

  @override
  Future<void> executeAction(
    String actionName,
    Map<String, dynamic> data,
  ) async {
    executedActions.add((actionName, Map<String, dynamic>.from(data)));
    if (actionName == 'submitDictionarySuggestion') {
      final id =
          (data['submissionId'] as String?) ??
          (data['id'] as String?) ??
          'sug-${_suggestions.length + 1}';
      final rawImages = (data['submittedImages'] as List<dynamic>? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (img) => <String, dynamic>{
              ...img.cast<String, dynamic>(),
              'reviewStatus': (img['reviewStatus'] as String?) ?? 'pending',
            },
          )
          .toList();
      _suggestions.insert(0, {
        ...data,
        'id': id,
        if (rawImages.isNotEmpty) 'submittedImages': rawImages,
        'textDecision': (data['kind'] == 'image_contribution')
            ? 'rejected'
            : 'pending',
        'status': 'submitted',
        'createdAt': DateTime.now().toIso8601String(),
      });
      return;
    }

    if (actionName != 'editDictionary') return;
    final action = data['action'] as String?;
    final id = data['id'] as String?;
    if (action == 'review' && id != null) {
      final note = (data['note'] as String?) ?? '';
      final imageDecisionsRaw = data['imageDecisions'];
      final decisionById = <String, Map<String, dynamic>>{};
      if (imageDecisionsRaw is List) {
        for (final entry
            in imageDecisionsRaw.whereType<Map<dynamic, dynamic>>()) {
          final imgId = entry['id'] as String?;
          if (imgId != null) {
            decisionById[imgId] = entry.cast<String, dynamic>();
          }
        }
      }
      var resolvedStatus = data['status'] as String?;
      for (final item in _suggestions) {
        if (item['id'] == id) {
          final currentImages =
              (item['submittedImages'] as List<dynamic>? ?? [])
                  .whereType<Map<dynamic, dynamic>>()
                  .map(
                    (e) => Map<String, dynamic>.from(e.cast<String, dynamic>()),
                  )
                  .toList();
          for (final img in currentImages) {
            final dec = decisionById[img['id']];
            if (dec != null) {
              if (dec['status'] != null) img['reviewStatus'] = dec['status'];
              if (dec['caption'] != null) img['caption'] = dec['caption'];
              if (dec['explanation'] != null) {
                img['explanation'] = dec['explanation'];
              }
              if (dec['imageType'] != null) img['imageType'] = dec['imageType'];
            } else if (resolvedStatus == 'rejected') {
              img['reviewStatus'] = 'rejected';
            }
          }
          if (currentImages.isNotEmpty) {
            item['submittedImages'] = currentImages;
          }
          if (data['textDecision'] != null) {
            item['textDecision'] = data['textDecision'];
          } else if (resolvedStatus == 'approved' ||
              resolvedStatus == 'rejected') {
            item['textDecision'] = resolvedStatus;
          }
          final editedFields = data['editedFields'];
          if (editedFields is Map) {
            item['proposedFields'] = Map<String, dynamic>.from(
              editedFields.cast<String, dynamic>(),
            );
          }
          resolvedStatus ??= (item['status'] as String?) ?? 'reviewed';
          item['status'] = resolvedStatus;
          break;
        }
      }
      _suggestionHistory.putIfAbsent(id, () => []).insert(0, {
        'status': resolvedStatus ?? 'reviewed',
        'note': note,
        'at': DateTime.now().toIso8601String(),
      });
      return;
    }

    if ((action == 'save_draft' || action == 'save' || action == 'publish') &&
        id != null) {
      final rawEntry = (data['entry'] as Map?)?.cast<String, dynamic>() ?? {};
      final previousRev =
          _draftsById[id]?.data['revision'] as int? ??
          _publishedById[id]?.data['revision'] as int? ??
          0;
      final nextRev = previousRev + 1;
      final isPublish = action == 'publish';
      final stored = <String, dynamic>{
        ...rawEntry,
        'id': id,
        'slug': (rawEntry['slug'] as String?) ?? id,
        'status': isPublish ? 'published' : 'draft',
        'revision': nextRev,
        if (isPublish) 'publishedAt': DateTime.now().toIso8601String(),
      };
      _draftsById[id] = DictionaryEntry(stored);
      _revisionsByEntryId.putIfAbsent(id, () => []).insert(0, stored);
      if (isPublish) {
        _publishedById[id] = DictionaryEntry(stored);
      }
      return;
    }

    if ((action == 'unpublish' || action == 'archive') && id != null) {
      _publishedById.remove(id);
      final draft = _draftsById[id];
      if (draft != null) {
        _draftsById[id] = DictionaryEntry({...draft.data, 'status': action});
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadSuggestions({int limit = 100}) async =>
      _suggestions.take(limit).map(Map<String, dynamic>.from).toList();

  @override
  Future<List<Map<String, dynamic>>> loadMySuggestions(
    String contributorUid, {
    int limit = 50,
  }) async => _suggestions
      .where((item) => item['contributorUid'] == contributorUid)
      .take(limit)
      .map(Map<String, dynamic>.from)
      .toList();

  @override
  Future<List<DictionaryEntry>> loadDrafts() async => _draftsById.values
      .map((entry) => DictionaryEntry(Map<String, dynamic>.from(entry.data)))
      .toList();

  @override
  Future<DictionaryEntry?> loadDraft(String entryId) async {
    final draft = _draftsById[entryId];
    return draft == null
        ? null
        : DictionaryEntry(Map<String, dynamic>.from(draft.data));
  }

  @override
  Future<List<Map<String, dynamic>>> loadSuggestionHistory(
    String suggestionId, {
    int limit = 30,
  }) async => (_suggestionHistory[suggestionId] ?? const [])
      .take(limit)
      .map(Map<String, dynamic>.from)
      .toList();

  @override
  Future<List<Map<String, dynamic>>> loadEntryRevisions(String entryId) async =>
      (_revisionsByEntryId[entryId] ?? const [])
          .map(Map<String, dynamic>.from)
          .toList();
}
