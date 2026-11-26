import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';

/// A single matched span of a published Dictionary term within text.
class DictionaryMatch {
  const DictionaryMatch(this.start, this.end, this.entry);

  final int start;
  final int end;
  final DictionaryEntry entry;
}

/// Result of a manual user lookup for selected text against published
/// Dictionary entries.
class DictionaryLookupResult {
  const DictionaryLookupResult({
    required this.normalizedQuery,
    this.exactMatch,
    this.ambiguousMatches = const [],
  });

  final String normalizedQuery;
  final DictionaryEntry? exactMatch;
  final List<DictionaryEntry> ambiguousMatches;

  bool get hasMatch => exactMatch != null || ambiguousMatches.isNotEmpty;
}

class _CompiledDictionaryIndex {
  _CompiledDictionaryIndex(List<DictionaryEntry> entries) {
    final published = entries.where((entry) => entry.published).toList();
    final meaningsByName = <String, Set<String>>{};

    for (final entry in published) {
      for (final rawKey in {
        entry.id,
        entry.slug,
        entry.term,
        ...entry.strings('synonyms'),
      }) {
        final key = rawKey.trim().toLowerCase();
        if (key.isEmpty) continue;
        _addLookup(key, entry);
        if (_hasInternalHyphen(key)) {
          final spaceKey = _normalizeHyphens(key);
          if (spaceKey != key) {
            _addLookup(spaceKey, entry);
          }
        }
      }
      for (final name in {entry.term, ...entry.strings('synonyms')}) {
        final normalized = name.trim().toLowerCase();
        if (normalized.isEmpty) continue;
        meaningsByName.putIfAbsent(normalized, () => <String>{}).add(entry.id);
      }
    }

    for (final entry in published.where((entry) => entry.contextual)) {
      for (final name in {entry.term, ...entry.strings('synonyms')}) {
        final trimmed = name.trim();
        if (trimmed.isEmpty) continue;
        final lower = trimmed.toLowerCase();
        if ((meaningsByName[lower]?.length ?? 0) > 1) {
          continue;
        }
        contextualPatterns.add((
          RegExp(
            r'(?<![\p{L}\p{N}_])' +
                RegExp.escape(trimmed) +
                r'(?![\p{L}\p{N}_])',
            caseSensitive: false,
            unicode: true,
          ),
          entry,
        ));
      }
    }
  }

  final List<(RegExp, DictionaryEntry)> contextualPatterns = [];
  final Map<String, List<DictionaryEntry>> lookupByKey = {};

  void _addLookup(String key, DictionaryEntry entry) {
    final list = lookupByKey.putIfAbsent(key, () => <DictionaryEntry>[]);
    if (!list.any((existing) => existing.id == entry.id)) {
      list.add(entry);
    }
  }
}

final Expando<_CompiledDictionaryIndex> _indexCache =
    Expando<_CompiledDictionaryIndex>('dictionaryIndex');

_CompiledDictionaryIndex _indexFor(List<DictionaryEntry> entries) {
  var cached = _indexCache[entries];
  if (cached == null) {
    cached = _CompiledDictionaryIndex(entries);
    _indexCache[entries] = cached;
  }
  return cached;
}

bool _hasInternalHyphen(String input) =>
    RegExp(r'[\p{L}\p{N}][-–—]+[\p{L}\p{N}]', unicode: true).hasMatch(input);

String _normalizeHyphens(String input) => input
    .replaceAll(RegExp('[-–—]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Strips surrounding punctuation and collapses internal whitespace from a
/// user's manual text selection.
String normalizeSelectedDictionaryText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final stripped = trimmed.replaceAll(
    RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true),
    '',
  );
  return stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Finds non-overlapping contextual matches in [text] for published,
/// contextually enabled Dictionary entries.
///
/// Prioritizes longer multiword expressions over shorter matches, honors
/// Unicode whole-word boundaries, is case-insensitive, skips ambiguous terms
/// shared across multiple published meanings, and highlights each meaning at
/// most once up to [maxMatches].
List<DictionaryMatch> matchDictionaryTerms(
  String text,
  List<DictionaryEntry> entries, {
  int maxMatches = 6,
}) {
  if (text.isEmpty || entries.isEmpty || maxMatches <= 0) return const [];
  final index = _indexFor(entries);
  if (index.contextualPatterns.isEmpty) return const [];

  final candidates = <DictionaryMatch>[];
  for (final (pattern, entry) in index.contextualPatterns) {
    for (final match in pattern.allMatches(text)) {
      candidates.add(DictionaryMatch(match.start, match.end, entry));
    }
  }
  if (candidates.isEmpty) return const [];

  candidates.sort((a, b) {
    final length = (b.end - b.start).compareTo(a.end - a.start);
    return length == 0 ? a.start.compareTo(b.start) : length;
  });

  final selected = <DictionaryMatch>[];
  final ids = <String>{};
  for (final match in candidates) {
    if (selected.length >= maxMatches) break;
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

/// Looks up manually selected text against all published Dictionary entries
/// (including entries with `contextual: false`), matching terms, approved
/// synonyms, IDs, slugs, and hyphen/space variants.
///
/// Never matches unpublished/draft entries and performs no network or AI calls.
DictionaryLookupResult lookupSelectedDictionaryTerm(
  String selectedText,
  List<DictionaryEntry> entries,
) {
  final trimmed = selectedText.trim();
  final normalized = normalizeSelectedDictionaryText(selectedText);
  if (trimmed.isEmpty || entries.isEmpty) {
    return DictionaryLookupResult(normalizedQuery: normalized);
  }

  final index = _indexFor(entries);
  final rawLower = trimmed.toLowerCase();
  final normalizedLower = normalized.toLowerCase();
  final matches =
      index.lookupByKey[rawLower] ??
      (normalizedLower.isEmpty ? null : index.lookupByKey[normalizedLower]) ??
      (_hasInternalHyphen(normalizedLower)
          ? index.lookupByKey[_normalizeHyphens(normalizedLower)]
          : null) ??
      const <DictionaryEntry>[];

  final displayQuery = index.lookupByKey.containsKey(rawLower)
      ? trimmed
      : normalized;

  if (matches.length == 1) {
    return DictionaryLookupResult(
      normalizedQuery: displayQuery,
      exactMatch: matches.single,
    );
  }
  if (matches.length > 1) {
    return DictionaryLookupResult(
      normalizedQuery: displayQuery,
      ambiguousMatches: List<DictionaryEntry>.unmodifiable(matches),
    );
  }
  return DictionaryLookupResult(normalizedQuery: normalized);
}
