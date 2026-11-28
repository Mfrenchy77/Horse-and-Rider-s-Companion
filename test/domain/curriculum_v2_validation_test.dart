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
      expect(families.length, 33);
      expect(skills.length, 84);
      final totalLevels = skills.fold<int>(
        0,
        (sum, s) => sum + s.availableLevels.length,
      );
      expect(totalLevels, 187);

      // Wave 1, Wave 2, Wave 3 & Batch 1/2 3-level progression checks
      for (final id in [
        'rider.in_hand.longeing',
        'rider.mounted.seat_balance',
        'rider.mounted.trot',
        'rider.mounted.canter',
        'rider.mounted.transitions',
        'rider.mounted.rein_back',
        'horse.in_hand.longeing',
        'horse.mounted.trot',
        'horse.mounted.canter',
        'horse.mounted.rein_back',
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

    test('enforces Wave 1 refinements, splits, and Horse In-Hand Yielding parity', () {
      // 1. Leading: Intro walk-focused, Int versatile, no rigid step counts.
      final leading = skillById['rider.in_hand.leading']!;
      expect(leading.availableLevels, [
        DifficultyState.Introductory,
        DifficultyState.Intermediate,
      ]);
      final leadingIntro = leading.levelDefinition(DifficultyState.Introductory)!;
      final leadingInt = leading.levelDefinition(DifficultyState.Intermediate)!;
      expect(leadingIntro.standardVersion, 2);
      expect(leadingInt.standardVersion, 2);
      expect(leadingIntro.proficient.contains('2–4'), isFalse);
      expect(leadingIntro.overview.toLowerCase(), contains('trot leading is not required'));
      expect(leadingInt.proficient.toLowerCase(), contains('either side'));

      // 2. Longeing: 3 levels without mandatory gait/pole gates.
      final longeing = skillById['rider.in_hand.longeing']!;
      expect(longeing.availableLevels, [
        DifficultyState.Introductory,
        DifficultyState.Intermediate,
        DifficultyState.Advanced,
      ]);
      expect(longeing.levelDefinition(DifficultyState.Introductory)!.standardVersion, 1);
      expect(longeing.levelDefinition(DifficultyState.Intermediate)!.standardVersion, 2);
      expect(longeing.levelDefinition(DifficultyState.Advanced)!.standardVersion, 2);
      expect(
        longeing.levelDefinition(DifficultyState.Introductory)!.overview.toLowerCase(),
        contains('no specific gait'),
      );
      expect(
        longeing.levelDefinition(DifficultyState.Intermediate)!.overview.toLowerCase(),
        contains('cantering is not mandatory'),
      );
      expect(
        longeing.levelDefinition(DifficultyState.Advanced)!.overview.toLowerCase(),
        contains('optional, not mandatory'),
      );

      // 3. Canter split: Counter-Canter and Flying Lead Changes as 2 skill pairs.
      final riderCounter = skillById['rider.mounted.counter_canter']!;
      final horseCounter = skillById['horse.mounted.counter_canter']!;
      final riderFlying = skillById['rider.mounted.flying_lead_changes']!;
      final horseFlying = skillById['horse.mounted.flying_lead_changes']!;
      expect(riderCounter.availableLevels, [
        DifficultyState.Intermediate,
        DifficultyState.Advanced,
      ]);
      expect(horseCounter.availableLevels, [
        DifficultyState.Intermediate,
        DifficultyState.Advanced,
      ]);
      expect(riderFlying.availableLevels, [DifficultyState.Advanced]);
      expect(horseFlying.availableLevels, [DifficultyState.Advanced]);
      expect(
        riderCounter.relatedSkills.any(
          (r) => r.skillId == 'horse.mounted.counter_canter' && r.relation == SkillRelationType.counterpart,
        ),
        isTrue,
      );
      expect(
        riderFlying.relatedSkills.any(
          (r) => r.skillId == 'horse.mounted.flying_lead_changes' && r.relation == SkillRelationType.counterpart,
        ),
        isTrue,
      );

      // 4. Training Principles renamed & zero mandatory mentoring in Theory Adv.
      final pyramid = skillById['rider.theory.training_pyramid']!;
      expect(pyramid.name, 'Training Principles & the Training Pyramid');
      for (final s in skills.where(
        (s) => s.subject == SkillSubject.rider && s.realm == SkillCategory.Other,
      )) {
        final adv = s.levelDefinition(DifficultyState.Advanced);
        if (adv == null) continue;
        expect(
          adv.proficient.toLowerCase().contains('mentor'),
          isFalse,
          reason: '${s.id} Adv proficient should not mandate mentoring',
        );
        expect(
          adv.overview.toLowerCase().contains('mentor'),
          isFalse,
          reason: '${s.id} Adv overview should not mandate mentoring',
        );
        for (final comp in adv.components) {
          expect(
            comp.title.toLowerCase().contains('mentor') ||
                comp.description.toLowerCase().contains('mentor'),
            isFalse,
            reason: '${s.id} Adv component should not mandate mentoring',
          );
        }
      }

      // 5. Three Horse In-Hand Yielding skills in Ground Control & Yielding.
      final groundControlFam = familyById['horse.in_hand.ground_control_yielding']!;
      expect(groundControlFam.name, 'Ground Control & Yielding');
      expect(groundControlFam.subject, SkillSubject.horse);
      expect(groundControlFam.realm, SkillCategory.In_Hand);
      for (final pair in const [
        ('horse.in_hand.yield_hindquarters', 'rider.in_hand.turn_on_forehand'),
        ('horse.in_hand.yield_forequarters', 'rider.in_hand.yield_forequarters'),
        ('horse.in_hand.sidepass_in_hand', 'rider.in_hand.sidepass_in_hand'),
      ]) {
        final horseSkill = skillById[pair.$1]!;
        final riderSkill = skillById[pair.$2]!;
        expect(horseSkill.familyId, 'horse.in_hand.ground_control_yielding');
        expect(horseSkill.availableLevels, [
          DifficultyState.Introductory,
          DifficultyState.Intermediate,
        ]);
        expect(
          horseSkill.relatedSkills.any(
            (r) => r.skillId == riderSkill.id && r.relation == SkillRelationType.counterpart,
          ),
          isTrue,
        );
      }

      // 6. Horse Rein Back: 3 levels without mandatory patterns/step counts.
      final reinBack = skillById['horse.mounted.rein_back']!;
      expect(reinBack.availableLevels, [
        DifficultyState.Introductory,
        DifficultyState.Intermediate,
        DifficultyState.Advanced,
      ]);
      for (final lvl in reinBack.availableLevels) {
        final prof = reinBack.levelDefinition(lvl)!.proficient.toLowerCase();
        expect(prof.contains('l or corridor'), isFalse);
        expect(prof.contains('3–5'), isFalse);
      }
    });

    test('Wave 2 foundational curriculum updates and entry levels preserve consistency', () {
      // 1. Six genuine Introductory entry levels added without padding.
      for (final id in const [
        'rider.husbandry.first_aid',
        'rider.in_hand.yield_forequarters',
        'rider.in_hand.sidepass_in_hand',
        'rider.mounted.rein_back',
        'horse.in_hand.vet_handling',
        'horse.in_hand.trailer_loading',
      ]) {
        expect(
          skillById[id]!.availableLevels,
          contains(DifficultyState.Introductory),
          reason: '$id should expose an Introductory entry level',
        );
      }

      // 2. Formerly orphaned Husbandry skills now link to progression/theory.
      expect(skillById['rider.husbandry.feeding']!.relatedSkills, isNotEmpty);
      expect(
        skillById['rider.husbandry.stable_care']!.relatedSkills,
        isNotEmpty,
      );

      // 3. Broad advisory theory links across practical Rider realms.
      final riderPractical = skills.where(
        (s) =>
            s.subject == SkillSubject.rider &&
            s.realm != SkillCategory.Other,
      );
      for (final s in riderPractical) {
        expect(
          s.relatedSkills.any((r) => r.relation == SkillRelationType.theory),
          isTrue,
          reason: '${s.id} should carry at least one advisory theory link',
        );
      }

      // 4. Broad internal Horse progression links beyond counterparts.
      final horseWithInternal = skills.where(
        (s) =>
            s.subject == SkillSubject.horse &&
            s.relatedSkills.any(
              (r) =>
                  r.relation == SkillRelationType.foundation ||
                  r.relation == SkillRelationType.next,
            ),
      );
      expect(horseWithInternal.length, greaterThanOrEqualTo(24));

      // 5. Rider Trot embraces rising trot OR relaxed sitting jog inclusively.
      final riderTrotIntro = skillById['rider.mounted.trot']!
          .levelDefinition(DifficultyState.Introductory)!
          .proficient
          .toLowerCase();
      expect(riderTrotIntro, contains('rising trot'));
      expect(riderTrotIntro, contains('sitting jog'));
      expect(riderTrotIntro, contains('regardless of diagonal'));

      // 6. Removed rigid L-corridor, mandatory rail, and degree quotas.
      final riderReinBackInt = skillById['rider.mounted.rein_back']!
          .levelDefinition(DifficultyState.Intermediate)!
          .proficient
          .toLowerCase();
      expect(riderReinBackInt.contains('through an l or corridor'), isFalse);
      final riderSidepass = skillById['rider.mounted.sidepass']!
          .levelDefinition(DifficultyState.Intermediate)!
          .proficient
          .toLowerCase();
      expect(riderSidepass, contains('optionally'));
      final horseForehand = skillById['horse.mounted.turn_on_forehand']!
          .levelDefinition(DifficultyState.Introductory)!
          .proficient
          .toLowerCase();
      expect(horseForehand.contains('90–180°'), isFalse);
    });

    test('Wave 3 foundational skills and Turn on the Haunches refinement preserve integrity', () {
      // 1. Five new foundational skills in expected families & levels.
      const expectedWave3 = {
        'rider.mounted.seat_balance': (
          familyId: 'rider.mounted.position_balance_safety',
          levels: [
            DifficultyState.Introductory,
            DifficultyState.Intermediate,
            DifficultyState.Advanced,
          ],
        ),
        'rider.mounted.emergency_control': (
          familyId: 'rider.mounted.position_balance_safety',
          levels: [
            DifficultyState.Introductory,
            DifficultyState.Intermediate,
          ],
        ),
        'horse.in_hand.catching_turnout': (
          familyId: 'horse.in_hand.leading_manners',
          levels: [
            DifficultyState.Introductory,
            DifficultyState.Intermediate,
          ],
        ),
        'horse.in_hand.longeing': (
          familyId: 'horse.in_hand.work_on_line',
          levels: [
            DifficultyState.Introductory,
            DifficultyState.Intermediate,
            DifficultyState.Advanced,
          ],
        ),
        'horse.in_hand.obstacles_outings': (
          familyId: 'horse.in_hand.travel_environments',
          levels: [
            DifficultyState.Introductory,
            DifficultyState.Intermediate,
          ],
        ),
      };
      for (final entry in expectedWave3.entries) {
        final skill = skillById[entry.key]!;
        expect(skill.familyId, entry.value.familyId);
        expect(skill.availableLevels, entry.value.levels);
      }

      // 2. Symmetric counterparts between new Horse In-Hand skills and Rider skills.
      for (final pair in const [
        ('horse.in_hand.catching_turnout', 'rider.in_hand.catch_halter_turnout'),
        ('horse.in_hand.longeing', 'rider.in_hand.longeing'),
        ('horse.in_hand.obstacles_outings', 'rider.in_hand.obstacles_outings'),
      ]) {
        final horseSkill = skillById[pair.$1]!;
        final riderSkill = skillById[pair.$2]!;
        expect(
          horseSkill.relatedSkills.any(
            (r) =>
                r.skillId == riderSkill.id &&
                r.relation == SkillRelationType.counterpart,
          ),
          isTrue,
        );
        expect(
          riderSkill.relatedSkills.any(
            (r) =>
                r.skillId == horseSkill.id &&
                r.relation == SkillRelationType.counterpart,
          ),
          isTrue,
        );
      }

      // 3. Emergency control cautions against one universal maneuver.
      final emergency = skillById['rider.mounted.emergency_control']!;
      expect(
        emergency.safety.join(' ').toLowerCase(),
        contains('one-rein stop'),
      );
      expect(
        emergency.safety.join(' ').toLowerCase(),
        contains('emergency dismount'),
      );

      // 4. Horse Longeing never mandates faster gaits at higher levels.
      final horseLonge = skillById['horse.in_hand.longeing']!;
      expect(
        horseLonge
            .levelDefinition(DifficultyState.Intermediate)!
            .proficient
            .toLowerCase(),
        contains('without requiring canter'),
      );
      expect(
        horseLonge
            .levelDefinition(DifficultyState.Introductory)!
            .proficient
            .toLowerCase(),
        contains('faster gaits are not required'),
      );

      // 5. Horse Catching/Turnout distinguishes calm cooperation from shutdown.
      final horseCatch = skillById['horse.in_hand.catching_turnout']!;
      expect(
        horseCatch.safety.join(' ').toLowerCase(),
        contains('shutdown'),
      );

      // 6. Discipline-neutral Turn on the Haunches removes arbitrary ~1 m mandate.
      final riderHaunches = skillById['rider.mounted.turn_on_haunches']!;
      final horseHaunches = skillById['horse.mounted.turn_on_haunches']!;
      for (final lvl in riderHaunches.availableLevels) {
        final def = riderHaunches.levelDefinition(lvl)!;
        expect(def.overview.contains('~1 m'), isFalse);
        expect(def.proficient.contains('~1 m'), isFalse);
      }
      for (final lvl in horseHaunches.availableLevels) {
        final def = horseHaunches.levelDefinition(lvl)!;
        expect(def.overview.contains('~1 m'), isFalse);
        expect(def.proficient.contains('~1 m'), isFalse);
      }
    });

    test(
      'Develop This Skill sample guides populate the 6 initial skills with valid Dictionary & skill links',
      () {
        final dictRaw =
            jsonDecode(File('functions/dictionary_seed.json').readAsStringSync())
                as List<dynamic>;
        final validSlugs = dictRaw
            .map((e) => (e as Map<String, dynamic>)['slug'] as String)
            .toSet();

        const targetIds = [
          'rider.in_hand.leading',
          'rider.mounted.seat_balance',
          'rider.mounted.rein_back',
          'horse.in_hand.leading',
          'horse.in_hand.longeing',
          'horse.mounted.rein_back',
        ];

        for (final id in targetIds) {
          final skill = skillById[id]!;
          final guide = skill.learningGuide;
          expect(guide, isNotNull, reason: '$id should have learningGuide');
          expect(guide!.hasContent, isTrue);
          expect(
            guide.exercises.length,
            inInclusiveRange(1, 2),
            reason: '$id should have 1-2 practical exercises',
          );
          for (final ex in guide.exercises) {
            expect(ex.title.trim(), isNotEmpty);
            expect(ex.summary.trim(), isNotEmpty);
            expect(ex.whatToNotice?.trim() ?? '', isNotEmpty);
          }
          expect(guide.commonDifficulties, isNotEmpty);
          expect(guide.trainerInsight?.trim() ?? '', isNotEmpty);
          expect(guide.welfareNote?.trim() ?? '', isNotEmpty);
          expect(guide.relatedDictionaryTerms, isNotEmpty);
          for (final slug in guide.relatedDictionaryTerms) {
            expect(
              validSlugs.contains(slug),
              isTrue,
              reason: '$id references unknown Dictionary slug "$slug"',
            );
          }
          expect(guide.relatedSkillIds, isNotEmpty);
          for (final relId in guide.relatedSkillIds) {
            expect(
              skillById.containsKey(relId),
              isTrue,
              reason: '$id references unknown related skill "$relId"',
            );
          }
        }
      },
    );
  });
}
