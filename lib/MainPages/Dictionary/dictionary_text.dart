import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class DictionaryMatch {
  const DictionaryMatch(this.start, this.end, this.entry);
  final int start;
  final int end;
  final DictionaryEntry entry;
}

/// Longest phrases, Unicode word boundaries, once per meaning.
List<DictionaryMatch> matchDictionaryTerms(
  String text,
  List<DictionaryEntry> entries,
) {
  if (text.isEmpty || entries.isEmpty) return const [];
  final candidates = <DictionaryMatch>[];
  final meaningsByName = <String, Set<String>>{};
  for (final entry in entries.where((entry) => entry.published)) {
    for (final name in {entry.term, ...entry.strings('synonyms')}) {
      meaningsByName.putIfAbsent(name.toLowerCase(), () => {}).add(entry.id);
    }
  }
  for (final entry in entries.where(
    (entry) => entry.published && entry.contextual,
  )) {
    for (final name in {entry.term, ...entry.strings('synonyms')}) {
      if (name.trim().isEmpty ||
          meaningsByName[name.toLowerCase()]!.length > 1) {
        continue;
      }
      final pattern = RegExp(
        r'(?<![\p{L}\p{N}_])' + RegExp.escape(name) + r'(?![\p{L}\p{N}_])',
        caseSensitive: false,
        unicode: true,
      );
      for (final match in pattern.allMatches(text)) {
        candidates.add(DictionaryMatch(match.start, match.end, entry));
      }
    }
  }
  candidates.sort((a, b) {
    final length = (b.end - b.start).compareTo(a.end - a.start);
    return length == 0 ? a.start.compareTo(b.start) : length;
  });
  final selected = <DictionaryMatch>[];
  final ids = <String>{};
  for (final match in candidates) {
    if (selected.length >= 6) break;
    if (ids.contains(match.entry.id) ||
        selected.any(
          (item) => match.start < item.end && match.end > item.start,
        )) {
      continue;
    }
    selected.add(match);
    ids.add(match.entry.id);
  }
  return selected..sort((a, b) => a.start.compareTo(b.start));
}

void _openFullDefinition(BuildContext context, DictionaryEntry entry) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.push('/Dictionary/${entry.slug}');
    return;
  }
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => DictionaryPage(slug: entry.slug),
    ),
  );
}

Future<void> _showDefinitionPopover(
  BuildContext context,
  DictionaryEntry entry,
) {
  final synonyms = entry.strings('synonyms');
  final categories = entry.strings('categories');
  return showAppGlassDialog<void>(
    context: context,
    builder: (dialogContext) => AppGlassDialog(
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
          label: const Text('Full definition'),
        ),
      ],
    ),
  );
}

/// Inline buttons preserve page position while an accessible definition opens.
class DictionaryText extends StatelessWidget {
  const DictionaryText({
    super.key,
    required this.text,
    required this.entries,
    this.style,
  });

  final String text;
  final List<DictionaryEntry> entries;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final matches = matchDictionaryTerms(text, entries);
    if (matches.isEmpty) {
      return Text(text, style: style);
    }
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final accent = AppTokens.accentColor(context);
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final match in matches) {
      if (match.start > offset) {
        spans.add(TextSpan(text: text.substring(offset, match.start)));
      }
      final matchedWord = text.substring(match.start, match.end);
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
                foregroundColor: AppTokens.primaryTextColor(context),
              ),
              onPressed: () => _showDefinitionPopover(context, match.entry),
              child: Text(
                matchedWord,
                style: effectiveStyle.copyWith(
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: accent,
                  decorationThickness: 1.6,
                ),
              ),
            ),
          ),
        ),
      );
      offset = match.end;
    }
    if (offset < text.length) {
      spans.add(TextSpan(text: text.substring(offset)));
    }
    return Text.rich(TextSpan(style: effectiveStyle, children: spans));
  }
}

/// Renders [text] with subtle inline Dictionary popovers using the cached
/// published glossary, falling back to plain [Text] while loading or when no
/// unambiguous terms appear.
class ContextualDictionaryText extends StatefulWidget {
  const ContextualDictionaryText({
    super.key,
    required this.text,
    this.style,
    this.entriesOverride,
  });

  final String text;
  final TextStyle? style;
  final List<DictionaryEntry>? entriesOverride;

  @override
  State<ContextualDictionaryText> createState() =>
      _ContextualDictionaryTextState();
}

class _ContextualDictionaryTextState extends State<ContextualDictionaryText> {
  late final Future<List<DictionaryEntry>> _entriesFuture =
      widget.entriesOverride != null
      ? Future.value(widget.entriesOverride!)
      : DictionaryRepository.cachedEntries();

  @override
  Widget build(BuildContext context) {
    final immediate =
        widget.entriesOverride ?? DictionaryRepository.peekCachedEntries;
    if (immediate != null) {
      return DictionaryText(
        text: widget.text,
        entries: immediate,
        style: widget.style,
      );
    }
    return FutureBuilder<List<DictionaryEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        if (entries == null || entries.isEmpty) {
          return Text(widget.text, style: widget.style);
        }
        return DictionaryText(
          text: widget.text,
          entries: entries,
          style: widget.style,
        );
      },
    );
  }
}
