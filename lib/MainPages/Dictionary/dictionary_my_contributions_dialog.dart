// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_contribution_auth.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Shows the signed-in contributor's own Dictionary submissions and per-image
/// moderation statuses without exposing private admin notes or email addresses.
class DictionaryMyContributionsDialog extends StatefulWidget {
  const DictionaryMyContributionsDialog({super.key, required this.repository});

  final DictionaryRepository repository;

  @override
  State<DictionaryMyContributionsDialog> createState() =>
      _DictionaryMyContributionsDialogState();
}

class _DictionaryMyContributionsDialogState
    extends State<DictionaryMyContributionsDialog> {
  Future<List<Map<String, dynamic>>>? _future;
  String? _loadedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final identity = DictionaryContributorIdentity.fromContext(context);
    if (identity.canContribute && _loadedUid != identity.uid) {
      _loadedUid = identity.uid;
      _future = widget.repository.loadMySuggestions(identity.uid);
    }
  }

  static String _kindLabel(String? kind) => switch (kind) {
    'new_term' || 'missing_term' => 'New term',
    'image_contribution' => 'Images',
    'correction' || 'improvement' => 'Improvement',
    'regional_usage' => 'Regional usage',
    'related_term' => 'Related term',
    _ => 'Contribution',
  };

  static (String label, AppStatusTone tone) _statusDisplay(String? status) =>
      switch (status) {
        'under_review' => ('Under review', AppStatusTone.info),
        'needs_clarification' => ('Needs clarification', AppStatusTone.warning),
        'partially_approved' => ('Partially approved', AppStatusTone.coral),
        'approved' => ('Approved', AppStatusTone.success),
        'published' => ('Published', AppStatusTone.success),
        'rejected' => ('Not accepted', AppStatusTone.error),
        _ => ('Submitted', AppStatusTone.neutral),
      };

  static (String label, AppStatusTone tone) _imageDecisionDisplay(
    String? reviewStatus,
  ) => switch (reviewStatus) {
    'approved' => ('Approved', AppStatusTone.success),
    'rejected' => ('Not accepted', AppStatusTone.error),
    _ => ('Pending review', AppStatusTone.neutral),
  };

  @override
  Widget build(BuildContext context) {
    final identity = DictionaryContributorIdentity.fromContext(context);
    final secondaryColor = AppTokens.secondaryTextColor(context);

    return AppGlassDialog(
      maxWidth: 640,
      title: const Text('My Dictionary Contributions'),
      content: !identity.canContribute
          ? DictionaryContributionAuthPrompt(
              identity: identity,
              contributionLabel: 'view your contribution history and status',
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return AppEmptyState(
                    icon: Icons.error_outline,
                    title: 'Could not load your contributions.',
                    description: snapshot.error.toString(),
                    actionLabel: 'Try again',
                    onAction: () => setState(() {
                      _future = widget.repository.loadMySuggestions(
                        identity.uid,
                      );
                    }),
                  );
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.edit_note_outlined,
                    title: 'No contributions yet',
                    description:
                        'When you suggest a term, propose an improvement, or '
                        'contribute images, its review status will appear here.',
                  );
                }
                return Column(
                  key: const Key('dictionaryMyContributionsList'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    for (final item in items)
                      _ContributionStatusCard(
                        item: item,
                        kindLabel: _kindLabel(item['kind'] as String?),
                        statusDisplay: _statusDisplay(
                          item['status'] as String?,
                        ),
                        imageDecisionDisplay: _imageDecisionDisplay,
                        secondaryColor: secondaryColor,
                      ),
                  ],
                );
              },
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ContributionStatusCard extends StatelessWidget {
  const _ContributionStatusCard({
    required this.item,
    required this.kindLabel,
    required this.statusDisplay,
    required this.imageDecisionDisplay,
    required this.secondaryColor,
  });

  final Map<String, dynamic> item;
  final String kindLabel;
  final (String, AppStatusTone) statusDisplay;
  final (String, AppStatusTone) Function(String?) imageDecisionDisplay;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final term = (item['term'] as String?) ?? 'Dictionary term';
    final proposal = (item['proposal'] as String?) ?? '';
    final images = (item['submittedImages'] as List<dynamic>? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    return Container(
      key: Key('myContributionCard_${item['id'] ?? term}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                term,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              AppStatusBadge(label: kindLabel, tone: AppStatusTone.info),
              AppStatusBadge(label: statusDisplay.$1, tone: statusDisplay.$2),
            ],
          ),
          if (proposal.isNotEmpty)
            Text(
              proposal,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: secondaryColor),
            ),
          if (images.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < images.length; i++)
                  Builder(
                    builder: (context) {
                      final decision = imageDecisionDisplay(
                        images[i]['reviewStatus'] as String?,
                      );
                      final caption = (images[i]['caption'] as String?)?.trim();
                      final title = (caption != null && caption.isNotEmpty)
                          ? caption
                          : 'Image ${i + 1}';
                      return AppStatusBadge(
                        label: '$title · ${decision.$1}',
                        tone: decision.$2,
                      );
                    },
                  ),
              ],
            ),
          if (item['recognitionConsent'] == true &&
              ((item['publicName'] as String?)?.trim().isNotEmpty ?? false))
            Text(
              'Public credit requested: ${item['publicName']}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: secondaryColor),
            ),
        ],
      ),
    );
  }
}
