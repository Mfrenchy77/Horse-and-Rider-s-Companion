import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_local_cache.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/known_terms_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Device-local settings section for viewing and restoring Dictionary terms
/// that the user has marked as already understood ("I know this term").
///
/// Resolves term titles purely from already-cached memory, local
/// [DictionaryLocalCache], or the bundled seed glossary — performing zero
/// Firestore reads or Cloud Function calls.
class KnownDictionaryTermsSection extends StatefulWidget {
  const KnownDictionaryTermsSection({
    super.key,
    this.repository,
    this.entriesOverride,
  });

  final KnownTermsRepository? repository;
  final List<DictionaryEntry>? entriesOverride;

  @override
  State<KnownDictionaryTermsSection> createState() =>
      _KnownDictionaryTermsSectionState();
}

class _KnownDictionaryTermsSectionState
    extends State<KnownDictionaryTermsSection> {
  final TextEditingController _searchController = TextEditingController();
  late KnownTermsRepository _repository;
  Map<String, DictionaryEntry> _entriesById = const {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? KnownTermsRepository.instance;
    unawaited(_repository.ensureLoaded());
    _syncLocalEntries();
  }

  @override
  void didUpdateWidget(covariant KnownDictionaryTermsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _repository = widget.repository ?? KnownTermsRepository.instance;
    if (!identical(widget.entriesOverride, oldWidget.entriesOverride)) {
      _syncLocalEntries();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncLocalEntries() {
    final override = widget.entriesOverride;
    if (override != null) {
      _entriesById = {for (final entry in override) entry.id: entry};
      return;
    }
    final peeked = DictionaryRepository.peekCachedEntries;
    if (peeked != null && peeked.isNotEmpty) {
      _entriesById = {for (final entry in peeked) entry.id: entry};
      return;
    }
    unawaited(_loadLocalOnlyCatalogue());
  }

  Future<void> _loadLocalOnlyCatalogue() async {
    try {
      final cached = await DictionaryLocalCache.read();
      if (cached != null && cached.entries.isNotEmpty) {
        if (!mounted || widget.entriesOverride != null) return;
        setState(() {
          _entriesById = {for (final entry in cached.entries) entry.id: entry};
        });
        return;
      }
      final raw = await rootBundle.loadString('functions/dictionary_seed.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return;
      final bundled = [
        for (final item in decoded)
          if (item is Map)
            DictionaryEntry(
              item.map((k, v) => MapEntry(k.toString(), v)),
              bundled: true,
            ),
      ];
      if (!mounted || widget.entriesOverride != null || bundled.isEmpty) return;
      setState(() {
        _entriesById = {for (final entry in bundled) entry.id: entry};
      });
    } catch (_) {
      // Fallback safely formats missing entries from their canonical IDs.
    }
  }

  Future<void> _confirmClearAll(BuildContext context, int count) async {
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => AppGlassDialog(
        key: const Key('clearKnownTermsConfirmDialog'),
        maxWidth: 420,
        title: Text(
          'Highlight all terms again?',
          style: AppTokens.sectionTitleStyle(dialogContext),
        ),
        content: Text(
          'This will restore automatic contextual highlighting for all '
          '$count known ${count == 1 ? 'term' : 'terms'} on this device.',
          style: Theme.of(dialogContext).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmClearKnownTermsButton'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Highlight all'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _repository.clearKnownTerms();
      if (mounted) {
        _searchController.clear();
        setState(() => _query = '');
      }
    }
  }

  static String _fallbackLabelForId(String termId) {
    final parts = termId
        .trim()
        .split(RegExp('[-_]+'))
        .where((p) => p.isNotEmpty)
        .map(
          (p) => p.length == 1
              ? p.toUpperCase()
              : '${p[0].toUpperCase()}${p.substring(1)}',
        )
        .toList();
    return parts.isEmpty ? termId : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    AppCubit? cubit;
    try {
      cubit = context.read<AppCubit>();
    } catch (_) {
      cubit = null;
    }

    Widget buildCard(BuildContext context) {
      final theme = Theme.of(context);
      final secondaryColor = AppTokens.secondaryTextColor(context);

      return ListenableBuilder(
        listenable: _repository,
        builder: (context, _) {
          if (!_repository.isEnabled) {
            return const SizedBox.shrink();
          }
          final knownIds = _repository.getKnownTerms().toList();
          final resolved =
              [
                for (final id in knownIds)
                  _KnownTermItem(
                    id: id,
                    title: _entriesById[id]?.term ?? _fallbackLabelForId(id),
                    isMissingFromCatalogue: !_entriesById.containsKey(id),
                  ),
              ]..sort(
                (a, b) =>
                    a.title.toLowerCase().compareTo(b.title.toLowerCase()),
              );

          final normalizedQuery = _query.trim().toLowerCase();
          final filtered = normalizedQuery.isEmpty
              ? resolved
              : [
                  for (final item in resolved)
                    if (item.title.toLowerCase().contains(normalizedQuery) ||
                        item.id.toLowerCase().contains(normalizedQuery))
                      item,
                ];

          final count = resolved.length;
          final countLabel = '$count ${count == 1 ? 'term' : 'terms'}';

          return AppSurfaceCard(
            key: const Key('knownTermsSettingsCard'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Known Dictionary Terms',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceSm),
                    AppStatusBadge(
                      key: const Key('knownTermsCountBadge'),
                      label: countLabel,
                      tone: count > 0
                          ? AppStatusTone.coral
                          : AppStatusTone.info,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spaceXs),
                Text(
                  "Terms you've marked as understood won't be automatically "
                  'highlighted while you read.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Saved locally for this account on this device/browser '
                  '(not synced across devices).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMd),
                if (count == 0)
                  Container(
                    key: const Key('knownTermsEmptyState'),
                    padding: const EdgeInsets.all(AppTokens.spaceMd),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.25
                                : 0.55,
                          ),
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 20,
                          color: secondaryColor,
                        ),
                        const SizedBox(width: AppTokens.spaceSm),
                        Expanded(
                          child: Text(
                            'No terms marked as known yet. Tap any '
                            'highlighted term while reading and check '
                            '"I know this term" to keep your reading view '
                            'uncluttered.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (count > 4) ...[
                    TextField(
                      key: const Key('knownTermsSearchField'),
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Filter known terms...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear filter',
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSm,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceSm),
                  ],
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.spaceSm,
                      ),
                      child: Text(
                        'No known terms match "${_query.trim()}".',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondaryColor,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < filtered.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _KnownTermRow(
                        item: filtered[i],
                        onRemove: () =>
                            unawaited(_repository.markUnknown(filtered[i].id)),
                      ),
                    ],
                  const SizedBox(height: AppTokens.spaceMd),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppOutlinedButton(
                      key: const Key('clearAllKnownTermsButton'),
                      icon: Icons.visibility_outlined,
                      label: 'Highlight all terms again',
                      onPressed: () => _confirmClearAll(context, count),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    if (cubit == null) {
      return buildCard(context);
    }
    return BlocSelector<AppCubit, AppState, bool>(
      bloc: cubit,
      selector: (state) => state.isSignedInUser,
      builder: (context, isSignedIn) {
        if (!isSignedIn) {
          return const SizedBox.shrink();
        }
        return buildCard(context);
      },
    );
  }
}

class _KnownTermItem {
  const _KnownTermItem({
    required this.id,
    required this.title,
    required this.isMissingFromCatalogue,
  });

  final String id;
  final String title;
  final bool isMissingFromCatalogue;
}

class _KnownTermRow extends StatelessWidget {
  const _KnownTermRow({required this.item, required this.onRemove});

  final _KnownTermItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.isMissingFromCatalogue)
                  Text(
                    'No longer in Dictionary',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTokens.secondaryTextColor(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.spaceSm),
          TextButton(
            key: Key('removeKnownTerm_${item.id}'),
            onPressed: onRemove,
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
