# Skill Tree 2.0: Independent Curriculum Quality Audit

> **Scope & Status:** Read-only educational and organizational audit of the version-controlled Skill Tree 2.0 curriculum (`curriculum/v2/`). No code, JSON curriculum files, Firestore documents, security rules, or user progress records were modified during this audit.

---

## Source Documents Inspected & Explicit Availability Report

The following primary files were inspected line by line:
- [skill_tree_2_architecture_proposal.md](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/skill_tree_2_architecture_proposal.md) (and identical artifact copy in the session artifact directory)
- [families.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/v2/families.json) (31 Skill Families)
- [skills_rider_husbandry.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/v2/skills_rider_husbandry.json) (10 skills, 16 level standards)
- [skills_rider_in_hand.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/v2/skills_rider_in_hand.json) (9 skills, 14 level standards)
- [skills_rider_mounted.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/v2/skills_rider_mounted.json) (16 skills, 31 level standards)
- [skills_horse_in_hand.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/v2/skills_horse_in_hand.json) (7 skills, 13 level standards)
- [skills_horse_mounted.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/v2/skills_horse_mounted.json) (15 skills, 30 level standards)
- [legacy_mapping.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/v2/legacy_mapping.json) (84 legacy ID mappings)
- Prior design and batch review documents in the artifact directory ([skill_tree_curriculum_proposal.md](file:///home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/skill_tree_curriculum_proposal.md), [skill_tree_ux_redesign_proposal.md](file:///home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/skill_tree_ux_redesign_proposal.md), and Batches 0A–0E review artifacts)

> [!IMPORTANT]
> **Explicit Document Availability Notice:** A standalone **"Skill Tree Guide"** document is **not present** in the repository (`docs/` contains only [state_management.md](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/state_management.md), and the repository root contains only [skill_tree_2_architecture_proposal.md](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/skill_tree_2_architecture_proposal.md), `README.md`, `TESTING.md`, and `TEST_AUDIT.md`). Curriculum guidance was therefore audited against [skill_tree_2_architecture_proposal.md](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/skill_tree_2_architecture_proposal.md), [skill_tree_curriculum_proposal.md](file:///home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/skill_tree_curriculum_proposal.md), and the Batch 0A–0E trainer review records.

---

## A. Executive Assessment

### 1. Overall Curriculum Quality
Skill Tree 2.0 is a major structural and pedagogical upgrade over the legacy 84-skill flat list. Consolidating the 84 legacy records (plus Horse Ground Driving) into **57 canonical skills** and **104 progressive difficulty standards** successfully eliminates artificial fragmentation (such as separate skills for picking hooves vs. brushing, or separate skills for straight lines, 20 m circles, and slaloms) while preserving 100% backward compatibility with `Resource.skillTreeIds` via `legacyIds`.

### 2. Major Strengths
- **Clean Separation of Trackable Abilities vs. Educational Components:** Sub-tasks (such as hoof picking within `Grooming`, girth checking within `Tack Use, Fit & Care`, and halting on a mark within `Transitions`) are preserved as searchable educational `components` rather than separate checkboxes.
- **Faithful Execution of Trainer-Approved Consolidations:**
  - `Steering & Navigation` (`rider.mounted.steering_navigation` and `horse.mounted.steering_navigation`) cleanly unifies lines, circles, figures, and marker patterns across `Introductory` (walk), `Intermediate` (trot), and `Advanced` (canter).
  - `Terrain & Obstacle Negotiation` and `Object Handling` follow the same intuitive gait-and-complexity progression with explicit safety guardrails ("never require unsafe gaits for an object" and "know when to slow down").
  - `Shoulder-In` offers an achievable `Intermediate` standard at walk (including shoulder-fore) and reserves sustained trot shoulder-in along a full long side for `Advanced`.
  - Both `Turn on the Forehand` and `Turn on the Haunches` include `Introductory` standards so riders and horses can learn the basic movement before refining pivot compactness at `Intermediate`.
- **Strong Horse vs. Rider Separation:** Unlike the legacy snapshot (where 46 of 52 Rider skills graded the horse's temperament), V2 Rider skills consistently specify *"on a cooperative horse"* or *"a reasonably prepared horse"* and focus on human posture, timing, preparation, and safety.
- **Technique Neutrality & Cross-Discipline Accessibility:** Descriptions avoid dogmatic pressure-escalation formulas or gadget requirements, and `aliases` bridge Classical/English, Western/Ranch, Working Equitation, and Natural Horsemanship vocabulary.

### 3. Most Important Concerns to Address Before Publishing
1. **Thirteen Single-Skill Families & Four Empty Families (17 of 31 Families):**
   - Because the Browse UI presents collapsible **Skill Family** cards, having **13 families that open to reveal only a single skill** creates unnecessary tap friction and structural imbalance. Most visibly, `horse.in_hand.travel_environments` (*Travel & New Environments*) contains only `Trailer Loading`, and `horse.in_hand.work_on_line` (*Work on the Line*) contains only `Ground Driving`.
   - Furthermore, all **4 Rider Theory & Knowledge families** (`rider.theory.*`) exist in `families.json` with **zero authored skills**, causing the *Theory & Knowledge* category to appear empty or non-functional unless hidden or populated.
2. **Difficulty-Progression Gaps on Core Skills (`Leading`, `Longeing`, `Transitions`):**
   - **`rider.in_hand.leading` (Introductory)** bundles *leading at trot* and *backing up* into `Introductory`, whereas its direct counterpart **`horse.in_hand.leading`** places *leading at trot* in `Intermediate`. A novice handler who can safely lead at walk/halt cannot be marked `Proficient` at `Introductory` until they also trot in-hand.
   - **`rider.in_hand.longeing`** starts at `Intermediate` and requires **walk, trot, AND canter** on the longe in both directions at that first available level. Longeing at walk and trot is a foundational milestone long before a handler is ready to longe at canter; either `Introductory` (walk/trot on a trained horse) should be added or canter should move to `Advanced`.
   - **`rider.mounted.transitions`** starts at `Intermediate` (unlike `horse.mounted.transitions`, which has `Introductory`, `Intermediate`, and `Advanced`), leaving beginner riders with no `Introductory` Transitions benchmark for basic halt–walk–trot coordination.
3. **In-Hand vs. Mounted Naming & Level Asymmetry on Forequarter/Hindquarter Yields:**
   - `rider.in_hand.turn_on_forehand` is named *Turn on the Forehand (In-Hand)* and offers `Introductory` + `Intermediate`, whereas its forehand counterpart `rider.in_hand.yield_forequarters` is named *Yield the Forequarters (In-Hand)* and offers **only `Intermediate`** (even though mounted `Turn on the Haunches` offers `Introductory` + `Intermediate`).
   - Worse, **Horse → In-Hand has no skill at all** for yielding the hindquarters, yielding the forequarters, or sidepassing in-hand—nor does it have a counterpart for `rider.in_hand.longeing` or `rider.in_hand.obstacles_outings`.
4. **Residual Rider/Horse Outcome Wording in 8 Skills:**
   - A small number of Rider `proficient` rubrics still require the horse to achieve a state (*"without the horse drifting"*, *"improving the horse's posture and responsiveness"*, *"loads a horse calmly"*) rather than grading how the rider/handler prepares, cues, and adjusts when a horse drifts or hesitates. Conversely, two Horse skills (`horse.mounted.steering_navigation` and `horse.mounted.rein_back`) reference arena pattern geometry (*"~20 m circles, and simple marker patterns"*, *"through an L or corridor"*) without clarifying that the rider steers the pattern while the horse is assessed on alignment, bend, and responsiveness.
5. **High-Value Foundational Gaps:**
   - Rider `Position, Balance & Safety` contains only `Mounting & Dismounting`; there is no skill for **Rider Seat, Position & Independent Balance** (or two-point / stirrup recovery / emergency stop).
   - **Horse → In-Hand** lacks counterparts for **Longeing**, **In-Hand Yielding (Forequarters/Hindquarters/Sidepass)**, and **In-Hand Obstacles & Novel Environments**.

---

## B. Current vs. Recommended Skill Family Structure

### Summary of Structural Findings Across All 31 Families
In the current collapsible-family UI, a Skill Family works best when it groups **2 to 5 related skills**. Currently:
- **4 families have 0 skills** (`rider.theory.*`)
- **13 families have only 1 skill**
- **14 families have 2 to 6 skills**

Below is the category-by-category evaluation and recommended family structure.

### 1. Rider → Husbandry (Current: 5 Families, 10 Skills → Recommended: 4 Families, 10 Skills)

| Current Family (`id`) | Current Skills (Count) | Assessment | Recommended Family Structure | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Safety & Handling** (`rider.husbandry.safety_handling`) | `Safe Handling & Restraint` (**1**) | Single-skill family. Closely tied to daily stall/barn routines or daily care. | **Option A (Recommended):** Merge into **Daily Care, Safety & Grooming** (` Safe Handling & Restraint`, `Grooming`, `Blanketing` — 3 skills).<br>**Option B:** Keep separate only if `Emergency & Barn Safety` is added later. | Eliminates a 1-skill accordion in Husbandry while keeping `Safe Handling & Restraint` at `sortOrder: 10` at the top of the first family. |
| **Daily Care & Grooming** (`rider.husbandry.daily_care_grooming`) | `Grooming`, `Blanketing` (**2**) | Cohesive and intuitive. | Combine with `Safe Handling & Restraint` as **Daily Care, Safety & Grooming** (3 skills), or retain if Option B is chosen. | Grouping approach/tying safety with grooming and blanketing matches the actual pre-/post-ride barn workflow. |
| **Health & First Aid** (`rider.husbandry.health_first_aid`) | `Health Monitoring`, `First Aid`, `Administering Medications`, `Leg Wraps & Bandaging` (**4**) | **Strong.** Well-sized (4 skills), clear scope, logical progression from daily observation to medical care. | **Retain as-is** (`Health & First Aid`, 4 skills). | Ideal family size and clear thematic cohesion. |
| **Feeding & Stable Management** (`rider.husbandry.feeding_stable`) | `Feeding`, `Stable Care` (**2**) | **Strong.** Natural pair covering nutrition, hydration, stall cleaning, and facility hazard checks. | **Retain as-is** (`Feeding & Stable Management`, 2 skills). | Clear everyday barn-management grouping. |
| **Tack & Equipment** (`rider.husbandry.tack_equipment`) | `Tack Use, Fit & Care` (**1**) | Single-skill family. While tack is conceptually distinct, a 1-skill family adds an extra tap. | **Retain as `Tack & Equipment`** (1 skill for now, expandable to auxiliary/protective gear or travel gear later), **or** move `Leg Wraps & Bandaging` (or polo/boot application) cross-reference here. | Trainers and riders look specifically for "Tack" as a top-level Husbandry heading; keeping this family is justifiable even with 1 broad skill, provided the trainer prefers topical clarity over strict minimum family size. |

### 2. Rider → In-Hand (Current: 4 Families, 9 Skills → Recommended: 4 Families, 9 Skills)

| Current Family (`id`) | Current Skills (Count) | Assessment | Recommended Family Structure | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Haltering & Leading** (`rider.in_hand.haltering_leading`) | `Catching, Haltering & Turnout`, `Leading` (**2**) | **Strong.** Natural entry point for all groundwork. | **Retain as-is** (2 skills). | Clear foundational progression. |
| **Ground Control & Yielding** (`rider.in_hand.ground_control_yielding`) | `Turn on the Forehand (In-Hand)`, `Yield the Forequarters (In-Hand)`, `Sidepass (In-Hand)` (**3**) | **Strong.** Cohesive body-control group; only skill naming/level symmetry needs tuning. | **Retain as-is** (3 skills). | Matches the Mounted `Pivots & Body Control` family. |
| **Longeing & Long-Lining** (`rider.in_hand.longeing_long_lining`) | `Longeing`, `Ground Driving` (**2**) | **Strong.** Clear distinction between work on lines vs. leading beside the horse. | **Retain as-is** (2 skills), or align name with Horse counterpart (`Work on the Line: Longeing & Ground Driving`). | Parallel naming between Rider and Horse In-Hand families improves cross-navigation. |
| **Obstacles, Outings & Travel** (`rider.in_hand.obstacles_outings_travel`) | `In-Hand Obstacles & Outings`, `Trailer Loading` (**2**) | **Strong.** Pairs environmental confidence with transport. | **Retain as-is** (2 skills). | Provides the exact template that `Horse → In-Hand → Travel & New Environments` should mirror. |

### 3. Rider → Mounted (Current: 7 Families, 16 Skills → Recommended: 5 or 6 Families, 16–18 Skills)

| Current Family (`id`) | Current Skills (Count) | Assessment | Recommended Family Structure | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Position, Balance & Safety** (`rider.mounted.position_balance_safety`) | `Mounting & Dismounting` (**1**) | **Underpopulated.** The family name promises *Position, Balance & Safety*, but contains only *Mounting & Dismounting*. | **Add `Rider Position & Independent Seat`** (and optionally `Emergency Control & Fall Risk Reduction`), **OR** rename/merge until position skills are authored. | A family named *Position, Balance & Safety* with only `Mounting & Dismounting` feels incomplete to riders and instructors. |
| **Gaits, Rhythm & Transitions** (`rider.mounted.gaits_rhythm_transitions`) | `Walk`, `Trot`, `Canter`, `Transitions`, `Half-Halt (Rebalancing)` (**5**) | **Excellent.** Cohesive, complete, and logically ordered. | **Retain as-is** (5 skills). | Forms the core spine of mounted riding. |
| **Steering, Bend & Direction Changes** (`rider.mounted.steering_bend_direction`) | `Steering & Navigation` (**1**) | **Single-skill family** resulting from merging `Steering & Arena Figures` and `Navigation Patterns`. | **Option A (Recommended if keeping 1 skill):** Rename family to **Steering & Navigation** or merge with **Terrain, Obstacles & Object Handling** only if desired.<br>**Option B:** Keep family and add `Lead Changes & Counter-Canter` when ready. | Having a family named *Steering, Bend & Direction Changes* that expands to a single skill named *Steering & Navigation* is redundant unless a second skill is planned. |
| **Pivots & Body Control** (`rider.mounted.pivots_body_control`) | `Turn on the Forehand`, `Turn on the Haunches`, `Rein Back`, `Sidepass` (**4**) | **Excellent.** Clear biomechanical boundary (stationary, backward, or pure 90° lateral). | **Retain as-is** (4 skills). | Well-differentiated from forward-and-sideways `Lateral Movements`. |
| **Lateral Movements** (`rider.mounted.lateral_movements`) | `Leg Yield`, `Shoulder-In`, `Travers (Haunches-In)` (**3**) | **Excellent.** Clean classical/gymnastic progression (`Intermediate` → `Advanced`). | **Retain as-is** (3 skills). | Ready for future `Renvers` and `Half-Pass` without restructuring. |
| **Terrain & Obstacles** (`rider.mounted.terrain_obstacles`) | `Terrain & Obstacle Negotiation` (**1**) | **Single-skill family.** | **Merge with `Object Handling` into one family: `Trail, Obstacles & Object Handling`** (containing `Terrain & Obstacle Negotiation` and `Object Handling` — **2 skills**). | Preserves `Terrain & Obstacle Negotiation` and `Object Handling` as separate multi-level skills while eliminating two consecutive 1-skill families at the bottom of the Mounted list. |
| **Object Handling** (`rider.mounted.object_handling`) | `Object Handling` (**1**) | **Single-skill family** (family name and skill name are identical: `Object Handling` → `Object Handling`). | Merge into **`Trail, Obstacles & Object Handling`** (2 skills total). | Prevents the user from tapping a family titled *Object Handling* only to see a single child card also titled *Object Handling*. |

### 4. Rider → Theory & Knowledge (`Other`) (Current: 4 Families, 0 Skills)

| Current Family (`id`) | Current Skills (Count) | Assessment | Recommended Family Structure | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **How Horses Learn** (`rider.theory.learning`)<br>**Behavior & Body Language** (`rider.theory.behavior`)<br>**Movement & Training Principles** (`rider.theory.movement_training`)<br>**Welfare, Ethics & Ownership** (`rider.theory.welfare_ethics`) | **0 skills** across all 4 families | **Critical Launch Gap.** The 4 families are defined in `families.json`, so the UI renders the *Theory & Knowledge* category chip and 4 empty families (or empty state), with zero skills to browse. | **Before launch, either:**<br>1. **Author 1–2 foundational multi-level skills per family** (4–8 skills total, e.g., `Equine Learning Theory (R- & R+)`, `Reading Equine Body Language & Pain`, `Biomechanics & the Training Scale`, `Equine Welfare & Emergency Readiness`), **OR**<br>2. **Hide empty families / the `Other` category in the UI** until Theory skills are published. | Shipping 4 empty families in production makes the feature appear unfinished. |

### 5. Horse → In-Hand (Current: 4 Families, 7 Skills → Recommended: 4 Families, 9–10 Skills)

> [!WARNING]
> **Special Focus — `Horse → In-Hand → Travel & New Environments` (`horse.in_hand.travel_environments`) and `Work on the Line` (`horse.in_hand.work_on_line`):**
> Currently, `Travel & New Environments` contains **only `Trailer Loading`**, even though its description promises *"Loading, hauling, and navigating unfamiliar obstacles and locations calmly in-hand."* Meanwhile, `Rider → In-Hand → Obstacles, Outings & Travel` has two skills (`In-Hand Obstacles & Outings` and `Trailer Loading`), leaving `rider.in_hand.obstacles_outings` with **no Horse counterpart**! Similarly, `Work on the Line` promises *"Moving on a circle or in long lines from the ground,"* but contains only `Ground Driving` (no `Longeing` counterpart for horses).

| Current Family (`id`) | Current Skills (Count) | Assessment | Recommended Family Structure | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Leading & Ground Manners** (`horse.in_hand.leading_manners`) | `Leading & Halter Response`, `Standing Quietly` (**2**) | Good foundation, or can include in-hand yielding (`Yielding & Body Control In-Hand`) if not given its own family. | **Retain `Leading & Ground Manners`** (2–3 skills; add `In-Hand Yielding & Body Control` here or as a sibling skill). | Gives horse owners a place to track whether their horse yields its hindquarters, forequarters, and sidepasses from the ground. |
| **Handling & Care** (`horse.in_hand.cooperative_care`) | `Daily Care Handling`, `Hoof Handling`, `Veterinary & Medical Handling` (**3**) | **Excellent.** Recently renamed to *Handling & Care*; well-balanced 3-skill family. | **Retain as-is** (3 skills). | Cleanly mirrors Rider Husbandry from the horse's behavioral perspective. |
| **Travel & New Environments** (`horse.in_hand.travel_environments`) | `Trailer Loading` (**1**) | **Mismatch between family name/description and content.** Contains only `Trailer Loading`; lacks a Horse counterpart to `rider.in_hand.obstacles_outings`. | **Add `In-Hand Obstacles & Outings (Horse)`** (`horse.in_hand.obstacles_outings`, `Introductory` + `Intermediate`) alongside `Trailer Loading` (making **2 skills**), **OR** if no new skill is added, merge `Trailer Loading` into `Leading & Ground Manners` and retire the 1-skill family. | Adding `horse.in_hand.obstacles_outings` fulfills the family's stated description (*"navigating unfamiliar obstacles and locations calmly in-hand"*), gives `rider.in_hand.obstacles_outings` its missing counterpart, and turns a 1-skill family into a cohesive 2-skill family matching Rider In-Hand. |
| **Work on the Line** (`horse.in_hand.work_on_line`) | `Ground Driving` (**1**) | **Single-skill family.** Family description explicitly mentions *"Moving on a circle or in long lines from the ground,"* yet `Longeing (Horse)` is missing. | **Add `Longeing (Horse)`** (`horse.in_hand.longeing`, `Introductory` walk/trot + `Intermediate` canter/transitions) alongside `Ground Driving` (**2 skills**). | Completes the family description and gives `rider.in_hand.longeing` its missing Horse counterpart. |

### 6. Horse → Mounted (Current: 7 Families, 15 Skills → Recommended: 5 or 6 Families, 15 Skills)

| Current Family (`id`) | Current Skills (Count) | Assessment | Recommended Family Structure | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Standing & Mounting Manners** (`horse.mounted.standing_mounting_manners`) | `Standing Under Saddle` (**1**) | Single-skill family. | **Option A:** Move `Standing Under Saddle` to the top of `Gaits, Rhythm & Transitions` (`sortOrder: 5`).<br>**Option B:** Keep if parallel 1:1 family structure with Rider Mounted is prioritized. | `Standing Under Saddle` is the stationary counterpart to halt/gaits; folding it into `Gaits, Rhythm & Transitions` removes a 1-skill family unless strict family parity with Rider is preferred. |
| **Gaits, Rhythm & Transitions** (`horse.mounted.gaits_rhythm_transitions`) | `Walk (Under Saddle)`, `Trot (Under Saddle)`, `Canter (Under Saddle)`, `Transitions (Under Saddle)` (**4**) | **Excellent.** Cleanly folds `respond_half_halt` and `halt_under_saddle` into `Transitions (Under Saddle)`. | **Retain as-is** (4 skills, or 5 if `Standing Under Saddle` is merged in). | Cohesive and well-structured. |
| **Steering, Bend & Direction Changes** (`horse.mounted.steering_bend_direction`) | `Steering & Navigation (Under Saddle)` (**1**) | Single-skill family (same as Rider Mounted). | Align with Rider Mounted decision (rename or keep if adding `Lead Changes`). | Maintain Rider/Horse family symmetry. |
| **Pivots & Body Control** (`horse.mounted.pivots_body_control`) | `Turn on the Forehand (Under Saddle)`, `Turn on the Haunches (Under Saddle)`, `Rein Back (Under Saddle)`, `Sidepass (Under Saddle)` (**4**) | **Excellent.** | **Retain as-is** (4 skills). | Exact counterpart symmetry with Rider Mounted. |
| **Lateral Movements** (`horse.mounted.lateral_movements`) | `Leg Yield (Under Saddle)`, `Shoulder-In (Under Saddle)`, `Travers (Haunches-In, Under Saddle)` (**3**) | **Excellent.** | **Retain as-is** (3 skills). | Exact counterpart symmetry with Rider Mounted. |
| **Terrain & Obstacles** (`horse.mounted.terrain_obstacles`) & **Object Handling** (`horse.mounted.object_handling`) | `Terrain & Obstacle Negotiation (Under Saddle)` (**1**) and `Object Handling (Under Saddle)` (**1**) | Two consecutive 1-skill families. | **Merge into `Trail, Obstacles & Object Handling`** (2 skills), mirroring Rider Mounted. | Eliminates two 1-skill accordions while preserving both skills intact. |

---

## C. Skill-Level Audit (All 57 Skills & 104 Level Standards)

**Legend for Audit Status:**
- **Pass:** Sound organization, level progression, and technique-neutral, subject-appropriate wording.
- **Minor Refine:** Sound structure, but wording or component clarity should be tightened (see Section D).
- **Level / Structure Change:** Recommended addition/adjustment of difficulty levels or family placement (see Section E).

### C.1 Rider → Husbandry (10 Skills, 16 Levels)

| # | Skill ID & Name | Family | Levels Offered | Audit Status | Concise Assessment of Organization, Levels & Wording |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `rider.husbandry.safe_handling`<br>**Safe Handling & Restraint** | `safety_handling` | `Intro`, `Int` | **Pass** | Clean progression from familiar-space approach/quick-release tying (`Intro`) to managing startled horses and busy spaces (`Int`). |
| 2 | `rider.husbandry.grooming`<br>**Grooming** | `daily_care_grooming` | `Intro`, `Int` | **Pass** | Exemplary V2 skill: integrates hoof picking (`Intro`) and bathing/seasonal coat care (`Int`) as components without separate checkboxes. |
| 3 | `rider.husbandry.blanketing`<br>**Blanketing** | `daily_care_grooming` | `Intro`, `Int` | **Pass** | `Intro` covers safe strap order (`chest → belly → hind legs`) and removal; `Int` covers blanket weight selection, rub/fit checks, and care. |
| 4 | `rider.husbandry.health_monitoring`<br>**Health Monitoring** | `health_first_aid` | `Intro`, `Int` | **Pass** | `Intro` covers daily appetite/manure/behavior observation; `Int` covers TPR (temperature, pulse, respiration), gums, digital pulses, and emergency recognition. |
| 5 | `rider.husbandry.first_aid`<br>**First Aid** | `health_first_aid` | `Int` | **Level Change** | Good `Int` standard, but lacks an **`Introductory`** level for basic wound/emergency recognition, knowing what *not* to do, and calling the vet/barn manager. |
| 6 | `rider.husbandry.medications`<br>**Administering Medications** | `health_first_aid` | `Int` | **Pass** | Appropriately `Intermediate`: covers dose/label verification, oral syringes, medicated feeds, and topical treatments. |
| 7 | `rider.husbandry.leg_wraps`<br>**Leg Wraps & Bandaging** | `health_first_aid` | `Int` | **Pass** | Appropriately `Intermediate` (due to tendon-bowing risk from uneven pressure); covers polo/standing/shipping wraps and boots. |
| 8 | `rider.husbandry.feeding`<br>**Feeding** | `feeding_stable` | `Intro`, `Int` | **Pass** | `Intro` covers following a feed chart, clean water, and group safety; `Int` covers forage evaluation, body condition, and gradual ration transitions. |
| 9 | `rider.husbandry.stable_care`<br>**Stable Care** | `feeding_stable` | `Intro` | **Pass** | Practical `Intro` standard covering mucking, bedding, water buckets, and physical hazard checks. Single level is appropriate. |
| 10 | `rider.husbandry.tack`<br>**Tack Use, Fit & Care** | `tack_equipment` | `Intro`, `Int` | **Pass** | Successfully incorporates tacking up/untacking, pre-ride safety checks, and cleaning (`Intro`) plus static/dynamic fit evaluation (`Int`). |

### C.2 Rider → In-Hand (9 Skills, 14 Levels)

| # | Skill ID & Name | Family | Levels Offered | Audit Status | Concise Assessment of Organization, Levels & Wording |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 11 | `rider.in_hand.catch_halter_turnout`<br>**Catching, Haltering & Turnout** | `haltering_leading` | `Intro`, `Int` | **Pass** | `Intro` covers quiet catching, haltering, and turning out to face the gate; `Int` covers group pastures, gate herd dynamics, and reluctant horses. |
| 12 | `rider.in_hand.leading`<br>**Leading** | `haltering_leading` | `Intro`, `Int` | **Level / Wording Change** | **Asymmetry:** `Intro` requires leading at **trot** in addition to walk, halt, turns, and backing, whereas `horse.in_hand.leading` puts trot in `Intermediate`. Move in-hand trot to `Intermediate` (or make `Intro` walk/halt/turn/back and `Int` trot, inspection, and busy venues). |
| 13 | `rider.in_hand.turn_on_forehand`<br>**Turn on the Forehand (In-Hand)** | `ground_control_yielding` | `Intro`, `Int` | **Minor Refine** | Good 2-level structure (`Intro` 90–180° step-across; `Int` 180–360° rhythmic pivot). Lacks a `counterpart` link because Horse In-Hand has no hindquarter-yield skill. |
| 14 | `rider.in_hand.yield_forequarters`<br>**Yield the Forequarters (In-Hand)** | `ground_control_yielding` | `Int` | **Level / Wording Change** | **Naming & Level Asymmetry:** Named *Yield the Forequarters (In-Hand)* while #13 is named *Turn on the Forehand (In-Hand)*, and offers only `Intermediate` while mounted `Turn on the Haunches` offers `Intro` + `Int`. Add `Introductory` (yielding 1–3 steps of the forehand) and harmonize title/aliases. |
| 15 | `rider.in_hand.sidepass_in_hand`<br>**Sidepass (In-Hand)** | `ground_control_yielding` | `Int` | **Pass** | Appropriate `Intermediate` standard (open space and over a ground pole). Note: legacy difficulty was `Advanced`, down-leveled to `Intermediate` to match mounted `Sidepass`. |
| 16 | `rider.in_hand.longeing`<br>**Longeing** | `longeing_long_lining` | `Int`, `Adv` | **Level / Wording Change** | **Major Jump:** `Intermediate` (first available level) requires walk, trot, **and canter** in both directions. Many handlers safely longe at walk/trot long before cantering on the longe. Also, `Adv` `proficient` grades horse output (*"visibly improving the horse's balance and relaxation"*). |
| 17 | `rider.in_hand.ground_driving`<br>**Ground Driving** | `longeing_long_lining` | `Int`, `Adv` | **Pass** | Exemplary progression: `Int` covers safe walk/halt/turns in an enclosed area on an experienced horse; `Adv` covers walk/trot figures, transitions, and varied settings. |
| 18 | `rider.in_hand.obstacles_outings`<br>**In-Hand Obstacles & Outings** | `obstacles_outings_travel` | `Intro`, `Int` | **Pass** | `Intro` covers poles, tarps, bridges, and narrow passages in-hand; `Int` covers water, uneven terrain, and hand-walking on trails/roads. (Needs a Horse counterpart.) |
| 19 | `rider.in_hand.trailer_loading`<br>**Trailer Loading** | `obstacles_outings_travel` | `Int` | **Minor Refine / Level Check** | `Int` `proficient` says *"Independently prepares a safe trailer, loads a horse calmly..."*—should specify *"a reasonably prepared horse"* so the handler isn't graded on rehabilitating a severe trailer-refuser at `Intermediate`. Consider adding `Intro` (trailer safety checks & assisted loading/unloading). |

### C.3 Rider → Mounted (16 Skills, 31 Levels)

| # | Skill ID & Name | Family | Levels Offered | Audit Status | Concise Assessment of Organization, Levels & Wording |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 20 | `rider.mounted.mounting`<br>**Mounting & Dismounting** | `position_balance_safety` | `Intro` | **Minor Refine** | Good `Intro` standard. Consider whether `Intermediate` (mounting from the ground on either side, adjusting girth/stirrups while mounted, emergency dismount) is warranted, or keep `Intro` only. |
| 21 | `rider.mounted.walk`<br>**Walk** | `gaits_rhythm_transitions` | `Intro`, `Int` | **Pass** | `Intro` = following the four-beat walk in balance; `Int` = adjusting working vs. free walk stride length and energy. |
| 22 | `rider.mounted.trot`<br>**Trot** | `gaits_rhythm_transitions` | `Intro`, `Int` | **Minor Refine** | `Intro` = functional balance in posting, sitting, or two-point; `Int` = diagonals, sitting trot, and tempo. Note: `Aliases` omit `"Jog"` and `"Two-point"` (add to `aliases`). |
| 23 | `rider.mounted.canter`<br>**Canter** | `gaits_rhythm_transitions` | `Intro`, `Int` | **Pass** | `Intro` explicitly states *"Correct lead selection is not required at this level"*; `Int` requires intended leads in both directions and 20 m circles. |
| 24 | `rider.mounted.transitions`<br>**Transitions** | `gaits_rhythm_transitions` | `Int`, `Adv` | **Level Change** | **Missing `Introductory` level:** `horse.mounted.transitions` has `Intro` + `Int` + `Adv`, but `rider.mounted.transitions` has only `Int` + `Adv`. Add `Introductory` (basic halt–walk–trot transitions with smooth preparation). |
| 25 | `rider.mounted.half_halt`<br>**Half-Halt (Rebalancing)** | `gaits_rhythm_transitions` | `Int` | **Minor Refine** | Technique-neutral and clear, but `proficient` says *"improving the horse's posture and responsiveness without breaking rhythm"* (grades horse outcome; refine to focus on rider coordination, release, and feel). |
| 26 | `rider.mounted.steering_navigation`<br>**Steering & Navigation** | `steering_bend_direction` | `Intro`, `Int`, `Adv` | **Pass** | Clean walk (`Intro`) → trot (`Int`) → canter (`Adv`) progression unifying straight lines, 20 m circles, serpentines, and cone/marker patterns. |
| 27 | `rider.mounted.turn_on_forehand`<br>**Turn on the Forehand** | `pivots_body_control` | `Intro`, `Int` | **Minor Refine** | `Intro` = 90–180° from halt/slow walk; `Int` = 180–360° with steady pivot and seamless walk transitions. In `Int` `proficient`, refine *"with steady forehand placement, no backward steps"* to reflect rider aid balance on a prepared horse. |
| 28 | `rider.mounted.turn_on_haunches`<br>**Turn on the Haunches** | `pivots_body_control` | `Intro`, `Int` | **Pass** | `Intro` = calm small-arc turn from walk without spinning/backing; `Int` = compact (~1 m) turn with four-beat rhythm and soft bend. Note: `relatedSkills` links `half_halt` at `intermediate`; clarify that this applies primarily to `Int`. |
| 29 | `rider.mounted.rein_back`<br>**Rein Back** | `pivots_body_control` | `Int`, `Adv` | **Level Check** | `Int` bundles both *3–5 straight diagonal backward steps* AND *backing through an L or corridor*. Consider adding `Introductory` for 2–4 calm straight backward steps from halt, leaving straight diagonal refinement + L/corridor steering for `Intermediate`. |
| 30 | `rider.mounted.sidepass`<br>**Sidepass** | `pivots_body_control` | `Int` | **Pass** | Unifies open-space sidepass and sidepass over a ground rail at `Intermediate`. |
| 31 | `rider.mounted.leg_yield`<br>**Leg Yield** | `lateral_movements` | `Int` | **Level Check** | `Intermediate` requires leg yield at **both walk and trot**. As noted in earlier curriculum discussions, riders learn the timing of leg yield at the four-beat walk before coordinating it at the two-beat trot; see Section E on whether walk-only should be `Introductory` or whether `Intermediate` walk+trot is preferred. |
| 32 | `rider.mounted.shoulder_in`<br>**Shoulder-In** | `lateral_movements` | `Int`, `Adv` | **Minor Refine** | Follows approved progression (`Int` = walk shoulder-fore/shoulder-in, *"Trot proficiency is not required"*; `Adv` = sustained trot along a full long side). In `Int` `proficient`, refine *"moving forward along the line without drifting"* so it evaluates rider alignment aids rather than horse perfection. |
| 33 | `rider.mounted.travers`<br>**Travers (Haunches-In)** | `lateral_movements` | `Adv` | **Pass** | Accurately describes inward bend in the direction of travel on three or four tracks at walk and trot. |
| 34 | `rider.mounted.terrain_obstacles`<br>**Terrain & Obstacle Negotiation** | `terrain_obstacles` | `Intro`, `Int`, `Adv` | **Pass** | Excellent walk (`Intro`) → trot/natural water/slopes (`Int`) → canter lines + safety judgment (`Adv`) progression. |
| 35 | `rider.mounted.object_handling`<br>**Object Handling** | `object_handling` | `Intro`, `Int`, `Adv` | **Minor Refine** | Excellent progression (`Intro` simple objects/assisted gate at halt/walk; `Int` full gate pass-through at halt/walk + trot object carrying; `Adv` canter object interactions where safe). In `Adv` `proficient`, refine *"and calm horse responsiveness"*. |

### C.4 Horse → In-Hand (7 Skills, 13 Levels)

| # | Skill ID & Name | Family | Levels Offered | Audit Status | Concise Assessment of Organization, Levels & Wording |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 36 | `horse.in_hand.leading`<br>**Leading & Halter Response** | `leading_manners` | `Intro`, `Int` | **Pass** | Better leveled than Rider `Leading`: `Intro` = halter softness (forward, halt, back, turn) + polite walk leading; `Int` = trot-up and busier environments. |
| 37 | `horse.in_hand.standing_quietly`<br>**Standing Quietly** | `leading_manners` | `Intro`, `Int`, `Adv` | **Pass** | Clean 3-level progression: `Intro` = tied in familiar setting; `Int` = tied at trailers/busy venues; `Adv` = ground-tying in enclosed/safe area. |
| 38 | `horse.in_hand.daily_care_handling`<br>**Daily Care Handling** | `cooperative_care` | `Intro`, `Int` | **Minor Refine** | Unifies standing for grooming, blanketing, bathing, and saddling (`Intro`) + clippers/sprays/busy wash stalls (`Int`). Note: putting full-body hosing/bathing in `Intro` when Rider `Grooming` puts bathing in `Int` is slightly asymmetric—clarify that `Intro` is basic leg/sponge rinsing or calm acceptance of familiar care. |
| 39 | `horse.in_hand.hoof_handling`<br>**Hoof Handling** | `cooperative_care` | `Intro`, `Int` | **Pass** | `Intro` = lifting and holding all four feet for daily cleaning; `Int` = standing patiently for complete farrier sessions. |
| 40 | `horse.in_hand.vet_handling`<br>**Veterinary & Medical Handling** | `cooperative_care` | `Int` | **Level Check** | Offers only `Intermediate`. Consider adding `Introductory` (accepting basic owner touch of gums, eyes, ears, and thermometer) vs. `Intermediate` (unfamiliar vet exam, stethoscope, oral syringe, and restraint in clinic/barn). |
| 41 | `horse.in_hand.trailer_loading`<br>**Trailer Loading** | `travel_environments` | `Int` | **Level / Family Change** | Sitting alone in `Travel & New Environments` (`horse.in_hand.travel_environments`). Also consider adding `Introductory` (walking over a ramp/platform or stepping calmly into a familiar open trailer for a meal/pause) below `Intermediate` (full loading, securing butt bar/doors, and unloading). |
| 42 | `horse.in_hand.ground_driving`<br>**Ground Driving** | `work_on_line` | `Intro`, `Int` | **Pass** | Exemplary asymmetric pairing with `rider.in_hand.ground_driving` (`Int`/`Adv`): `Intro` = line acceptance, walk, halt, turns in enclosed space; `Int` = walk/trot figures and varied settings. |

### C.5 Horse → Mounted (15 Skills, 30 Levels)

| # | Skill ID & Name | Family | Levels Offered | Audit Status | Concise Assessment of Organization, Levels & Wording |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 43 | `horse.mounted.standing`<br>**Standing Under Saddle** | `standing_mounting_manners` | `Intro`, `Int` | **Pass** | `Intro` = standing quietly at mounting block and during pauses in familiar spaces; `Int` = standing patiently in group rides and busy settings. |
| 44 | `horse.mounted.walk`<br>**Walk (Under Saddle)** | `gaits_rhythm_transitions` | `Intro`, `Int` | **Pass** | `Intro` = willing four-beat walk; `Int` = adjusting between active working walk and relaxed free walk. |
| 45 | `horse.mounted.trot`<br>**Trot (Under Saddle)** | `gaits_rhythm_transitions` | `Intro`, `Int` | **Minor Refine** | `Intro` = steady two-beat trot on lines and large turns; `Int` = balanced, adjustable tempo through turns and transitions. Add `"Jog under saddle"` to `aliases`. |
| 46 | `horse.mounted.canter`<br>**Canter (Under Saddle)** | `gaits_rhythm_transitions` | `Intro`, `Int` | **Pass** | `Intro` = calm depart and three-beat rhythm (lead not yet required); `Int` = reliable requested lead in both directions and 20 m circles. |
| 47 | `horse.mounted.transitions`<br>**Transitions (Under Saddle)** | `gaits_rhythm_transitions` | `Intro`, `Int`, `Adv` | **Pass** | Excellent 3-level progression (`Intro` halt/walk/trot responsiveness → `Int` walk/trot/canter + half-halt response → `Adv` direct and within-gait transitions). |
| 48 | `horse.mounted.steering_navigation`<br>**Steering & Navigation (Under Saddle)** | `steering_bend_direction` | `Intro`, `Int`, `Adv` | **Minor Refine** | Good 3-level structure, but `proficient` wording says *"Walks straight lines away from the rail, ~20 m circles, and simple marker patterns calmly on light steering requests"*—slightly conflates rider route-planning with horse responsiveness (see Section D). |
| 49 | `horse.mounted.turn_on_forehand`<br>**Turn on the Forehand (Under Saddle)** | `pivots_body_control` | `Intro`, `Int` | **Pass** | `Intro` = 90–180° relaxed hindquarter yield; `Int` = 180–360° rhythmic turn with steady forehand and smooth walk exit. |
| 50 | `horse.mounted.turn_on_haunches`<br>**Turn on the Haunches (Under Saddle)** | `pivots_body_control` | `Intro`, `Int` | **Pass** | `Intro` = generous forward walk arc around the haunches; `Int` = compact (~1 m) turn with active inside hind and soft bend. |
| 51 | `horse.mounted.rein_back`<br>**Rein Back (Under Saddle)** | `pivots_body_control` | `Int` | **Level / Wording Change** | **Asymmetry with Rider `Rein Back`:** Rider `Rein Back` offers `Int` + `Adv`, whereas Horse `Rein Back` offers only `Int`. Either add `Adv` (extended/curved backing and direct transitions to forward gaits) or `Intro` (2–4 calm straight steps back) to `horse.mounted.rein_back`. Also refine L-corridor wording to focus on the horse's alignment and responsiveness to shoulder/hip cues. |
| 52 | `horse.mounted.sidepass`<br>**Sidepass (Under Saddle)** | `pivots_body_control` | `Int` | **Pass** | Clear `Intermediate` standard for straight sideways steps in open space and over a ground pole. |
| 53 | `horse.mounted.leg_yield`<br>**Leg Yield (Under Saddle)** | `lateral_movements` | `Int` | **Pass** | Clear `Intermediate` standard for forward-and-sideways yielding at walk and trot. |
| 54 | `horse.mounted.shoulder_in`<br>**Shoulder-In (Under Saddle)** | `lateral_movements` | `Int`, `Adv` | **Pass** | Matches Rider `Shoulder-In`: `Int` = walk shoulder-fore/shoulder-in; `Adv` = sustained trot shoulder-in along a full long side. |
| 55 | `horse.mounted.travers`<br>**Travers (Haunches-In, Under Saddle)** | `lateral_movements` | `Adv` | **Pass** | Matches Rider `Travers`: true inward bend at walk and trot with forehand on the track and hindquarters carried inward. |
| 56 | `horse.mounted.terrain_obstacles`<br>**Terrain & Obstacle Negotiation (Under Saddle)** | `terrain_obstacles` | `Intro`, `Int`, `Adv` | **Pass** | Clear walk (`Intro`), trot/natural water (`Int`), and adjustable canter/technical down-transition (`Adv`) standards focused on the horse's confidence and footwork. |
| 57 | `horse.mounted.object_handling`<br>**Object Handling (Under Saddle)** | `object_handling` | `Intro`, `Int`, `Adv` | **Pass** | Clear focus on the horse's patience, stillness at gates, and composure around carried/manipulated objects across halt/walk (`Intro`), trot (`Int`), and canter (`Adv`). |

---

## D. Proposed Wording Improvements

For every skill with Rider/Horse boundary blur, gait bundling, or naming inconsistency, the table below shows the exact existing text alongside the recommended replacement.

### 1. `rider.in_hand.leading` — Leading (Introductory & Intermediate)
- **Issue:** `Introductory` currently requires leading at **trot** (`"at walk and trot"`), while `horse.in_hand.leading` places trot leading in `Intermediate`.
- **Existing (`introductory.overview` & `proficient`):**
  - *Overview:* `"Leading a cooperative horse safely at walk and trot, halting, turning Both ways, and backing up a few steps in familiar spaces."` *(Note also the capitalization typo `"turning Both ways"` at line 66 of `skills_rider_in_hand.json`.)*
  - *Proficient:* `"Independently leads a cooperative horse at walk and trot in balance, executes calm halts and turns in both directions, and guides several straight steps backward on light cues."`
- **Recommended (`introductory` & `intermediate`):**
  - *Introductory Overview:* `"Leading a cooperative horse safely at walk, halting, turning both ways, and backing up a few steps in familiar spaces."`
  - *Introductory Proficient:* `"Independently leads a cooperative horse at walk with safe handler positioning and slack in the line, executes calm halts and turns in both directions, and guides several straight steps backward on light cues."`
  - *Intermediate Overview:* `"Leading at trot, regulating space in busier environments, and presenting a horse neatly in-hand (such as for a trot-up or veterinary/breed inspection)."`
  - *Intermediate Proficient:* `"Independently leads at walk and a controlled trot, maintains safe spacing and composure in distracting environments, and presents the horse squarely and attentively for inspection."`

### 2. `rider.in_hand.yield_forequarters` — Yield the Forequarters (In-Hand)
- **Issue:** Title uses *"Yield the Forequarters (In-Hand)"* while its sibling `#13` is titled *"Turn on the Forehand (In-Hand)"*.
- **Existing (`name` & `aliases`):**
  - *Name:* `"Yield the Forequarters (In-Hand)"`
  - *Aliases:* `["Yield forequarters from the ground", "Move the shoulders over", "Turn on the haunches in-hand"]`
- **Recommended (`name` & `aliases`):**
  - *Name:* `"Yield the Forequarters / Turn on the Haunches (In-Hand)"` (or keep `"Yield the Forequarters (In-Hand)"` and rename `#13` to `"Yield the Hindquarters / Turn on the Forehand (In-Hand)"` so both In-Hand yielding skills use parallel naming).

### 3. `rider.in_hand.longeing` — Longeing (Advanced `proficient`)
- **Issue:** Grades whether the horse visibly improves (*"visibly improving the horse's balance and relaxation"*), which depends on the horse's soundness and temperament.
- **Existing (`advanced.proficient`):**
  - `"Independently longes with refined line/whip coordination, regulates circle size and transitions smoothly, and adapts the session to the horse's needs—visibly improving the horse's balance and relaxation."`
- **Recommended (`advanced.proficient`):**
  - `"Independently longes across walk, trot, and canter with refined line, voice, and whip coordination, regulates circle size and within-gait or direct transitions smoothly, and adapts the session thoughtfully to support the horse's balance and relaxation."`

### 4. `rider.in_hand.trailer_loading` — Trailer Loading (`intermediate.proficient`)
- **Issue:** Grades whether the horse loads calmly without qualifying that the horse is reasonably prepared.
- **Existing (`intermediate.proficient`):**
  - `"Independently prepares a safe trailer, loads a horse calmly, secures ties and bars in the correct sequence, and unloads smoothly while staying out of crush zones."`
- **Recommended (`intermediate.proficient`):**
  - `"Independently completes a pre-haul trailer safety check, guides a reasonably prepared horse to load and unload calmly while maintaining safe handler positioning out of crush zones, and secures bars/partitions and ties in the correct sequence."`

### 5. `rider.mounted.half_halt` — Half-Halt (Rebalancing) (`intermediate.proficient`)
- **Issue:** Grades the horse's resulting posture (*"improving the horse's posture and responsiveness without breaking rhythm"*).
- **Existing (`intermediate.proficient`):**
  - `"Independently uses subtle, timely rebalancing requests before turns and transitions, improving the horse's posture and responsiveness without breaking rhythm."`
- **Recommended (`intermediate.proficient`):**
  - `"Independently coordinates seat, core, leg, and brief rein feel before turns and transitions on a reasonably prepared horse, releasing promptly as the horse rebalances without blocking forward rhythm."`

### 6. `rider.mounted.turn_on_forehand` — Turn on the Forehand (`intermediate.proficient`)
- **Issue:** `"with steady forehand placement, no backward steps"` reads as a horse-execution guarantee rather than a rider-aid standard.
- **Existing (`intermediate.proficient`):**
  - `"Independently rides crisp, rhythmic turns on the forehand in both directions with steady forehand placement, no backward steps, and seamless walk transitions."`
- **Recommended (`intermediate.proficient`):**
  - `"Independently prepares and rides crisp, rhythmic 180–360° turns on the forehand in both directions on a prepared horse, coordinating inside leg and outside receiving aids to prevent forehand drift or backward steps and transitioning smoothly into and out of walk."`

### 7. `rider.mounted.shoulder_in` — Shoulder-In (`intermediate.proficient`)
- **Issue:** `"The horse moves forward along the line without drifting"` / `"moving forward along the line without drifting"` grades the horse's track rather than the rider's corridor of aids.
- **Existing (`intermediate.proficient`):**
  - `"Independently rides a recognizable, functional shoulder-fore or shoulder-in at walk in both directions, moving forward along the line without drifting and returning smoothly to straight. Trot proficiency is not required."`
- **Recommended (`intermediate.proficient`):**
  - `"Independently prepares and rides a recognizable, functional shoulder-fore or shoulder-in at walk in both directions on a prepared horse, coordinating inside leg and outside aids to maintain the line of travel and returning smoothly to straight. Trot proficiency is not required."`

### 8. `rider.mounted.object_handling` — Object Handling (`advanced.proficient`)
- **Issue:** Ends with `"and calm horse responsiveness"`, which is assessed on `horse.mounted.object_handling`.
- **Existing (`advanced.proficient`):**
  - `"Independently executes demanding object-handling sequences—including accurate interaction at canter where appropriate—with poised one-handed control, balanced posture, and calm horse responsiveness."`
- **Recommended (`advanced.proficient`):**
  - `"Independently executes demanding object-handling sequences—including accurate interaction at canter where safe and appropriate—with poised one-handed control, balanced posture, and clear, fair cues to the horse."`

### 9. `horse.mounted.steering_navigation` — Steering & Navigation (Under Saddle) (`introductory` & `intermediate`)
- **Issue:** Phrasing slightly implies the horse plans the 20 m circle or marker pattern, whereas the horse is responding to the rider's steering cues with alignment, bend, and rhythm.
- **Existing (`introductory.proficient` & `intermediate.proficient`):**
  - *Introductory:* `"Walks straight lines away from the rail, ~20 m circles, and simple marker patterns calmly on light steering requests without drifting."`
  - *Intermediate:* `"Maintains steady rhythm, soft uniform bend, and smooth changes of direction through trot figures and marker patterns without rushing."`
- **Recommended (`introductory.proficient` & `intermediate.proficient`):**
  - *Introductory:* `"Follows light rider steering cues calmly at walk along straight lines away from the rail, ~20 m circles, and simple marker paths without drifting, bulging through the shoulder, or drawing toward the rail/gate."`
  - *Intermediate:* `"Responds smoothly to the rider's directional and bend cues at trot across circles, serpentines, and marker patterns, maintaining steady rhythm and soft, uniform bend without rushing or falling inward."`

### 10. `horse.in_hand.daily_care_handling` — Daily Care Handling (`introductory.components`)
- **Issue:** Lists `"Bathing and tacking"` in `Introductory`, whereas `rider.husbandry.grooming` places bathing in `Intermediate`.
- **Existing (`introductory.components[1]`):**
  - `{"title": "Bathing and tacking", "description": "Accepting water/hosing and saddle/bridle placement without pinning ears, kicking, or evading."}`
- **Recommended (`introductory.components[1]`):**
  - `{"title": "Tacking and basic water rinsing", "description": "Accepting saddle/bridle placement and basic leg hosing or sponging calmly without pinning ears, kicking, or evading."}` *(Full-body bathing, sprays, and busy wash stalls remain in `Intermediate`.)*

---

## E. Difficulty-Level Corrections

The following table summarizes all recommended level additions and adjustments, with educational justification. None of these remove existing legacy mappings.

| Skill ID & Name | Current Levels | Recommended Levels | Educational Justification |
| :--- | :--- | :--- | :--- |
| **`rider.husbandry.first_aid`**<br>First Aid | `Int` | **`Intro`**, `Int` | **Add `Introductory`:** Every beginner rider/handler needs a baseline safety standard: recognizing obvious bleeding, swelling, lameness, or distress, staying safe around a painful horse, knowing where the first-aid kit and emergency numbers are, and calling the vet/trainer immediately before applying treatments. `Intermediate` remains hands-on wound cleaning, bandaging, and triage. |
| **`rider.in_hand.leading`**<br>Leading | `Intro`, `Int` | `Intro`, `Int` *(rebalance content)* | **Shift in-hand trot from `Intro` to `Int`:** Leading a horse at walk, halting, turning both ways, and backing a few steps is the true `Introductory` milestone (matching `horse.in_hand.leading`). Trotting in-hand alongside a horse requires greater handler coordination and pace control and belongs in `Intermediate` alongside inspection trot-ups. |
| **`rider.in_hand.yield_forequarters`**<br>Yield the Forequarters (In-Hand) | `Int` | **`Intro`**, `Int` | **Add `Introductory`:** Currently, `Turn on the Forehand (In-Hand)` has `Intro` + `Int`, and mounted `Turn on the Haunches` has `Intro` + `Int`, but `Yield the Forequarters (In-Hand)` has only `Int`. Adding `Introductory` (guiding 1–3 calm sideways steps of the forehand away from light pressure) gives beginners an achievable groundwork entry point before full 90–180° pivots at `Intermediate`. |
| **`rider.in_hand.longeing`**<br>Longeing | `Int`, `Adv` | **Option A:** **`Intro`**, `Int`, `Adv`<br>**Option B:** `Int` (walk/trot), `Adv` (canter + refinement) | **Separate Walk/Trot Longeing from Canter Longeing:** Requiring a handler to longe at walk, trot, **and canter** in both directions to achieve their very first Longeing proficiency level (`Intermediate`) is too steep. Either make `Intermediate` walk/trot longeing on a trained horse and move canter on the longe to `Advanced` (Option B, preserving 2 levels), or add an `Introductory` level for safe walk/trot circle work on a schooled horse (Option A). |
| **`rider.mounted.transitions`**<br>Transitions | `Int`, `Adv` | **`Intro`**, `Int`, `Adv` | **Add `Introductory` (Parity with `horse.mounted.transitions`):** `horse.mounted.transitions` offers `Intro` (basic halt, walk, trot transitions), `Int` (walk, trot, canter progressive transitions + half-halt), and `Adv` (direct and within-gait transitions). Adding `Introductory` to `rider.mounted.transitions` gives novice riders a clear place to track smooth halt–walk–trot transitions before canter transitions and halt-on-a-mark at `Intermediate`. |
| **`rider.mounted.rein_back`** & **`horse.mounted.rein_back`**<br>Rein Back | Rider: `Int`, `Adv`<br>Horse: `Int` | **Option A:** Add `Intro` (2–4 straight steps back from halt) to both, keeping L-corridor at `Int`.<br>**Option B:** Add `Adv` to `horse.mounted.rein_back` to match Rider. | **Resolve Level Bundling & Counterpart Asymmetry:** Currently, a rider or horse cannot be marked proficient at any level of `Rein Back` until they can also back through an L-shaped corridor. Adding `Introductory` for 2–4 calm, straight backward steps on the flat separates basic straight rein-back from steered obstacle backing (`Intermediate`) and advanced serpentines/direct transitions (`Advanced`). At minimum, `horse.mounted.rein_back` should match `rider.mounted.rein_back`'s `Adv` level. |
| **`horse.in_hand.vet_handling`**<br>Veterinary & Medical Handling | `Int` | **`Intro`**, `Int` | **Add `Introductory`:** Accepting daily owner handling of ears, eyes, muzzle/mouth, and tail (`Introductory`) is a distinct, foundational stepping stone before standing calmly for an unfamiliar veterinarian, stethoscope, rectal thermometer, and oral syringe (`Intermediate`). |
| **`horse.in_hand.trailer_loading`** & **`rider.in_hand.trailer_loading`**<br>Trailer Loading | `Int` | **`Intro`**, `Int` *(optional)* | **Optional `Introductory` Level:** For green horses and novice handlers, approaching and stepping calmly onto a ramp/platform or walking into an open, familiar trailer to eat/pause (`Introductory`) is a valuable training milestone before full shut-in securing and unloading (`Intermediate`). |

---

## F. Missing Competencies (Prioritized)

### Tier 1: Essential Foundational Gaps (Recommend Addressing Before or Immediately After Launch)
1. **Rider Theory & Knowledge Seed Skills (`rider.theory.*` — 4 Skills to Populate the 4 Empty Families):**
   - Currently, the 4 Theory families in `families.json` have **0 skills**. Authoring **1 multi-level skill per family (4 skills total)** immediately populates the *Theory & Knowledge* category without overwhelming users:
     1. `rider.theory.learning_principles` — **How Horses Learn (Conditioning, Pressure/Release & Rewards)** (`Introductory`, `Intermediate`) in `rider.theory.learning`
     2. `rider.theory.equine_behavior_signals` — **Equine Body Language, Stress & Pain Recognition** (`Introductory`, `Intermediate`) in `rider.theory.behavior`
     3. `rider.theory.biomechanics_training_scale` — **Gaits, Biomechanics & Training Principles** (`Introductory`, `Intermediate`, `Advanced`) in `rider.theory.movement_training`
     4. `rider.theory.welfare_ownership_ethics` — **Equine Welfare, Preventive Care & Ethical Horsemanship** (`Introductory`, `Intermediate`) in `rider.theory.welfare_ethics`
2. **Rider Mounted Position & Balance (`rider.mounted.seat_balance` in `rider.mounted.position_balance_safety`):**
   - Currently, `Position, Balance & Safety` contains only `Mounting & Dismounting`. Adding **`Seat, Position & Independent Balance`** (`Introductory`: balanced alignment at halt/walk and stirrup recovery; `Intermediate`: independent seat/hands across two-point, posting, and sitting without gripping; `Advanced`: self-carriage and subtle weight aids across demanding movements) fulfills the family's name and gives instructors a core equitation skill to verify.
3. **Missing Horse → In-Hand Counterparts (3 Skills to Complete Existing Families):**
   - **`horse.in_hand.obstacles_outings` — In-Hand Obstacles & Outings (Horse)** (`Introductory`, `Intermediate`) in `horse.in_hand.travel_environments`: Resolves the 1-skill `Travel & New Environments` family and provides the missing counterpart to `rider.in_hand.obstacles_outings`.
   - **`horse.in_hand.longeing` — Longeing (Horse)** (`Introductory`, `Intermediate`) in `horse.in_hand.work_on_line`: Resolves the 1-skill `Work on the Line` family and provides the missing counterpart to `rider.in_hand.longeing`.
   - **`horse.in_hand.yielding` — Yielding Forequarters, Hindquarters & Sidepass (In-Hand)** (`Introductory`, `Intermediate`) in `horse.in_hand.leading_manners` (or a `Ground Control & Yielding` family): Provides the missing Horse counterpart to the 3 Rider In-Hand yielding skills (`turn_on_forehand`, `yield_forequarters`, `sidepass_in_hand`).

### Tier 2: Useful Future Additions (Foundational Safety & All-Around Horsemanship)
4. **Emergency Control & Disengagement (`rider.mounted.emergency_control`):**
   - Riding without stirrups, regaining lost stirrups at walk/trot, one-rein stop / emergency hindquarter disengagement (with explicit safety warnings against high-speed sharp pulls on slick/steep footing), and managing a spook or bolt safely.
5. **Ground Poles & Cavaletti (`rider.mounted.poles_cavaletti` & `horse.mounted.poles_cavaletti`):**
   - While `Terrain & Obstacle Negotiation` touches on trot/canter poles alongside trail obstacles, a dedicated gymnastic pole/cavaletti skill (adjusting stride length, rhythm, and two-point balance over spaced grids) is valuable across flatwork, trail, and jumping riders.
6. **Lead Changes & Counter-Canter (`rider.mounted.lead_changes` & `horse.mounted.lead_changes`):**
   - Currently folded briefly into `Steering & Navigation (Advanced)`. As riders progress, tracking **Simple Lead Changes (through trot/walk)** (`Intermediate`), **Counter-Canter** (`Intermediate`/`Advanced`), and **Flying Lead Changes** (`Advanced`) as a dedicated skill under `Gaits, Rhythm & Transitions` or `Steering, Bend & Direction Changes` provides clearer milestones.

### Tier 3: Discipline-Specific or Specialist Topics (Keep Out of Core Baseline Until Optional Pathways Are Added)
7. **Classical / Advanced Dressage Lateral & Collected Work:**
   - `Renvers (Haunches-Out)`, `Half-Pass (Appuyer)`, `Walk Pirouette`, `Canter Pirouette`, `Piaffe`, and `Passage`.
8. **Jumping / Over Fences:**
   - Cross-rails, gymnastic grids, courses, and cross-country jumping.
9. **Western / Ranch Specialist Maneuvers:**
   - `Western Spin / Turn-Around`, `Rollback`, `Sliding Stop`, and roping/cattle work.
10. **Liberty & Bridleless Work:**
    - Liberty circles, changes of direction at liberty, and bridleless riding in enclosed spaces.

---

## G. Trainer Decisions Required

Before any curriculum edits or production publishing take place, the following 7 consequential decisions require trainer sign-off:

1. **Empty `Theory & Knowledge` Families at Launch (Section B.4 & F.1):**
   - Should we **author 4 foundational multi-level Theory skills** (1 per existing `rider.theory.*` family) before publishing Skill Tree 2.0, **or** keep `rider.theory.*` empty for now and hide empty families/categories in the UI until the Theory curriculum is ready?
2. **Resolving Single-Skill Families in `Horse → In-Hand` (Section B.5 & F.3):**
   - To fix `Travel & New Environments` (currently only `Trailer Loading`) and `Work on the Line` (currently only `Ground Driving`), do you want to:
     - **Option A (Recommended):** Add `horse.in_hand.obstacles_outings` (*In-Hand Obstacles & Outings*) to `Travel & New Environments` and `horse.in_hand.longeing` (*Longeing*) to `Work on the Line`?
     - **Option B:** Keep the 57-skill count fixed and merge `Trailer Loading` and `Ground Driving` into fewer Horse In-Hand families?
3. **Consolidating Single-Skill Mounted Families (`Terrain & Obstacles` + `Object Handling`, and `Steering`) (Section B.3 & B.6):**
   - Should we merge the two 1-skill families `Terrain & Obstacles` and `Object Handling` into a single 2-skill family (**`Trail, Obstacles & Object Handling`**) for both Rider and Horse while keeping both skills (`Terrain & Obstacle Negotiation` and `Object Handling`) completely separate?
4. **Longeing Difficulty Progression (`rider.in_hand.longeing`, Section E):**
   - Should we separate **Walk/Trot Longeing** from **Canter Longeing**—either by making `Intermediate` cover walk/trot longeing and moving canter longeing to `Advanced`, or by adding an `Introductory` level for basic walk/trot longeing on a schooled horse?
5. **Leading In-Hand Trot Placement (`rider.in_hand.leading`, Section D.1 & E):**
   - Approve moving **leading at trot** from `Introductory` to `Intermediate` in `rider.in_hand.leading` so that `Introductory` Rider Leading (walk, halt, turn, back up) matches `Introductory` Horse Leading?
6. **Adding Missing `Introductory` Entry Levels (`First Aid`, `Yield Forequarters In-Hand`, `Rider Transitions`, `Rein Back`, Section E):**
   - Which of the following proposed `Introductory` levels would you like added?
     - `rider.husbandry.first_aid` (`Introductory`: emergency/wound recognition & calling the vet)
     - `rider.in_hand.yield_forequarters` (`Introductory`: 1–3 steps of forequarter yield, matching `Turn on the Forehand In-Hand`)
     - `rider.mounted.transitions` (`Introductory`: basic halt–walk–trot transitions, matching `horse.mounted.transitions`)
     - `rider.mounted.rein_back` & `horse.mounted.rein_back` (`Introductory`: 2–4 calm straight backward steps on the flat, keeping L-corridor backing at `Intermediate`)
7. **Adding `Rider Seat, Position & Independent Balance` to `Position, Balance & Safety` (Section B.3 & F.2):**
   - Should we add a multi-level `Seat, Position & Independent Balance` skill so `Position, Balance & Safety` contains more than just `Mounting & Dismounting`, or defer new mounted skills to a post-launch update?
