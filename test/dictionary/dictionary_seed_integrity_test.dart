// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';

void main() {
  group('Published Dictionary seed cross-reference & matching integrity', () {
    late List<DictionaryEntry> seedEntries;
    late Set<String> seedIds;
    late Set<String> curriculumSkillIds;

    setUpAll(() {
      final raw =
          jsonDecode(File('functions/dictionary_seed.json').readAsStringSync())
              as List<dynamic>;
      seedEntries = raw
          .map((item) => DictionaryEntry((item as Map).cast<String, dynamic>()))
          .toList();
      seedIds = seedEntries.map((e) => e.id).toSet();

      const skillFiles = [
        'curriculum/v2/skills_rider_husbandry.json',
        'curriculum/v2/skills_rider_in_hand.json',
        'curriculum/v2/skills_rider_mounted.json',
        'curriculum/v2/skills_rider_theory.json',
        'curriculum/v2/skills_horse_in_hand.json',
        'curriculum/v2/skills_horse_mounted.json',
      ];
      curriculumSkillIds = <String>{};
      for (final path in skillFiles) {
        final skills =
            jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
        for (final skill in skills) {
          curriculumSkillIds.add((skill as Map)['id'] as String);
        }
      }
    });

    test(
      'every seed entry has unique id/slug, valid skillIds, and valid relatedTerms',
      () {
        expect(seedEntries, hasLength(28));
        expect(seedIds, hasLength(seedEntries.length));
        expect(
          seedEntries.map((e) => e.slug).toSet(),
          hasLength(seedEntries.length),
        );

        for (final entry in seedEntries) {
          expect(
            entry.published,
            isTrue,
            reason: '${entry.id} must be published',
          );
          expect(entry.term.trim(), isNotEmpty);
          expect(entry.definition.trim(), isNotEmpty);
          expect(entry.explanation.trim(), isNotEmpty);
          expect(entry.strings('categories'), isNotEmpty);
          expect(entry.strings('examples'), isNotEmpty);
          expect(
            entry.strings('skillIds'),
            isNotEmpty,
            reason: '${entry.id} should connect to at least one V2 skill',
          );
          for (final skillId in entry.strings('skillIds')) {
            expect(
              curriculumSkillIds.contains(skillId),
              isTrue,
              reason: '${entry.id} references unknown skillId $skillId',
            );
          }
          for (final relatedId in entry.strings('relatedTerms')) {
            expect(
              seedIds.contains(relatedId),
              isTrue,
              reason: '${entry.id} references unknown relatedTerm $relatedId',
            );
          }
        }
      },
    );

    test(
      'Batch 2 terms auto-highlight cleanly while ambiguous standalone words stay quiet',
      () {
        // Bare ambiguous words ('contact', 'posting', 'aids', 'cues', 'lead', 'diagonal', 'green', 'collection', 'poll') must NOT auto-highlight.
        final ambiguous = matchDictionaryTerms(
          'Please contact support about posting aids, cues, a green collection, '
          'a poll, a diagonal line, or a lead.',
          seedEntries,
        );
        expect(ambiguous, isEmpty);

        // Specific Batch 2 equestrian terms & synonyms DO auto-highlight.
        final hits = matchDictionaryTerms(
          'Check your cinch and TPR, then work on rhythm, rein contact, '
          'pressure and release, and self-carriage.',
          seedEntries,
        );
        expect(hits.map((m) => m.entry.id), [
          'girth-cinch',
          'vital-signs-tpr',
          'rhythm',
          'rein-contact',
          'negative-reinforcement',
          'self-carriage',
        ]);

        // Manual Define resolves both contextual and non-contextual terms/synonyms.
        for (final pair in [
          ('cinch', 'girth-cinch'),
          ('girth', 'girth-cinch'),
          ('lunging', 'longeing'),
          ('haunches', 'hindquarters'),
          ('R+', 'positive-reinforcement'),
          ('R-', 'negative-reinforcement'),
          ('elastic contact', 'rein-contact'),
          ('safety knot', 'quick-release-knot'),
          ('aids', 'aids'),
          ('cues', 'aids'),
          ('green', 'green'),
        ]) {
          expect(
            lookupSelectedDictionaryTerm(pair.$1, seedEntries).exactMatch?.id,
            pair.$2,
            reason:
                'Manual lookup of "${pair.$1}" should resolve to ${pair.$2}',
          );
        }
      },
    );
  });
}
