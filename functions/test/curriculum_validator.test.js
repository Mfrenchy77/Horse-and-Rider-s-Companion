/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  MAX_DRAFT_DOC_BYTES,
  WARN_DRAFT_DOC_BYTES,
  validateCurriculum,
} = require('../curriculum_validator');

function makeFamily(overrides = {}) {
  return {
    id: 'rider.mounted.balance',
    schemaVersion: 2,
    subject: 'rider',
    realm: 'Mounted',
    name: 'Mounted Balance',
    description: 'Core rider balance in the saddle.',
    sortOrder: 10,
    ...overrides,
  };
}

function makeSkill(overrides = {}) {
  return {
    id: 'rider.mounted.neutral_pelvis',
    schemaVersion: 2,
    status: 'active',
    subject: 'rider',
    realm: 'Mounted',
    familyId: 'rider.mounted.balance',
    name: 'Neutral Pelvis',
    aliases: ['Balanced Seat'],
    summary: 'Maintains a neutral pelvis at halt and walk.',
    purpose: 'Supports independent seat and leg aids.',
    safety: ['Check girth before mounting.'],
    availableLevels: ['introductory'],
    levels: {
      introductory: {
        overview: 'Finds neutral alignment at halt and walk.',
        components: [{title: 'Seat bones', description: 'Even weight on seat bones.'}],
        learning: 'Finds alignment at halt.',
        proficient: 'Maintains alignment through walk transitions.',
        standardVersion: 1,
      },
    },
    relatedSkills: [],
    legacyIds: ['legacy_seat_1'],
    sortOrder: 10,
    ...overrides,
  };
}

test('validateCurriculum detects duplicate IDs, missing family, and subject/realm mismatches', () => {
  const res = validateCurriculum({
    families: [
      makeFamily(),
      makeFamily({name: 'Duplicate Family'}),
      makeFamily({id: 'horse.husbandry.invalid', subject: 'horse', realm: 'Husbandry'}),
    ],
    skills: [
      makeSkill(),
      makeSkill({name: 'Duplicate Skill', familyId: 'missing.family', legacyIds: ['legacy_seat_1']}),
      makeSkill({id: 'rider.in_hand.mismatch', realm: 'In_Hand', familyId: 'rider.mounted.balance', legacyIds: []}),
    ],
  });

  assert.equal(res.ok, false);
  assert.ok(res.errors.some((e) => e.includes('Duplicate family ID')));
  assert.ok(res.errors.some((e) => e.includes('invalid subject/realm combination horse/Husbandry')));
  assert.ok(res.errors.some((e) => e.includes('Duplicate skill ID')));
  assert.ok(res.errors.some((e) => e.includes('does not match skill (rider/In_Hand)')));
});

test('validateCurriculum detects broken relatedSkills, self-refs, invalid level, asymmetric counterpart, and cycles', () => {
  const f1 = makeFamily({id: 'rider.mounted.balance'});
  const f2 = makeFamily({id: 'horse.mounted.balance', subject: 'horse', name: 'Horse Balance'});

  const s1 = makeSkill({
    id: 'rider.mounted.a',
    relatedSkills: [
      {skillId: 'rider.mounted.a', relation: 'next'},
      {skillId: 'rider.mounted.missing', relation: 'next'},
      {skillId: 'rider.mounted.b', relation: 'foundation', level: 'advanced'},
      {skillId: 'horse.mounted.c', relation: 'counterpart'},
    ],
  });
  const s2 = makeSkill({
    id: 'rider.mounted.b',
    legacyIds: [],
    relatedSkills: [{skillId: 'rider.mounted.a', relation: 'foundation'}],
  });
  const s3 = makeSkill({
    id: 'horse.mounted.c',
    subject: 'horse',
    familyId: 'horse.mounted.balance',
    legacyIds: [],
    relatedSkills: [],
  });

  const res = validateCurriculum({
    families: [f1, f2],
    skills: [s1, s2, s3],
  });

  assert.equal(res.ok, false);
  assert.ok(res.errors.some((e) => e.includes('cannot reference itself')));
  assert.ok(res.errors.some((e) => e.includes('relatedSkill "rider.mounted.missing" not found')));
  assert.ok(res.errors.some((e) => e.includes('does not offer level "advanced"')));
  assert.ok(res.errors.some((e) => e.includes('is not symmetric')));
  assert.ok(res.errors.some((e) => e.includes('Cycle detected in foundation links')));
});

