import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_matcher.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

export 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_matcher.dart';

void _openFullDefinition(BuildContext context, DictionaryEntry entry) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.push('/Dictionary/${entry.slug}');
    return;
  }
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(builder: (_) => DictionaryPage(slug: entry.slug)),
  );
}

void _openDictionarySearch(BuildContext context, String query) {
  final encoded = Uri.encodeQueryComponent(query);
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.push('/Dictionary?q=$encoded');
    return;
  }
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => DictionaryPage(initialQuery: query),
    ),
  );
}

/// Opens a compact glass dialog showing a published Dictionary [entry] without
/// navigating away from the current screen.
Future<void> showDictionaryDefinitionDialog(
  BuildContext context,
  DictionaryEntry entry,
) {
  final synonyms = entry.strings('synonyms');
  final categories = entry.strings('categories');
  return showAppGlassDialog<void>(
    context: context,
    builder: (dialogContext) => AppGlassDialog(
      key: const Key('dictionaryDefinitionDialog'),
      maxWidth: 460,
      title: Text(
        entry.term,
        style: AppTokens.sectionTitleStyle(dialogContext),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          if (categories.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final cat in categories)
                  AppStatusBadge(label: cat, tone: AppStatusTone.info),
              ],
            ),
          Text(
            entry.definition,
            style: Theme.of(dialogContext).textTheme.bodyLarge,
          ),
          if (synonyms.isNotEmpty)
            Text(
              'Also called: ${synonyms.join(' · ')}',
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                color: AppTokens.secondaryTextColor(dialogContext),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.menu_book_outlined, size: 16),
          onPressed: () {
            Navigator.pop(dialogContext);
            _openFullDefinition(context, entry);
          },
          label: const Text('View full definition'),
        ),
      ],
    ),
  );
}

