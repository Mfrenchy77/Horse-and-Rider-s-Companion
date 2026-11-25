# Horse and Rider's Companion — Project Instructions

## Project Overview

Horse and Rider's Companion is a Flutter application for horse owners, riders, trainers, instructors, and equestrian communities.

The application supports Rider and Horse profiles, educational Resources, progress tracking, instructor verification, and Skill Tree 2.0.

**The application serves ALL equestrians**, including Western, English, recreational, trail, ranch, driving, therapeutic, competitive, and general horsemanship communities.

Do not assume the user practices dressage or Working Equitation.

## Project Environment

- Framework: Flutter / Dart
- Backend: Firebase Authentication, Cloud Firestore, Cloud Functions
- Development OS: Rocky Linux
- Repository: `Mfrenchy77/Horse-and-Rider-s-Companion`
- Main branch: `main`
- Production Firebase project: `horse-and-riders-compani-d2bd4`
- Production URL: `https://horse-and-riders-compani-d2bd4.web.app`

Inspect the current repository before assuming implementation details.

## Working With the Project Owner

The owner is an experienced professional horse trainer and Flutter application developer.

They prefer:

- Practical implementation over lengthy planning.
- Complete, working solutions rather than vague suggestions.
- Small, focused changes.
- Troubleshooting one step at a time.
- Clear explanations without unnecessary technical jargon.
- Minimal repeated audits and prolonged revision cycles.
- Proactive recommendations when they genuinely improve the application.

Do not turn a minor UI request into a large refactor.

Do not repeatedly request approval for routine local development.

## Git Workflow

For each completed development task:

1. Inspect the existing implementation.
2. Implement the requested change.
3. Run relevant tests and Flutter analysis.
4. Review the Git diff.
5. Stage only task-related files.
6. Create a descriptive local Git commit.
7. Report the commit hash and any outstanding issues.

**Never push to GitHub without explicit authorization.**

**Never deploy to Firebase or modify production data without explicit authorization.**

Do not commit secrets, credentials, generated build artifacts, or temporary debugging files.

Do not discard unrelated changes or rewrite existing Git history without approval.

## Skill Tree 2.0 Architecture

Skill Tree 2.0 is the production default.

Its hierarchy is:

Subject → Category → Skill Family → Skill → Difficulty Level

Subjects are Rider and Horse.

Rider and Horse assessments are independent and must remain associated with the correct profile.

Progress states include:

- Not Started
- Learning
- Proficient

Instructor verification is independent from self-assessment.

Skill Families organize skills but do not independently track completion.

Educational components, examples, and aliases support learning and search. They are not separate assessment checklists.

Each available difficulty level has its own assessment standards.

Do not create unnecessary micro-skills.

### Curriculum Philosophy

Skill Tree 2.0 tracks meaningful horsemanship competencies.

It emphasizes:

- Clear and humane communication.
- Equine behavior and learning theory.
- Safety and welfare.
- Rider and horse biomechanics.
- Progressive physical and mental development.
- Practical knowledge applicable across disciplines.

The Training Pyramid is included as a useful framework, not the only legitimate training philosophy.

Theory proficiency must be achievable regardless of riding discipline.

### Curriculum Storage

The live curriculum is stored in Firestore:

- `SkillFamilies`
- `SkillsV2`

Progress and verification are stored separately:

- `SkillProgress`
- `SkillVerifications`

Version-controlled curriculum definitions live in `curriculum/v2/*.json`.

Flutter also bundles curriculum assets as a fallback.

Keep these representations synchronized when publishing curriculum changes.

Preserve stable skill IDs, legacy mappings, assessments, and instructor verifications.

Never reset existing progress when reorganizing curriculum categories or families.

### Current Curriculum Baseline

Following the Theory & Knowledge expansion, production contains:

- 32 Skill Families
- 72 Skills
- 149 difficulty-level standards
- 84 legacy skill mappings

Verify current counts before relying on them in future changes.

### Existing Documentation

Consult relevant project documentation, including:

- `docs/SKILL_TREE_CURRICULUM_GUIDE.md`
- `docs/skill_tree_v2_curriculum_audit.md`
- `docs/ADMINISTRATION_ARCHITECTURE_PROPOSAL.md`

## Navigation

Skill Tree 2.0 is the default interface.

Linked skills from Resources, profile skill lists, and associated-skill dialogs should open the corresponding skill in V2.

Legacy IDs must resolve through existing mappings.

Preserve Rider/Horse context and difficulty-level selection.

Newly selected skills should open at the top of their details.

Do not restore legacy Skill Tree navigation unless the V2 rollback flag is explicitly disabled.

## Administration and Permissions

Ordinary users can view skills, record authorized progress, and submit suggestions.

Moderators can triage community suggestions within their permissions.

Administrators can manage curriculum drafts and review suggestions.

Curriculum edits must be authorized server-side.

Resource editing follows established ownership/editor/administrator permissions.

Never assume a hidden button provides adequate security.

Do not expose privileged controls to ordinary users.

Production custom claims must not be altered without explicit approval.

## UI and UX Principles

The application uses a dark teal visual identity, coral accents, gradient surfaces, and frosted-glass dialogs.

The overall design should feel polished, welcoming, and uncluttered.

Prefer **progressive disclosure**:

- Content first.
- Primary interactions clearly visible.
- Secondary editing actions in overflow menus or expandable sections.
- Advanced administration controls shown only when requested.

Avoid duplicate actions.

Keep modal backgrounds consistent using the project's existing glass-dialog infrastructure.

Maintain responsive layouts for mobile, tablet, and desktop.

Do not sacrifice text contrast or accessibility for decorative effects.

### Resource Interface

- Associated-skill chips remain clickable.
- Edit Resource belongs in the Resource overflow menu.
- Associated Skills opens in compact read-only mode.
- Authorized users can select Manage Links inside the dialog.
- Do not reintroduce duplicate standalone editing buttons.

## Current Visual Issue: Double Gradient

A recent local commit, `18fca4c`, introduced an optional `useDoubleGradient` treatment in `AppSurfaceCard`, enabled for Skill Tree 2.0 detail panels.

The owner liked the double-gradient appearance of the older interface.

However, the desired effect is not yet clearly visible in the correct V2 screen.

Investigate which widgets actually paint the larger teal background around the Skill Tree 2.0 content.

Reuse existing theme gradients rather than inventing unrelated styling.

**Do not replace or restore the legacy Skill Tree layout to achieve the gradient effect.**

Keep any fix limited to presentation and verify the result in the local preview.

## Testing and Release Safety

Run targeted tests first.

Do not repeatedly run large test suites when focused coverage is sufficient.

Fix relevant regressions, but avoid unrelated cleanup.

Never perform production writes during tests.

Use Firebase emulators for backend and security tests.

Before a production release:

- Confirm the target Firebase project.
- Preserve existing data.
- Validate rules and permissions.
- Verify the build.
- Prepare a rollback path.

Production deployment always requires explicit owner authorization.

## General Development Principle

Prioritize delivering a working, maintainable application over endlessly refining implementation details.

Make thoughtful improvements, test them, commit completed work locally, and move forward.

## Equestrian Dictionary

Follow docs/EQUESTRIAN_DICTIONARY_GUIDING_PRINCIPLES.md for Dictionary implementation and editorial work. Published meanings have stable IDs and slugs. Keep submissions, drafts, contributor identities, and review history private. Public recognition requires explicit consent.
