// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:typed_data';

import 'package:database_repository/database_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_diff.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class _InboxBundle {
  const _InboxBundle({required this.items, required this.publishedEntries});

  final List<Map<String, dynamic>> items;
  final List<DictionaryEntry> publishedEntries;
}

bool _detectRevisionMismatch({
  required Map<String, dynamic> suggestion,
  required DictionaryEntry? currentPublished,
}) {
  if (currentPublished == null) return false;
  final baseRev = suggestion['baseRevision'] as int?;
  final currentRev = currentPublished.publishedRevision;
  if (baseRev != null && currentRev != baseRev) {
    return true;
  }
  final rawBase = suggestion['baseFields'];
  if (rawBase is Map) {
    final baseFields = DictionaryStructuredFields.fromMap(
      rawBase.cast<String, dynamic>(),
    );
    final liveFields = DictionaryStructuredFields.fromEntry(currentPublished);
    if (!baseFields.equals(liveFields)) {
      return true;
    }
  }
  return false;
}

/// Picked image payload for Dictionary admin uploads (injectable in tests).
typedef DictionaryImagePicker =
    Future<({String name, Uint8List bytes})?> Function();

/// Uses the existing verified administrator claims and private suggestion/audit
/// pattern. Dictionary editors have no direct client write permissions.
class DictionaryAdminPage extends StatefulWidget {
  const DictionaryAdminPage({
    super.key,
    this.firestore,
    this.repository,
    this.mediaStorage,
    this.pickImageFile,
  });
  static const path = '/DictionaryReview';

  /// Optional legacy Firestore passthrough when [repository] is omitted.
  final Object? firestore;
  final DictionaryRepository? repository;
  final MediaStorageRepository? mediaStorage;
  final DictionaryImagePicker? pickImageFile;

  @override
  State<DictionaryAdminPage> createState() => _DictionaryAdminPageState();
}

class _DictionaryAdminPageState extends State<DictionaryAdminPage> {
  late final DictionaryRepository _repository =
      widget.repository ??
      DictionaryRepository.withLegacyFirestore(widget.firestore);

  Future<_InboxBundle>? _inbox;
  String? _statusFilter;

  Future<_InboxBundle> _load() async {
    final results = await Future.wait<dynamic>([
      _repository.loadSuggestions(),
      _repository.load(),
    ]);
    final items = results[0] as List<Map<String, dynamic>>;
    final published = results[1] as List<DictionaryEntry>;
    return _InboxBundle(items: items, publishedEntries: published);
  }