test('validateCurriculum validates replacedBy and preserves replacedBy, standardUpdatedAt, updatedBy', () => {
  const f1 = makeFamily();
  const activeSkill = makeSkill({id: 'rider.mounted.active_target', legacyIds: []});
  const retiredValid = makeSkill({
    id: 'rider.mounted.old_skill',
    status: 'retired',
    replacedBy: 'rider.mounted.active_target',
    updatedBy: 'admin-uid',
    updatedAt: '2026-11-23T00:00:00.000Z',
    levels: {
      introductory: {
        overview: 'Old overview.',
        components: [],
        learning: 'Old learning.',
        proficient: 'Old proficient.',
        standardVersion: 2,
        standardUpdatedAt: '2026-11-22T12:00:00.000Z',
      },
    },
  });

  const okRes = validateCurriculum({
    families: [f1],
    skills: [activeSkill, retiredValid],
  });
  assert.equal(okRes.ok, true, okRes.errors.join('; '));
  const savedRetired = okRes.skills.find((s) => s.id === 'rider.mounted.old_skill');
  assert.equal(savedRetired.replacedBy, 'rider.mounted.active_target');
  assert.equal(savedRetired.updatedBy, 'admin-uid');
  assert.equal(savedRetired.updatedAt, '2026-11-23T00:00:00.000Z');
  assert.equal(savedRetired.levels.introductory.standardVersion, 2);
  assert.equal(savedRetired.levels.introductory.standardUpdatedAt, '2026-11-22T12:00:00.000Z');

  // Invalid replacedBy cases
  const badRes = validateCurriculum({
    families: [f1],
    skills: [
      makeSkill({id: 'rider.mounted.active_bad', status: 'active', replacedBy: 'rider.mounted.retired_target'}),
      makeSkill({id: 'rider.mounted.retired_target', status: 'retired', legacyIds: []}),
    ],
  });
  assert.equal(badRes.ok, false);
  assert.ok(badRes.errors.some((e) => e.includes('only allowed when status is "retired"')));
  assert.ok(badRes.errors.some((e) => e.includes('must have status "active"')));
});

test('validateCurriculum protects published skill IDs, levels, legacyIds, and standardVersion bumps', () => {
  const family = makeFamily();
  const published = [
    makeSkill({
      availableLevels: ['introductory', 'intermediate'],
      levels: {
        introductory: {
          overview: 'Intro overview.',
          components: [],
          learning: 'Intro learning.',
          proficient: 'Intro proficient v1.',
          standardVersion: 1,
        },
        intermediate: {
          overview: 'Int overview.',
          components: [],
          learning: 'Int learning.',
          proficient: 'Int proficient v1.',
          standardVersion: 2,
        },
      },
    }),
  ];

  // Attempt to delete published skill ID
  const deletedSkillRes = validateCurriculum({
    families: [family],
    skills: [],
    publishedSkills: published,
  });
  assert.equal(deletedSkillRes.ok, false);
  assert.ok(deletedSkillRes.errors.some((e) => e.includes('cannot be deleted; set status to "retired"')));

  // Attempt to delete published level, drop legacyId, change proficient without bump, or downgrade version
  const brokenEdit = makeSkill({
    availableLevels: ['introductory'],
    legacyIds: [],
    levels: {
      introductory: {
        overview: 'Intro overview.',
        components: [],
        learning: 'Intro learning.',
        proficient: 'Intro proficient CHANGED.',
        standardVersion: 1,
      },
    },
  });
  const brokenRes = validateCurriculum({
    families: [family],
    skills: [brokenEdit],
    publishedSkills: published,
  });
  assert.equal(brokenRes.ok, false);
  assert.ok(brokenRes.errors.some((e) => e.includes('Published difficulty level "intermediate"')));
  assert.ok(brokenRes.errors.some((e) => e.includes('Published legacyId "legacy_seat_1"')));
  assert.ok(brokenRes.errors.some((e) => e.includes('increment standardVersion above v1')));

  // Valid update: retains levels & legacyIds, bumps standardVersion
  const validEdit = makeSkill({
    availableLevels: ['introductory', 'intermediate'],
    levels: {
      introductory: {
        overview: 'Intro overview.',
        components: [],
        learning: 'Intro learning.',
        proficient: 'Intro proficient CHANGED.',
        standardVersion: 2,
      },
      intermediate: {
        overview: 'Int overview.',
        components: [],
        learning: 'Int learning.',
        proficient: 'Int proficient v1.',
        standardVersion: 2,
      },
    },
  });
  const validRes = validateCurriculum({
    families: [family],
    skills: [validEdit],
    publishedSkills: published,
  });
  assert.equal(validRes.ok, true, validRes.errors.join('; '));
});

