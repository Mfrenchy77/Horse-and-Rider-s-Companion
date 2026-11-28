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
        expect(seedEntries, hasLength(84));
        expect(seedIds, hasLength(seedEntries.length));
        expect(
          seedEntries.map((e) => e.slug).toSet(),
          hasLength(seedEntries.length),
        );

        final nameOwners = <String, Set<String>>{};
        for (final entry in seedEntries) {
          for (final rawName in [entry.term, ...entry.strings('synonyms')]) {
            final key = rawName.trim().toLowerCase();
            if (key.isEmpty) continue;
            nameOwners.putIfAbsent(key, () => <String>{}).add(entry.id);
          }
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

        final collisions = nameOwners.entries
            .where((e) => e.value.length > 1)
            .toList();
        expect(
          collisions,
          isEmpty,
          reason: 'Terms and synonyms must not collide across meanings',
        );

        final nonContextualIds = seedEntries
            .where((e) => !e.contextual)
            .map((e) => e.id)
            .toSet();
        expect(nonContextualIds, {
          'green',
          'collection',
          'poll',
          'aids',
          'bend',
          'flexion',
          'choke',
          'flooding',
          'engagement',
        });

        final leakedPattern = RegExp(
          'contextual=|manual Define|Welfare and safety note:|'
          'Clinical and welfare caution:|Welfare caution:|curriculum/v2',
          caseSensitive: false,
        );
        for (final entry in seedEntries) {
          final combinedText = [
            entry.definition,
            entry.explanation,
            entry.text('usage'),
            entry.text('regionalUsage'),
            ...entry.strings('examples'),
          ].join(' ');
          expect(
            leakedPattern.hasMatch(combinedText),
            isFalse,
            reason:
                '${entry.id} must not expose internal audit/technical strings',
          );
          expect(
            entry.definition.length,
            lessThanOrEqualTo(500),
            reason: '${entry.id} definition must stay concise',
          );
          for (final ex in entry.strings('examples')) {
            expect(
              ex.length,
              lessThanOrEqualTo(240),
              reason: '${entry.id} examples must fit validation limit',
            );
          }
        }
      },
    );

    test(
      'Batch 2 and Wave 3 terms auto-highlight cleanly while ambiguous standalone words stay quiet',
      () {
        // Bare/ambiguous terms must NOT auto-highlight in ordinary language.
        final ambiguous = matchDictionaryTerms(
          'Please contact support about posting aids, cues, a green collection, '
          'a poll, a diagonal line, backing up, a founder, a simple change, '
          'a transition, a lunge, bend, knee flexion, choke, flooding, '
          'engagement, or a lead.',
          seedEntries,
        );
        expect(ambiguous, isEmpty);

        // Specific Batch 2 equestrian terms & synonyms DO auto-highlight.
        final hits = matchDictionaryTerms(
          'Check your cinch and TPR, then work on rhythm, rein contact, '
          'pressure-and-release, and self-carriage.',
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

        // Wave 3 Priority A/B/C terms + upgraded hyphen/plural variants highlight cleanly.
        final wave3Hits = matchDictionaryTerms(
          'Develop an independent seat and two-point position before learning '
          'rein back, avoiding learned helplessness, checking for colic and '
          'laminitis, and respecting half-halts and ground-tying.',
          seedEntries,
          maxMatches: 12,
        );
        expect(
          wave3Hits.map((m) => m.entry.id),
          containsAll([
            'independent-seat',
            'two-point-position',
            'rein-back',
            'learned-helplessness',
            'colic',
            'laminitis',
            'half-halt',
            'ground-tie',
          ]),
        );

        // Known Terms suppresses selected Wave 3 IDs immediately.
        final suppressed = matchDictionaryTerms(
          'Build an independent seat and avoid learned helplessness.',
          seedEntries,
          knownTermIds: const {'independent-seat', 'learned-helplessness'},
        );
        expect(suppressed, isEmpty);

        // Manual Define resolves both contextual and non-contextual terms/synonyms.
        for (final pair in [
          ('cinch', 'girth-cinch'),
          ('girthiness', 'girth-cinch'),
          ('lunging', 'longeing'),
          ('haunches', 'hindquarters'),
          ('R+', 'positive-reinforcement'),
          ('R-', 'negative-reinforcement'),
          ('pressure-and-release', 'negative-reinforcement'),
          ('elastic contact', 'rein-contact'),
          ('safety knot', 'quick-release-knot'),
          ('aids', 'aids'),
          ('cues', 'aids'),
          ('green', 'green'),
          ('bend', 'bend'),
          ('flexion', 'flexion'),
          ('choke', 'choke'),
          ('flooding', 'flooding'),
          ('engagement', 'engagement'),
          ('proprioception', 'proprioception'),
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
