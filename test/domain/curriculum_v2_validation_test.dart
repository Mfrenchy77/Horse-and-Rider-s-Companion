// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Skill Tree 2.0 curriculum JSON validation', () {
    late List<SkillFamily> families;
    late Map<String, SkillFamily> familyById;
    late List<CurriculumSkill> skills;
    late Map<String, CurriculumSkill> skillById;
    late List<Map<String, dynamic>> legacySnapshot;
    late List<Map<String, dynamic>> legacyMapping;

    setUpAll(() {
      final famJson =
          jsonDecode(File('curriculum/v2/families.json').readAsStringSync())
              as List<dynamic>;
      families = famJson
          .map((e) => SkillFamily.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      familyById = {for (final f in families) f.id: f};

      const skillFiles = [
        'curriculum/v2/skills_rider_husbandry.json',
        'curriculum/v2/skills_rider_in_hand.json',
        'curriculum/v2/skills_rider_mounted.json',
        'curriculum/v2/skills_rider_theory.json',
        'curriculum/v2/skills_horse_in_hand.json',
        'curriculum/v2/skills_horse_mounted.json',
      ];
      skills = [];
      for (final path in skillFiles) {
        final raw = jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
        skills.addAll(
          raw.map(
            (e) => CurriculumSkill.fromMap(Map<String, dynamic>.from(e as Map)),
          ),
        );
      }
      skillById = {for (final s in skills) s.id: s};

      final snapRaw =
          jsonDecode(
                File(
                  'migrate_working_dir/skills_snapshot.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      legacySnapshot = (snapRaw['skills'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final mapRaw =
          jsonDecode(
                File('curriculum/v2/legacy_mapping.json').readAsStringSync(),
              )
              as List<dynamic>;
      legacyMapping = mapRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    });

    test('contains expected families, skills, and level standards', () {
      expect(families.length, 32);
      expect(skills.length, 72);
      final totalLevels = skills.fold<int>(
        0,
        (sum, s) => sum + s.availableLevels.length,
      );
      expect(totalLevels, 154);

      // Batch 1 & 2 3-level progression checks
      for (final id in [
        'rider.mounted.trot',
        'rider.mounted.canter',
        'rider.mounted.transitions',
        'horse.mounted.trot',
        'horse.mounted.canter',
      ]) {
        expect(skillById[id]!.availableLevels, [
          DifficultyState.Introductory,
          DifficultyState.Intermediate,
          DifficultyState.Advanced,
        ], reason: '$id should expose 3 progressive levels');
      }
    });

    test(
      'all skills have valid families, ordered levels, and non-empty criteria',
      () {
        for (final s in skills) {
          final fam = familyById[s.familyId];
          expect(
            fam,
            isNotNull,
            reason: '${s.id} missing family ${s.familyId}',
          );
          expect(fam!.subject, s.subject, reason: '${s.id} subject mismatch');
          expect(fam.realm, s.realm, reason: '${s.id} realm mismatch');
          expect(
            s.availableLevels,
            isNotEmpty,
            reason: '${s.id} has no levels',
          );
          expect(s.levels.length, s.availableLevels.length);
          for (final lvl in s.availableLevels) {
            final def = s.levelDefinition(lvl);
            expect(def, isNotNull, reason: '${s.id} missing $lvl');
            expect(def!.overview.trim(), isNotEmpty);
            expect(def.learning.trim(), isNotEmpty);
            expect(def.proficient.trim(), isNotEmpty);
            expect(def.standardVersion, greaterThanOrEqualTo(1));
          }
        }
      },
    );

    test(
      'counterpart links cross subjects symmetrically and allow independent levels',
      () {
        for (final s in skills) {
          for (final rel in s.relatedSkills) {
            final target = skillById[rel.skillId];
            expect(target, isNotNull, reason: '${s.id} -> ${rel.skillId}');
            if (rel.relation == SkillRelationType.counterpart) {
              expect(target!.subject, isNot(s.subject));
              expect(
                target.relatedSkills.any(
                  (r) =>
                      r.skillId == s.id &&
                      r.relation == SkillRelationType.counterpart,
                ),
                isTrue,
                reason: 'Asymmetric counterpart ${s.id} <-> ${target.id}',
              );
            }
            if (rel.level != null) {
              expect(target!.hasLevel(rel.level!), isTrue);
            }
          }
        }

        // Ground driving subject independence check
        final riderGD = skillById['rider.in_hand.ground_driving']!;
        final horseGD = skillById['horse.in_hand.ground_driving']!;
        expect(riderGD.availableLevels, [
          DifficultyState.Intermediate,
          DifficultyState.Advanced,
        ]);
        expect(horseGD.availableLevels, [
          DifficultyState.Introductory,
          DifficultyState.Intermediate,
        ]);
      },
    );

    test('enforces trainer-approved merges, Shoulder-In, and basic pivots', () {
      expect(skillById['rider.mounted.steering_navigation']?.availableLevels, [
        DifficultyState.Introductory,
        DifficultyState.Intermediate,
        DifficultyState.Advanced,
      ]);
      expect(skillById['rider.mounted.object_handling']?.availableLevels, [
        DifficultyState.Introductory,
        DifficultyState.Intermediate,
        DifficultyState.Advanced,
      ]);
      expect(skillById['rider.mounted.terrain_obstacles']?.availableLevels, [
        DifficultyState.Introductory,
        DifficultyState.Intermediate,
        DifficultyState.Advanced,
      ]);
      expect(skillById['rider.mounted.shoulder_in']?.availableLevels, [
        DifficultyState.Intermediate,
        DifficultyState.Advanced,
      ]);
      expect(
        skillById['rider.mounted.turn_on_forehand']?.hasLevel(
          DifficultyState.Introductory,
        ),
        isTrue,
      );
      expect(
        skillById['rider.mounted.turn_on_haunches']?.hasLevel(
          DifficultyState.Introductory,
        ),
        isTrue,
      );
      expect(
        skillById['horse.mounted.turn_on_haunches']?.hasLevel(
          DifficultyState.Introductory,
        ),
        isTrue,
      );
    });

    test(
      'all 84 legacy skill IDs map uniquely to v2 skills and valid levels',
      () {
        expect(legacySnapshot.length, 84);
        expect(legacyMapping.length, 84);

        final mappedFromSkills = <String, String>{};
        for (final s in skills) {
          for (final lid in s.legacyIds) {
            expect(
              mappedFromSkills.containsKey(lid),
              isFalse,
              reason: 'Dup $lid',
            );
            mappedFromSkills[lid] = s.id;
          }
        }

        final snapIds = legacySnapshot.map((e) => e['id'] as String).toSet();
        expect(mappedFromSkills.keys.toSet(), snapIds);

        for (final row in legacyMapping) {
          final lid = row['legacyId'] as String;
          final v2Id = row['v2SkillId'] as String;
          final lvl = parseOptionalDifficulty(row['targetLevel'] as String?);
          expect(snapIds.contains(lid), isTrue);
          expect(mappedFromSkills[lid], v2Id);
          expect(lvl, isNotNull);
          expect(skillById[v2Id]?.hasLevel(lvl!), isTrue);
        }
      },
    );
  });
}
