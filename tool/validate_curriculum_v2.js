const fs = require('fs');
const path = require('path');
const {validateCurriculum} = require('../functions/curriculum_validator');

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

function main() {
  const families = JSON.parse(fs.readFileSync(path.join(V2_DIR, 'families.json'), 'utf8'));
  const allSkills = [];
  for (const file of SKILL_FILES) {
    const list = JSON.parse(fs.readFileSync(path.join(V2_DIR, file), 'utf8'));
    allSkills.push(...list);
  }

  const snap = JSON.parse(fs.readFileSync(SNAPSHOT_PATH, 'utf8'));
  const snapSkills = Array.isArray(snap) ? snap : snap.skills;
  const legacySnapshotIds = new Set(snapSkills.map((x) => x.id));

  const mappingPath = path.join(V2_DIR, 'legacy_mapping.json');
  const legacyMapping = fs.existsSync(mappingPath)
    ? JSON.parse(fs.readFileSync(mappingPath, 'utf8'))
    : null;

  const result = validateCurriculum({
    families,
    skills: allSkills,
    legacySnapshotIds,
    legacyMapping,
    requireFamilyDescription: true,
    enforceSizeLimit: true,
  });

  if (snapSkills.length !== 84) {
    result.errors.push(`Expected 84 snapshot skills, found ${snapSkills.length}`);
  }

  console.log(`Families: ${result.families.length}`);
  console.log(`V2 Skills: ${result.skills.length} | Total Level Standards: ${result.totalLevels}`);
  console.log(`Legacy IDs mapped: ${result.legacyCount}/${snapSkills.length}`);
  console.log(`Draft JSON size: ${(result.sizeBytes / 1024).toFixed(1)} KB`);
  console.log(`Errors: ${result.errors.length}`);
  if (result.errors.length) {
    console.error(result.errors.join('\n'));
    process.exit(1);
  }
}

main();
