/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {
  DEFAULT_IMPORT_OUT_FILE,
  SKILL_FILE_MAP,
  cleanSkillForExport,
  buildExportFiles,
  diffExportFiles,
  loadLocalCurriculumV2,
  buildCanonicalImportPayload,
  bundleLocalCurriculumForImport,
} = require('../../tool/export_curriculum_v2');

function loadRepoCurriculum() {
  const v2Dir = path.resolve(__dirname, '../../curriculum/v2');
  const families = JSON.parse(fs.readFileSync(path.join(v2Dir, 'families.json'), 'utf8'));
  const skills = [];
  for (const spec of SKILL_FILE_MAP) {
    skills.push(...JSON.parse(fs.readFileSync(path.join(v2Dir, spec.file), 'utf8')));
  }
  return {families, skills};
}

test('buildExportFiles produces deterministic JSON matching curriculum/v2 file structure', () => {
  const {families, skills} = loadRepoCurriculum();
  const exportA = buildExportFiles({families, skills});
  const exportB = buildExportFiles({
    families: [...families].reverse(),
    skills: [...skills].reverse(),
  });

  assert.equal(exportA.familyCount, 33);
  assert.equal(exportA.skillCount, 84);
  assert.equal(exportA.totalLevels, 187);
  assert.equal(exportA.checksum, exportB.checksum);
  assert.equal(exportA.files.size, 7);

  for (const [fileName, contentA] of exportA.files.entries()) {
    assert.equal(contentA, exportB.files.get(fileName), `Deterministic output required for ${fileName}`);
    const parsed = JSON.parse(contentA);
    assert.ok(Array.isArray(parsed));
  }
});

test('diffExportFiles detects modified files in dry-run without touching unrelated files', () => {
  const {families, skills} = loadRepoCurriculum();
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'hrc-export-test-'));
  try {
    const unrelatedPath = path.join(tmpDir, 'UNRELATED.txt');
    fs.writeFileSync(unrelatedPath, 'keep-me', 'utf8');

    const built = buildExportFiles({families, skills});
    const firstDiff = diffExportFiles(built.files, tmpDir);
    assert.equal(firstDiff.filter((d) => d.changed).length, 7);

    // Write exported files, then re-diff -> 0 changed, unrelated file untouched.
    for (const [fileName, content] of built.files.entries()) {
      fs.writeFileSync(path.join(tmpDir, fileName), content, 'utf8');
    }
    const secondDiff = diffExportFiles(built.files, tmpDir);
    assert.equal(secondDiff.filter((d) => d.changed).length, 0);
    assert.equal(fs.readFileSync(unrelatedPath, 'utf8'), 'keep-me');
  } finally {
    fs.rmSync(tmpDir, {recursive: true, force: true});
  }
});

test('bundleLocalCurriculumForImport builds validated canonical v2 JSON without touching unrelated files', () => {
  const {families, skills} = loadLocalCurriculumV2();
  const bundled = buildCanonicalImportPayload({families, skills});

  assert.equal(bundled.payload.schemaVersion, 2);
  assert.equal(bundled.familyCount, 33);
  assert.equal(bundled.skillCount, 84);
  assert.equal(bundled.totalLevels, 187);
  assert.ok(bundled.json.endsWith('\n'));
  assert.ok(
      DEFAULT_IMPORT_OUT_FILE.endsWith(
          path.join('build', 'curriculum', 'skill_tree_v2_import.json'),
      ),
  );

  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'hrc-bundle-import-test-'));
  try {
    const outFile = path.join(tmpDir, 'nested', 'skill_tree_v2_import.json');
    const dryRun = bundleLocalCurriculumForImport({outFile, write: false});
    assert.equal(dryRun.wroteFile, false);
    assert.equal(fs.existsSync(outFile), false);

    const written = bundleLocalCurriculumForImport({outFile, write: true});
    assert.equal(written.wroteFile, true);
    assert.equal(fs.existsSync(outFile), true);
    const parsed = JSON.parse(fs.readFileSync(outFile, 'utf8'));
    assert.equal(parsed.schemaVersion, 2);
    assert.equal(parsed.families.length, 33);
    assert.equal(parsed.skills.length, 84);
    for (const skill of parsed.skills) {
      assert.ok(skill.learningGuide, `${skill.id} missing learningGuide`);
      assert.ok(skill.learningGuide.exercises.length >= 1, `${skill.id} missing exercises`);
    }
    const reinBack = parsed.skills.find((s) => s.id === 'rider.mounted.rein_back');
    assert.ok(reinBack.learningGuide);
    const grooming = parsed.skills.find((s) => s.id === 'rider.husbandry.grooming');
    assert.ok(grooming.learningGuide);

    // Optional learningGuide remains backward-compatible when omitted on legacy data.
    const guideLess = structuredClone(grooming);
    delete guideLess.learningGuide;
    const cleaned = cleanSkillForExport(guideLess);
    assert.equal('learningGuide' in cleaned, false);
  } finally {
    fs.rmSync(tmpDir, {recursive: true, force: true});
  }
});