/// Looks up [selectedText] against published [entries] and shows a compact
/// definition dialog, a multi-meaning chooser if ambiguous, or a
/// non-disruptive not-found dialog.
Future<void> showSelectedTermDefinition(
  BuildContext context, {
  required String selectedText,
  required List<DictionaryEntry> entries,
}) {
  final result = lookupSelectedDictionaryTerm(selectedText, entries);
  if (result.exactMatch case final match?) {
    return showDictionaryDefinitionDialog(context, match);
  }
  if (result.ambiguousMatches.isNotEmpty) {
    return showAppGlassDialog<void>(
      context: context,
      builder: (dialogContext) => AppGlassDialog(
        key: const Key('dictionaryAmbiguousDialog'),
        maxWidth: 480,
        title: Text(
          result.normalizedQuery,
          style: AppTokens.sectionTitleStyle(dialogContext),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              'This term has multiple published meanings:',
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                color: AppTokens.secondaryTextColor(dialogContext),
              ),
            ),
            for (final entry in result.ambiguousMatches)
              AppSurfaceCard(
                padding: const EdgeInsets.all(AppTokens.spaceSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          entry.term,
                          style: Theme.of(dialogContext).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        for (final cat in entry.strings('categories'))
                          AppStatusBadge(label: cat, tone: AppStatusTone.info),
                      ],
                    ),
                    Text(
                      entry.definition,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.menu_book_outlined, size: 15),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _openFullDefinition(context, entry);
                        },
                        label: const Text('View full definition'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  final displayQuery = result.normalizedQuery.isEmpty
      ? selectedText.trim()
      : result.normalizedQuery;
  return showAppGlassDialog<void>(
    context: context,
    builder: (dialogContext) => AppGlassDialog(
      key: const Key('dictionaryNoDefinitionDialog'),
      maxWidth: 420,
      title: Text(
        'No definition found',
        style: AppTokens.sectionTitleStyle(dialogContext),
      ),
      content: Text(
        displayQuery.isEmpty
            ? 'Select a word or phrase to look it up in the Equestrian '
                  'Dictionary.'
            : 'No published Dictionary entry was found for "$displayQuery".',
        style: Theme.of(dialogContext).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        if (displayQuery.isNotEmpty)
          FilledButton.tonalIcon(
            icon: const Icon(Icons.search, size: 16),
            onPressed: () {
              Navigator.pop(dialogContext);
              _openDictionarySearch(context, displayQuery);
            },
            label: const Text('Search Dictionary'),
          ),
      ],
    ),
  );
}

/// Renders [text] with:
/// 1. Subtle, accessible inline Dictionary highlights for recognized published
///    terms (tapping opens a compact definition dialog without leaving the
///    screen).
/// 2. Optional manual text selection with a "Define" action in the platform
///    selection toolbar alongside standard Copy / Select All actions.
class DictionaryText extends StatefulWidget {
  const DictionaryText({
    super.key,
    required this.text,
    required this.entries,
    this.style,
    this.enableSelection = true,
    this.maxMatches = 6,
  });

  final String text;
  final List<DictionaryEntry> entries;
  final TextStyle? style;
  final bool enableSelection;
  final int maxMatches;

  @override
  State<DictionaryText> createState() => _DictionaryTextState();
}

class _DictionaryTextState extends State<DictionaryText> {
  late List<DictionaryMatch> _matches;
  String _selectedText = '';

  @override
  void initState() {
    super.initState();
    _matches = matchDictionaryTerms(
      widget.text,
      widget.entries,
      maxMatches: widget.maxMatches,
    );
  }

  @override
  void didUpdateWidget(covariant DictionaryText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        !identical(oldWidget.entries, widget.entries) ||
        oldWidget.maxMatches != widget.maxMatches) {
      _matches = matchDictionaryTerms(
        widget.text,
        widget.entries,
        maxMatches: widget.maxMatches,
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_matches.isEmpty) {
      return Text(widget.text, style: widget.style);
    }
    final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final accent = AppTokens.accentColor(context);
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final match in _matches) {
      if (match.start > offset) {
        spans.add(TextSpan(text: widget.text.substring(offset, match.start)));
      }
      final matchedWord = widget.text.substring(match.start, match.end);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Semantics(
            button: true,
            label: '$matchedWord, open dictionary definition',
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                minimumSize: const Size(0, 22),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                foregroundColor: accent,
              ),
              onPressed: () =>
                  showDictionaryDefinitionDialog(context, match.entry),
              child: Text(
                matchedWord,
                style: effectiveStyle.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.solid,
                  decorationColor: accent,
                  decorationThickness: 1.2,
                ),
              ),
            ),
          ),
        ),
      );
      offset = match.end;
    }
    if (offset < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(offset)));
    }
    return Text.rich(TextSpan(style: effectiveStyle, children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (!widget.enableSelection) {
      return content;
    }
    return SelectionArea(
      onSelectionChanged: (SelectedContent? selection) {
        _selectedText = selection?.plainText ?? '';
      },
      contextMenuBuilder: (menuContext, selectableRegionState) {
        final buttonItems = List<ContextMenuButtonItem>.of(
          selectableRegionState.contextMenuButtonItems,
        );
        final selected = _selectedText.trim();
        if (selected.isNotEmpty) {
          buttonItems.insert(
            0,
            ContextMenuButtonItem(
              label: 'Define',
              onPressed: () {
                ContextMenuController.removeAny();
                selectableRegionState.clearSelection();
                showSelectedTermDefinition(
                  context,
                  selectedText: selected,
                  entries: widget.entries,
                );
              },
            ),
          );
        }
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: selectableRegionState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
      child: content,
    );
  }
}

/// Renders [text] with subtle inline Dictionary popovers and manual "Define"
/// text selection using the cached published glossary, falling back gracefully
/// while loading or when no unambiguous terms appear.
class ContextualDictionaryText extends StatefulWidget {
  const ContextualDictionaryText({
    super.key,
    required this.text,
    this.style,
    this.entriesOverride,
    this.enableSelection = true,
    this.maxMatches = 6,
  });

  final String text;
  final TextStyle? style;
  final List<DictionaryEntry>? entriesOverride;
  final bool enableSelection;
  final int maxMatches;

  @override
  State<ContextualDictionaryText> createState() =>
      _ContextualDictionaryTextState();
}

class _ContextualDictionaryTextState extends State<ContextualDictionaryText> {
  @override
  void initState() {
    super.initState();
    if (widget.entriesOverride == null) {
      unawaited(DictionaryRepository.cachedEntries());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entriesOverride case final overrideEntries?) {
      return DictionaryText(
        text: widget.text,
        entries: overrideEntries,
        style: widget.style,
        enableSelection: widget.enableSelection,
        maxMatches: widget.maxMatches,
      );
    }
    return ValueListenableBuilder<List<DictionaryEntry>?>(
      valueListenable: DictionaryRepository.entriesNotifier,
      builder: (context, entries, _) => DictionaryText(
        text: widget.text,
        entries: entries ?? const <DictionaryEntry>[],
        style: widget.style,
        enableSelection: widget.enableSelection,
        maxMatches: widget.maxMatches,
      ),
    );
  }
}