test('validateCurriculum checks single-document draft size thresholds', () => {
  const family = makeFamily();
  const largeSummary = 'x'.repeat(980);
  const skills = [];
  for (let i = 0; i < 250; i += 1) {
    skills.push(makeSkill({
      id: `rider.mounted.s_${i}`,
      legacyIds: [],
      summary: largeSummary,
      purpose: largeSummary,
      availableLevels: ['introductory', 'intermediate', 'advanced'],
      levels: {
        introductory: {
          overview: largeSummary,
          components: [{title: `C1_${i}`, description: largeSummary}],
          learning: largeSummary,
          proficient: largeSummary,
          standardVersion: 1,
        },
        intermediate: {
          overview: largeSummary,
          components: [{title: `C2_${i}`, description: largeSummary}],
          learning: largeSummary,
          proficient: largeSummary,
          standardVersion: 1,
        },
        advanced: {
          overview: largeSummary,
          components: [{title: `C3_${i}`, description: largeSummary}],
          learning: largeSummary,
          proficient: largeSummary,
          standardVersion: 1,
        },
      },
    }));
  }

  const res = validateCurriculum({
    families: [family],
    skills,
    enforceSizeLimit: true,
  });
  assert.ok(res.sizeBytes > WARN_DRAFT_DOC_BYTES);
  assert.ok(res.warnings.length > 0);
  assert.ok(res.sizeBytes > MAX_DRAFT_DOC_BYTES);
  assert.equal(res.ok, false);
  assert.ok(res.errors.some((e) => e.includes('exceeds safe single-document limit')));
});

test('validateCurriculum validates optional learningGuide without requiring standardVersion bumps', () => {
  const family = makeFamily();
  const secondary = makeSkill({id: 'rider.mounted.halt', legacyIds: [], name: 'Halt'});
  const base = makeSkill({
    relatedSkills: [{skillId: 'rider.mounted.halt', relation: 'foundation'}],
  });

  const withValidGuide = makeSkill({
    relatedSkills: [{skillId: 'rider.mounted.halt', relation: 'foundation'}],
    learningGuide: {
      exercises: [
        {
          badge: 'Foundation Exercise',
          title: 'Quiet Halt Check',
          focusLevel: 'introductory',
          summary: 'Ask gently for a calm halt and release forward right away.',
          whatToNotice: 'Does the horse settle softly without raising the head?',
        },
      ],
      commonDifficulties: [
        {
          issue: 'Holding tension too long',
          guidance: 'Release the instant weight shifts smoothly.',
        },
      ],
      trainerInsight: 'Soft timing beats stronger hands.',
      welfareNote: 'Check back and tack comfort if tension persists.',
      relatedDictionaryTerms: ['half-halt', 'rein-contact'],
      relatedSkillIds: ['rider.mounted.halt'],
    },
  });

  const validRes = validateCurriculum({
    families: [family],
    skills: [withValidGuide, secondary],
    publishedSkills: [base, secondary],
  });
  assert.equal(validRes.ok, true, validRes.errors.join('; '));
  assert.equal(validRes.skills[0].learningGuide.exercises.length, 1);

  const emptyGuideSkill = makeSkill({
    relatedSkills: [{skillId: 'rider.mounted.halt', relation: 'foundation'}],
    learningGuide: {exercises: [], relatedDictionaryTerms: []},
  });
  const emptyRes = validateCurriculum({
    families: [family],
    skills: [emptyGuideSkill, secondary],
  });
  assert.equal(emptyRes.ok, true, emptyRes.errors.join('; '));
  assert.equal(emptyRes.skills[0].learningGuide, undefined);

  const badGuideSkill = makeSkill({
    learningGuide: {
      exercises: [{title: '', summary: ''}],
      relatedDictionaryTerms: ['Not A Valid Slug!'],
      relatedSkillIds: ['rider.mounted.neutral_pelvis', 'does.not.exist'],
    },
  });
  const badRes = validateCurriculum({
    families: [family],
    skills: [badGuideSkill],
  });
  assert.equal(badRes.ok, false);
  assert.ok(badRes.errors.some((e) => e.includes('learningGuide.exercises[0].title is required')));
  assert.ok(badRes.errors.some((e) => e.includes('valid Dictionary slug')));
  assert.ok(badRes.errors.some((e) => e.includes('cannot reference itself')));
  assert.ok(badRes.errors.some((e) => e.includes('target "does.not.exist" not found')));
});
