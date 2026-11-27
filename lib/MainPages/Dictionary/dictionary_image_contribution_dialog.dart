// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_contribution_auth.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Streamlined dialog allowing verified community members to contribute up to
/// 3 educational images (with optional captions & explanations) to an existing
/// Dictionary entry without needing any wording changes.
class DictionaryImageContributionDialog extends StatefulWidget {
  const DictionaryImageContributionDialog({
    super.key,
    required this.repository,
    required this.entry,
    this.mediaStorage,
    this.pickImages,
    this.processImage,
  });

  final DictionaryRepository repository;
  final DictionaryEntry entry;
  final MediaStorageRepository? mediaStorage;
  final DictionaryMultiImagePicker? pickImages;
  final Future<ProcessedDictionaryImage> Function({
    required Uint8List bytes,
    required String fileName,
  })?
  processImage;

  @override
  State<DictionaryImageContributionDialog> createState() =>
      _DictionaryImageContributionDialogState();
}

class _DictionaryImageContributionDialogState
    extends State<DictionaryImageContributionDialog> {
  final _form = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _publicNameController = TextEditingController();
  final _submissionId = DictionaryRepository.newSubmissionId();

  List<CommunityPendingImage> _images = [];
  MediaStorageRepository? _resolvedStorage;
  bool _rightsConfirmed = false;
  bool _recognitionConsent = false;
  bool _uploadBusy = false;
  bool _submitting = false;
  bool _done = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolvedStorage ??=
        widget.mediaStorage ?? context.read<MediaStorageRepository?>();
  }

  @override
  void dispose() {
    if (!_done) {
      _cleanupTempUploads();
    }
    for (final img in _images) {
      img.dispose();
    }
    _noteController.dispose();
    _publicNameController.dispose();
    super.dispose();
  }

  void _cleanupTempUploads() {
    final storage = _resolvedStorage ?? widget.mediaStorage;
    if (storage == null) return;
    for (final img in _images) {
      final url = img.uploadedUrl;
      if (url != null && url.isNotEmpty) {
        storage.deleteByUrl(url).catchError((_) {});
      }
    }
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    return raw.startsWith('Bad state: ') ? raw.substring(11) : raw;
  }

  Future<void> _submit() async {
    if (_submitting || _uploadBusy) return;
    if (!(_form.currentState?.validate() ?? true)) return;
    if (_images.isEmpty) {
      setState(() => _error = 'Attach at least one image before submitting.');
      return;
    }
    if (_images.any((img) => !img.isReady)) {
      setState(
        () => _error =
            'Wait for uploads to finish or remove/retry failed images first.',
      );
      return;
    }
    if (!_rightsConfirmed) {
      setState(
        () => _error =
            'Please confirm image permissions and review expectations first.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final note = _noteController.text.trim();
      await widget.repository.call('submitDictionarySuggestion', {
        'submissionId': _submissionId,
        'term': widget.entry.term,
        'termId': widget.entry.id,
        'kind': 'image_contribution',
        if (note.isNotEmpty) 'reason': note,
        'submittedImages': _images.map((e) => e.toSubmissionMap()).toList(),
        'rightsConfirmed': true,
        'recognitionConsent': _recognitionConsent,
        'publicName': _recognitionConsent ? _publicNameController.text : '',
        'website': '',
      });
      if (mounted) {
        setState(() => _done = true);
      }
    } catch (error) {
      if (mounted) setState(() => _error = _cleanError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = DictionaryContributorIdentity.fromContext(context);
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final busy = _submitting || _uploadBusy;

    return PopScope(
      canPop: !_submitting,
      child: AppGlassDialog(
        maxWidth: 640,
        title: Text(
          _done ? 'Thank you' : 'Contribute Images · ${widget.entry.term}',
        ),
        content: !identity.canContribute
            ? DictionaryContributionAuthPrompt(
                identity: identity,
                contributionLabel:
                    'contribute educational images to the Dictionary',
              )
            : _done
            ? Column(
                key: const Key('dictionaryImageContributionSuccess'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  Text(
                    'Submitted ${_images.length} '
                    '${_images.length == 1 ? 'image' : 'images'} for '
                    'editorial review on ${widget.entry.term}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Images stay private until an administrator reviews them '
                    'for clarity and accuracy. You can check your progress '
                    'anytime in My Contributions.',
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
                  spacing: 12,
                  children: [
                    Text(
                      'Share clear photographs, diagrams, or illustrations '
                      'that help horsemen and riders visualize '
                      '${widget.entry.term}. Up to 3 images per submission.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                    ),
                    DictionaryImagePickerSection(
                      uid: identity.uid,
                      submissionId: _submissionId,
                      items: _images,
                      mediaStorage: widget.mediaStorage,
                      pickImages: widget.pickImages,
                      processImage: widget.processImage,
                      onItemsChanged: (next) => setState(() => _images = next),
                      onBusyChanged: (isBusy) {
                        if (isBusy != _uploadBusy) {
                          setState(() => _uploadBusy = isBusy);
                        }
                      },
                    ),
                    TextFormField(
                      key: const Key('imageContributionNoteField'),
                      controller: _noteController,
                      maxLength: 2000,
                      minLines: 2,
                      maxLines: 3,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Notes for editors (optional)',
                        hintText:
                            'Discipline context, angle, or what is helpful to verify',
                      ),
                    ),
                    DictionaryContributorAttributionSection(
                      requireRightsConfirmation: true,
                      rightsConfirmed: _rightsConfirmed,
                      onRightsChanged: (value) =>
                          setState(() => _rightsConfirmed = value),
                      recognitionConsent: _recognitionConsent,
                      onRecognitionConsentChanged: (value) =>
                          setState(() => _recognitionConsent = value),
                      publicNameController: _publicNameController,
                      busy: busy,
                      errorText: _error,
                    ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            child: Text(_done || !identity.canContribute ? 'Close' : 'Cancel'),
          ),
          if (identity.canContribute && !_done)
            FilledButton(
              key: const Key('submitImageContributionButton'),
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
                    _submitting
                        ? 'Submitting…'
                        : (_uploadBusy ? 'Uploading…' : 'Submit for review'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