  void _refresh() => setState(() => _inbox = _load());

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
    final drafts = await _repository.loadDrafts();
    final entriesById = {for (final entry in published) entry.id: entry};
    for (final draft in drafts) {
      entriesById[draft.id] = draft;
    }
    return entriesById.values.toList()
      ..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
  }

  DictionaryEntry? _resolveSuggestionTarget(
    List<DictionaryEntry> entries,
    Map<String, dynamic> suggestion,
  ) {
    final lookup =
        ((suggestion['termId'] as String?)?.trim().isNotEmpty ?? false)
        ? suggestion['termId'] as String
        : (suggestion['term'] as String? ?? '');
    if (lookup.trim().isEmpty) return null;
    return DictionaryRepository.resolve(entries, lookup);
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

  Future<void> _editProposal(
    Map<String, dynamic> item,
    DictionaryEntry? targetPublished,
  ) async {
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) => _EditProposalDialog(
        item: item,
        targetPublished: targetPublished,
        repository: _repository,
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _showAuditHistory(Map<String, dynamic> item) async {
    final id = item['id'] as String?;
    if (id == null || id.isEmpty) return;
    final events = await _repository.loadSuggestionHistory(id);
    if (!mounted) return;
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
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                ((ev['status'] as String?) ?? 'event')
                                    .replaceAll('_', ' '),
                                style: Theme.of(ctx).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (ev['proposalEdited'] == true)
                                const AppStatusBadge(
                                  label: 'Proposal edited',
                                  tone: AppStatusTone.info,
                                ),
                            ],
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
    final published = await _repository.load();
    final drafts = await _repository.loadDrafts();
    if (!mounted) return;
    final entriesById = {for (final entry in published) entry.id: entry};
    for (final draft in drafts) {
      entriesById[draft.id] = draft;
    }
    final allEntries = entriesById.values.toList()
      ..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
    final publishedTarget = suggestion == null
        ? null
        : _resolveSuggestionTarget(published, suggestion);
    final initial = suggestion == null
        ? null
        : (publishedTarget != null
              ? entriesById[publishedTarget.id] ?? publishedTarget
              : _resolveSuggestionTarget(allEntries, suggestion));
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) => _EntryEditor(
        repository: _repository,
        mediaStorage: widget.mediaStorage,
        pickImageFile: widget.pickImageFile,
        existingEntries: allEntries,
        initial: initial,
        publishedTarget: publishedTarget,
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
        repository: _repository,
        mediaStorage: widget.mediaStorage,
        pickImageFile: widget.pickImageFile,
        existingEntries: entries,
        initial: selected,
      ),
    );
    if (mounted) _refresh();
  }

  Widget _buildSuggestionDiffSection(
    BuildContext context, {
    required Map<String, dynamic> item,
    required DictionaryEntry? targetPublished,
  }) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final rawProposed = item['proposedFields'];
    final rawBase = item['baseFields'];
    final reason = (item['reason'] as String?)?.trim() ?? '';
    final mismatch = _detectRevisionMismatch(
      suggestion: item,
      currentPublished: targetPublished,
    );
    final baseRev = item['baseRevision'] as int?;
    final currentRev = targetPublished?.publishedRevision;

    if (rawProposed is! Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (mismatch)
            AppFeedbackBanner(
              key: Key('suggestionRevisionMismatch_${item['id']}'),
              message:
                  'Published definition changed since this suggestion was '
                  'submitted (submitted against rev ${baseRev ?? 0}, current '
                  'rev ${currentRev ?? 0}). Review current wording carefully '
                  'before applying.',
              tone: AppStatusTone.warning,
            ),
          Text(item['proposal'] as String? ?? ''),
          if (reason.isNotEmpty)
            _ReasonCallout(reason: reason, secondaryColor: secondaryColor),
        ],
      );
    }

    final proposed = DictionaryStructuredFields.fromMap(
      rawProposed.cast<String, dynamic>(),
    );
    final base = rawBase is Map
        ? DictionaryStructuredFields.fromMap(rawBase.cast<String, dynamic>())
        : (targetPublished != null
              ? DictionaryStructuredFields.fromEntry(targetPublished)
              : const DictionaryStructuredFields());
    final currentFields = targetPublished != null
        ? DictionaryStructuredFields.fromEntry(targetPublished)
        : null;

    final keysToShow = <String>{
      ...proposed.changedKeysAgainst(base),
      if (mismatch && currentFields != null)
        ...currentFields.changedKeysAgainst(base),
    };
    final orderedKeys = [
      for (final spec in DictionaryStructuredFields.specs)
        if (keysToShow.contains(spec.key)) spec.key,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        if (mismatch)
          AppFeedbackBanner(
            key: Key('suggestionRevisionMismatch_${item['id']}'),
            message:
                'Published definition changed while this suggestion was '
                'pending (submitted against rev ${baseRev ?? 0}, current '
                'published rev ${currentRev ?? 0}). Old, current, and '
                'proposed wording are shown below and require explicit '
                'review before applying.',
            tone: AppStatusTone.warning,
          ),
        const DictionaryDiffLegend(),
        if (orderedKeys.isEmpty)
          Text(item['proposal'] as String? ?? '')
        else
          for (final key in orderedKeys)
            DictionaryFieldDiffCard(
              fieldKey: '${item['id']}_$key',
              label: DictionaryStructuredFields.labelForKey(key),
              oldText: base.displayTextFor(key),
              proposedText: proposed.displayTextFor(key),
              currentPublishedText: mismatch
                  ? currentFields?.displayTextFor(key)
                  : null,
              baseRevision: baseRev,
              currentRevision: currentRev,
            ),
        if (reason.isNotEmpty)
          _ReasonCallout(reason: reason, secondaryColor: secondaryColor),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppCubit>().state;
    final isAuthorizedAdmin =
        !appState.isGuest &&
        appState.isAdmin &&
        (widget.firestore != null ||
            widget.repository != null ||
            appState.user.emailVerified);
    if (!isAuthorizedAdmin) {
      return Scaffold(
        appBar: ThemedAppBar(title: const Text('Dictionary review')),
        body: const Center(child: Text('Administrator access required.')),
      );
    }
    _inbox ??= _load();
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
                    FutureBuilder<_InboxBundle>(
                      future: _inbox,
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
                        final bundle = snapshot.data!;
                        final filtered = bundle.items
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
                              Builder(
                                builder: (context) {
                                  final target = _resolveSuggestionTarget(
                                    bundle.publishedEntries,
                                    item,
                                  );
                                  return Padding(
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
                                                    ((item['status']
                                                                as String?) ??
                                                            'submitted')
                                                        .replaceAll('_', ' '),
                                                tone: switch (item['status']) {
                                                  'approved' || 'published' =>
                                                    AppStatusTone.success,
                                                  'needs_clarification' =>
                                                    AppStatusTone.warning,
                                                  'rejected' =>
                                                    AppStatusTone.error,
                                                  _ => AppStatusTone.info,
                                                },
                                              ),
                                              if ((item['kind'] as String?)
                                                      ?.isNotEmpty ??
                                                  false)
                                                AppStatusBadge(
                                                  label:
                                                      dictionaryContributionLabel(
                                                        item['kind'] as String?,
                                                      ),
                                                ),
                                              if (item['contributorUid'] !=
                                                  null)
                                                const AppStatusBadge(
                                                  label:
                                                      'Signed-in contributor',
                                                )
                                              else
                                                const AppStatusBadge(
                                                  label: 'Guest contributor',
                                                ),
                                              if (item['editedByAdminUid'] !=
                                                  null)
                                                const AppStatusBadge(
                                                  label:
                                                      'Proposal edited by admin',
                                                  tone: AppStatusTone.info,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          _buildSuggestionDiffSection(
                                            context,
                                            item: item,
                                            targetPublished: target,
                                          ),
                                          const SizedBox(height: 10),
                                          if (item['recognitionConsent'] ==
                                                  true &&
                                              ((item['publicName'] as String?)
                                                      ?.isNotEmpty ??
                                                  false))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Text(
                                                'Opt-in recognition requested '
                                                'as: ${item['publicName']}',
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
                                                      item['status'] ==
                                                          'published'
                                                      ? null
                                                      : () => _review(
                                                          item,
                                                          status,
                                                        ),
                                                  child: Text(
                                                    status.replaceAll('_', ' '),
                                                  ),
                                                ),
                                              TextButton.icon(
                                                key: Key(
                                                  'editProposalButton_${item['id']}',
                                                ),
                                                onPressed:
                                                    item['status'] ==
                                                        'published'
                                                    ? null
                                                    : () => _perform(
                                                        () => _editProposal(
                                                          item,
                                                          target,
                                                        ),
                                                      ),
                                                icon: const Icon(
                                                  Icons.edit_note_outlined,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'Edit proposal',
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
                                                key: Key(
                                                  'incorporateWording_${item['id']}',
                                                ),
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
                                  );
                                },
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

class _ReasonCallout extends StatelessWidget {
  const _ReasonCallout({required this.reason, required this.secondaryColor});

  final String reason;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            'Why contributor suggested this change',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: secondaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(reason),
        ],
      ),
    );
  }
}

class _EditProposalDialog extends StatefulWidget {
  const _EditProposalDialog({
    required this.item,
    required this.targetPublished,
    required this.repository,
  });

  final Map<String, dynamic> item;
  final DictionaryEntry? targetPublished;
  final DictionaryRepository repository;

  @override
  State<_EditProposalDialog> createState() => _EditProposalDialogState();
}

class _EditProposalDialogState extends State<_EditProposalDialog> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  late final TextEditingController _freeTextProposal;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _isStructured =>
      widget.item['proposedFields'] is Map || widget.targetPublished != null;

  @override
  void initState() {
    super.initState();
    final rawProposed = widget.item['proposedFields'];
    final initialFields = rawProposed is Map
        ? DictionaryStructuredFields.fromMap(
            rawProposed.cast<String, dynamic>(),
          )
        : (widget.targetPublished != null
              ? DictionaryStructuredFields.fromEntry(widget.targetPublished!)
              : const DictionaryStructuredFields());
    for (final spec in DictionaryStructuredFields.specs) {
      _controllers[spec.key] = TextEditingController(
        text: initialFields.displayTextFor(spec.key),
      );
    }
    _freeTextProposal = TextEditingController(
      text: widget.item['proposal'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _freeTextProposal.dispose();
    _note.dispose();
    super.dispose();
  }

  DictionaryStructuredFields _editedStructuredFields() {
    return DictionaryStructuredFields(
      definition: _controllers['definition']?.text.trim() ?? '',
      explanation: _controllers['explanation']?.text.trim() ?? '',
      usage: _controllers['usage']?.text.trim() ?? '',
      regionalUsage: _controllers['regionalUsage']?.text.trim() ?? '',
      examples: DictionaryStructuredFields.normalizeLines(
        (_controllers['examples']?.text ?? '').split('\n'),
      ),
      synonyms: DictionaryStructuredFields.normalizeLines(
        (_controllers['synonyms']?.text ?? '').split('\n'),
      ),
    );
  }

  Future<void> _save({required bool approve}) async {
    if (!(_form.currentState?.validate() ?? false) || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = approve
          ? 'approved'
          : ((widget.item['status'] as String?) ?? 'under_review');
      final payload = <String, dynamic>{
        'action': 'review',
        'id': widget.item['id'],
        'status': status,
        'note': _note.text.trim(),
      };
      if (_isStructured) {
        payload['editedFields'] = _editedStructuredFields().toMap();
      } else {
        payload['editedProposal'] = _freeTextProposal.text.trim();
      }
      await widget.repository.call('editDictionary', payload);
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
    return AppGlassDialog(
      maxWidth: 680,
      title: Text('Edit proposal · ${widget.item['term'] ?? ''}'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isStructured)
              for (final spec in DictionaryStructuredFields.specs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    key: Key('adminEditProposal_${spec.key}'),
                    controller: _controllers[spec.key],
                    maxLength: spec.maxLength,
                    minLines: spec.minLines,
                    maxLines: spec.maxLines,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      labelText: spec.isList
                          ? '${spec.label} (one per line)'
                          : spec.label,
                    ),
                    validator: (value) {
                      if (spec.requiredField &&
                          (value?.trim().isEmpty ?? true)) {
                        return 'Short definition is required.';
                      }
                      return null;
                    },
                  ),
                )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  key: const Key('adminEditProposal_freeText'),
                  controller: _freeTextProposal,
                  maxLength: 4000,
                  minLines: 3,
                  maxLines: 6,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Proposed wording',
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Proposed wording is required.'
                      : null,
                ),
              ),
            TextFormField(
              key: const Key('adminEditProposal_note'),
              controller: _note,
              maxLength: 2000,
              minLines: 2,
              maxLines: 3,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Private editorial note (optional)',
              ),
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
          key: const Key('saveEditedProposalButton'),
          onPressed: _busy ? null : () => _save(approve: false),
          child: const Text('Save edited proposal'),
        ),
        FilledButton(
          key: const Key('saveAndApproveProposalButton'),
          onPressed: _busy ? null : () => _save(approve: true),
          child: const Text('Save & approve'),
        ),
      ],
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
    required this.repository,
    required this.existingEntries,
    this.mediaStorage,
    this.pickImageFile,
    this.initial,
    this.publishedTarget,
    this.suggestion,
  });
  final DictionaryRepository repository;
  final MediaStorageRepository? mediaStorage;
  final DictionaryImagePicker? pickImageFile;
  final List<DictionaryEntry> existingEntries;
  final DictionaryEntry? initial;
  final DictionaryEntry? publishedTarget;
  final Map<String, dynamic>? suggestion;
  @override
  State<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<_EntryEditor> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  final List<String> _mediaUrls = [];
  final List<TextEditingController> _mediaLabelControllers = [];
  final Set<String> _persistedMediaUrls = {};
  final Set<String> _sessionUploadedDraftUrls = {};
  MediaStorageRepository? _resolvedStorage;
  bool _savedOrPublished = false;
  int _revision = 0;
  bool _busy = true;
  bool _uploadingMedia = false;
  double _uploadProgress = 0;
  bool _contextual = false;
  String? _error;
  String? _mediaError;
  bool _existingDraft = false;
  bool _slugManuallyEdited = false;
  bool _acknowledgedMismatch = false;
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

  bool get _hasRevisionMismatch {
    final suggestion = widget.suggestion;
    if (suggestion == null) return false;
    return _detectRevisionMismatch(
      suggestion: suggestion,
      currentPublished: widget.publishedTarget,
    );
  }

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
      if (_mediaUrls.isEmpty && !_uploadingMedia) {
        _fields['id']!.text = generated;
      }
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
      var data = Map<String, dynamic>.from(initial);
      if (initial['id'] != null && (initial['id'] as String).isNotEmpty) {
        final draft = await widget.repository.loadDraft(
          initial['id'] as String,
        );
        if (draft != null) {
          data = Map<String, dynamic>.from(draft.data);
          _existingDraft = true;
        }
      }

      // Apply ONLY the structured fields modified by the suggestion so
      // unchanged fields on the live/draft entry remain intact.
      final rawProposed = widget.suggestion?['proposedFields'];
      if (rawProposed is Map) {
        final proposed = DictionaryStructuredFields.fromMap(
          rawProposed.cast<String, dynamic>(),
        );
        final rawBase = widget.suggestion?['baseFields'];
        final base = rawBase is Map
            ? DictionaryStructuredFields.fromMap(
                rawBase.cast<String, dynamic>(),
              )
            : (widget.publishedTarget != null
                  ? DictionaryStructuredFields.fromEntry(
                      widget.publishedTarget!,
                    )
                  : const DictionaryStructuredFields());
        data = proposed.applyChangedFieldsToEntry(data, base: base);
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
      _clearMediaControllers();
      _persistedMediaUrls.clear();
      final existingMedia = data['media'] as List<dynamic>? ?? const [];
      for (final rawItem in existingMedia) {
        if (rawItem is Map) {
          final url = (rawItem['url'] as String?)?.trim() ?? '';
          final label = (rawItem['label'] as String?)?.trim() ?? '';
          if (url.isNotEmpty) {
            _mediaUrls.add(url);
            _persistedMediaUrls.add(url);
            _mediaLabelControllers.add(TextEditingController(text: label));
          }
        }
      }
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _busy = false);
  }

  void _clearMediaControllers() {
    for (final controller in _mediaLabelControllers) {
      controller.dispose();
    }
    _mediaLabelControllers.clear();
    _mediaUrls.clear();
  }

  @override
  void dispose() {
    if (!_savedOrPublished) {
      _cleanupSessionDraftUrls(_sessionUploadedDraftUrls.toList());
    }
    _fields['term']?.removeListener(_syncSlugFromTerm);
    for (final controller in _fields.values) {
      controller.dispose();
    }
    _clearMediaControllers();
    super.dispose();
  }

  void _cleanupSessionDraftUrls(Iterable<String> urls) {
    final storage = _resolvedStorage ?? widget.mediaStorage;
    if (storage == null) return;
    for (final url in urls) {
      if (_persistedMediaUrls.contains(url)) continue;
      if (!_sessionUploadedDraftUrls.contains(url)) continue;
      _sessionUploadedDraftUrls.remove(url);
      unawaited(storage.deleteByUrl(url).catchError((Object _) {}));
    }
  }

  List<Map<String, dynamic>> _mediaPayload() => [
    for (var i = 0; i < _mediaUrls.length; i++)
      {'url': _mediaUrls[i], 'label': _mediaLabelControllers[i].text.trim()},
  ];

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
    'media': _mediaPayload(),
    'status': 'published',
  };

  Future<({String name, Uint8List bytes})?> _defaultPickImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return (name: file.name, bytes: bytes);
  }

  String _defaultCaptionFromFileName(String fileName) {
    final withoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final cleaned = withoutExt.replaceAll(RegExp('[-_]+'), ' ').trim();
    if (cleaned.isEmpty) return 'Dictionary illustration';
    return cleaned.length > 120 ? cleaned.substring(0, 120) : cleaned;
  }

  Future<void> _pickAndUploadImage({int? replaceIndex}) async {
    if (_busy || _uploadingMedia) return;
    final entryId = _fields['id']!.text.trim().toLowerCase();
    if (entryId.isEmpty) {
      setState(() {
        _mediaError = 'Enter a term or ID before uploading images.';
      });
      return;
    }
    if (replaceIndex == null && _mediaUrls.length >= maxDictionaryMediaItems) {
      setState(() {
        _mediaError =
            'Up to $maxDictionaryMediaItems images are allowed per definition.';
      });
      return;
    }

    setState(() {
      _mediaError = null;
    });

    try {
      final picked = await (widget.pickImageFile ?? _defaultPickImage)();
      if (picked == null) return;

      final validated = DictionaryImageValidator.validate(
        bytes: picked.bytes,
        fileName: picked.name,
      );

      if (!mounted) return;
      final storage =
          widget.mediaStorage ??
          context.read<MediaStorageRepository?>() ??
          CloudRepository();
      _resolvedStorage = storage;

      setState(() {
        _uploadingMedia = true;
        _uploadProgress = 0;
        _mediaError = null;
      });

      final uploadId = DictionaryRepository.newSubmissionId().substring(0, 24);
      final storagePath =
          'dictionary_drafts/$entryId/${uploadId}_${validated.fileName}';
      final url = await storage.uploadBytes(
        path: storagePath,
        bytes: validated.bytes,
        contentType: validated.contentType,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress.clamp(0.0, 1.0));
          }
        },
      );

      if (!mounted) {
        unawaited(storage.deleteByUrl(url).catchError((Object _) {}));
        return;
      }
      _sessionUploadedDraftUrls.add(url);
      String? replacedUrl;
      setState(() {
        if (replaceIndex != null && replaceIndex < _mediaUrls.length) {
          replacedUrl = _mediaUrls[replaceIndex];
          _mediaUrls[replaceIndex] = url;
          if (_mediaLabelControllers[replaceIndex].text.trim().isEmpty) {
            _mediaLabelControllers[replaceIndex].text =
                _defaultCaptionFromFileName(validated.fileName);
          }
        } else {
          _mediaUrls.add(url);
          _mediaLabelControllers.add(
            TextEditingController(
              text: _defaultCaptionFromFileName(validated.fileName),
            ),
          );
        }
        _uploadingMedia = false;
        _uploadProgress = 0;
      });
      if (replacedUrl != null) {
        _cleanupSessionDraftUrls([replacedUrl!]);
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() {
          _uploadingMedia = false;
          _uploadProgress = 0;
          _mediaError = error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _uploadingMedia = false;
          _uploadProgress = 0;
          _mediaError = 'Image upload failed: $error';
        });
      }
    }
  }

  void _moveMedia(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _mediaUrls.length) return;
    setState(() {
      final url = _mediaUrls.removeAt(index);
      _mediaUrls.insert(target, url);
      final controller = _mediaLabelControllers.removeAt(index);
      _mediaLabelControllers.insert(target, controller);
    });
  }

  void _removeMedia(int index) {
    if (index < 0 || index >= _mediaUrls.length) return;
    late final String removedUrl;
    setState(() {
      removedUrl = _mediaUrls.removeAt(index);
      _mediaLabelControllers.removeAt(index).dispose();
    });
    _cleanupSessionDraftUrls([removedUrl]);
  }

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
        title: Text(
          'Preview · ${previewEntry.term.isEmpty ? 'Untitled' : previewEntry.term}',
        ),
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
              Text(
                'Also called: ${previewEntry.strings('synonyms').join(' · ')}',
              ),
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
              Text(
                'Regional variations: ${previewEntry.text('regionalUsage')}',
              ),
            if (previewEntry.strings('examples').isNotEmpty)
              Text('Examples:\n${previewEntry.strings('examples').join('\n')}'),
            if ((previewEntry.data['media'] as List<dynamic>? ?? []).isNotEmpty)
              DictionaryMediaGallery(
                media: (previewEntry.data['media'] as List<dynamic>)
                    .map((item) => (item as Map).cast<String, dynamic>())
                    .toList(),
              ),
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
    final revisions = await widget.repository.loadEntryRevisions(id);
    if (!mounted) return;
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
    if (_hasRevisionMismatch && !_acknowledgedMismatch) {
      setState(() {
        _error =
            'Confirm that you reviewed old, current, and proposed wording '
            'before saving or publishing.';
      });
      return;
    }
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
        if (_hasRevisionMismatch && _acknowledgedMismatch)
          'acknowledgeRevisionMismatch': true,
      });
      if (action == 'publish' || action == 'unpublish' || action == 'archive') {
        DictionaryRepository.invalidateCache();
        if (widget.repository.usesDefaultBackend) {
          unawaited(DictionaryRepository.refreshCachedEntries());
        }
      }
      _savedOrPublished = true;
      final activeUrls = _mediaUrls.toSet();
      _cleanupSessionDraftUrls(
        _sessionUploadedDraftUrls
            .where((u) => !activeUrls.contains(u))
            .toList(),
      );
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

  Widget _buildMismatchComparisonPanel(BuildContext context) {
    final suggestion = widget.suggestion!;
    final currentPublished = widget.publishedTarget!;
    final baseRev = suggestion['baseRevision'] as int?;
    final currentRev = currentPublished.publishedRevision;
    final rawProposed = suggestion['proposedFields'];
    final rawBase = suggestion['baseFields'];

    final currentFields = DictionaryStructuredFields.fromEntry(
      currentPublished,
    );
    final baseFields = rawBase is Map
        ? DictionaryStructuredFields.fromMap(rawBase.cast<String, dynamic>())
        : currentFields;
    final proposedFields = rawProposed is Map
        ? DictionaryStructuredFields.fromMap(
            rawProposed.cast<String, dynamic>(),
          )
        : null;

    final keysToShow = <String>{
      if (proposedFields != null)
        ...proposedFields.changedKeysAgainst(baseFields),
      ...currentFields.changedKeysAgainst(baseFields),
    };
    final orderedKeys = [
      for (final spec in DictionaryStructuredFields.specs)
        if (keysToShow.contains(spec.key)) spec.key,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          AppFeedbackBanner(
            key: const Key('editorRevisionMismatchWarning'),
            message:
                'Revision mismatch: this proposal was submitted against '
                'revision ${baseRev ?? 0}, while the live published definition '
                'is now revision $currentRev. Review old, current, and '
                'proposed wording below before applying.',
            tone: AppStatusTone.warning,
          ),
          if (proposedFields != null)
            for (final key in orderedKeys)
              DictionaryFieldDiffCard(
                fieldKey: 'editor_mismatch_$key',
                label: DictionaryStructuredFields.labelForKey(key),
                oldText: baseFields.displayTextFor(key),
                currentPublishedText: currentFields.displayTextFor(key),
                proposedText: proposedFields.displayTextFor(key),
                baseRevision: baseRev,
                currentRevision: currentRev,
              ),
          CheckboxListTile(
            key: const Key('acknowledgeRevisionMismatchCheckbox'),
            contentPadding: EdgeInsets.zero,
            value: _acknowledgedMismatch,
            onChanged: _busy
                ? null
                : (value) =>
                      setState(() => _acknowledgedMismatch = value ?? false),
            title: const Text(
              'I have reviewed the old, current published, and proposed '
              'wording and confirm applying these changes.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaEditorSection(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    return Container(
      key: const Key('dictionaryMediaSection'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Images (${_mediaUrls.length}/$maxDictionaryMediaItems)',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              OutlinedButton.icon(
                key: const Key('dictionaryUploadImageButton'),
                onPressed:
                    _busy ||
                        _uploadingMedia ||
                        _mediaUrls.length >= maxDictionaryMediaItems
                    ? null
                    : _pickAndUploadImage,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Upload image (PNG, JPEG, WebP)'),
              ),
            ],
          ),
          Text(
            'Uploads stay private in draft storage until published. The first '
            'image is also used for link-sharing previews.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondaryColor),
          ),
          if (_uploadingMedia)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                LinearProgressIndicator(
                  key: const Key('dictionaryMediaUploadProgress'),
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                ),
                Text(
                  'Uploading image… ${(_uploadProgress * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          if (_mediaError != null)
            AppFeedbackBanner(
              key: const Key('dictionaryMediaError'),
              message: _mediaError!,
              tone: AppStatusTone.error,
            ),
          for (var i = 0; i < _mediaUrls.length; i++)
            Container(
              key: Key('dictionaryMediaItem_$i'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        child: SmartImage(
                          _mediaUrls[i],
                          width: 112,
                          height: 84,
                          maxLogicalWidth: 240,
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          key: Key('dictionaryMediaLabel_$i'),
                          controller: _mediaLabelControllers[i],
                          enabled: !_busy && !_uploadingMedia,
                          maxLength: 120,
                          decoration: InputDecoration(
                            labelText: i == 0
                                ? 'Caption / alt text (primary OG image)'
                                : 'Caption / alt text',
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Caption is required.';
                            }
                            if (RegExp(
                              r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
                              caseSensitive: false,
                            ).hasMatch(trimmed)) {
                              return 'Remove email addresses from captions.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      IconButton(
                        key: Key('dictionaryMediaMoveUp_$i'),
                        tooltip: 'Move up',
                        onPressed: _busy || _uploadingMedia || i == 0
                            ? null
                            : () => _moveMedia(i, -1),
                        icon: const Icon(Icons.arrow_upward, size: 18),
                      ),
                      IconButton(
                        key: Key('dictionaryMediaMoveDown_$i'),
                        tooltip: 'Move down',
                        onPressed:
                            _busy ||
                                _uploadingMedia ||
                                i == _mediaUrls.length - 1
                            ? null
                            : () => _moveMedia(i, 1),
                        icon: const Icon(Icons.arrow_downward, size: 18),
                      ),
                      TextButton.icon(
                        key: Key('dictionaryMediaReplace_$i'),
                        onPressed: _busy || _uploadingMedia
                            ? null
                            : () => _pickAndUploadImage(replaceIndex: i),
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Replace'),
                      ),
                      TextButton.icon(
                        key: Key('dictionaryMediaRemove_$i'),
                        onPressed: _busy || _uploadingMedia
                            ? null
                            : () => _removeMedia(i),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNewEntry = widget.initial == null && !_existingDraft;
    final duplicateMatch = _conflictingTermMatch();
    final canPersist =
        !_busy &&
        !_uploadingMedia &&
        (!_hasRevisionMismatch || _acknowledgedMismatch);

    return PopScope(
      canPop: !_busy && !_uploadingMedia,
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
              if (_hasRevisionMismatch) _buildMismatchComparisonPanel(context),
              if (widget.suggestion != null && !_hasRevisionMismatch)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Submitted wording: ${widget.suggestion!['proposal']}',
                  ),
                ),
              if ((widget.suggestion?['reason'] as String?)
                      ?.trim()
                      .isNotEmpty ??
                  false)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReasonCallout(
                    reason: (widget.suggestion!['reason'] as String).trim(),
                    secondaryColor: AppTokens.secondaryTextColor(context),
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
                        (key == 'id'
                            ? (isNewEntry &&
                                  _mediaUrls.isEmpty &&
                                  !_uploadingMedia)
                            : (key != 'slug' || isNewEntry)),
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
                        ['definition', 'explanation', ...lists].contains(key)
                        ? 8
                        : 1,
                    decoration: InputDecoration(
                      labelText:
                          key + (lists.contains(key) ? ' (one per line)' : ''),
                      helperText:
                          key == 'id' &&
                              isNewEntry &&
                              (_mediaUrls.isNotEmpty || _uploadingMedia)
                          ? 'Entry ID is locked while images are attached.'
                          : null,
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
              const SizedBox(height: 8),
              _buildMediaEditorSection(context),
              const SizedBox(height: 8),
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
            key: const Key('dictionarySaveDraftButton'),
            onPressed: canPersist ? () => _save('save') : null,
            child: const Text('Save draft'),
          ),
          FilledButton(
            key: const Key('dictionaryPublishButton'),
            onPressed: canPersist ? () => _save('publish') : null,
            child: const Text('Publish reviewed definition'),
          ),
        ],
      ),
    );
  }
}
