// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Operation type for word-level text comparisons.
enum DiffOp { equal, delete, insert }

/// Contiguous run of unchanged, removed, or added text.
@immutable
class DiffSegment {
  const DiffSegment(this.op, this.text);

  final DiffOp op;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is DiffSegment && other.op == op && other.text == text;

  @override
  int get hashCode => Object.hash(op, text);

  @override
  String toString() => 'DiffSegment(${op.name}, "$text")';
}

final RegExp _wordTokenizer = RegExp(
  r"\s+|\p{L}[\p{L}\p{N}\u2019'-]*|\p{N}+|[^\s\p{L}\p{N}]",
  unicode: true,
);

List<String> _tokenize(String input) {
  if (input.isEmpty) return const [];
  return _wordTokenizer.allMatches(input).map((m) => m.group(0)!).toList();
}

List<DiffSegment> _coalesce(List<DiffSegment> raw) {
  if (raw.isEmpty) return const [];
  final merged = <DiffSegment>[];
  for (final seg in raw) {
    if (seg.text.isEmpty) continue;
    if (merged.isNotEmpty && merged.last.op == seg.op) {
      merged[merged.length - 1] = DiffSegment(
        seg.op,
        merged.last.text + seg.text,
      );
    } else {
      merged.add(seg);
    }
  }
  return merged;
}

/// Computes a deterministic word-and-whitespace diff between [oldText] and
/// [newText], highlighting exact word/sentence additions and removals while
/// keeping unchanged text intact.
List<DiffSegment> diffWords(String oldText, String newText) {
  if (oldText == newText) {
    return oldText.isEmpty
        ? const []
        : [DiffSegment(DiffOp.equal, oldText)];
  }
  if (oldText.isEmpty) return [DiffSegment(DiffOp.insert, newText)];
  if (newText.isEmpty) return [DiffSegment(DiffOp.delete, oldText)];

  final a = _tokenize(oldText);
  final b = _tokenize(newText);

  var prefix = 0;
  while (prefix < a.length && prefix < b.length && a[prefix] == b[prefix]) {
    prefix++;
  }

  var suffix = 0;
  while (suffix < (a.length - prefix) &&
      suffix < (b.length - prefix) &&
      a[a.length - 1 - suffix] == b[b.length - 1 - suffix]) {
    suffix++;
  }

  final out = <DiffSegment>[];
  if (prefix > 0) {
    out.add(DiffSegment(DiffOp.equal, a.sublist(0, prefix).join()));
  }

  final aMid = a.sublist(prefix, a.length - suffix);
  final bMid = b.sublist(prefix, b.length - suffix);

  if (aMid.isEmpty && bMid.isNotEmpty) {
    out.add(DiffSegment(DiffOp.insert, bMid.join()));
  } else if (bMid.isEmpty && aMid.isNotEmpty) {
    out.add(DiffSegment(DiffOp.delete, aMid.join()));
  } else if (aMid.isNotEmpty && bMid.isNotEmpty) {
    final m = aMid.length;
    final n = bMid.length;
    if (m * n > 250000) {
      // Safe fallback for unusually large text blocks.
      out
        ..add(DiffSegment(DiffOp.delete, aMid.join()))
        ..add(DiffSegment(DiffOp.insert, bMid.join()));
    } else {
      final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
      for (var i = m - 1; i >= 0; i--) {
        for (var j = n - 1; j >= 0; j--) {
          if (aMid[i] == bMid[j]) {
            dp[i][j] = dp[i + 1][j + 1] + 1;
          } else {
            final down = dp[i + 1][j];
            final right = dp[i][j + 1];
            dp[i][j] = down >= right ? down : right;
          }
        }
      }
      var i = 0;
      var j = 0;
      while (i < m && j < n) {
        if (aMid[i] == bMid[j]) {
          out.add(DiffSegment(DiffOp.equal, aMid[i]));
          i++;
          j++;
        } else if (dp[i + 1][j] >= dp[i][j + 1]) {
          out.add(DiffSegment(DiffOp.delete, aMid[i]));
          i++;
        } else {
          out.add(DiffSegment(DiffOp.insert, bMid[j]));
          j++;
        }
      }
      while (i < m) {
        out.add(DiffSegment(DiffOp.delete, aMid[i++]));
      }
      while (j < n) {
        out.add(DiffSegment(DiffOp.insert, bMid[j++]));
      }
    }
  }

  if (suffix > 0) {
    out.add(DiffSegment(DiffOp.equal, a.sublist(a.length - suffix).join()));
  }

  return _coalesce(out);
}

