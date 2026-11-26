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

    if (action == 'approve_and_publish' && id != null) {
      final suggIndex = _suggestions.indexWhere((item) => item['id'] == id);
      if (suggIndex < 0) {
        throw StateError('Suggestion not found.');
      }
      final suggestion = _suggestions[suggIndex];
      if (suggestion['status'] == 'published') {
        throw StateError('This submission has already been published.');
      }
      if (suggestion['status'] == 'rejected') {
        throw StateError('Rejected submissions cannot be published directly.');
      }
      if (suggestion['rightsConfirmed'] == false) {
        throw StateError(
          'Contributor rights confirmation is required before publishing.',
        );
      }
      final targetId = (suggestion['termId'] as String?)?.trim() ?? '';
      if (targetId.isEmpty) {
        throw StateError('Target Dictionary entry is required.');
      }
      final baseEntry =
          _publishedById[targetId]?.data ?? _draftsById[targetId]?.data;
      if (baseEntry == null) {
        throw StateError('Target Dictionary entry not found.');
      }
      final currentRevision =
          _draftsById[targetId]?.data['revision'] as int? ??
          _publishedById[targetId]?.publishedRevision ??
          0;
      final expectedRevision = data['expectedRevision'] as int?;
      if (expectedRevision != null && expectedRevision != currentRevision) {
        throw StateError('This entry changed. Reload before publishing.');
      }

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
      final rawImages = (suggestion['submittedImages'] as List<dynamic>? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList();
      if (rawImages.isEmpty) {
        throw StateError('No submitted images found on this contribution.');
      }
      for (final img in rawImages) {
        final dec = decisionById[img['id']];
        final nextStatus =
            (dec?['status'] as String?) ??
            (img['reviewStatus'] == 'rejected' ? 'rejected' : 'approved');
        img['reviewStatus'] = nextStatus;
        if (dec?['caption'] != null) img['caption'] = dec!['caption'];
        if (dec?['explanation'] != null) {
          img['explanation'] = dec!['explanation'];
        }
        if (dec?['imageType'] != null) img['imageType'] = dec!['imageType'];
      }
      final approvedImages = rawImages
          .where((img) => img['reviewStatus'] == 'approved')
          .toList();
      final rejectedCount = rawImages
          .where((img) => img['reviewStatus'] == 'rejected')
          .length;
      if (approvedImages.isEmpty) {
        throw StateError('Approve at least one image before publishing.');
      }

      final contributorCredit = suggestion['recognitionConsent'] == true
          ? (suggestion['publicName'] as String?)?.trim()
          : null;
      final existingMedia = (baseEntry['media'] as List<dynamic>? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList();
      final approvedMediaEntries = approvedImages.map((img) {
        final caption = (img['caption'] as String?)?.trim() ?? '';
        final item = <String, dynamic>{
          'url': img['url'],
          'label': caption.isNotEmpty
              ? caption
              : (baseEntry['term'] as String? ?? 'Dictionary image'),
          if (img['imageType'] != null && img['imageType'] != 'illustrative')
            'imageType': img['imageType'],
          if (((img['explanation'] as String?)?.trim() ?? '').isNotEmpty)
            'explanation': (img['explanation'] as String).trim(),
          if (contributorCredit != null && contributorCredit.isNotEmpty)
            'attribution': contributorCredit,
        };
        return (id: img['id'] as String?, item: item);
      }).toList();

      final heroImageId = (data['heroImageId'] as String?) ?? '';
      late final List<Map<String, dynamic>> combinedMedia;
      if (heroImageId.startsWith('submitted:')) {
        final chosenId = heroImageId.substring('submitted:'.length);
        final heroMatch = approvedMediaEntries.where((e) => e.id == chosenId);
        if (heroMatch.isEmpty) {
          throw StateError(
            'Selected hero image must be an approved submitted image.',
          );
        }
        combinedMedia = [
          heroMatch.first.item,
          ...existingMedia,
          ...approvedMediaEntries
              .where((e) => e.id != chosenId)
              .map((e) => e.item),
        ];
      } else if (heroImageId.startsWith('existing:')) {
        final idx = int.tryParse(heroImageId.substring('existing:'.length));
        if (idx == null || idx < 0 || idx >= existingMedia.length) {
          throw StateError('Selected existing hero image is invalid.');
        }
        combinedMedia = [
          existingMedia[idx],
          for (var i = 0; i < existingMedia.length; i++)
            if (i != idx) existingMedia[i],
          ...approvedMediaEntries.map((e) => e.item),
        ];
      } else {
        combinedMedia = [
          ...existingMedia,
          ...approvedMediaEntries.map((e) => e.item),
        ];
      }

      if (combinedMedia.length > 8) {
        throw StateError('Publishing would exceed the 8-image limit.');
      }

      final nextRev = currentRevision + 1;
      final priorAttributions =
          (baseEntry['attributions'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList();
      final nextAttributions = <String>{
        ...priorAttributions,
        if (contributorCredit != null && contributorCredit.isNotEmpty)
          contributorCredit,
      }.toList();

      final stored = <String, dynamic>{
        ...baseEntry,
        'id': targetId,
        'slug': (baseEntry['slug'] as String?) ?? targetId,
        'media': combinedMedia,
        'attributions': nextAttributions,
        'status': 'published',
        'revision': nextRev,
        'publishedAt': DateTime.now().toIso8601String(),
      };
      _draftsById[targetId] = DictionaryEntry(stored);
      _publishedById[targetId] = DictionaryEntry(stored);
      _revisionsByEntryId.putIfAbsent(targetId, () => []).insert(0, stored);

      suggestion['submittedImages'] = rawImages;
      suggestion['status'] = 'published';
      suggestion['entryId'] = targetId;

      final note = (data['note'] as String?) ?? '';
      final nowIso = DateTime.now().toIso8601String();
      _suggestionHistory.putIfAbsent(id, () => [])
        ..insert(0, {
          'status': rejectedCount > 0 ? 'partially_approved' : 'approved',
          'note': note,
          'at': nowIso,
        })
        ..insert(0, {
          'status': 'published',
          'note': note,
          'entryId': targetId,
          'publishedImageCount': approvedImages.length,
          'rejectedImageCount': rejectedCount,
          'at': nowIso,
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
