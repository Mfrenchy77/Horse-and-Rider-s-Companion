// ignore_for_file: lines_longer_than_80_chars

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Uses the existing verified administrator claims and private suggestion/audit
/// pattern. Dictionary editors have no direct client write permissions.
class DictionaryAdminPage extends StatefulWidget {
  const DictionaryAdminPage({super.key, this.firestore, this.repository});
  static const path = '/DictionaryReview';

  final FirebaseFirestore? firestore;
  final DictionaryRepository? repository;

  @override
  State<DictionaryAdminPage> createState() => _DictionaryAdminPageState();
}

class _DictionaryAdminPageState extends State<DictionaryAdminPage> {
  FirebaseFirestore get _db => widget.firestore ?? FirebaseFirestore.instance;
  late final DictionaryRepository _repository =
      widget.repository ?? DictionaryRepository(firestore: widget.firestore);

  Future<List<Map<String, dynamic>>>? _items;
  String? _statusFilter;

  Future<List<Map<String, dynamic>>> _load() async {
    final result = await _db
        .collection('DictionarySuggestions')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return result.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  void _refresh() => setState(() => _items = _load());

  Future<void> _perform(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load the editor. Try again.')),
      );
    }
  }

  Future<List<DictionaryEntry>> _loadAllEntries() async {
    final published = await _repository.load();
    final drafts = await _db.collection('DictionaryDrafts').get();
    final entriesById = {for (final entry in published) entry.id: entry};
    for (final doc in drafts.docs) {
      entriesById[doc.id] = DictionaryEntry(doc.data());
    }
    return entriesById.values.toList()
      ..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
  }

  Future<void> _review(Map<String, dynamic> item, String status) async {
    final note = TextEditingController();
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) => _ReviewDialog(
        item: item,
        status: status,
        note: note,
        repository: _repository,
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _showAuditHistory(Map<String, dynamic> item) async {
    final id = item['id'] as String?;
    if (id == null || id.isEmpty) return;
    final snap = await _db
        .collection('DictionarySuggestions')
        .doc(id)
        .collection('AuditEvents')
        .orderBy('at', descending: true)
        .limit(30)
        .get();
    if (!mounted) return;
    final events = snap.docs.map((d) => d.data()).toList();
    await showAppGlassDialog<void>(
      context: context,
      builder: (ctx) => AppGlassDialog(
        title: Text('Contribution history · ${item['term'] ?? ''}'),
        content: events.isEmpty
            ? const Text('No review decisions recorded yet.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  for (final ev in events)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(
                          color: Theme.of(ctx).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(
                            ((ev['status'] as String?) ?? 'event').replaceAll(
                              '_',
                              ' ',
                            ),
                            style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if ((ev['note'] as String?)?.trim().isNotEmpty ??
                              false)
                            Text(ev['note'] as String),
                        ],
                      ),
                    ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit({Map<String, dynamic>? suggestion}) async {
    final allEntries = await _loadAllEntries();
    if (!mounted) return;
    final initial = suggestion == null
        ? null
        : DictionaryRepository.resolve(
            allEntries,
            ((suggestion['termId'] as String?)?.trim().isNotEmpty ?? false)
                ? suggestion['termId'] as String
                : (suggestion['term'] as String? ?? ''),
          );
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) => _EntryEditor(
        firestore: _db,
        repository: _repository,
        existingEntries: allEntries,
        initial: initial,
        suggestion: suggestion,
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _existing() async {
    final entries = await _loadAllEntries();
    if (!mounted) return;
    final selected = await showAppGlassDialog<DictionaryEntry>(
      context: context,
      builder: (ctx) => AppGlassDialog(
        title: const Text('Edit a definition'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: entries.length,
            itemBuilder: (_, index) {
              final entry = entries[index];
              final status = (entry.data['status'] as String?) ?? 'published';
              return ListTile(
                title: Text(entry.term),
                subtitle: Text('/Dictionary/${entry.slug} · $status'),
                onTap: () => Navigator.pop(ctx, entry),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) => _EntryEditor(
        firestore: _db,
        repository: _repository,
        existingEntries: entries,
        initial: selected,
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppCubit>().state;
    final isAuthorizedAdmin =
        !appState.isGuest &&
        appState.isAdmin &&
        (widget.firestore != null || appState.user.emailVerified);
    if (!isAuthorizedAdmin) {
      return Scaffold(
        appBar: ThemedAppBar(title: const Text('Dictionary review')),
        body: const Center(child: Text('Administrator access required.')),
      );
    }
    _items ??= _load();
    return Scaffold(
      appBar: ThemedAppBar(
        title: const Text('Dictionary review'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: AppScaffoldBackdrop(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          key: const Key('dictionaryAdminNewButton'),
                          onPressed: () => _perform(_edit),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New definition'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('dictionaryAdminEditExistingButton'),
                          onPressed: () => _perform(_existing),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit published definition'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _statusFilter == null,
                          onSelected: (_) =>
                              setState(() => _statusFilter = null),
                        ),
                        for (final status in const [
                          'submitted',
                          'under_review',
                          'needs_clarification',
                          'approved',
                          'published',
                          'rejected',
                        ])
                          ChoiceChip(
                            label: Text(status.replaceAll('_', ' ')),
                            selected: _statusFilter == status,
                            onSelected: (sel) => setState(
                              () => _statusFilter = sel ? status : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _items,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const AppFeedbackBanner(
                            message: 'Could not load submissions. Try Refresh.',
                            tone: AppStatusTone.error,
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final filtered = snapshot.data!
                            .where(
                              (item) =>
                                  _statusFilter == null ||
                                  item['status'] == _statusFilter,
                            )
                            .toList();
                        if (filtered.isEmpty) {
                          return AppSurfaceCard(
                            child: Text(
                              _statusFilter == null
                                  ? 'No Dictionary submissions yet.'
                                  : 'No submissions with status '
                                        '${_statusFilter!.replaceAll('_', ' ')}.',
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final item in filtered)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppSurfaceCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            item['term'] as String,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          AppStatusBadge(
                                            label:
                                                ((item['status'] as String?) ??
                                                        'submitted')
                                                    .replaceAll('_', ' '),
                                            tone: switch (item['status']) {
                                              'approved' ||
                                              'published' =>
                                                AppStatusTone.success,
                                              'needs_clarification' =>
                                                AppStatusTone.warning,
                                              'rejected' => AppStatusTone.error,
                                              _ => AppStatusTone.info,
                                            },
                                          ),
                                          if ((item['kind'] as String?)
                                                  ?.isNotEmpty ??
                                              false)
                                            AppStatusBadge(
                                              label: (item['kind'] as String)
                                                  .replaceAll('_', ' '),
                                            ),
                                          if (item['contributorUid'] != null)
                                            const AppStatusBadge(
                                              label: 'Signed-in contributor',
                                            )
                                          else
                                            const AppStatusBadge(
                                              label: 'Guest contributor',
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(item['proposal'] as String),
                                      const SizedBox(height: 10),
                                      if (item['recognitionConsent'] == true &&
                                          ((item['publicName'] as String?)
                                                  ?.isNotEmpty ??
                                              false))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Text(
                                            'Opt-in recognition requested as: '
                                            '${item['publicName']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppTokens.secondaryTextColor(
                                                        context,
                                                      ),
                                                ),
                                          ),
                                        ),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final status in const [
                                            'under_review',
                                            'needs_clarification',
                                            'approved',
                                            'rejected',
                                          ])
                                            TextButton(
                                              onPressed:
                                                  item['status'] == 'published'
                                                  ? null
                                                  : () => _review(item, status),
                                              child: Text(
                                                status.replaceAll('_', ' '),
                                              ),
                                            ),
                                          TextButton.icon(
                                            onPressed: () => _perform(
                                              () => _showAuditHistory(item),
                                            ),
                                            icon: const Icon(
                                              Icons.history,
                                              size: 16,
                                            ),
                                            label: const Text('History'),
                                          ),
                                          OutlinedButton(
                                            onPressed:
                                                item['status'] == 'approved'
                                                ? () => _perform(
                                                    () => _edit(
                                                      suggestion: item,
                                                    ),
                                                  )
                                                : null,
                                            child: const Text(
                                              'Incorporate wording',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({
    required this.item,
    required this.status,
    required this.note,
    required this.repository,
  });
  final Map<String, dynamic> item;
  final String status;
  final TextEditingController note;
  final DictionaryRepository repository;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  bool _busy = false;
  String? _error;
  @override
  Widget build(BuildContext context) => AppGlassDialog(
    title: Text(widget.status.replaceAll('_', ' ')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        TextField(
          controller: widget.note,
          maxLength: 2000,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Private review note'),
        ),
        if (widget.status == 'needs_clarification')
          const Text(
            'The clarification request is recorded privately in the audit '
            'log. Automated email delivery is planned for a later milestone.',
          ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy
            ? null
            : () async {
                setState(() => _busy = true);
                try {
                  await widget.repository.call('editDictionary', {
                    'action': 'review',
                    'id': widget.item['id'],
                    'status': widget.status,
                    'note': widget.note.text,
                  });
                  if (context.mounted) Navigator.pop(context);
                } catch (error) {
                  if (mounted) {
                    setState(() {
                      _error = error.toString();
                      _busy = false;
                    });
                  }
                }
              },
        child: const Text('Save review'),
      ),
    ],
  );
}

class _EntryEditor extends StatefulWidget {
  const _EntryEditor({
    required this.firestore,
    required this.repository,
    required this.existingEntries,
    this.initial,
    this.suggestion,
  });
  final FirebaseFirestore firestore;
  final DictionaryRepository repository;
  final List<DictionaryEntry> existingEntries;
  final DictionaryEntry? initial;
  final Map<String, dynamic>? suggestion;
  @override
  State<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<_EntryEditor> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  int _revision = 0;
  bool _busy = true;
  bool _contextual = false;
  String? _error;
  bool _existingDraft = false;
  bool _slugManuallyEdited = false;
  String? _suggestionId;

  static const lists = [
    'synonyms',
    'categories',
    'relatedTerms',
    'skillIds',
    'resourceIds',
    'examples',
  ];
  static const fields = [
    'id',
    'slug',
    'term',
    'definition',
    'explanation',
    'synonyms',
    'categories',
    'usage',
    'regionalUsage',
    'examples',
    'relatedTerms',
    'skillIds',
    'resourceIds',
  ];

  static String _slugify(String raw) => raw
      .toLowerCase()
      .trim()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  @override
  void initState() {
    super.initState();
    for (final key in fields) {
      _fields[key] = TextEditingController();
    }
    _fields['term']!.addListener(_syncSlugFromTerm);
    _load();
  }

  void _syncSlugFromTerm() {
    if (widget.initial != null || _existingDraft || _slugManuallyEdited) return;
    final generated = _slugify(_fields['term']!.text);
    if (generated.isNotEmpty) {
      _fields['id']!.text = generated;
      _fields['slug']!.text = generated;
    }
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final suggestedTerm = (widget.suggestion?['term'] as String?) ?? '';
      final suggestedSlug = _slugify(suggestedTerm);
      final initial =
          widget.initial?.data ??
          <String, dynamic>{
            if (suggestedSlug.isNotEmpty) 'id': suggestedSlug,
            if (suggestedSlug.isNotEmpty) 'slug': suggestedSlug,
            'term': suggestedTerm,
            'definition': widget.suggestion?['proposal'] ?? '',
          };
      var data = initial;
      if (initial['id'] != null && (initial['id'] as String).isNotEmpty) {
        final draft = await widget.firestore
            .collection('DictionaryDrafts')
            .doc(initial['id'] as String)
            .get();
        if (draft.exists) {
          data = draft.data()!;
          _existingDraft = true;
        }
      }
      _revision = _existingDraft || !(widget.initial?.bundled ?? true)
          ? data['revision'] as int? ?? 0
          : 0;
      _suggestionId =
          data['suggestionId'] as String? ??
          widget.suggestion?['id'] as String?;
      _contextual = data['contextual'] == true;
      for (final key in fields) {
        _fields[key]!.text = lists.contains(key)
            ? (data[key] as List<dynamic>? ?? []).join('\n')
            : data[key] as String? ?? '';
      }
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _fields['term']?.removeListener(_syncSlugFromTerm);
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _currentEntryPayload() => <String, dynamic>{
    for (final key in fields)
      key: lists.contains(key)
          ? _fields[key]!.text
                .split('\n')
                .map((text) => text.trim())
                .where((text) => text.isNotEmpty)
                .toList()
          : _fields[key]!.text.trim(),
    'contextual': _contextual,
    'media': widget.initial?.data['media'] ?? <dynamic>[],
    'status': 'published',
  };

  DictionaryEntry? _conflictingTermMatch() {
    final currentId = _fields['id']!.text.trim().toLowerCase();
    final currentTerm = _fields['term']!.text.trim().toLowerCase();
    if (currentTerm.isEmpty) return null;
    for (final existing in widget.existingEntries) {
      if (existing.id == currentId) continue;
      final names = {
        existing.term.toLowerCase(),
        ...existing.strings('synonyms').map((s) => s.toLowerCase()),
      };
      if (names.contains(currentTerm)) return existing;
    }
    return null;
  }

  Future<void> _openPreview() async {
    final previewEntry = DictionaryEntry(_currentEntryPayload());
    await showAppGlassDialog<void>(
      context: context,
      builder: (ctx) => AppGlassDialog(
        maxWidth: 620,
        title: Text('Preview · ${previewEntry.term.isEmpty ? 'Untitled' : previewEntry.term}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              '/Dictionary/${previewEntry.slug}',
              style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                color: AppTokens.secondaryTextColor(ctx),
              ),
            ),
            if (previewEntry.strings('categories').isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final cat in previewEntry.strings('categories'))
                    AppStatusBadge(label: cat, tone: AppStatusTone.info),
                ],
              ),
            Text(
              previewEntry.definition,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            if (previewEntry.strings('synonyms').isNotEmpty)
              Text('Also called: ${previewEntry.strings('synonyms').join(' · ')}'),
            if (previewEntry.explanation.isNotEmpty)
              DictionaryText(
                text: previewEntry.explanation,
                entries: widget.existingEntries
                    .where((other) => other.id != previewEntry.id)
                    .toList(),
              ),
            if (previewEntry.text('usage').isNotEmpty)
              Text('Usage: ${previewEntry.text('usage')}'),
            if (previewEntry.text('regionalUsage').isNotEmpty)
              Text('Regional variations: ${previewEntry.text('regionalUsage')}'),
            if (previewEntry.strings('examples').isNotEmpty)
              Text('Examples:\n${previewEntry.strings('examples').join('\n')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close preview'),
          ),
        ],
      ),
    );
  }

  Future<void> _openRevisions() async {
    final id = _fields['id']!.text.trim();
    if (id.isEmpty) return;
    final snap = await widget.firestore
        .collection('DictionaryDrafts')
        .doc(id)
        .collection('Revisions')
        .get();
    if (!mounted) return;
    final revisions = snap.docs.map((d) => d.data()).toList()
      ..sort(
        (a, b) =>
            ((b['revision'] as int?) ?? 0).compareTo((a['revision'] as int?) ?? 0),
      );
    await showAppGlassDialog<void>(
      context: context,
      builder: (ctx) => AppGlassDialog(
        maxWidth: 560,
        title: Text('Revision history · ${_fields['term']!.text.trim()}'),
        content: revisions.isEmpty
            ? const Text('No saved server revisions yet.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  for (final rev in revisions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Revision ${rev['revision']} · ${rev['status'] ?? 'draft'}',
                      ),
                      subtitle: Text(
                        (rev['definition'] as String?) ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(String action) async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final entry = _currentEntryPayload()..remove('status');
      await widget.repository.call('editDictionary', {
        'action': action,
        'id': entry['id'],
        'entry': entry,
        'expectedRevision': _revision,
        'suggestionId': _suggestionId,
      });
      if (action == 'publish') {
        DictionaryRepository.invalidateCache();
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewEntry = widget.initial == null && !_existingDraft;
    final duplicateMatch = _conflictingTermMatch();

    return PopScope(
      canPop: !_busy,
      child: AppGlassDialog(
        maxWidth: 760,
        title: Text(
          isNewEntry
              ? 'New Dictionary definition'
              : 'Review definition (rev $_revision)',
        ),
        content: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.suggestion != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Submitted wording: ${widget.suggestion!['proposal']}',
                  ),
                ),
              if (duplicateMatch != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppFeedbackBanner(
                    key: const Key('dictionaryDuplicateTermWarning'),
                    message:
                        '“${_fields['term']!.text.trim()}” already matches '
                        'canonical entry “${duplicateMatch.term}” '
                        '(/Dictionary/${duplicateMatch.slug}). Edit that '
                        'entry or add a synonym unless this is a distinct '
                        'meaning with its own slug.',
                    tone: AppStatusTone.warning,
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('dictionaryPreviewButton'),
                    onPressed: _busy ? null : _openPreview,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Preview'),
                  ),
                  if (!isNewEntry)
                    OutlinedButton.icon(
                      key: const Key('dictionaryRevisionHistoryButton'),
                      onPressed: _busy ? null : _openRevisions,
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('Revision history'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final key in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    key: Key('dictionaryField_$key'),
                    controller: _fields[key],
                    enabled:
                        !_busy &&
                        (!const ['id', 'slug'].contains(key) || isNewEntry),
                    onChanged: (value) {
                      if (key == 'id' || key == 'slug') {
                        _slugManuallyEdited = true;
                      }
                      if (key == 'term') setState(() {});
                    },
                    minLines:
                        const [
                          'definition',
                          'explanation',
                          'examples',
                        ].contains(key)
                        ? 3
                        : 1,
                    maxLines:
                        [
                          'definition',
                          'explanation',
                          ...lists,
                        ].contains(key)
                        ? 8
                        : 1,
                    decoration: InputDecoration(
                      labelText:
                          key + (lists.contains(key) ? ' (one per line)' : ''),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (const [
                            'id',
                            'slug',
                            'term',
                            'definition',
                          ].contains(key) &&
                          trimmed.isEmpty) {
                        return 'Required';
                      }
                      if (isNewEntry && key == 'id') {
                        final exists = widget.existingEntries.any(
                          (e) => e.id == trimmed.toLowerCase(),
                        );
                        if (exists) {
                          return 'ID already exists — edit the existing entry.';
                        }
                      }
                      if (isNewEntry && key == 'slug') {
                        final exists = widget.existingEntries.any(
                          (e) => e.slug == trimmed.toLowerCase(),
                        );
                        if (exists) {
                          return 'URL slug already exists.';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _contextual,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _contextual = value!),
                title: const Text(
                  'Allow contextual matching (unambiguous terms only)',
                ),
              ),
              const Text(
                'Review meaning, examples, welfare, usage, licensing, '
                'and contributor consent before publishing.',
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: _busy ? null : () => _save('save'),
            child: const Text('Save draft'),
          ),
          FilledButton(
            onPressed: _busy ? null : () => _save('publish'),
            child: const Text('Publish reviewed definition'),
          ),
        ],
      ),
    );
  }
}