/// Human-friendly label for contribution types, using "Suggest an Improvement"
/// instead of "Correction" in user-facing surfaces.
String dictionaryContributionLabel(String? kind) {
  return switch (kind) {
    'missing_term' => 'Missing term',
    'definition' => 'Definition',
    'correction' || 'improvement' => 'Suggest an Improvement',
    'regional_usage' => 'Regional usage',
    'related_term' => 'Related terminology',
    null || '' => 'Suggestion',
    _ => kind.replaceAll('_', ' '),
  };
}

/// Metadata for a structured Dictionary field editable in community proposals.
class DictionaryFieldSpec {
  const DictionaryFieldSpec({
    required this.key,
    required this.label,
    required this.maxLength,
    this.isList = false,
    this.minLines = 1,
    this.maxLines = 4,
    this.requiredField = false,
  });

  final String key;
  final String label;
  final int maxLength;
  final bool isList;
  final int minLines;
  final int maxLines;
  final bool requiredField;
}

/// Structured fields supported for community editing and administrator review
/// on existing Dictionary entries.
@immutable
class DictionaryStructuredFields {
  const DictionaryStructuredFields({
    this.definition = '',
    this.explanation = '',
    this.usage = '',
    this.regionalUsage = '',
    this.examples = const [],
    this.synonyms = const [],
  });

  factory DictionaryStructuredFields.fromEntry(DictionaryEntry entry) {
    return DictionaryStructuredFields(
      definition: entry.definition.trim(),
      explanation: entry.explanation.trim(),
      usage: entry.text('usage').trim(),
      regionalUsage: entry.text('regionalUsage').trim(),
      examples: normalizeLines(entry.strings('examples')),
      synonyms: normalizeLines(entry.strings('synonyms')),
    );
  }

  factory DictionaryStructuredFields.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return const DictionaryStructuredFields();
    List<String> readList(String key) {
      final value = raw[key];
      if (value is List) {
        return normalizeLines(value.map((e) => e.toString()));
      }
      if (value is String) {
        return normalizeLines(value.split('\n'));
      }
      return const [];
    }

