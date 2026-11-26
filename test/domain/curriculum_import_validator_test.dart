// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_export_dialog.dart';

Map<String, dynamic> _basePayload() => {
  'schemaVersion': 2,
  'families': [
    {
      'id': 'rider.mounted.balance',
      'schemaVersion': 2,
      'subject': 'rider',
      'realm': 'Mounted',
      'name': 'Mounted Balance',
      'description': 'Core rider balance.',
      'sortOrder': 10,
    },
    {
      'id': 'horse.mounted.gaits',
      'schemaVersion': 2,
      'subject': 'horse',
      'realm': 'Mounted',
      'name': 'Mounted Gaits',
      'description': 'Horse gait quality under saddle.',
      'sortOrder': 10,
    },
  ],
  'skills': [
    {
      'id': 'rider.mounted.trot',
      'schemaVersion': 2,
      'status': 'active',
      'subject': 'rider',
      'realm': 'Mounted',
      'familyId': 'rider.mounted.balance',
      'name': 'Trot / Jog',
      'aliases': ['Rising Trot'],
      'summary': 'Maintaining balance in a two-beat diagonal trot.',
      'purpose': 'Builds rhythmic posting and sitting stability.',
      'safety': <String>['Maintain safe spacing.'],
      'availableLevels': <String>['introductory', 'intermediate'],
      'levels': {
        'introductory': {
          'overview': 'Intro overview',
          'components': <Map<String, dynamic>>[
            {'title': 'Two-beat rhythm', 'description': 'Follows diagonal.'},
          ],
          'learning': 'Learning text',
          'proficient': 'Proficient v1',
          'standardVersion': 1,
          'standardUpdatedAt': '2026-11-20T10:00:00.000Z',
        },
        'intermediate': {
          'overview': 'Int overview',
          'components': <Map<String, dynamic>>[],
          'learning': 'Int learning',
          'proficient': 'Int proficient v1',
          'standardVersion': 1,
        },
      },
      'relatedSkills': [
        {'skillId': 'horse.mounted.trot', 'relation': 'counterpart'},
      ],
      'legacyIds': <String>['legacy_trot'],
      'sortOrder': 10,
    },
    {
      'id': 'horse.mounted.trot',
      'schemaVersion': 2,
      'status': 'active',
      'subject': 'horse',
      'realm': 'Mounted',
      'familyId': 'horse.mounted.gaits',
      'name': 'Trot / Jog',
      'aliases': <String>[],
      'summary': 'Symmetrical two-beat diagonal gait.',
      'purpose': 'Develops steady rhythm under saddle.',
      'safety': <String>[],
      'availableLevels': <String>['introductory'],
      'levels': {
        'introductory': {
          'overview': 'Horse intro',
          'components': <Map<String, dynamic>>[],
          'learning': 'Horse learning',
          'proficient': 'Horse proficient v1',
          'standardVersion': 1,
        },
      },
      'relatedSkills': [
        {'skillId': 'rider.mounted.trot', 'relation': 'counterpart'},
      ],
      'legacyIds': <String>['legacy_horse_trot'],
      'sortOrder': 10,
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Curriculum import validator', () {
    test(
      'accepts canonical export JSON and bundled curriculum assets without losing metadata',
      () async {
        const loader = AssetCurriculumV2Loader();
        final families = await loader.loadFamilies();
        final skills = await loader.loadSkills();
        final exportJson = buildCanonicalCurriculumExportJson(
          families: families,
          skills: skills,
        );

        final result = parseAndValidateCurriculumImportJson(exportJson);
        expect(result.isValid, isTrue, reason: result.errors.join('\n'));
        expect(result.families!.length, families.length);
        expect(result.skills!.length, skills.length);
        expect(result.totalLevels, greaterThan(0));

        // Ensure canonical IDs and legacyIds are preserved verbatim.
        final origTrot = skills.firstWhere((s) => s.id == 'rider.mounted.trot');
        final importedTrot = result.skills!.firstWhere(
          (s) => s.id == 'rider.mounted.trot',
        );
        expect(importedTrot.legacyIds, origTrot.legacyIds);
        expect(
          importedTrot.levels[DifficultyState.Introductory]?.standardVersion,
          origTrot.levels[DifficultyState.Introductory]?.standardVersion,
        );
      },
    );

    test('preserves timestamps and optional metadata on valid payload', () {
      final raw = jsonEncode(_basePayload());
      final result = parseAndValidateCurriculumImportJson(raw);

      expect(result.isValid, isTrue, reason: result.errors.join('\n'));
      final skill = result.skills!.first;
      expect(
        skill.levels[DifficultyState.Introductory]?.standardUpdatedAt,
        DateTime.utc(2026, 11, 20, 10),
      );
      expect(skill.legacyIds, ['legacy_trot']);
      expect(skill.relatedSkills.single.skillId, 'horse.mounted.trot');
    });

    test(
      'rejects empty, malformed JSON, non-object root, and wrong schema',
      () {
        expect(parseAndValidateCurriculumImportJson('  ').isValid, isFalse);
        final badJson = parseAndValidateCurriculumImportJson('{bad json');
        expect(badJson.isValid, isFalse);
        expect(badJson.errors.single, contains('Malformed JSON'));

        final listRoot = parseAndValidateCurriculumImportJson('[]');
        expect(listRoot.isValid, isFalse);
        expect(listRoot.errors.single, contains('must be a JSON object'));

        final badSchema = _basePayload()..['schemaVersion'] = 1;
        final schemaResult = parseAndValidateCurriculumImportJson(
          jsonEncode(badSchema),
        );
        expect(schemaResult.isValid, isFalse);
        expect(
          schemaResult.errors,
          contains('Root schemaVersion must equal 2.'),
        );
      },
    );

    test('rejects duplicate family IDs, skill IDs, and legacy IDs', () {
      final payload = _basePayload();
      (payload['families'] as List).add((payload['families'] as List).first);
      (payload['skills'] as List).add((payload['skills'] as List).first);

      final result = parseAndValidateCurriculumImportJson(jsonEncode(payload));
      expect(result.isValid, isFalse);
      expect(
        result.errors,
        containsAll([
          'Duplicate family ID: rider.mounted.balance.',
          'Duplicate skill ID: rider.mounted.trot.',
        ]),
      );

      final dupLegacyPayload = _basePayload();
      ((dupLegacyPayload['skills'] as List)[1] as Map)['legacyIds'] = [
        'legacy_trot',
      ];
      final dupLegacyResult = parseAndValidateCurriculumImportJson(
        jsonEncode(dupLegacyPayload),
      );
      expect(dupLegacyResult.isValid, isFalse);
      expect(
        dupLegacyResult.errors.any(
          (e) => e.contains('Legacy ID "legacy_trot"'),
        ),
        isTrue,
      );
    });

    test(
      'rejects missing relationships, asymmetric counterparts, and cycles',
      () {
        final missingRef = _basePayload();
        ((missingRef['skills'] as List)[0] as Map)['familyId'] =
            'missing.family';
        ((missingRef['skills'] as List)[0] as Map)['relatedSkills'] = [
          {'skillId': 'does.not.exist', 'relation': 'foundation'},
        ];
        final missingRes = parseAndValidateCurriculumImportJson(
          jsonEncode(missingRef),
        );
        expect(missingRes.isValid, isFalse);
        expect(
          missingRes.errors,
          containsAll([
            'Skill rider.mounted.trot: unknown familyId "missing.family".',
            'Skill rider.mounted.trot: relatedSkill "does.not.exist" not found.',
          ]),
        );

        final cyclePayload = _basePayload();
        ((cyclePayload['skills'] as List)[0] as Map)['relatedSkills'] = [
          {'skillId': 'horse.mounted.trot', 'relation': 'foundation'},
        ];
        ((cyclePayload['skills'] as List)[1] as Map)['relatedSkills'] = [
          {'skillId': 'rider.mounted.trot', 'relation': 'foundation'},
        ];
        final cycleRes = parseAndValidateCurriculumImportJson(
          jsonEncode(cyclePayload),
        );
        expect(cycleRes.isValid, isFalse);
        expect(
          cycleRes.errors.any(
            (e) => e.contains('Cycle detected in foundation'),
          ),
          isTrue,
        );
      },
    );

    test('enforces published standardVersion increment, ID retention, and '
        'legacy preservation', () {
      final publishedParsed = parseAndValidateCurriculumImportJson(
        jsonEncode(_basePayload()),
      );
      final publishedFamilies = publishedParsed.families!;
      final publishedSkills = publishedParsed.skills!;

      // 1. Editing proficient without incrementing standardVersion -> error.
      final unbumped = _basePayload();
      final unbumpedLevels =
          ((unbumped['skills'] as List)[0] as Map<String, dynamic>)['levels']
              as Map<String, dynamic>;
      final unbumpedIntro =
          unbumpedLevels['introductory'] as Map<String, dynamic>;
      unbumpedIntro['proficient'] = 'Changed proficient text';
      final unbumpedRes = parseAndValidateCurriculumImportJson(
        jsonEncode(unbumped),
        publishedFamilies: publishedFamilies,
        publishedSkills: publishedSkills,
      );
      expect(unbumpedRes.isValid, isFalse);
      expect(
        unbumpedRes.errors.any(
          (e) => e.contains('increment standardVersion above v1'),
        ),
        isTrue,
      );

      // 2. Incrementing standardVersion -> valid.
      final bumped = _basePayload();
      final bumpedLevels =
          ((bumped['skills'] as List)[0] as Map<String, dynamic>)['levels']
              as Map<String, dynamic>;
      final introMap = bumpedLevels['introductory'] as Map<String, dynamic>;
      introMap['proficient'] = 'Changed proficient text';
      introMap['standardVersion'] = 2;
      final bumpedRes = parseAndValidateCurriculumImportJson(
        jsonEncode(bumped),
        publishedFamilies: publishedFamilies,
        publishedSkills: publishedSkills,
      );
      expect(bumpedRes.isValid, isTrue, reason: bumpedRes.errors.join('\n'));

      // 3. Removing a published skill -> blocked unless retired.
      final deleted = _basePayload();
      (deleted['skills'] as List).removeAt(0);
      final deletedRes = parseAndValidateCurriculumImportJson(
        jsonEncode(deleted),
        publishedFamilies: publishedFamilies,
        publishedSkills: publishedSkills,
      );
      expect(deletedRes.isValid, isFalse);
      expect(
        deletedRes.errors.any(
          (e) => e.contains('cannot be deleted; set status to "retired"'),
        ),
        isTrue,
      );
    });
  });
}
