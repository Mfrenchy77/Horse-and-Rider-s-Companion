// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_diff.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class DictionarySuggestionDialog extends StatefulWidget {
  const DictionarySuggestionDialog({
    super.key,
    required this.repository,
    this.entry,
  });

  final DictionaryRepository repository;
  final DictionaryEntry? entry;

  @override
  State<DictionarySuggestionDialog> createState() =>
      _DictionarySuggestionDialogState();
}

class _DictionarySuggestionDialogState
    extends State<DictionarySuggestionDialog> {
  final _form = GlobalKey<FormState>();
  late final _term = TextEditingController(text: widget.entry?.term);
  final _proposal = TextEditingController();
  final _reason = TextEditingController();
  final _name = TextEditingController();
  final _structuredControllers = <String, TextEditingController>{};
  late final DictionaryStructuredFields _baseFields = widget.entry != null
      ? DictionaryStructuredFields.fromEntry(widget.entry!)
      : const DictionaryStructuredFields();
  final _id = DictionaryRepository.newSubmissionId();

  String _kind = 'missing_term';
  bool _consent = false;
  bool _busy = false;
  bool _done = false;
  bool _reviewingChanges = false;
  String? _error;

  bool get _isImprovementMode => widget.entry != null;

  @override
  void initState() {
    super.initState();
    if (_isImprovementMode) {
      _kind = 'correction';
      for (final spec in DictionaryStructuredFields.specs) {
        _structuredControllers[spec.key] = TextEditingController(
          text: _baseFields.displayTextFor(spec.key),
        );
      }
    }
  }

  @override
  void dispose() {
    _term.dispose();
    _proposal.dispose();
    _reason.dispose();
    _name.dispose();
    for (final controller in _structuredControllers.values) {
      controller.dispose();
    }
    super.dispose();
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

  String _cleanError(Object error) {
    final raw = error.toString();
    return raw.startsWith('Bad state: ') ? raw.substring(11) : raw;
  }

  void _openReviewChanges() {
    if (!_form.currentState!.validate()) return;
    final proposed = _currentProposedFields();
    final changed = proposed.changedKeysAgainst(_baseFields);
    if (changed.isEmpty) {
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
    if (!_reviewingChanges && !(_form.currentState?.validate() ?? true)) {
      return;
    }
    if (_busy) return;

    Map<String, dynamic> payload;
    if (_isImprovementMode) {
      final entry = widget.entry!;
      final proposed = _currentProposedFields();
      final changed = proposed.changedKeysAgainst(_baseFields);
      if (changed.isEmpty) {
        setState(() {
          _error = 'Modify at least one field before submitting.';
        });
        return;
      }
      final reasonText = _reason.text.trim();
      payload = {
        'submissionId': _id,
        'term': entry.term,
        'proposal': proposed.summaryAgainst(_baseFields, reason: reasonText),
        'kind': _kind,
        'termId': entry.id,
        'baseRevision': entry.publishedRevision,
        'baseFields': _baseFields.toMap(),
        'proposedFields': proposed.toMap(),
        if (reasonText.isNotEmpty) 'reason': reasonText,
        'recognitionConsent': _consent,
        'publicName': _consent ? _name.text : '',
        'website': '',
      };
    } else {
      payload = {
        'submissionId': _id,
        'term': _term.text,
        'proposal': _proposal.text,
        'kind': _kind,
        'termId': '',
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
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current published definition · ${entry.term}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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

  Widget _buildImprovementEditor(BuildContext context, bool isGuest) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final entry = widget.entry!;

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
                enabled: !_busy,
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
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Why are you suggesting this change? (optional)',
              hintText:
                  'Share discipline context, clarity improvements, or sources.',
            ),
          ),
          _buildAttributionAndPrivacySection(context, isGuest),
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

  Widget _buildAttributionAndPrivacySection(
    BuildContext context,
    bool isGuest,
  ) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          key: const Key('dictionaryRecognitionConsentCheckbox'),
          contentPadding: EdgeInsets.zero,
          value: _consent,
          title: const Text('Recognize my contribution publicly'),
          onChanged: _busy
              ? null
              : (value) => setState(() => _consent = value ?? false),
        ),
        if (_consent)
          TextFormField(
            key: const Key('dictionaryPublicNameField'),
            controller: _name,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Public name (optional recognition)',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty || value.contains('@')
                ? 'Use a public name without an email address.'
                : null,
          ),
        Text(
          isGuest
              ? 'Guests can contribute without an account. Submissions are '
                    'reviewed before publication, and public recognition '
                    'requires your consent.'
              : 'Submissions are reviewed before publication. Linked privately '
                    'for editorial follow-up while keeping your email private.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: secondaryColor),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildNewTermForm(BuildContext context, bool isGuest) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              isGuest
                  ? 'Guests can suggest terms without an account. Creating a '
                        'free account is optional if you would like private '
                        'editorial follow-up.'
                  : 'Signed-in contributions allow private editorial follow-up '
                        'while keeping your email private.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: secondaryColor),
            ),
          ),
          TextFormField(
            controller: _term,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Term'),
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Enter a term.' : null,
          ),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            decoration: const InputDecoration(labelText: 'Contribution'),
            items: const [
              DropdownMenuItem(
                value: 'missing_term',
                child: Text('Missing term'),
              ),
              DropdownMenuItem(value: 'definition', child: Text('Definition')),
              DropdownMenuItem(
                value: 'correction',
                child: Text('Suggest an Improvement'),
              ),
              DropdownMenuItem(
                value: 'regional_usage',
                child: Text('Regional usage'),
              ),
              DropdownMenuItem(
                value: 'related_term',
                child: Text('Related terminology'),
              ),
            ],
            onChanged: _busy
                ? null
                : (value) => setState(() => _kind = value!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _proposal,
            maxLength: 4000,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Your suggestion and context',
            ),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Describe your suggestion.'
                : null,
          ),
          _buildAttributionAndPrivacySection(context, isGuest),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appCubit = context.watch<AppCubit?>();
    final isGuest = appCubit?.state.isGuest ?? true;
    final secondaryColor = AppTokens.secondaryTextColor(context);

    final titleText = _done
        ? 'Thank you'
        : _isImprovementMode
        ? (_reviewingChanges
              ? 'Review Changes · ${widget.entry!.term}'
              : 'Suggest an Improvement · ${widget.entry!.term}')
        : 'Contribute to the Dictionary';

    return PopScope(
      canPop: !_busy,
      child: AppGlassDialog(
        maxWidth: _isImprovementMode ? 680 : 540,
        title: Text(titleText),
        content: _done
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  const Text(
                    'Your suggestion has been submitted for review. '
                    'You can continue exploring without an account.',
                  ),
                  if (isGuest)
                    Container(
                      key: const Key('dictionaryGuestAccountPrompt'),
                      padding: const EdgeInsets.all(AppTokens.spaceSm + 2),
                      decoration: BoxDecoration(
                        color: AppTokens.accentColor(
                          context,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(
                          color: AppTokens.accentColor(
                            context,
                          ).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text(
                            'Want private follow-up on future suggestions and '
                            'access to the Skill Tree & Training Logbook?',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          OutlinedButton.icon(
                            key: const Key('dictionaryCreateAccountButton'),
                            icon: const Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 16,
                            ),
                            label: const Text('Create a free account'),
                            onPressed: () {
                              final router = GoRouter.maybeOf(context);
                              Navigator.pop(context);
                              router?.go('/Auth?mode=register');
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Linked privately to your account in case editors need '
                      'clarification. Your email address is never shown '
                      'publicly.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                    ),
                ],
              )
            : _isImprovementMode
            ? (_reviewingChanges
                  ? _buildReviewChangesStep(context)
                  : _buildImprovementEditor(context, isGuest))
            : _buildNewTermForm(context, isGuest),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(_done ? 'Close' : 'Cancel'),
          ),
          if (!_done && _isImprovementMode && _reviewingChanges)
            OutlinedButton(
              key: const Key('dictionaryBackToEditingButton'),
              onPressed: _busy
                  ? null
                  : () => setState(() => _reviewingChanges = false),
              child: const Text('Back to editing'),
            ),
          if (!_done && _isImprovementMode && !_reviewingChanges)
            OutlinedButton(
              key: const Key('dictionaryReviewChangesButton'),
              onPressed: _busy ? null : _openReviewChanges,
              child: const Text('Review Changes'),
            ),
          if (!_done)
            FilledButton(
              key: const Key('dictionarySubmitSuggestionButton'),
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Submitting…' : 'Submit suggestion'),
            ),
        ],
      ),
    );
  }
}