    return DictionaryStructuredFields(
      definition: (raw['definition'] as String? ?? '').trim(),
      explanation: (raw['explanation'] as String? ?? '').trim(),
      usage: (raw['usage'] as String? ?? '').trim(),
      regionalUsage: (raw['regionalUsage'] as String? ?? '').trim(),
      examples: readList('examples'),
      synonyms: readList('synonyms'),
    );
  }

  static const List<DictionaryFieldSpec> specs = [
    DictionaryFieldSpec(
      key: 'definition',
      label: 'Short definition',
      maxLength: 500,
      minLines: 2,
      requiredField: true,
    ),
    DictionaryFieldSpec(
      key: 'explanation',
      label: 'Detailed explanation',
      maxLength: 6000,
      minLines: 3,
      maxLines: 7,
    ),
    DictionaryFieldSpec(
      key: 'usage',
      label: 'Discipline & general usage',
      maxLength: 2000,
      minLines: 2,
    ),
    DictionaryFieldSpec(
      key: 'regionalUsage',
      label: 'Regional usage',
      maxLength: 2000,
      minLines: 2,
    ),
    DictionaryFieldSpec(
      key: 'examples',
      label: 'Examples',
      maxLength: 2000,
      isList: true,
      minLines: 2,
      maxLines: 6,
    ),
    DictionaryFieldSpec(
      key: 'synonyms',
      label: 'Synonyms / alternate names',
      maxLength: 1500,
      isList: true,
    ),
  ];

  final String definition;
  final String explanation;
  final String usage;
  final String regionalUsage;
  final List<String> examples;
  final List<String> synonyms;

  static List<String> normalizeLines(Iterable<String> items) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in items) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed)) {
        result.add(trimmed);
      }
    }
    return result;
  }

  String displayTextFor(String key) {
    return switch (key) {
      'definition' => definition,
      'explanation' => explanation,
      'usage' => usage,
      'regionalUsage' => regionalUsage,
      'examples' => examples.join('\n'),
      'synonyms' => synonyms.join('\n'),
      _ => '',
    };
  }

  dynamic rawValueFor(String key) {
    return switch (key) {
      'definition' => definition,
      'explanation' => explanation,
      'usage' => usage,
      'regionalUsage' => regionalUsage,
      'examples' => examples,
      'synonyms' => synonyms,
      _ => null,
    };
  }

  Map<String, dynamic> toMap() => {
    'definition': definition,
    'explanation': explanation,
    'usage': usage,
    'regionalUsage': regionalUsage,
    'examples': examples,
    'synonyms': synonyms,
  };

  /// Returns the ordered keys of fields that differ from [base].
  List<String> changedKeysAgainst(DictionaryStructuredFields base) {
    final changed = <String>[];
    if (definition != base.definition) changed.add('definition');
    if (explanation != base.explanation) changed.add('explanation');
    if (usage != base.usage) changed.add('usage');
    if (regionalUsage != base.regionalUsage) changed.add('regionalUsage');
    if (!listEquals(examples, base.examples)) changed.add('examples');
    if (!listEquals(synonyms, base.synonyms)) changed.add('synonyms');
    return changed;
  }

  bool equals(DictionaryStructuredFields other) =>
      changedKeysAgainst(other).isEmpty;

  static String labelForKey(String key) {
    for (final spec in specs) {
      if (spec.key == key) return spec.label;
    }
    return key;
  }

  /// Concise human-readable summary stored in `proposal` for backward
  /// compatibility with flat-text displays and audit logs.
  String summaryAgainst(DictionaryStructuredFields base, {String reason = ''}) {
    final changed = changedKeysAgainst(base);
    final labels = changed.map(labelForKey).join(', ');
    final trimmedReason = reason.trim();
    final prefix = changed.isEmpty
        ? 'Suggested improvement.'
        : 'Suggested improvement to $labels.';
    return trimmedReason.isEmpty ? prefix : '$prefix Reason: $trimmedReason';
  }

  /// Applies ONLY the fields modified relative to [base] onto
  /// [currentEntryData], leaving all unchanged fields untouched.
  Map<String, dynamic> applyChangedFieldsToEntry(
    Map<String, dynamic> currentEntryData, {
    required DictionaryStructuredFields base,
  }) {
    final merged = Map<String, dynamic>.from(currentEntryData);
    for (final key in changedKeysAgainst(base)) {
      merged[key] = rawValueFor(key);
    }
    return merged;
  }
}

/// Accessible legend explaining added, removed, and unchanged diff styling.
class DictionaryDiffLegend extends StatelessWidget {
  const DictionaryDiffLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addBg = isDark
        ? const Color(0xFF1B5E4A).withValues(alpha: 0.55)
        : const Color(0xFFD2F4E8);
    final addFg = isDark ? const Color(0xFF8FF5CC) : const Color(0xFF0A543C);
    final delBg = isDark
        ? const Color(0xFF6E252A).withValues(alpha: 0.55)
        : const Color(0xFFFCE0E2);
    final delFg = isDark ? const Color(0xFFFFB4B8) : const Color(0xFF8A1C22);

    Widget pill({
      required String label,
      required Color bg,
      required TextStyle style,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        child: Text(label, style: style),
      );
    }

