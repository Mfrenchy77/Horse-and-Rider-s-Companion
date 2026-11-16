const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const V2_DIR = path.join(ROOT, 'curriculum', 'v2');
const SNAPSHOT_PATH = path.join(ROOT, 'migrate_working_dir', 'skills_snapshot.json');

const SKILL_FILES = [
  'skills_rider_husbandry.json',
  'skills_rider_in_hand.json',
  'skills_rider_mounted.json',
  'skills_rider_theory.json',
  'skills_horse_in_hand.json',
  'skills_horse_mounted.json',
];

const LEVEL_ORDER = ['introductory', 'intermediate', 'advanced'];
const VALID_REALMS = {
  rider: ['Husbandry', 'In_Hand', 'Mounted', 'Other'],
  horse: ['In_Hand', 'Mounted'],
};

function main() {
  const errors = [];
  const families = JSON.parse(fs.readFileSync(path.join(V2_DIR, 'families.json'), 'utf8'));
  const familyMap = new Map();

  for (const f of families) {
    if (!f.id || familyMap.has(f.id)) errors.push(`Duplicate or missing family id: ${f.id}`);
    if (!VALID_REALMS[f.subject]?.includes(f.realm)) {
      errors.push(`Invalid subject/realm on family ${f.id}: ${f.subject}/${f.realm}`);
    }
    if (!f.name || !f.description) errors.push(`Family ${f.id} missing name/description`);
    familyMap.set(f.id, f);
  }

  const allSkills = [];
  const skillMap = new Map();
  for (const file of SKILL_FILES) {
    const list = JSON.parse(fs.readFileSync(path.join(V2_DIR, file), 'utf8'));
    for (const s of list) {
      allSkills.push(s);
      if (!s.id || skillMap.has(s.id)) errors.push(`Duplicate or missing skill id: ${s.id}`);
      skillMap.set(s.id, s);
    }
  }

  const legacySeen = new Map();
  let totalLevels = 0;

  for (const s of allSkills) {
    if (s.schemaVersion !== 2) errors.push(`${s.id}: schemaVersion !== 2`);
    if (!['draft', 'active', 'retired'].includes(s.status)) errors.push(`${s.id}: invalid status ${s.status}`);
    if (!VALID_REALMS[s.subject]?.includes(s.realm)) {
      errors.push(`${s.id}: invalid subject/realm ${s.subject}/${s.realm}`);
    }
    const fam = familyMap.get(s.familyId);
    if (!fam) {
      errors.push(`${s.id}: unknown familyId ${s.familyId}`);
    } else if (fam.subject !== s.subject || fam.realm !== s.realm) {
      errors.push(`${s.id}: family ${s.familyId} subject/realm mismatch`);
    }
    if (!s.name || !s.summary || !s.purpose) errors.push(`${s.id}: missing name/summary/purpose`);

    const avail = s.availableLevels || [];
    if (avail.length < 1 || avail.length > 3) errors.push(`${s.id}: availableLevels length ${avail.length}`);
    let lastIdx = -1;
    for (const lvl of avail) {
      const idx = LEVEL_ORDER.indexOf(lvl);
      if (idx === -1 || idx <= lastIdx) errors.push(`${s.id}: invalid or unordered level ${lvl}`);
      lastIdx = idx;
    }

    const levelKeys = Object.keys(s.levels || {});
    if (levelKeys.length !== avail.length || !avail.every((l) => levelKeys.includes(l))) {
      errors.push(`${s.id}: levels keys [${levelKeys}] != availableLevels [${avail}]`);
    }

    for (const lvl of avail) {
      totalLevels++;
      const def = s.levels[lvl];
      if (!def.overview || !def.learning || !def.proficient) {
        errors.push(`${s.id}.${lvl}: missing overview/learning/proficient`);
      }
      if (!def.standardVersion || def.standardVersion < 1) {
        errors.push(`${s.id}.${lvl}: invalid standardVersion`);
      }
    }

    for (const rel of s.relatedSkills || []) {
      const target = skillMap.get(rel.skillId);
      if (!target) {
        errors.push(`${s.id}: relatedSkill ${rel.skillId} not found`);
        continue;
      }
      if (rel.relation === 'counterpart') {
        if (target.subject === s.subject) {
          errors.push(`${s.id}: counterpart ${rel.skillId} must be opposite subject`);
        }
        const reverse = (target.relatedSkills || []).some(
          (r) => r.skillId === s.id && r.relation === 'counterpart',
        );
        if (!reverse) {
          errors.push(`${s.id}: counterpart ${rel.skillId} is not symmetric`);
        }
      }
      if (rel.level && !target.availableLevels.includes(rel.level)) {
        errors.push(`${s.id}: relatedSkill ${rel.skillId} does not offer level ${rel.level}`);
      }
    }

    for (const oldId of s.legacyIds || []) {
      if (legacySeen.has(oldId)) {
        errors.push(`Legacy ID ${oldId} mapped twice: ${legacySeen.get(oldId)} and ${s.id}`);
      }
      legacySeen.set(oldId, s.id);
    }
  }

  // Check foundation DAG has no cycles
  const visiting = new Set();
  const visited = new Set();
  function hasCycle(id) {
    if (visited.has(id)) return false;
    if (visiting.has(id)) return true;
    visiting.add(id);
    const s = skillMap.get(id);
    for (const r of (s?.relatedSkills || []).filter((x) => x.relation === 'foundation')) {
      if (hasCycle(r.skillId)) return true;
    }
    visiting.delete(id);
    visited.add(id);
    return false;
  }
  for (const s of allSkills) {
    if (hasCycle(s.id)) errors.push(`Cycle detected in foundation links at ${s.id}`);
  }

  // Verify 100% of 84 legacy snapshot IDs are accounted for
  const snap = JSON.parse(fs.readFileSync(SNAPSHOT_PATH, 'utf8'));
  const snapSkills = Array.isArray(snap) ? snap : snap.skills;
  if (snapSkills.length !== 84) errors.push(`Expected 84 snapshot skills, found ${snapSkills.length}`);
  const snapIds = new Set(snapSkills.map((x) => x.id));
  for (const id of snapIds) {
    if (!legacySeen.has(id)) errors.push(`Unmapped legacy skill ID: ${id}`);
  }
  for (const id of legacySeen.keys()) {
    if (!snapIds.has(id)) errors.push(`Unknown legacy ID in v2: ${id}`);
  }

  // Validate legacy_mapping.json if present
  const mappingPath = path.join(V2_DIR, 'legacy_mapping.json');
  if (fs.existsSync(mappingPath)) {
    const mapping = JSON.parse(fs.readFileSync(mappingPath, 'utf8'));
    if (mapping.length !== 84) errors.push(`legacy_mapping.json has ${mapping.length} entries, expected 84`);
    for (const m of mapping) {
      if (!snapIds.has(m.legacyId)) errors.push(`legacy_mapping unknown legacyId: ${m.legacyId}`);
      const v2 = skillMap.get(m.v2SkillId);
      if (!v2) errors.push(`legacy_mapping unknown v2SkillId: ${m.v2SkillId}`);
      else if (!v2.legacyIds.includes(m.legacyId)) {
        errors.push(`legacy_mapping mismatch: ${m.legacyId} -> ${m.v2SkillId}`);
      }
      if (!v2?.availableLevels.includes(m.targetLevel)) {
        errors.push(`legacy_mapping invalid targetLevel ${m.targetLevel} on ${m.v2SkillId}`);
      }
    }
  }

  console.log(`Families: ${families.length}`);
  console.log(`V2 Skills: ${allSkills.length} | Total Level Standards: ${totalLevels}`);
  console.log(`Legacy IDs mapped: ${legacySeen.size}/${snapSkills.length}`);
  console.log(`Errors: ${errors.length}`);
  if (errors.length) {
    console.error(errors.join('\n'));
    process.exit(1);
  }
}

main();
