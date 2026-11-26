// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_contribution_auth.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_diff.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class DictionarySuggestionDialog extends StatefulWidget {
  const DictionarySuggestionDialog({
    super.key,
    required this.repository,
    this.entry,
    this.availableCategories = const [],
    this.mediaStorage,
    this.pickImages,
  });

  final DictionaryRepository repository;
  final DictionaryEntry? entry;
  final List<String> availableCategories;
  final MediaStorageRepository? mediaStorage;
  final DictionaryMultiImagePicker? pickImages;

  @override
  State<DictionarySuggestionDialog> createState() =>
      _DictionarySuggestionDialogState();
}

class _DictionarySuggestionDialogState
    extends State<DictionarySuggestionDialog> {
  final _form = GlobalKey<FormState>();
  late final _term = TextEditingController(text: widget.entry?.term);
  final _customCategory = TextEditingController();
  final _reason = TextEditingController();
  final _name = TextEditingController();
  final _structuredControllers = <String, TextEditingController>{};
  late final DictionaryStructuredFields _baseFields = widget.entry != null
      ? DictionaryStructuredFields.fromEntry(widget.entry!)
      : const DictionaryStructuredFields();
  final _id = DictionaryRepository.newSubmissionId();
  final _selectedCategories = <String>{};

  List<CommunityPendingImage> _images = [];
  bool _rightsConfirmed = false;
  bool _consent = false;
  bool _busy = false;
  bool _uploadBusy = false;
  bool _done = false;
  bool _reviewingChanges = false;
  String? _error;

  bool get _isImprovementMode => widget.entry != null;

  @override
  void initState() {
    super.initState();
    for (final spec in DictionaryStructuredFields.specs) {
      _structuredControllers[spec.key] = TextEditingController(
        text: _isImprovementMode ? _baseFields.displayTextFor(spec.key) : '',
      );
    }
  }

  @override
  void dispose() {
    if (!_done) {
      _cleanupTempUploads();
    }
    for (final img in _images) {
      img.dispose();
    }
    _term.dispose();
    _customCategory.dispose();
    _reason.dispose();
    _name.dispose();
    for (final controller in _structuredControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _cleanupTempUploads() {
    MediaStorageRepository? storage;
    try {
      storage =
          widget.mediaStorage ??
          context.read<MediaStorageRepository?>() ??
          CloudRepository();
    } catch (_) {
      storage = widget.mediaStorage;
    }
    if (storage == null) return;
    for (final img in _images) {
      final url = img.uploadedUrl;
      if (url != null && url.isNotEmpty) {
        storage.deleteByUrl(url).catchError((_) {});
      }
    }
  }

  DictionaryStructuredFields _currentProposedFields() {
    return DictionaryStructuredFields(
      definition: _structuredControllers['definition']?.text.trim() ?? '',
      explanation: _structuredControllers['explanation']?.text.trim() ?? '',
      usage: _structuredControllers['usage']?.text.trim() ?? '',
      regionalUsage: _structuredControllers['regionalUsage']?.text.trim() ?? '',
      examples: DictionaryStructuredFields.normalizeLines(
        (_structuredControllers['examples']?.text ?? '').split('\n'),
      ),
      synonyms: DictionaryStructuredFields.normalizeLines(
        (_structuredControllers['synonyms']?.text ?? '').split('\n'),
      ),
    );
  }

  List<String> _resolvedCategories() {
    final merged = <String>{
      ..._selectedCategories,
      ..._customCategory.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty),
    };
    return merged.take(6).toList();
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    return raw.startsWith('Bad state: ') ? raw.substring(11) : raw;
  }

  void _openReviewChanges() {
    if (!_form.currentState!.validate()) return;
    final proposed = _currentProposedFields();
    final changed = proposed.changedKeysAgainst(_baseFields);
    if (changed.isEmpty && _images.isEmpty) {
      setState(() {
        _error = 'Edit at least one field before reviewing changes.';
      });
      return;
    }
    setState(() {
      _error = null;
      _reviewingChanges = true;
    });
  }

  Future<void> _submit() async {
    if (_busy || _uploadBusy) return;
    if (!_reviewingChanges && !(_form.currentState?.validate() ?? true)) {
      return;
    }
    if (_images.any((img) => !img.isReady)) {
      setState(
        () => _error =
            'Wait for image uploads to finish or remove failed images first.',
      );
      return;
    }
    if (_images.isNotEmpty && !_rightsConfirmed) {
      setState(
        () => _error =
            'Please confirm image permissions and review expectations first.',
      );
      return;
    }

    final submittedImages = _images
        .map((img) => img.toSubmissionMap())
        .toList();
    final reasonText = _reason.text.trim();
    late final Map<String, dynamic> payload;

    if (_isImprovementMode) {
      final entry = widget.entry!;
      final proposed = _currentProposedFields();
      final changed = proposed.changedKeysAgainst(_baseFields);
      if (changed.isEmpty && submittedImages.isEmpty) {
        setState(() {
          _error = 'Modify at least one field before submitting.';
        });
        return;
      }
      payload = {
        'submissionId': _id,
        'term': entry.term,
        'proposal': changed.isEmpty
            ? 'Contributed ${submittedImages.length} educational '
                  '${submittedImages.length == 1 ? 'image' : 'images'}.'
            : proposed.summaryAgainst(_baseFields, reason: reasonText),
        'kind': changed.isEmpty && submittedImages.isNotEmpty
            ? 'image_contribution'
            : 'correction',
        'termId': entry.id,
        'baseRevision': entry.publishedRevision,
        'baseFields': _baseFields.toMap(),
        if (changed.isNotEmpty) 'proposedFields': proposed.toMap(),
        if (submittedImages.isNotEmpty) 'submittedImages': submittedImages,
        if (submittedImages.isNotEmpty) 'rightsConfirmed': true,
        if (reasonText.isNotEmpty) 'reason': reasonText,
        'recognitionConsent': _consent,
        'publicName': _consent ? _name.text : '',
        'website': '',
      };
    } else {
      final proposed = _currentProposedFields();
      final categories = _resolvedCategories();
      payload = {
        'submissionId': _id,
        'term': _term.text.trim(),
        'proposal': proposed.definition,
        'kind': 'new_term',
        'termId': '',
        'proposedFields': proposed.toMap(),
        if (categories.isNotEmpty) 'categories': categories,
        if (submittedImages.isNotEmpty) 'submittedImages': submittedImages,
        if (submittedImages.isNotEmpty) 'rightsConfirmed': true,
        if (reasonText.isNotEmpty) 'reason': reasonText,
        'recognitionConsent': _consent,
        'publicName': _consent ? _name.text : '',
        'website': '',
      };
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.call('submitDictionarySuggestion', payload);
      if (mounted) setState(() => _done = true);
    } catch (error) {
      if (mounted) setState(() => _error = _cleanError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildPublishedReferenceCard(
    BuildContext context,
    DictionaryEntry entry,
  ) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final synonyms = entry.strings('synonyms');
    final examples = entry.strings('examples');
    final usage = entry.text('usage');
    final regional = entry.text('regionalUsage');

    Widget row(String label, String text) {
      if (text.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: secondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(text, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return Container(
      key: const Key('dictionaryCurrentPublishedCard'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current published definition · ${entry.term}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (entry.publishedRevision > 0)
                AppStatusBadge(
                  label: 'Rev ${entry.publishedRevision}',
                  tone: AppStatusTone.info,
                ),
            ],
          ),
          row('Short definition', entry.definition),
          row('Detailed explanation', entry.explanation),
          row('Discipline & general usage', usage),
          row('Regional usage', regional),
          if (examples.isNotEmpty) row('Examples', examples.join('\n')),
          if (synonyms.isNotEmpty) row('Synonyms', synonyms.join(' · ')),
        ],
      ),
    );
  }

  Widget _buildImprovementEditor(
    BuildContext context,
    DictionaryContributorIdentity identity,
  ) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final entry = widget.entry!;
    final busy = _busy || _uploadBusy;

    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Edit the wording directly below. Unchanged fields stay as '
              'published, and you can review highlighted changes before '
              'submitting.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: secondaryColor),
            ),
          ),
          _buildPublishedReferenceCard(context, entry),
          for (final spec in DictionaryStructuredFields.specs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                key: Key('suggestionField_${spec.key}'),
                controller: _structuredControllers[spec.key],
                maxLength: spec.maxLength,
                minLines: spec.minLines,
                maxLines: spec.maxLines,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: spec.isList
                      ? '${spec.label} (one per line)'
                      : spec.label,
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (spec.requiredField && trimmed.isEmpty) {
                    return 'Short definition cannot be empty.';
                  }
                  if (RegExp(
                    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
                    caseSensitive: false,
                  ).hasMatch(trimmed)) {
                    return 'Do not include email addresses in public wording.';
                  }
                  return null;
                },
              ),
            ),
          TextFormField(
            key: const Key('suggestionReasonField'),
            controller: _reason,
            maxLength: 2000,
            minLines: 2,
            maxLines: 4,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'Why are you suggesting this change? (optional)',
              hintText:
                  'Share discipline context, clarity improvements, or sources.',
            ),
          ),
          const SizedBox(height: 12),
          DictionaryImagePickerSection(
            uid: identity.uid,
            submissionId: _id,
            items: _images,
            mediaStorage: widget.mediaStorage,
            pickImages: widget.pickImages,
            onItemsChanged: (next) => setState(() => _images = next),
            onBusyChanged: (isBusy) {
              if (isBusy != _uploadBusy) {
                setState(() => _uploadBusy = isBusy);
              }
            },
          ),
          const SizedBox(height: 10),
          DictionaryContributorAttributionSection(
            requireRightsConfirmation: _images.isNotEmpty,
            rightsConfirmed: _rightsConfirmed,
            onRightsChanged: (value) =>
                setState(() => _rightsConfirmed = value),
            recognitionConsent: _consent,
            onRecognitionConsentChanged: (value) =>
                setState(() => _consent = value),
            publicNameController: _name,
            busy: busy,
            errorText: _error,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewChangesStep(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final proposed = _currentProposedFields();
    final changedKeys = proposed.changedKeysAgainst(_baseFields);
    final unchangedCount =
        DictionaryStructuredFields.specs.length - changedKeys.length;
    final reasonText = _reason.text.trim();

    return Column(
      key: const Key('dictionaryReviewChangesView'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        const DictionaryDiffLegend(),
        for (final key in changedKeys)
          DictionaryFieldDiffCard(
            fieldKey: key,
            label: DictionaryStructuredFields.labelForKey(key),
            oldText: _baseFields.displayTextFor(key),
            proposedText: proposed.displayTextFor(key),
          ),
        if (_images.isNotEmpty)
          Text(
            'Attached ${_images.length} educational '
            '${_images.length == 1 ? 'image' : 'images'} for editorial review.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (unchangedCount > 0)
          Text(
            '$unchangedCount unchanged ${unchangedCount == 1 ? 'field' : 'fields'} '
            'will remain exactly as currently published.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondaryColor),
          ),
        if (reasonText.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  'Why you are suggesting this change',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: secondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(reasonText),
              ],
            ),
          ),
        if (_consent && _name.text.trim().isNotEmpty)
          Text(
            'Opt-in public recognition: ${_name.text.trim()}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondaryColor),
          ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  Widget _buildNewTermForm(
    BuildContext context,
    DictionaryContributorIdentity identity,
  ) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final busy = _busy || _uploadBusy;
    final categoryOptions = widget.availableCategories.isNotEmpty
        ? widget.availableCategories
        : const ['Foundations', 'Gaits', 'Groundwork', 'Anatomy', 'Safety'];

    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            'Propose a new horsemanship term with plain-language context '
            'applicable across disciplines.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondaryColor),
          ),
          TextFormField(
            key: const Key('newTermField_term'),
            controller: _term,
            maxLength: 120,
            enabled: !busy,
            decoration: const InputDecoration(labelText: 'Term'),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Enter a term.';
              if (RegExp(
                r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
                caseSensitive: false,
              ).hasMatch(trimmed)) {
                return 'Do not include email addresses.';
              }
              return null;
            },
          ),
          TextFormField(
            key: const Key('newTermField_definition'),
            controller: _structuredControllers['definition'],
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'Short definition',
              hintText: 'Clear, plain-language definition',
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Enter a short definition.';
              if (RegExp(
                r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
                caseSensitive: false,
              ).hasMatch(trimmed)) {
                return 'Do not include email addresses.';
              }
              return null;
            },
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(
                'Category (optional)',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final category in categoryOptions)
                    FilterChip(
                      key: Key('newTermCategoryChip_$category'),
                      label: Text(category),
                      selected: _selectedCategories.contains(category),
                      onSelected: busy
                          ? null
                          : (selected) => setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            }),
                    ),
                ],
              ),
              TextFormField(
                key: const Key('newTermField_category'),
                controller: _customCategory,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Additional category (optional)',
                  hintText: 'Or type another category, comma-separated',
                ),
              ),
            ],
          ),
          for (final spec in DictionaryStructuredFields.specs.where(
            (s) => s.key != 'definition',
          ))
            TextFormField(
              key: Key('newTermField_${spec.key}'),
              controller: _structuredControllers[spec.key],
              maxLength: spec.maxLength,
              minLines: spec.minLines,
              maxLines: spec.maxLines,
              enabled: !busy,
              decoration: InputDecoration(
                labelText: spec.isList
                    ? '${spec.label} (one per line, optional)'
                    : '${spec.label} (optional)',
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (RegExp(
                  r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
                  caseSensitive: false,
                ).hasMatch(trimmed)) {
                  return 'Do not include email addresses in public wording.';
                }
                return null;
              },
            ),
          DictionaryImagePickerSection(
            uid: identity.uid,
            submissionId: _id,
            items: _images,
            mediaStorage: widget.mediaStorage,
            pickImages: widget.pickImages,
            onItemsChanged: (next) => setState(() => _images = next),
            onBusyChanged: (isBusy) {
              if (isBusy != _uploadBusy) {
                setState(() => _uploadBusy = isBusy);
              }
            },
          ),
          TextFormField(
            key: const Key('suggestionReasonField'),
            controller: _reason,
            maxLength: 2000,
            minLines: 2,
            maxLines: 3,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'Notes or references for editors (optional)',
            ),
          ),
          DictionaryContributorAttributionSection(
            requireRightsConfirmation: _images.isNotEmpty,
            rightsConfirmed: _rightsConfirmed,
            onRightsChanged: (value) =>
                setState(() => _rightsConfirmed = value),
            recognitionConsent: _consent,
            onRecognitionConsentChanged: (value) =>
                setState(() => _consent = value),
            publicNameController: _name,
            busy: busy,
            errorText: _error,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final identity = DictionaryContributorIdentity.fromContext(context);
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final busy = _busy || _uploadBusy;

    final titleText = _done
        ? 'Thank you'
        : _isImprovementMode
        ? (_reviewingChanges
              ? 'Review Changes · ${widget.entry!.term}'
              : 'Suggest an Improvement · ${widget.entry!.term}')
        : 'Suggest a New Term';

    return PopScope(
      canPop: !_busy,
      child: AppGlassDialog(
        maxWidth: _isImprovementMode ? 680 : 620,
        title: Text(titleText),
        content: !identity.canContribute
            ? DictionaryContributionAuthPrompt(
                identity: identity,
                contributionLabel: _isImprovementMode
                    ? 'suggest improvements to the Dictionary'
                    : 'suggest a new Dictionary term',
              )
            : _done
            ? Column(
                key: const Key('dictionarySuggestionSuccess'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  const Text(
                    'Your contribution has been submitted for editorial review.',
                  ),
                  Text(
                    'Linked privately to your account so you can follow its '
                    'review status in My Contributions. Your email address '
                    'is never shown publicly.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                  ),
                ],
              )
            : _isImprovementMode
            ? (_reviewingChanges
                  ? _buildReviewChangesStep(context)
                  : _buildImprovementEditor(context, identity))
            : _buildNewTermForm(context, identity),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(_done || !identity.canContribute ? 'Close' : 'Cancel'),
          ),
          if (identity.canContribute &&
              !_done &&
              _isImprovementMode &&
              _reviewingChanges)
            OutlinedButton(
              key: const Key('dictionaryBackToEditingButton'),
              onPressed: busy
                  ? null
                  : () => setState(() => _reviewingChanges = false),
              child: const Text('Back to editing'),
            ),
          if (identity.canContribute &&
              !_done &&
              _isImprovementMode &&
              !_reviewingChanges)
            OutlinedButton(
              key: const Key('dictionaryReviewChangesButton'),
              onPressed: busy ? null : _openReviewChanges,
              child: const Text('Review Changes'),
            ),
          if (identity.canContribute && !_done)
            FilledButton(
              key: const Key('dictionarySubmitSuggestionButton'),
              onPressed: busy ? null : _submit,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (busy)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  Text(
                    _busy
                        ? 'Submitting…'
                        : (_uploadBusy ? 'Uploading…' : 'Submit suggestion'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
