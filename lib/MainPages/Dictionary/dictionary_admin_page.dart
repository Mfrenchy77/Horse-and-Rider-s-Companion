// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:typed_data';

import 'package:database_repository/database_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_diff.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class _InboxBundle {
  const _InboxBundle({
    required this.items,
    required this.publishedEntries,
    this.resolvedContributors = const {},
    this.contributorModeration = const {},
  });

  final List<Map<String, dynamic>> items;
  final List<DictionaryEntry> publishedEntries;
  final Map<String, Map<String, dynamic>> resolvedContributors;
  final Map<String, Map<String, dynamic>> contributorModeration;
}

class _AdminContributorDetails {
  const _AdminContributorDetails({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.isLegacyResolved,
    required this.submittedAtLabel,
    required this.recognitionConsent,
    required this.publicName,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final bool isLegacyResolved;
  final String submittedAtLabel;
  final bool recognitionConsent;
  final String publicName;

  String get creditLabel {
    if (recognitionConsent && publicName.isNotEmpty) {
      return 'Yes — "$publicName"';
    }
    if (recognitionConsent) {
      return 'Yes (no public display name set)';
    }
    return 'No (private — do not credit publicly)';
  }
}

DateTime? _parseAdminDateTime(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw.toLocal();
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
  if (raw is String) return DateTime.tryParse(raw)?.toLocal();
  try {
    final dynamic dyn = raw;
    // Support Firestore Timestamp without coupling this UI module to cloud_firestore.
    // ignore: avoid_dynamic_calls
    final dynamic converted = dyn.toDate();
    if (converted is DateTime) return converted.toLocal();
  } catch (_) {
    // Ignore non-Timestamp objects cleanly.
  }
  return null;
}

String _formatAdminDateTime(Object? raw) {
  final dt = _parseAdminDateTime(raw);
  if (dt == null) return 'Unknown date';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}

_AdminContributorDetails _resolveAdminContributor(
  Map<String, dynamic> item,
  Map<String, Map<String, dynamic>> resolvedByUid,
) {
  final uid = (item['contributorUid'] as String?)?.trim() ?? '';
  final rawSnapshot = item['contributorSnapshot'];
  final snapshot = rawSnapshot is Map
      ? rawSnapshot.cast<String, dynamic>()
      : null;
  final snapshotName = (snapshot?['displayName'] as String?)?.trim() ?? '';
  final snapshotEmail = (snapshot?['email'] as String?)?.trim() ?? '';
  final resolved = uid.isNotEmpty ? resolvedByUid[uid] : null;
  final resolvedName = (resolved?['displayName'] as String?)?.trim() ?? '';
  final resolvedEmail = (resolved?['email'] as String?)?.trim() ?? '';
  final displayName = snapshotName.isNotEmpty
      ? snapshotName
      : (resolvedName.isNotEmpty ? resolvedName : null);
  final email = snapshotEmail.isNotEmpty
      ? snapshotEmail
      : (resolvedEmail.isNotEmpty ? resolvedEmail : null);
  final hasSnapshotIdentity =
      snapshotName.isNotEmpty || snapshotEmail.isNotEmpty;
  final isLegacyResolved =
      !hasSnapshotIdentity &&
      (resolvedName.isNotEmpty || resolvedEmail.isNotEmpty);
  return _AdminContributorDetails(
    uid: uid,
    displayName: displayName,
    email: email,
    isLegacyResolved: isLegacyResolved,
    submittedAtLabel: _formatAdminDateTime(item['createdAt']),
    recognitionConsent: item['recognitionConsent'] == true,
    publicName: (item['publicName'] as String?)?.trim() ?? '',
  );
}

class _AdminContributorInfoPanel extends StatelessWidget {
  const _AdminContributorInfoPanel({
    super.key,
    required this.details,
    this.submissionCount,
    this.publishedCount,
    this.isSuspended = false,
    this.suspensionReason,
    this.onViewHistory,
    this.onModerateContributor,
    this.compact = false,
  });

  final _AdminContributorDetails details;
  final int? submissionCount;
  final int? publishedCount;
  final bool isSuspended;
  final String? suspensionReason;
  final VoidCallback? onViewHistory;
  final VoidCallback? onModerateContributor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final hasUid = details.uid.isNotEmpty;
    final nameLabel = details.displayName ?? 'Not set';
    final emailLabel = details.email ?? 'Unavailable';
    final cleanReason = suspensionReason?.trim() ?? '';

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
        border: Border.all(
          color: isSuspended
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.6)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Private Contributor Audit Record',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (isSuspended)
                const AppStatusBadge(
                  label: 'Dictionary suspended',
                  tone: AppStatusTone.error,
                ),
              if (details.isLegacyResolved)
                const AppStatusBadge(
                  label: 'Resolved from account',
                  tone: AppStatusTone.info,
                ),
              if (submissionCount != null)
                AppStatusBadge(
                  label:
                      '$submissionCount '
                      '${submissionCount == 1 ? 'submission' : 'submissions'}'
                      '${(publishedCount ?? 0) > 0 ? ' · $publishedCount published' : ''}',
                ),
            ],
          ),
          Text(
            'Profile name: $nameLabel · Email: $emailLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SelectableText(
            'UID: ${hasUid ? details.uid : 'Legacy / unavailable'} · '
            'Submitted: ${details.submittedAtLabel}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondaryColor),
          ),
          if (isSuspended && cleanReason.isNotEmpty)
            Text(
              'Suspension reason: $cleanReason',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Public credit preference: ${details.creditLabel}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: secondaryColor),
              ),
              if (hasUid && onViewHistory != null)
                TextButton.icon(
                  onPressed: onViewHistory,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.person_search_outlined, size: 15),
                  label: const Text('Contributor history'),
                ),
              if (hasUid && onModerateContributor != null)
                TextButton.icon(
                  key: Key('adminModerateContributorButton_${details.uid}'),
                  onPressed: onModerateContributor,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: isSuspended
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  icon: Icon(
                    isSuspended
                        ? Icons.settings_backup_restore_outlined
                        : Icons.block_outlined,
                    size: 15,
                  ),
                  label: Text(
                    isSuspended ? 'Restore privileges' : 'Suspend contributor',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContributorModerationDialog extends StatefulWidget {
  const _ContributorModerationDialog({
    required this.details,
    required this.isSuspended,
    required this.repository,
  });

  final _AdminContributorDetails details;
  final bool isSuspended;
  final DictionaryRepository repository;

  @override
  State<_ContributorModerationDialog> createState() =>
      _ContributorModerationDialogState();
}

class _ContributorModerationDialogState
    extends State<_ContributorModerationDialog> {
  final _form = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? true)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final reason = _reasonController.text.trim();
      if (widget.isSuspended) {
        await widget.repository.restoreContributor(
          uid: widget.details.uid,
          reason: reason,
        );
      } else {
        await widget.repository.suspendContributor(
          uid: widget.details.uid,
          reason: reason,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final isRestore = widget.isSuspended;
    final label = widget.details.displayName ?? widget.details.uid;

    return AppGlassDialog(
      key: const Key('adminContributorModerationDialog'),
      maxWidth: 540,
      title: Text(
        isRestore
            ? 'Restore Dictionary privileges · $label'
            : 'Suspend Dictionary contributor · $label',
      ),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              isRestore
                  ? 'Restoring privileges allows this member to submit new '
                        'Dictionary terms, improvements, and images again.'
                  : 'Suspending stops this member from submitting new Dictionary '
                        'terms, improvements, or images. Their main account '
                        'and existing contributions remain untouched.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: secondaryColor),
            ),
            Text(
              'UID: ${widget.details.uid}'
              '${widget.details.email != null ? ' · ${widget.details.email}' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextFormField(
              key: const Key('adminModerationReasonField'),
              controller: _reasonController,
              enabled: !_busy,
              maxLength: 1000,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: isRestore
                    ? 'Private restoration note (optional)'
                    : 'Private moderation reason (required)',
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (!isRestore && trimmed.isEmpty) {
                  return 'Enter a private reason for this moderation action.';
                }
                if (RegExp(
                  r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
                  caseSensitive: false,
                ).hasMatch(trimmed)) {
                  return 'Do not include email addresses in moderation notes.';
                }
                return null;
              },
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirmContributorModerationButton'),
          onPressed: _busy ? null : _submit,
          child: Text(isRestore ? 'Restore privileges' : 'Suspend contributor'),
        ),
      ],
    );
  }
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
  String? _focusedSubmissionId;
  final Map<String, GlobalKey> _submissionCardKeys = {};
  final Map<String, Map<String, dynamic>> _resolvedContributors = {};
  final Map<String, List<Map<String, dynamic>>> _contributorHistoryCache = {};

  static bool _isPendingSubmission(Map<String, dynamic> item) {
    final status = (item['status'] as String?) ?? 'submitted';
    return status == 'submitted' ||
        status == 'under_review' ||
        status == 'needs_clarification';
  }

  static bool _isQuickPublishImageSubmission(
    Map<String, dynamic> item,
    DictionaryEntry? target,
  ) {
    if (target == null) return false;
    final status = item['status'] as String?;
    if (status == 'published' || status == 'rejected') return false;
    final images = item['submittedImages'] as List<dynamic>?;
    if (images == null || images.isEmpty) return false;
    return item['kind'] == 'image_contribution' ||
        item['proposedFields'] == null;
  }

  GlobalKey _keyForSubmission(String id) =>
      _submissionCardKeys.putIfAbsent(id, GlobalKey.new);

  void _focusSubmission(String? id) {
    if (!mounted) return;
    setState(() {
      _statusFilter = null;
      _focusedSubmissionId = id;
    });
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _submissionCardKeys[id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 220),
          alignment: 0.1,
        );
      }
    });
  }

  Map<String, dynamic>? _nextPendingItem(
    List<Map<String, dynamic>> items, {
    String? afterId,
  }) {
    final pending = items.where(_isPendingSubmission).toList();
    if (pending.isEmpty) return null;
    if (afterId == null) return pending.first;
    final idx = pending.indexWhere((e) => e['id'] == afterId);
    if (idx >= 0 && idx + 1 < pending.length) {
      return pending[idx + 1];
    }
    return pending.firstWhere(
      (e) => e['id'] != afterId,
      orElse: () => pending.first,
    );
  }

  Future<void> _openQuickApproveAndPublish(
    Map<String, dynamic> item,
    DictionaryEntry target,
    _InboxBundle bundle,
  ) async {
    final draftMatch = await _repository.loadDraft(target.id);
    if (!mounted) return;
    final effectiveTarget = draftMatch ?? target;
    var refreshed = false;
    final selectedNext = await showAppGlassDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => _ApproveAndPublishImagesDialog(
        item: item,
        targetEntry: effectiveTarget,
        allSubmissions: bundle.items,
        resolvedContributors: bundle.resolvedContributors,
        repository: _repository,
        onPublished: () {
          if (mounted) {
            refreshed = true;
            _refresh();
          }
        },
      ),
    );
    if (!mounted) return;
    if (!refreshed) {
      _refresh();
    }
    if (selectedNext != null) {
      final refreshedBundle = await (_inbox ?? _load());
      if (!mounted) return;
      final nextTarget = _resolveSuggestionTarget(
        refreshedBundle.publishedEntries,
        selectedNext,
      );
      if (_isQuickPublishImageSubmission(selectedNext, nextTarget)) {
        await _openQuickApproveAndPublish(
          selectedNext,
          nextTarget!,
          refreshedBundle,
        );
      } else {
        _focusSubmission(selectedNext['id'] as String?);
      }
    }
  }

  Future<_InboxBundle> _load() async {
    final results = await Future.wait<dynamic>([
      _repository.loadSuggestions(),
      _repository.load(),
    ]);
    final items = results[0] as List<Map<String, dynamic>>;
    final published = results[1] as List<DictionaryEntry>;
    final allUids = <String>[];
    final seenAllUids = <String>{};
    final missingUids = <String>[];
    final seenMissingUids = <String>{};
    for (final item in items) {
      final uid = (item['contributorUid'] as String?)?.trim() ?? '';
      if (uid.isEmpty) continue;
      if (seenAllUids.add(uid)) {
        allUids.add(uid);
      }
      if (_resolvedContributors.containsKey(uid)) continue;
      final rawSnapshot = item['contributorSnapshot'];
      final snapshot = rawSnapshot is Map
          ? rawSnapshot.cast<String, dynamic>()
          : null;
      final snapName = (snapshot?['displayName'] as String?)?.trim() ?? '';
      final snapEmail = (snapshot?['email'] as String?)?.trim() ?? '';
      if (snapName.isEmpty && snapEmail.isEmpty && seenMissingUids.add(uid)) {
        missingUids.add(uid);
      }
    }
    var moderationByUid = const <String, Map<String, dynamic>>{};
    await Future.wait<void>([
      if (missingUids.isNotEmpty)
        () async {
          try {
            final resolved = await _repository.resolveContributorIdentities(
              missingUids,
            );
            _resolvedContributors.addAll(resolved);
          } catch (_) {
            // Legacy contributor resolution must never block the review inbox.
          }
        }(),
      if (allUids.isNotEmpty)
        () async {
          try {
            moderationByUid = await _repository
                .loadContributorModerationStatuses(allUids);
          } catch (_) {
            // Moderation lookup failure must never block the review inbox.
          }
        }(),
    ]);
    return _InboxBundle(
      items: items,
      publishedEntries: published,
      resolvedContributors: Map<String, Map<String, dynamic>>.unmodifiable(
        _resolvedContributors,
      ),
      contributorModeration: Map<String, Map<String, dynamic>>.unmodifiable(
        moderationByUid,
      ),
    );
  }

  void _refresh() {
    final nextInbox = _load();
    setState(() {
      _inbox = nextInbox;
    });
  }

  Future<bool> _moderateContributor(
    _AdminContributorDetails details, {
    required bool isSuspended,
  }) async {
    if (details.uid.isEmpty) return false;
    final changed = await showAppGlassDialog<bool>(
      context: context,
      builder: (_) => _ContributorModerationDialog(
        details: details,
        isSuspended: isSuspended,
        repository: _repository,
      ),
    );
    if ((changed ?? false) && mounted) {
      _contributorHistoryCache.remove(details.uid);
      _refresh();
      return true;
    }
    return false;
  }

  Future<void> _showContributorHistory(
    _AdminContributorDetails details,
    List<Map<String, dynamic>> inboxItems, {
    Map<String, dynamic>? moderationStatus,
    bool canModerate = true,
  }) async {
    if (details.uid.isEmpty) return;
    var history = _contributorHistoryCache[details.uid];
    if (history == null) {
      try {
        history = await _repository.loadMySuggestions(details.uid);
      } catch (_) {
        history = const [];
      }
      if (history.isEmpty) {
        history = inboxItems
            .where((entry) => entry['contributorUid'] == details.uid)
            .toList();
      }
      _contributorHistoryCache[details.uid] = history;
    }
    var moderationHistory = const <Map<String, dynamic>>[];
    try {
      moderationHistory = await _repository.loadContributorModerationHistory(
        details.uid,
      );
    } catch (_) {
      moderationHistory = const [];
    }
    if (!mounted) return;
    final isSuspended = moderationStatus?['suspended'] == true;
    final suspensionReason =
        (moderationStatus?['reason'] as String?)?.trim() ?? '';
    await showAppGlassDialog<void>(
      context: context,
      builder: (ctx) => AppGlassDialog(
        key: const Key('adminContributorHistoryDialog'),
        maxWidth: 640,
        title: Text(
          'Contributor History · ${details.displayName ?? details.uid}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            _AdminContributorInfoPanel(
              details: details,
              submissionCount: history!.length,
              publishedCount: history
                  .where((e) => e['status'] == 'published')
                  .length,
              isSuspended: isSuspended,
              suspensionReason: suspensionReason,
              onModerateContributor: canModerate
                  ? () async {
                      Navigator.pop(ctx);
                      await _moderateContributor(
                        details,
                        isSuspended: isSuspended,
                      );
                    }
                  : null,
              compact: true,
            ),
            if (moderationHistory.isNotEmpty)
              Container(
                key: const Key('adminContributorModerationHistory'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      'Moderation audit trail',
                      style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final ev in moderationHistory)
                      Text(
                        '${ev['action'] == 'restore' ? 'Restored' : 'Suspended'} · '
                        '${_formatAdminDateTime(ev['at'])}'
                        '${((ev['actorUid'] as String?)?.trim().isNotEmpty ?? false) ? ' · by ${ev['actorUid']}' : ''}'
                        '${((ev['reason'] as String?)?.trim().isNotEmpty ?? false) ? ' — ${ev['reason']}' : ''}',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            if (history.isEmpty)
              const Text('No Dictionary contributions recorded yet.')
            else
              for (final entry in history)
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
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            (entry['term'] as String?) ?? 'Dictionary term',
                            style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppStatusBadge(
                            label: ((entry['status'] as String?) ?? 'submitted')
                                .replaceAll('_', ' '),
                          ),
                          if ((entry['kind'] as String?)?.isNotEmpty ?? false)
                            AppStatusBadge(
                              label: dictionaryContributionLabel(
                                entry['kind'] as String?,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'Submitted: ${_formatAdminDateTime(entry['createdAt'])}'
                        '${entry['recognitionConsent'] == true && ((entry['publicName'] as String?)?.trim().isNotEmpty ?? false) ? ' · Public credit: ${entry['publicName']}' : ' · Private'}',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
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
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) =>
          _ReviewDialog(item: item, status: status, repository: _repository),
    );
    if (mounted) _refresh();
  }

  Future<void> _partialReview(Map<String, dynamic> item) async {
    await showAppGlassDialog<void>(
      context: context,
      builder: (_) => _PartialReviewDialog(
        item: item,
        repository: _repository,
        onSaved: () {
          if (mounted) _refresh();
        },
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
    final details = _resolveAdminContributor(item, _resolvedContributors);
    await showAppGlassDialog<void>(
      context: context,
      builder: (ctx) => AppGlassDialog(
        title: Text('Contribution history · ${item['term'] ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            _AdminContributorInfoPanel(details: details, compact: true),
            if (events.isEmpty)
              const Text('No review decisions recorded yet.')
            else
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
                            ((ev['status'] as String?) ?? 'event').replaceAll(
                              '_',
                              ' ',
                            ),
                            style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (ev['proposalEdited'] == true)
                            const AppStatusBadge(
                              label: 'Proposal edited',
                              tone: AppStatusTone.info,
                            ),
                        ],
                      ),
                      if ((ev['note'] as String?)?.trim().isNotEmpty ?? false)
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
    final publishedTarget = suggestion == null
        ? null
        : _resolveSuggestionTarget(published, suggestion);
    final entriesById = {for (final entry in published) entry.id: entry};
    DictionaryEntry? draftMatch;
    if (publishedTarget != null) {
      draftMatch = await _repository.loadDraft(publishedTarget.id);
      if (draftMatch != null) entriesById[draftMatch.id] = draftMatch;
    } else if (suggestion != null) {
      final termId = (suggestion['termId'] as String?)?.trim() ?? '';
      if (termId.isNotEmpty) {
        draftMatch = await _repository.loadDraft(termId);
        if (draftMatch != null) entriesById[draftMatch.id] = draftMatch;
      }
      if (draftMatch == null) {
        for (final draft in await _repository.loadDrafts()) {
          entriesById[draft.id] = draft;
        }
      }
    }
    if (!mounted) return;
    final allEntries = entriesById.values.toList()
      ..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
    final initial = suggestion == null
        ? null
        : (publishedTarget != null
              ? draftMatch ?? publishedTarget
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

  Widget _buildSubmittedImagesPreview(
    BuildContext context, {
    required Map<String, dynamic> item,
  }) {
    final submittedImages = (item['submittedImages'] as List<dynamic>? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    if (submittedImages.isEmpty) return const SizedBox.shrink();

    final secondaryColor = AppTokens.secondaryTextColor(context);
    final rightsConfirmed = item['rightsConfirmed'] == true;
    final consent = item['recognitionConsent'] == true;
    final publicName = (item['publicName'] as String?)?.trim() ?? '';
    final attributionText = consent && publicName.isNotEmpty
        ? 'Public credit: $publicName'
        : 'Contributor: Private account (no public credit)';

    return Column(
      key: Key('adminSubmittedImages_${item['id']}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Submitted images (${submittedImages.length})',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            AppStatusBadge(
              key: Key('adminRightsBadge_${item['id']}'),
              label: rightsConfirmed
                  ? 'Permissions confirmed'
                  : 'Permissions not confirmed',
              tone: rightsConfirmed
                  ? AppStatusTone.success
                  : AppStatusTone.warning,
            ),
            Text(
              attributionText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: secondaryColor),
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < submittedImages.length; i++)
              Builder(
                builder: (context) {
                  final img = submittedImages[i];
                  final url = (img['url'] as String?) ?? '';
                  final imgId = (img['id'] as String?) ?? '$i';
                  final caption = (img['caption'] as String?)?.trim() ?? '';
                  final explanation =
                      (img['explanation'] as String?)?.trim() ?? '';
                  final imageType = DictionaryImageType.fromStorageValue(
                    img['imageType'] as String?,
                  );
                  final reviewStatus =
                      (img['reviewStatus'] as String?) ?? 'pending';
                  final tone = switch (reviewStatus) {
                    'approved' => AppStatusTone.success,
                    'rejected' => AppStatusTone.error,
                    _ => AppStatusTone.neutral,
                  };
                  return Container(
                    key: Key('adminSubmittedImageCard_${item['id']}_$imgId'),
                    width: 240,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        InkWell(
                          key: Key(
                            'adminSubmittedImageZoom_${item['id']}_$imgId',
                          ),
                          onTap: url.startsWith('https://')
                              ? () => showProfilePhoto(
                                  context,
                                  url,
                                  caption: caption.isEmpty
                                      ? 'Submitted image ${i + 1}'
                                      : caption,
                                  explanation: explanation.isEmpty
                                      ? null
                                      : explanation,
                                  imageTypeLabel: imageType.label,
                                )
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSm,
                            ),
                            child: SmartImage(
                              url,
                              width: 224,
                              height: 120,
                              maxLogicalWidth: 320,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            AppStatusBadge(label: reviewStatus, tone: tone),
                            AppStatusBadge(
                              label: imageType.label,
                              tone: AppStatusTone.info,
                            ),
                          ],
                        ),
                        if (caption.isNotEmpty)
                          Text(
                            caption,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        if (explanation.isNotEmpty)
                          Text(
                            explanation,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: secondaryColor),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
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
    final categories = (item['categories'] as List<dynamic>? ?? [])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();
    final textDecision = item['textDecision'] as String?;
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
          if (categories.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final cat in categories)
                  AppStatusBadge(label: cat, tone: AppStatusTone.info),
              ],
            ),
          Text(item['proposal'] as String? ?? ''),
          _buildSubmittedImagesPreview(context, item: item),
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
        if (categories.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final cat in categories)
                AppStatusBadge(label: cat, tone: AppStatusTone.info),
            ],
          ),
        if (textDecision == 'rejected')
          const AppFeedbackBanner(
            message:
                'Text wording changes marked rejected; only approved images will be incorporated.',
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
        _buildSubmittedImagesPreview(context, item: item),
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
                          'partially_approved',
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
                        final pendingItems = bundle.items
                            .where(_isPendingSubmission)
                            .toList();
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (pendingItems.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppSurfaceCard(
                                  key: const Key('dictionaryPendingQueueBar'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '${pendingItems.length} pending '
                                        '${pendingItems.length == 1 ? 'submission' : 'submissions'} '
                                        'ready for review',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      OutlinedButton.icon(
                                        key: const Key(
                                          'inboxNextSubmissionButton',
                                        ),
                                        onPressed: () {
                                          final next = _nextPendingItem(
                                            bundle.items,
                                            afterId: _focusedSubmissionId,
                                          );
                                          _focusSubmission(
                                            next?['id'] as String?,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                        ),
                                        label: const Text('Next Submission'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (bundle.items.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: AppFeedbackBanner(
                                  key: Key('inboxQueueCaughtUpBanner'),
                                  message:
                                      'All caught up! No pending submissions '
                                      'remain in the review queue.',
                                ),
                              ),
                            for (final item in filtered)
                              Builder(
                                builder: (context) {
                                  final target = _resolveSuggestionTarget(
                                    bundle.publishedEntries,
                                    item,
                                  );
                                  final itemId = (item['id'] as String?) ?? '';
                                  final isFocused =
                                      itemId.isNotEmpty &&
                                      itemId == _focusedSubmissionId;
                                  final isQuickPublish =
                                      _isQuickPublishImageSubmission(
                                        item,
                                        target,
                                      );
                                  return Padding(
                                    key: itemId.isNotEmpty
                                        ? _keyForSubmission(itemId)
                                        : null,
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: AppSurfaceCard(
                                      key: itemId.isNotEmpty
                                          ? Key('submissionCard_$itemId')
                                          : null,
                                      borderColor: isFocused
                                          ? AppTokens.accentColor(context)
                                          : null,
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
                                                  'partially_approved' =>
                                                    AppStatusTone.coral,
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
                                          Builder(
                                            builder: (context) {
                                              final contribDetails =
                                                  _resolveAdminContributor(
                                                    item,
                                                    bundle.resolvedContributors,
                                                  );
                                              final uid = contribDetails.uid;
                                              final historyItems = uid.isEmpty
                                                  ? const <
                                                      Map<String, dynamic>
                                                    >[]
                                                  : bundle.items
                                                        .where(
                                                          (e) =>
                                                              e['contributorUid'] ==
                                                              uid,
                                                        )
                                                        .toList();
                                              final pubCount = historyItems
                                                  .where(
                                                    (e) =>
                                                        e['status'] ==
                                                        'published',
                                                  )
                                                  .length;
                                              final modStatus = uid.isEmpty
                                                  ? null
                                                  : bundle
                                                        .contributorModeration[uid];
                                              final isSuspended =
                                                  modStatus?['suspended'] ==
                                                  true;
                                              final suspensionReason =
                                                  modStatus?['reason']
                                                      as String?;
                                              final currentAdminUid =
                                                  context
                                                      .read<AppCubit?>()
                                                      ?.state
                                                      .user
                                                      .id ??
                                                  '';
                                              final canModerate =
                                                  uid.isNotEmpty &&
                                                  uid != currentAdminUid;
                                              return _AdminContributorInfoPanel(
                                                key: Key(
                                                  'adminContributorPanel_${item['id']}',
                                                ),
                                                details: contribDetails,
                                                submissionCount: uid.isEmpty
                                                    ? null
                                                    : historyItems.length,
                                                publishedCount: uid.isEmpty
                                                    ? null
                                                    : pubCount,
                                                isSuspended: isSuspended,
                                                suspensionReason:
                                                    suspensionReason,
                                                onViewHistory: uid.isEmpty
                                                    ? null
                                                    : () => _perform(
                                                        () =>
                                                            _showContributorHistory(
                                                              contribDetails,
                                                              bundle.items,
                                                              moderationStatus:
                                                                  modStatus,
                                                              canModerate:
                                                                  canModerate,
                                                            ),
                                                      ),
                                                onModerateContributor:
                                                    canModerate
                                                    ? () => _perform(
                                                        () =>
                                                            _moderateContributor(
                                                              contribDetails,
                                                              isSuspended:
                                                                  isSuspended,
                                                            ),
                                                      )
                                                    : null,
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          _buildSuggestionDiffSection(
                                            context,
                                            item: item,
                                            targetPublished: target,
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              if (isQuickPublish)
                                                FilledButton.icon(
                                                  key: Key(
                                                    'approveAndPublishButton_${item['id']}',
                                                  ),
                                                  onPressed: () => _perform(
                                                    () =>
                                                        _openQuickApproveAndPublish(
                                                          item,
                                                          target!,
                                                          bundle,
                                                        ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.publish_outlined,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Approve & Publish',
                                                  ),
                                                ),
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
                                              if ((item['submittedImages']
                                                          as List<dynamic>?)
                                                      ?.isNotEmpty ??
                                                  false)
                                                OutlinedButton.icon(
                                                  key: Key(
                                                    'reviewImagesButton_${item['id']}',
                                                  ),
                                                  onPressed:
                                                      item['status'] ==
                                                          'published'
                                                      ? null
                                                      : () => _perform(
                                                          () => _partialReview(
                                                            item,
                                                          ),
                                                        ),
                                                  icon: const Icon(
                                                    Icons.collections_outlined,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Review / edit images',
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
                                              Builder(
                                                builder: (context) {
                                                  final canIncorporate =
                                                      item['status'] ==
                                                          'approved' ||
                                                      item['status'] ==
                                                          'partially_approved';
                                                  final hasApprovedImages =
                                                      (item['submittedImages']
                                                                  as List<
                                                                    dynamic
                                                                  >? ??
                                                              const [])
                                                          .whereType<
                                                            Map<
                                                              dynamic,
                                                              dynamic
                                                            >
                                                          >()
                                                          .any(
                                                            (img) =>
                                                                img['reviewStatus'] ==
                                                                'approved',
                                                          );
                                                  return OutlinedButton(
                                                    key: Key(
                                                      'incorporateWording_${item['id']}',
                                                    ),
                                                    onPressed: canIncorporate
                                                        ? () => _perform(
                                                            () => _edit(
                                                              suggestion: item,
                                                            ),
                                                          )
                                                        : null,
                                                    child: Text(
                                                      hasApprovedImages
                                                          ? 'Incorporate approved'
                                                          : 'Incorporate wording',
                                                    ),
                                                  );
                                                },
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
    required this.repository,
  });
  final Map<String, dynamic> item;
  final String status;
  final DictionaryRepository repository;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final TextEditingController _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppGlassDialog(
    title: Text(widget.status.replaceAll('_', ' ')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        TextField(
          controller: _note,
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
                    'note': _note.text,
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

class _PartialImageDraft {
  _PartialImageDraft({
    required this.id,
    required this.url,
    required this.status,
    required this.imageType,
    required String caption,
    required String explanation,
  }) : captionController = TextEditingController(text: caption),
       explanationController = TextEditingController(text: explanation);

  final String id;
  final String url;
  String status;
  DictionaryImageType imageType;
  final TextEditingController captionController;
  final TextEditingController explanationController;

  void dispose() {
    captionController.dispose();
    explanationController.dispose();
  }
}

class _PartialReviewDialog extends StatefulWidget {
  const _PartialReviewDialog({
    required this.item,
    required this.repository,
    this.onSaved,
  });

  final Map<String, dynamic> item;
  final DictionaryRepository repository;
  final VoidCallback? onSaved;

  @override
  State<_PartialReviewDialog> createState() => _PartialReviewDialogState();
}

class _PartialReviewDialogState extends State<_PartialReviewDialog> {
  final _note = TextEditingController();
  late final List<_PartialImageDraft> _images;
  late String _textDecision;
  late final bool _hasTextProposal;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hasTextProposal =
        widget.item['kind'] != 'image_contribution' &&
        (widget.item['proposedFields'] is Map ||
            ((widget.item['proposal'] as String?)?.isNotEmpty ?? false));
    _textDecision =
        (widget.item['textDecision'] as String?) ??
        (widget.item['kind'] == 'image_contribution' ? 'rejected' : 'pending');
    _images = [
      for (final raw
          in (widget.item['submittedImages'] as List<dynamic>? ?? [])
              .whereType<Map<dynamic, dynamic>>())
        _PartialImageDraft(
          id: (raw['id'] as String?) ?? '',
          url: (raw['url'] as String?) ?? '',
          status: (raw['reviewStatus'] as String?) ?? 'pending',
          imageType: DictionaryImageType.fromStorageValue(
            raw['imageType'] as String?,
          ),
          caption: (raw['caption'] as String?) ?? '',
          explanation: (raw['explanation'] as String?) ?? '',
        ),
    ];
  }

  @override
  void dispose() {
    _note.dispose();
    for (final img in _images) {
      img.dispose();
    }
    super.dispose();
  }

  String _computedOverallStatus() {
    final decisions = <String>[
      if (_hasTextProposal) _textDecision,
      for (final img in _images) img.status,
    ];
    final approvedCount = decisions.where((d) => d == 'approved').length;
    final rejectedCount = decisions.where((d) => d == 'rejected').length;
    if (decisions.isNotEmpty && approvedCount == decisions.length) {
      return 'approved';
    }
    if (approvedCount > 0) return 'partially_approved';
    if (decisions.isNotEmpty && rejectedCount == decisions.length) {
      return 'rejected';
    }
    return 'under_review';
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final overallStatus = _computedOverallStatus();
      await widget.repository.call('editDictionary', {
        'action': 'review',
        'id': widget.item['id'],
        'status': overallStatus,
        'textDecision': _textDecision,
        'imageDecisions': [
          for (final img in _images)
            {
              'id': img.id,
              'status': img.status,
              'caption': img.captionController.text.trim(),
              'explanation': img.explanationController.text.trim(),
              'imageType': img.imageType.storageValue,
            },
        ],
        'note': _note.text.trim(),
      });
      widget.onSaved?.call();
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
    final sugId = widget.item['id'];
    final secondaryColor = AppTokens.secondaryTextColor(context);
    return AppGlassDialog(
      maxWidth: 720,
      title: Text('Review submission · ${widget.item['term'] ?? ''}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (_hasTextProposal)
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
                spacing: 8,
                children: [
                  Text(
                    'Proposed wording decision',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        key: Key('adminTextApprove_$sugId'),
                        label: const Text('Approve wording'),
                        selected: _textDecision == 'approved',
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _textDecision = 'approved'),
                      ),
                      ChoiceChip(
                        key: Key('adminTextReject_$sugId'),
                        label: const Text('Reject wording'),
                        selected: _textDecision == 'rejected',
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _textDecision = 'rejected'),
                      ),
                      ChoiceChip(
                        label: const Text('Keep pending'),
                        selected: _textDecision == 'pending',
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _textDecision = 'pending'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          for (var i = 0; i < _images.length; i++)
            Container(
              key: Key('adminReviewImageCard_${sugId}_${_images[i].id}'),
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
                    spacing: 10,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        child: SmartImage(
                          _images[i].url,
                          width: 112,
                          height: 90,
                          maxLogicalWidth: 200,
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              key: Key(
                                'adminImageApprove_${sugId}_${_images[i].id}',
                              ),
                              label: const Text('Approve image'),
                              selected: _images[i].status == 'approved',
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(
                                      () => _images[i].status = 'approved',
                                    ),
                            ),
                            ChoiceChip(
                              key: Key(
                                'adminImageReject_${sugId}_${_images[i].id}',
                              ),
                              label: const Text('Reject image'),
                              selected: _images[i].status == 'rejected',
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(
                                      () => _images[i].status = 'rejected',
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<DictionaryImageType>(
                    key: Key('adminImageType_${sugId}_${_images[i].id}'),
                    initialValue: _images[i].imageType,
                    decoration: const InputDecoration(
                      labelText: 'Educational image type',
                    ),
                    items: [
                      for (final type in DictionaryImageType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _images[i].imageType = value);
                            }
                          },
                  ),
                  TextFormField(
                    key: Key('adminImageCaption_${sugId}_${_images[i].id}'),
                    controller: _images[i].captionController,
                    enabled: !_busy,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Caption / alt text',
                    ),
                  ),
                  TextFormField(
                    key: Key('adminImageExplanation_${sugId}_${_images[i].id}'),
                    controller: _images[i].explanationController,
                    enabled: !_busy,
                    maxLength: 600,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText:
                          'Educational explanation (recommended for diagrams)',
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Rejected images are automatically deleted from private submission '
            'storage when saved.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondaryColor),
          ),
          TextField(
            key: Key('adminPartialReviewNote_$sugId'),
            controller: _note,
            enabled: !_busy,
            maxLength: 2000,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Private review note'),
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
          key: Key('savePartialReviewButton_$sugId'),
          onPressed: _busy ? null : _save,
          child: const Text('Save review decisions'),
        ),
      ],
    );
  }
}

class _ApproveAndPublishImagesDialog extends StatefulWidget {
  const _ApproveAndPublishImagesDialog({
    required this.item,
    required this.targetEntry,
    required this.allSubmissions,
    required this.repository,
    this.resolvedContributors = const {},
    this.onPublished,
  });

  final Map<String, dynamic> item;
  final DictionaryEntry targetEntry;
  final List<Map<String, dynamic>> allSubmissions;
  final DictionaryRepository repository;
  final Map<String, Map<String, dynamic>> resolvedContributors;
  final VoidCallback? onPublished;

  @override
  State<_ApproveAndPublishImagesDialog> createState() =>
      _ApproveAndPublishImagesDialogState();
}

class _ApproveAndPublishImagesDialogState
    extends State<_ApproveAndPublishImagesDialog> {
  final _note = TextEditingController();
  late final List<_PartialImageDraft> _images;
  late final List<DictionaryMediaItem> _existingMedia;
  late String _selectedHeroId;
  bool _busy = false;
  bool _published = false;
  String? _error;
  int _publishedCount = 0;

  @override
  void initState() {
    super.initState();
    _existingMedia = (widget.targetEntry.data['media'] as List<dynamic>? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => DictionaryMediaItem.fromMap(e.cast<String, dynamic>()))
        .where((m) => m.url.isNotEmpty)
        .toList();
    _images = [
      for (final raw
          in (widget.item['submittedImages'] as List<dynamic>? ?? [])
              .whereType<Map<dynamic, dynamic>>())
        _PartialImageDraft(
          id: (raw['id'] as String?) ?? '',
          url: (raw['url'] as String?) ?? '',
          status: (raw['reviewStatus'] == 'rejected') ? 'rejected' : 'approved',
          imageType: DictionaryImageType.fromStorageValue(
            raw['imageType'] as String?,
          ),
          caption: (raw['caption'] as String?) ?? '',
          explanation: (raw['explanation'] as String?) ?? '',
        ),
    ];
    if (_existingMedia.isNotEmpty) {
      _selectedHeroId = 'existing:0';
    } else {
      final firstApproved = _images
          .where((img) => img.status == 'approved')
          .firstOrNull;
      _selectedHeroId = firstApproved != null
          ? 'submitted:${firstApproved.id}'
          : '';
    }
  }

  @override
  void dispose() {
    _note.dispose();
    for (final img in _images) {
      img.dispose();
    }
    super.dispose();
  }

  List<_PartialImageDraft> get _approvedImages =>
      _images.where((img) => img.status == 'approved').toList();

  List<_PartialImageDraft> get _rejectedImages =>
      _images.where((img) => img.status == 'rejected').toList();

  List<Map<String, dynamic>> get _remainingPendingSubmissions => widget
      .allSubmissions
      .where(
        (s) =>
            s['id'] != widget.item['id'] &&
            _DictionaryAdminPageState._isPendingSubmission(s),
      )
      .toList();

  void _setImageStatus(_PartialImageDraft img, String status) {
    setState(() {
      img.status = status;
      if (status == 'rejected' && _selectedHeroId == 'submitted:${img.id}') {
        final fallbackSubmitted = _approvedImages.firstOrNull;
        if (_existingMedia.isNotEmpty) {
          _selectedHeroId = 'existing:0';
        } else if (fallbackSubmitted != null) {
          _selectedHeroId = 'submitted:${fallbackSubmitted.id}';
        } else {
          _selectedHeroId = '';
        }
      } else if (status == 'approved' && _selectedHeroId.isEmpty) {
        _selectedHeroId = _existingMedia.isNotEmpty
            ? 'existing:0'
            : 'submitted:${img.id}';
      }
    });
  }

  String _heroSummaryLabel() {
    if (_selectedHeroId.startsWith('submitted:')) {
      final id = _selectedHeroId.substring('submitted:'.length);
      final match = _approvedImages.where((img) => img.id == id).firstOrNull;
      if (match != null) {
        final caption = match.captionController.text.trim();
        return caption.isNotEmpty ? caption : 'Submitted image (${match.id})';
      }
    }
    if (_existingMedia.isNotEmpty) {
      final existingLabel = _existingMedia.first.label.trim();
      return existingLabel.isNotEmpty
          ? 'Current hero: $existingLabel'
          : 'Keep current hero image';
    }
    return 'None selected';
  }

  Future<void> _publish() async {
    if (_busy || _published) return;
    final approved = _approvedImages;
    if (approved.isEmpty) {
      setState(() => _error = 'Approve at least one image before publishing.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.approveAndPublishImages(
        suggestionId: (widget.item['id'] as String?) ?? '',
        expectedRevision: widget.targetEntry.storedRevision,
        heroImageId: _selectedHeroId,
        note: _note.text.trim(),
        imageDecisions: [
          for (final img in _images)
            {
              'id': img.id,
              'status': img.status,
              'caption': img.captionController.text.trim(),
              'explanation': img.explanationController.text.trim(),
              'imageType': img.imageType.storageValue,
            },
        ],
      );
      DictionaryRepository.invalidateCache();
      if (widget.repository.usesDefaultBackend) {
        unawaited(DictionaryRepository.refreshCachedEntries());
      }
      widget.onPublished?.call();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _published = true;
        _publishedCount = approved.length;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sugId = (widget.item['id'] as String?) ?? '';
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final consent = widget.item['recognitionConsent'] == true;
    final publicName = (widget.item['publicName'] as String?)?.trim() ?? '';
    final rightsConfirmed = widget.item['rightsConfirmed'] == true;
    final approved = _approvedImages;
    final rejected = _rejectedImages;
    final galleryTotal =
        (_existingMedia.length +
                approved.length -
                (approved.isNotEmpty || _existingMedia.isNotEmpty ? 1 : 0))
            .clamp(0, maxDictionaryMediaItems);
    final remainingPending = _remainingPendingSubmissions;

    return PopScope(
      canPop: !_busy,
      child: AppGlassDialog(
        maxWidth: 740,
        title: Text(
          _published
              ? 'Published to ${widget.targetEntry.term}'
              : 'Approve & Publish · ${widget.targetEntry.term}',
        ),
        content: _published
            ? Column(
                key: const Key('approveAndPublishSuccessView'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  AppFeedbackBanner(
                    message:
                        'Published $_publishedCount approved '
                        '${_publishedCount == 1 ? 'image' : 'images'} to '
                        '${widget.targetEntry.term}.',
                  ),
                  if (remainingPending.isNotEmpty)
                    Text(
                      '${remainingPending.length} pending '
                      '${remainingPending.length == 1 ? 'submission' : 'submissions'} '
                      'remaining in the review queue.',
                    )
                  else
                    Container(
                      key: const Key('dictionaryQueueEmptyMessage'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: const Row(
                        spacing: 8,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          Expanded(
                            child: Text(
                              'All caught up! No pending submissions remain in the review queue.',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  _AdminContributorInfoPanel(
                    details: _resolveAdminContributor(
                      widget.item,
                      widget.resolvedContributors,
                    ),
                    compact: true,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppStatusBadge(
                        label: rightsConfirmed
                            ? 'Permissions confirmed'
                            : 'Permissions not confirmed',
                        tone: rightsConfirmed
                            ? AppStatusTone.success
                            : AppStatusTone.warning,
                      ),
                      Text(
                        consent && publicName.isNotEmpty
                            ? 'Public credit: $publicName'
                            : 'Contributor: Private account (no public credit)',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                      ),
                    ],
                  ),
                  Container(
                    key: const Key('approveAndPublishPreviewSummary'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.35),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(
                          'Confirmation preview',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text('Hero image: ${_heroSummaryLabel()}'),
                        Text(
                          'Gallery images: $galleryTotal '
                          '(${_existingMedia.length} existing, '
                          '${approved.length} approved)',
                        ),
                        if (rejected.isNotEmpty)
                          Text(
                            'Rejected images: ${rejected.length} '
                            '(excluded and deleted from private storage)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_existingMedia.isNotEmpty)
                    Wrap(
                      key: const Key('heroImageSelectionRow'),
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Hero image:',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        ChoiceChip(
                          key: const Key('selectHero_existing_0'),
                          label: const Text('Keep existing hero'),
                          selected: _selectedHeroId == 'existing:0',
                          onSelected: _busy
                              ? null
                              : (_) => setState(
                                  () => _selectedHeroId = 'existing:0',
                                ),
                        ),
                      ],
                    ),
                  for (var i = 0; i < _images.length; i++)
                    Container(
                      key: Key(
                        'quickReviewImageCard_${sugId}_${_images[i].id}',
                      ),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        border: Border.all(
                          color: _selectedHeroId == 'submitted:${_images[i].id}'
                              ? AppTokens.accentColor(context)
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 10,
                            children: [
                              InkWell(
                                key: Key(
                                  'quickImageZoom_${sugId}_${_images[i].id}',
                                ),
                                onTap: _images[i].url.startsWith('https://')
                                    ? () => showProfilePhoto(
                                        context,
                                        _images[i].url,
                                        caption:
                                            _images[i].captionController.text
                                                .trim()
                                                .isEmpty
                                            ? 'Submitted image ${i + 1}'
                                            : _images[i].captionController.text
                                                  .trim(),
                                        explanation: _images[i]
                                            .explanationController
                                            .text
                                            .trim(),
                                        imageTypeLabel:
                                            _images[i].imageType.label,
                                        attribution:
                                            consent && publicName.isNotEmpty
                                            ? publicName
                                            : null,
                                      )
                                    : null,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppTokens.radiusSm,
                                  ),
                                  child: SmartImage(
                                    _images[i].url,
                                    width: 112,
                                    height: 90,
                                    maxLogicalWidth: 200,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    ChoiceChip(
                                      key: Key(
                                        'quickApproveImg_${sugId}_${_images[i].id}',
                                      ),
                                      label: const Text('Approve'),
                                      selected: _images[i].status == 'approved',
                                      onSelected: _busy
                                          ? null
                                          : (_) => _setImageStatus(
                                              _images[i],
                                              'approved',
                                            ),
                                    ),
                                    ChoiceChip(
                                      key: Key(
                                        'quickRejectImg_${sugId}_${_images[i].id}',
                                      ),
                                      label: const Text('Reject'),
                                      selected: _images[i].status == 'rejected',
                                      onSelected: _busy
                                          ? null
                                          : (_) => _setImageStatus(
                                              _images[i],
                                              'rejected',
                                            ),
                                    ),
                                    ChoiceChip(
                                      key: Key(
                                        'selectHero_submitted_${_images[i].id}',
                                      ),
                                      label: const Text('Use as hero'),
                                      selected:
                                          _selectedHeroId ==
                                          'submitted:${_images[i].id}',
                                      onSelected:
                                          _busy ||
                                              _images[i].status != 'approved'
                                          ? null
                                          : (_) => setState(
                                              () => _selectedHeroId =
                                                  'submitted:${_images[i].id}',
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          DropdownButtonFormField<DictionaryImageType>(
                            key: Key('quickImageType_${_images[i].id}'),
                            initialValue: _images[i].imageType,
                            decoration: const InputDecoration(
                              labelText: 'Educational image type',
                            ),
                            items: [
                              for (final type in DictionaryImageType.values)
                                DropdownMenuItem(
                                  value: type,
                                  child: Text(type.label),
                                ),
                            ],
                            onChanged: _busy
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(
                                        () => _images[i].imageType = value,
                                      );
                                    }
                                  },
                          ),
                          TextFormField(
                            key: Key('quickCaption_${_images[i].id}'),
                            controller: _images[i].captionController,
                            enabled: !_busy,
                            maxLength: 120,
                            decoration: const InputDecoration(
                              labelText: 'Caption / alt text',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          TextFormField(
                            key: Key('quickExplanation_${_images[i].id}'),
                            controller: _images[i].explanationController,
                            enabled: !_busy,
                            maxLength: 600,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Educational explanation (optional)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    key: const Key('quickPublishNote'),
                    controller: _note,
                    enabled: !_busy,
                    maxLength: 2000,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Private editorial audit note (optional)',
                    ),
                  ),
                  if (_error != null)
                    AppFeedbackBanner(
                      key: const Key('quickPublishErrorBanner'),
                      message: _error!,
                      tone: AppStatusTone.error,
                    ),
                ],
              ),
        actions: _published
            ? [
                TextButton(
                  key: const Key('closeAfterPublishButton'),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    remainingPending.isEmpty ? 'Done' : 'Back to inbox',
                  ),
                ),
                if (remainingPending.isNotEmpty)
                  FilledButton.icon(
                    key: const Key('nextSubmissionAfterPublishButton'),
                    onPressed: () =>
                        Navigator.pop(context, remainingPending.first),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Next Submission'),
                  ),
              ]
            : [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  key: const Key('confirmApproveAndPublishButton'),
                  onPressed: (_busy || approved.isEmpty) ? null : _publish,
                  icon: const Icon(Icons.publish_outlined, size: 16),
                  label: Text(_busy ? 'Publishing…' : 'Confirm & Publish'),
                ),
              ],
      ),
    );
  }
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
  final List<DictionaryImageType> _mediaTypes = [];
  final List<TextEditingController> _mediaExplanationControllers = [];
  final List<TextEditingController> _mediaAttributionControllers = [];
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

      // Apply ONLY approved structured fields modified by the suggestion so
      // unchanged (or rejected) fields on the live/draft entry remain intact.
      final textRejected = widget.suggestion?['textDecision'] == 'rejected';
      final rawProposed = textRejected
          ? null
          : widget.suggestion?['proposedFields'];
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
      if (!textRejected &&
          (data['categories'] as List<dynamic>? ?? const []).isEmpty &&
          widget.suggestion?['categories'] is List) {
        data['categories'] = List<String>.from(
          (widget.suggestion!['categories'] as List)
              .whereType<String>()
              .map((c) => c.trim())
              .where((c) => c.isNotEmpty),
        );
      }

      _revision = _existingDraft || !(widget.initial?.bundled ?? true)
          ? (data['revision'] as num?)?.toInt() ?? 0
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
          final parsed = DictionaryMediaItem.fromMap(
            rawItem.cast<String, dynamic>(),
          );
          if (parsed.url.isNotEmpty) {
            _addMediaRow(
              url: parsed.url,
              label: parsed.label,
              imageType: parsed.imageType,
              explanation: parsed.explanation,
              attribution: parsed.attribution ?? '',
              persisted: true,
            );
          }
        }
      }
      // Append ONLY approved community-submitted images without replacing
      // existing published images.
      final submittedImages =
          (widget.suggestion?['submittedImages'] as List<dynamic>? ?? const [])
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => e.cast<String, dynamic>());
      final consentedName = widget.suggestion?['recognitionConsent'] == true
          ? ((widget.suggestion?['publicName'] as String?)?.trim() ?? '')
          : '';
      for (final img in submittedImages) {
        if (img['reviewStatus'] != 'approved') continue;
        final url = (img['url'] as String?)?.trim() ?? '';
        if (url.isEmpty || _mediaUrls.contains(url)) continue;
        if (_mediaUrls.length >= maxDictionaryMediaItems) break;
        final caption = (img['caption'] as String?)?.trim() ?? '';
        _addMediaRow(
          url: url,
          label: caption.isNotEmpty ? caption : _fields['term']!.text.trim(),
          imageType: DictionaryImageType.fromStorageValue(
            img['imageType'] as String?,
          ),
          explanation: (img['explanation'] as String?)?.trim() ?? '',
          attribution: consentedName,
          persisted: true,
        );
      }
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _busy = false);
  }

  void _addMediaRow({
    required String url,
    required String label,
    DictionaryImageType imageType = DictionaryImageType.illustrative,
    String explanation = '',
    String attribution = '',
    bool persisted = false,
  }) {
    _mediaUrls.add(url);
    if (persisted) {
      _persistedMediaUrls.add(url);
    }
    _mediaLabelControllers.add(TextEditingController(text: label));
    _mediaTypes.add(imageType);
    _mediaExplanationControllers.add(TextEditingController(text: explanation));
    _mediaAttributionControllers.add(TextEditingController(text: attribution));
  }

  void _clearMediaControllers() {
    for (final controller in _mediaLabelControllers) {
      controller.dispose();
    }
    for (final controller in _mediaExplanationControllers) {
      controller.dispose();
    }
    for (final controller in _mediaAttributionControllers) {
      controller.dispose();
    }
    _mediaLabelControllers.clear();
    _mediaExplanationControllers.clear();
    _mediaAttributionControllers.clear();
    _mediaTypes.clear();
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
      DictionaryMediaItem(
        url: _mediaUrls[i],
        label: _mediaLabelControllers[i].text.trim(),
        imageType: _mediaTypes[i],
        explanation: _mediaExplanationControllers[i].text.trim(),
        attribution: _mediaAttributionControllers[i].text.trim().isNotEmpty
            ? _mediaAttributionControllers[i].text.trim()
            : null,
      ).toMap(),
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
          _addMediaRow(
            url: url,
            label: _defaultCaptionFromFileName(validated.fileName),
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

  void _moveMediaToIndex(int from, int target) {
    if (from < 0 ||
        from >= _mediaUrls.length ||
        target < 0 ||
        target >= _mediaUrls.length ||
        from == target) {
      return;
    }
    setState(() {
      final url = _mediaUrls.removeAt(from);
      _mediaUrls.insert(target, url);
      final label = _mediaLabelControllers.removeAt(from);
      _mediaLabelControllers.insert(target, label);
      final type = _mediaTypes.removeAt(from);
      _mediaTypes.insert(target, type);
      final exp = _mediaExplanationControllers.removeAt(from);
      _mediaExplanationControllers.insert(target, exp);
      final attr = _mediaAttributionControllers.removeAt(from);
      _mediaAttributionControllers.insert(target, attr);
    });
  }

  void _moveMedia(int index, int delta) =>
      _moveMediaToIndex(index, index + delta);

  void _removeMedia(int index) {
    if (index < 0 || index >= _mediaUrls.length) return;
    late final String removedUrl;
    setState(() {
      removedUrl = _mediaUrls.removeAt(index);
      _mediaLabelControllers.removeAt(index).dispose();
      _mediaTypes.removeAt(index);
      _mediaExplanationControllers.removeAt(index).dispose();
      _mediaAttributionControllers.removeAt(index).dispose();
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
                entries: widget.existingEntries,
                excludeEntryId: previewEntry.id,
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
                      InkWell(
                        onTap: () => showProfilePhoto(
                          context,
                          _mediaUrls[i],
                          caption: _mediaLabelControllers[i].text.trim().isEmpty
                              ? 'Dictionary image ${i + 1}'
                              : _mediaLabelControllers[i].text.trim(),
                          explanation: _mediaExplanationControllers[i].text
                              .trim(),
                          imageTypeLabel: _mediaTypes[i].label,
                          attribution: _mediaAttributionControllers[i].text
                              .trim(),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSm,
                          ),
                          child: SmartImage(
                            _mediaUrls[i],
                            width: 112,
                            height: 84,
                            maxLogicalWidth: 240,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          spacing: 8,
                          children: [
                            TextFormField(
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
                            DropdownButtonFormField<DictionaryImageType>(
                              key: Key('dictionaryMediaType_${_mediaUrls[i]}'),
                              initialValue: _mediaTypes[i],
                              decoration: const InputDecoration(
                                labelText: 'Educational image type',
                              ),
                              items: [
                                for (final type in DictionaryImageType.values)
                                  DropdownMenuItem(
                                    value: type,
                                    child: Text(type.label),
                                  ),
                              ],
                              onChanged: _busy || _uploadingMedia
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _mediaTypes[i] = value);
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    key: Key('dictionaryMediaExplanation_$i'),
                    controller: _mediaExplanationControllers[i],
                    enabled: !_busy && !_uploadingMedia,
                    maxLength: 600,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Educational explanation (optional)',
                      hintText:
                          'Clarify biomechanical or practical details shown',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (RegExp(
                        r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
                        caseSensitive: false,
                      ).hasMatch(trimmed)) {
                        return 'Remove email addresses from explanations.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    key: Key('dictionaryMediaAttribution_$i'),
                    controller: _mediaAttributionControllers[i],
                    enabled: !_busy && !_uploadingMedia,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Contributor attribution (optional)',
                      hintText: 'Only include a public name when consented',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.contains('@')) {
                        return 'Remove email addresses from attribution.';
                      }
                      return null;
                    },
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (i == 0)
                        const AppStatusBadge(
                          label: 'Primary image',
                          tone: AppStatusTone.info,
                        )
                      else
                        TextButton.icon(
                          key: Key('dictionaryMediaSetPrimary_$i'),
                          onPressed: _busy || _uploadingMedia
                              ? null
                              : () => _moveMediaToIndex(i, 0),
                          icon: const Icon(Icons.star_outline, size: 16),
                          label: const Text('Set as primary'),
                        ),
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
