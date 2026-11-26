// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';

void main() {
  group('Batch 1 Dictionary draft entries validation', () {
    late List<DictionaryEntry> draftEntries;
    late Set<String> curriculumSkillIds;

    setUpAll(() {
      final raw =
          jsonDecode(
                File(
                  'curriculum/dictionary/batch_01_drafts.json',
                ).readAsStringSync(),
              )
              as List<dynamic>;
      draftEntries = raw
          .map((item) => DictionaryEntry((item as Map).cast<String, dynamic>()))
          .toList();

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

    test('contains 5 valid draft-only entries with valid Skill Tree IDs', () {
      expect(draftEntries, hasLength(5));
      expect(draftEntries.map((e) => e.id), [
        'trot',
        'posting-trot',
        'trot-diagonal',
        'canter-lead',
        'aids',
      ]);

      for (final entry in draftEntries) {
        // Must remain unpublished drafts until explicitly approved & published.
        expect(entry.published, isFalse, reason: '${entry.id} must be draft');
        expect(entry.slug, isNotEmpty);
        expect(entry.term, isNotEmpty);
        expect(entry.definition, isNotEmpty);
        expect(entry.explanation, isNotEmpty);
        expect(entry.strings('categories'), isNotEmpty);
        expect(entry.strings('examples'), isNotEmpty);
        for (final skillId in entry.strings('skillIds')) {
          expect(
            curriculumSkillIds.contains(skillId),
            isTrue,
            reason: '${entry.id} references unknown skillId $skillId',
          );
        }
      }

      // Drafts are never matched or returned before publication.
      expect(
        matchDictionaryTerms(
          'Practice posting trot on the correct trot diagonal and canter lead.',
          draftEntries,
        ),
        isEmpty,
      );
      expect(
        lookupSelectedDictionaryTerm('jog', draftEntries).hasMatch,
        isFalse,
      );
    });

    test(
      'when simulated as published, highlights unambiguous terms while preventing standalone posting, aids, cues, diagonal, and lead auto-highlights',
      () {
        final simulatedPublished = draftEntries
            .map((e) => DictionaryEntry({...e.data, 'status': 'published'}))
            .toList();

        // Ambiguous standalone words must NOT auto-highlight.
        final ambiguousMatches = matchDictionaryTerms(
          'Posting a comment about aids, cues, a diagonal line, or a lead rope.',
          simulatedPublished,
        );
        expect(ambiguousMatches, isEmpty);

        // Specific equestrian phrases & synonyms DO auto-highlight.
        final validMatches = matchDictionaryTerms(
          'Warm up in rising trot on the posting diagonal, then sit a quiet '
          'jog before asking for the left lope lead.',
          simulatedPublished,
        );
        expect(validMatches.map((m) => m.entry.id), [
          'posting-trot',
          'trot-diagonal',
          'trot',
          'canter-lead',
        ]);

        // Manual Define still resolves aids, cues, natural aids, artificial aids,
        // jog, rising trot, posting diagonal, and lope lead cleanly.
        for (final pair in [
          ('aids', 'aids'),
          ('cues', 'aids'),
          ('natural aids', 'aids'),
          ('artificial aids', 'aids'),
          ('jog', 'trot'),
          ('rising trot', 'posting-trot'),
          ('posting diagonal', 'trot-diagonal'),
          ('lope lead', 'canter-lead'),
        ]) {
          final result = lookupSelectedDictionaryTerm(
            pair.$1,
            simulatedPublished,
          );
          expect(
            result.exactMatch?.id,
            pair.$2,
            reason:
                'Manual lookup of "${pair.$1}" should resolve to ${pair.$2}',
          );
        }
      },
    );

    test(
      'trot definition does not require suspension and trot-diagonal describes opposite-side leg pairs accurately',
      () {
        final trot = draftEntries.firstWhere((e) => e.id == 'trot');
        expect(trot.definition.toLowerCase(), contains('two-beat diagonal'));
        expect(trot.definition.toLowerCase(), isNot(contains('suspension')));

        final diagonal = draftEntries.firstWhere(
          (e) => e.id == 'trot-diagonal',
        );
        expect(
          diagonal.explanation.toLowerCase(),
          contains('outside foreleg and inside hind leg'),
        );
      },
    );
  });

  test(
    'Skill Tree Rider Trot & Canter contain demonstrable 3-level criteria',
    () {
      final raw =
          jsonDecode(
                File(
                  'curriculum/v2/skills_rider_mounted.json',
                ).readAsStringSync(),
              )
              as List<dynamic>;
      final skills = {
        for (final item in raw)
          (item as Map)['id'] as String: CurriculumSkill.fromMap(
            Map<String, dynamic>.from(item),
          ),
      };

      final trot = skills['rider.mounted.trot']!;
      expect(
        trot
            .levelDefinition(DifficultyState.Introductory)!
            .proficient
            .toLowerCase(),
        contains('regardless of diagonal'),
      );
      expect(
        trot
            .levelDefinition(DifficultyState.Intermediate)!
            .proficient
            .toLowerCase(),
        contains('changes posting diagonals'),
      );
      expect(
        trot
            .levelDefinition(DifficultyState.Advanced)!
            .proficient
            .toLowerCase(),
        contains('sitting trot'),
      );

      final canter = skills['rider.mounted.canter']!;
      expect(
        canter
            .levelDefinition(DifficultyState.Introductory)!
            .proficient
            .toLowerCase(),
        contains('correct lead selection is not required'),
      );
      expect(
        canter
            .levelDefinition(DifficultyState.Intermediate)!
            .proficient
            .toLowerCase(),
        contains('simple lead changes'),
      );
      final advCanter = canter
          .levelDefinition(DifficultyState.Advanced)!
          .proficient
          .toLowerCase();
      expect(advCanter, contains('counter-canter'));
      expect(advCanter, contains('flying lead changes'));
    },
  );
}