    final baseSmall = Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 12);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        pill(
          label: '+ Added wording',
          bg: addBg,
          style: baseSmall.copyWith(
            color: addFg,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: addFg,
          ),
        ),
        pill(
          label: '− Removed wording',
          bg: delBg,
          style: baseSmall.copyWith(
            color: delFg,
            decoration: TextDecoration.lineThrough,
            decorationColor: delFg,
          ),
        ),
        Text(
          'Unchanged text shown normally',
          style: baseSmall.copyWith(
            color: AppTokens.secondaryTextColor(context),
          ),
        ),
      ],
    );
  }
}

/// Inline rich-text diff view highlighting additions, removals, and unchanged
/// text with both color and typographic cues (underline + bold vs strikethrough).
class DictionaryDiffRichText extends StatelessWidget {
  const DictionaryDiffRichText({
    super.key,
    required this.oldText,
    required this.newText,
  });

  final String oldText;
  final String newText;

  @override
  Widget build(BuildContext context) {
    final segments = diffWords(oldText, newText);
    if (segments.isEmpty) {
      return Text(
        '(Empty)',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: AppTokens.secondaryTextColor(context),
        ),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addBg = isDark
        ? const Color(0xFF1B5E4A).withValues(alpha: 0.55)
        : const Color(0xFFD2F4E8);
    final addFg = isDark ? const Color(0xFF8FF5CC) : const Color(0xFF0A543C);
    final delBg = isDark
        ? const Color(0xFF6E252A).withValues(alpha: 0.55)
        : const Color(0xFFFCE0E2);
    final delFg = isDark ? const Color(0xFFFFB4B8) : const Color(0xFF8A1C22);
    final baseStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    return Semantics(
      label: 'Comparison between original and proposed wording',
      child: SelectableText.rich(
        TextSpan(
          style: baseStyle,
          children: [
            for (final segment in segments)
              switch (segment.op) {
                DiffOp.equal => TextSpan(text: segment.text),
                DiffOp.insert => TextSpan(
                  text: segment.text,
                  style: baseStyle.copyWith(
                    backgroundColor: addBg,
                    color: addFg,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: addFg,
                  ),
                ),
                DiffOp.delete => TextSpan(
                  text: segment.text,
                  style: baseStyle.copyWith(
                    backgroundColor: delBg,
                    color: delFg,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: delFg,
                  ),
                ),
              },
          ],
        ),
      ),
    );
  }
}

/// Card displaying changes for a single structured field, supporting both
/// standard 2-way comparison (Original vs Proposed) and 3-way revision-mismatch
/// comparison (Old Base vs Current Published vs Proposed).
class DictionaryFieldDiffCard extends StatelessWidget {
  const DictionaryFieldDiffCard({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.oldText,
    required this.proposedText,
    this.currentPublishedText,
    this.baseRevision,
    this.currentRevision,
  });

  final String fieldKey;
  final String label;
  final String oldText;
  final String proposedText;
  final String? currentPublishedText;
  final int? baseRevision;
  final int? currentRevision;

  @override
  Widget build(BuildContext context) {
    final secondary = AppTokens.secondaryTextColor(context);
    final hasThreeWay =
        currentPublishedText != null &&
        (baseRevision != currentRevision || currentPublishedText != oldText);

    Widget labeledVersion(String heading, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            heading,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value.isEmpty ? '(Empty)' : value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      );
    }

    return Container(
      key: Key('dictionaryDiffCard_$fieldKey'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasThreeWay) ...[
            labeledVersion(
              baseRevision != null
                  ? 'Old wording (rev $baseRevision)'
                  : 'Old wording (contributor baseline)',
              oldText,
            ),
            labeledVersion(
              currentRevision != null
                  ? 'Current published wording (rev $currentRevision)'
                  : 'Current published wording',
              currentPublishedText!,
            ),
            labeledVersion('Proposed wording', proposedText),
            const Divider(height: 12),
            Text(
              'Inline changes against current published wording:',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            DictionaryDiffRichText(
              oldText: currentPublishedText!,
              newText: proposedText,
            ),
          ] else ...[
            DictionaryDiffRichText(
              oldText: oldText,
              newText: proposedText,
            ),
          ],
        ],
      ),
    );
  }
}
