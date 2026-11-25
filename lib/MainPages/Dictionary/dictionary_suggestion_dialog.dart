import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
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
  final _name = TextEditingController();
  final _id = DictionaryRepository.newSubmissionId();
  String _kind = 'missing_term';
  bool _consent = false;
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) _kind = 'correction';
  }

  @override
  void dispose() {
    _term.dispose();
    _proposal.dispose();
    _name.dispose();
    super.dispose();
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    return raw.startsWith('Bad state: ') ? raw.substring(11) : raw;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.call('submitDictionarySuggestion', {
        'submissionId': _id,
        'term': _term.text,
        'proposal': _proposal.text,
        'kind': _kind,
        'termId': widget.entry?.id ?? '',
        'recognitionConsent': _consent,
        'publicName': _consent ? _name.text : '',
        'website': '',
      });
      if (mounted) setState(() => _done = true);
    } catch (error) {
      if (mounted) setState(() => _error = _cleanError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appCubit = context.watch<AppCubit?>();
    final isGuest = appCubit?.state.isGuest ?? true;
    final secondaryColor = AppTokens.secondaryTextColor(context);

    return PopScope(
      canPop: !_busy,
      child: AppGlassDialog(
        maxWidth: 540,
        title: Text(_done ? 'Thank you' : 'Contribute to the Dictionary'),
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
            : Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        isGuest
                            ? 'Guests can suggest terms without an account. '
                                  'Creating a free account is optional if you '
                                  'would like private editorial follow-up.'
                            : 'Signed-in contributions allow private editorial '
                                  'follow-up while keeping your email private.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                      ),
                    ),
                    TextFormField(
                      controller: _term,
                      maxLength: 120,
                      decoration: const InputDecoration(labelText: 'Term'),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Enter a term.'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _kind,
                      decoration: const InputDecoration(
                        labelText: 'Contribution',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'missing_term',
                          child: Text('Missing term'),
                        ),
                        DropdownMenuItem(
                          value: 'definition',
                          child: Text('Definition'),
                        ),
                        DropdownMenuItem(
                          value: 'correction',
                          child: Text('Correction'),
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
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _consent,
                      title: const Text('Recognize my contribution publicly'),
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _consent = value!),
                    ),
                    if (_consent)
                      TextFormField(
                        controller: _name,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          labelText: 'Public name (optional recognition)',
                        ),
                        validator: (value) =>
                            value == null ||
                                value.trim().isEmpty ||
                                value.contains('@')
                            ? 'Use a public name without an email address.'
                            : null,
                      ),
                    Text(
                      'Submissions are reviewed before publication. '
                      'Public recognition requires your consent.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(_done ? 'Close' : 'Cancel'),
          ),
          if (!_done)
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Submitting…' : 'Submit suggestion'),
            ),
        ],
      ),
    );
  }
}
