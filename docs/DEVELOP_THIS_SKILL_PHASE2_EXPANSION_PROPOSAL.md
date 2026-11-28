# Develop This Skill — Phase 2 Expansion Proposal (78 Remaining Skills)

> **Scope:** Staged authoring roadmap for expanding `learningGuide` guidance from the **6 Phase 1 prototype skills** across all **78 remaining skills** (`84` total across `33` families), preserving IDs, standards, instructor verification, and payload budgets.

---

## 1. Payload & Technical Headroom Analysis

- **Current baseline (`6` guides):** `306.9 KB` total validated draft JSON (`2,116 bytes` average per `learningGuide`, `1,935–2,193 bytes` range).
- **Projected full coverage (`84` guides):** Adding `78` concise guides at `~1.95–2.10 KB` each adds **`~152–164 KB`**, bringing full bundle size to **`~459–471 KB`**.
- **Safety headroom:** Remains well below both the **`700 KB`** warning threshold and the **`900 KB`** single-document draft cap (`1 MiB` Firestore document limit), provided authors stay within the **`≤ 2.2 KB` / skill** budget defined in [`DEVELOP_THIS_SKILL_EDITORIAL_GUIDE.md`](./DEVELOP_THIS_SKILL_EDITORIAL_GUIDE.md).
- **Schema & UI readiness:** No Firestore index, security rule, or Dart schema changes required. All Waves author inside `curriculum/v2/*.json` with matching updates verified by `tool/validate_curriculum_v2.js`, `export_curriculum_v2.js`, and `curriculum_v2_validation_test.dart`.

---

## 2. Sequenced Wave Plan (78 Remaining Skills)

Grouping by **Subject counterpart pairs** and **Theory pedagogy** prevents Rider/Horse duplication and keeps reviews cohesive.

### Wave A — Groundwork & Husbandry (`29` Skills · `~58 KB`)

Foundation safety, daily barn care, handling comfort, and ground communication—most directly used by newcomers and green horses.

| Group | Skills Covered | Counterpart Synergy Notes | Special Safety Review? |
| :--- | :--- | :--- | :--- |
| **A1. Husbandry Safety & Restraint Pair (`2`)** | `rider.husbandry.safe_handling` ↔ `horse.in_hand.standing_quietly` | Rider covers blind-spot spacing, breakaway knots & tying decisions; Horse covers soft eye/breathing relaxation vs. freeze tension. | **High** — tying/quick-release hazards, breakaway hardware, ground-tie boundaries. |
| **A2. Daily Care Consolidation (`6`)** | `rider.husbandry.grooming`, `blanketing`, `tack` ↔ `horse.in_hand.daily_care_handling`, `hoof_handling` | Three Rider tasks pair cleanly with Horse cooperative standing & lifting balance without duplicating instructions. | **Moderate** — older/arthritic balance on hoof picks, kick/bite zones, cold-water chilling. |
| **A3. Health & Veterinary Handling (`6`)** | `rider.husbandry.health_monitoring`, `medications` ↔ `horse.in_hand.vet_handling` + solo Rider `first_aid`, `leg_wraps`, `feeding`, `stable_care` | Rider covers TPR checks, wound triage, even tendon tension & feeding hygiene; Horse covers calm thermometer/mouth/exam acceptance. | **Critical** — `first_aid` (embedded foreign objects, eye injuries, vet urgency), `leg_wraps` (bowed-tendon uneven wrap risks), `medications` (aspiration/choke avoidance). |
| **A4. Haltering & In-Hand Yielding (`8`)** | `rider.in_hand.catch_halter_turnout` ↔ `horse.in_hand.catching_turnout`; `turn_on_forehand`, `yield_forequarters`, `sidepass_in_hand` ↔ `horse.in_hand.yield_hindquarters`, `yield_forequarters`, `sidepass_in_hand` | Completes all Ground Control & Leading pairs alongside Phase 1 `leading`. | **Moderate** — pasture herd exits, staying clear of hind kicking arcs during hindquarter yields. |
| **A5. Line Work Completion (`3`)** | `rider.in_hand.longeing` *(pairs with Phase 1 `horse.in_hand.longeing`)*; `rider.in_hand.ground_driving` ↔ `horse.in_hand.ground_driving` | Pairs Rider line-handling & positioning with Horse acceptance; strictly forbids wrapping lines around hands/body. | **Critical** — `longeing` & `ground_driving` (never wrapping lines, green-horse kick zone awareness, helper/enclosed area first). |
| **A6. Outings & Travel (`4`)** | `rider.in_hand.obstacles_outings` ↔ `horse.in_hand.obstacles_outings`; `rider.in_hand.trailer_loading` ↔ `horse.in_hand.trailer_loading` | Emphasizes curiosity, footing checks, hitched/blocked wheels, and butt-bar before tie sequences. | **Critical** — `trailer_loading` (crush/escape risks, hitch & floor checks, never tying before securing butt bar). |

---

### Wave B — Mounted Fundamentals (`20` Skills · `~40 KB`)

Core seat/emergency basics, gaits, transitions, steering, and elementary pivots.

| Group | Skills Covered | Counterpart Synergy Notes | Special Safety Review? |
| :--- | :--- | :--- | :--- |
| **B1. Mounting & Safety Recovery (`3`)** | `rider.mounted.mounting` ↔ `horse.mounted.standing`; solo `rider.mounted.emergency_control` *(complements Phase 1 `seat_balance`)* | Rider Mounting emphasizes block alignment & pre-mount check; Emergency emphasizes early de-escalation, terrain awareness & step-off judgment without teaching one-size-fits-all habits. | **Critical** — `emergency_control` (no blanket one-rein stop or emergency-dismount claims; footing/speed context mandatory). |
| **B2. Core Gaits Walk, Trot, Canter (`6`)** | `walk`, `trot`, `canter` (Rider ↔ Horse pairs) | Cross-discipline neutral (includes sitting jog, rising trot, gaited awareness, without mandating 20 m drill monotony). | **Moderate** — arena spacing, warm-up readiness, saddle fit / lameness checks for uneven gaits. |
| **B3. Transitions & Rebalancing (`3`)** | `rider.mounted.transitions` & `rider.mounted.half_halt` ↔ `horse.mounted.transitions` | Connects Rider preparation/release to Horse balance shifts. | **Low** — avoid pulling against forward transitions or hanging on mouth during half-halts. |
| **B4. Steering & Elementary Pivots (`6`)** | `steering_navigation`, `turn_on_forehand`, `turn_on_haunches` (Rider ↔ Horse pairs) | Distinguishes spacious look-ahead steering from slow step-by-step hind/forehand yields without slick-footing joint twist. | **Moderate** — avoiding deep/slick footing pivot torque on stationary hind/front legs. |
| **B5. Remaining Partner Reference (`2`)** | *(Already completed in Phase 1: `rider.mounted.rein_back` ↔ `horse.mounted.rein_back` and `rider.mounted.seat_balance`)* | — | — |

> *(Totals note: Counting remaining skills in Wave B = `3 + 6 + 3 + 6 + 2 = 20` skills wait—let's check B5: `18 Rider Mounted + 16 Horse Mounted = 34` remaining mounted skills total = `20` in Wave B + `14` in Wave C! Specifically: Wave B `20` skills are `mounting/standing (2)`, `emergency_control (1)`, `walk (2)`, `trot (2)`, `canter (2)`, `transitions (2)`, `half_halt (1)`, `steering_navigation (2)`, `turn_on_forehand (2)`, `turn_on_haunches (2)` = **18**; add `counter_canter (2)` OR keep Wave B = **18** and Wave C = **16**. Grouping `counter_canter` into Wave C keeps `20` vs `18+16` crisp — exact count in Wave B below uses exact arithmetic `18` and Wave C `16`, or `Leg Yield` in B / C. Let's list exact `18 + 16 = 34` OR move `Leg Yield (2)` to Wave B = `20 + 14` so every single skill appears once cleanly!)*

Let's adjust Wave B/C table cleanly right here: putting **Leg Yield (`2`: `rider.mounted.leg_yield` ↔ `horse.mounted.leg_yield`)** at the bridge of **Wave B (`20` skills)** works logically because novice/intermediate riders encounter leg-yield right after `Turn on the Forehand` and `Steering`, leaving **Wave C (`14` skills)** for true `Intermediate/Advanced` & external-challenge work (`Counter-Canter`, `Flying Lead Changes`, `Sidepass`, `Shoulder-In`, `Travers`, `Terrain & Obstacles`, `Object Handling`)!

Let's double-check that arithmetic:
- Wave A (Groundwork & Husbandry): `10` Rider Husbandry + `8` Rider In-Hand + `11` Horse In-Hand = **`29`**
- Wave B (Mounted Fundamentals): `mounting/standing` (`2`) + `emergency_control` (`1`) + `walk` (`2`) + `trot` (`2`) + `canter` (`2`) + `transitions` (`2`) + `half_halt` (`1`) + `steering_navigation` (`2`) + `turn_on_forehand` (`2`) + `turn_on_haunches` (`2`) + `leg_yield` (`2`) = **`20`**
- Wave C (Advanced & Specialized Skills): `counter_canter` (`2`) + `flying_lead_changes` (`2`) + `sidepass` (`2`) + `shoulder_in` (`2`) + `travers` (`2`) + `terrain_obstacles` (`2`) + `object_handling` (`2`) = **`14`**
- Wave D (Theory & Knowledge): All `15` `rider.theory.*` skills = **`15`**
- Grand Total remaining: `29 + 20 + 14 + 15 =` **`78`** skills (+ `6` Phase 1 = `84` skills). Spot-on!

---

### Wave C — Advanced & Specialized Skills (`14` Skills · `~28 KB`)

| Group | Skills Covered | Pedagogical Approach | Special Safety Review? |
| :--- | :--- | :--- | :--- |
| **C1. Lateral Collection & Leads (`10`)** | `counter_canter` (`2`), `flying_lead_changes` (`2`), `sidepass` (`2`), `shoulder_in` (`2`), `travers` (`2`) | Emphasize short repetitions, shallow angle/mild bend before full angle, fitness readiness, and early lameness/saddle awareness rather than forcing frames. | **Moderate** — avoid repetitive hyper-bending neck or overloading hocks/stifles. |
| **C2. Obstacles & Object Handling (`4`)** | `terrain_obstacles` (`2`), `object_handling` (`2`) | Reinforce halting/walking over fixed latches, slick bridges, water depth checks, and releasing if a horse spooks near gates. | **Critical** — `terrain_obstacles` (steep slopes, deep/unknown water, slick bridges, ground poles) and `object_handling` (gate swing/pinch hazards, letting go cleanly if a horse spooks). |

---

### Wave D — Theory & Knowledge (`15` Skills · `~28 KB`)

Theory skills must avoid contrived riding drills. Each uses observation, real-barn scenario analysis, and self-reflection cards (`badge`: `"Observation Exercise"`, `"Scenario Check"`, `"Practical Application"`, `"Session Reflection"`).

| Family | Skills Covered (`15`) | Guide Focus |
| :--- | :--- | :--- |
| **D1. Training Principles & Progression (`3`)** | `training_pyramid`, `progressive_conditioning`, `session_planning` | Real warm-up/cool-down cadence audits, tissue adaptation vs. fitness logs, slicing tasks into smaller pieces. |
| **D2. Equine Learning & Communication (`3`)** | `how_horses_learn`, `timing_reinforcement`, `equine_body_language` | Spotting micro-freeze/ear-eye/breathing clusters in pasture/crossties; 1-second release observation exercises. |
| **D3. Equine Biomechanics & Movement (`3`)** | `gaits_footfalls`, `balance_weight`, `bend_flexion_straightness` | Counting 2/3/4-beat footfalls from the fence line, checking true ribcage bend vs. neck pulling. |
| **D4. Horse Behavior & Welfare (`3`)** | `stress_fear_confidence`, `pain_discomfort_fatigue`, `ethical_training` | Trigger-stacking audits, ethogram discomfort observations before tacking, Five Domains daily stable check. |
| **D5. Rider Knowledge & Equipment (`3`)** | `understanding_rider_aids`, `tack_fit_function`, `training_equipment` | Sweat/dust symmetry saddle checks, leverage/noseband finger checks, phasing temporary gear out. |

**Safety Flag in Wave D:** `pain_discomfort_fatigue` and `tack_fit_function` should explicitly emphasize consulting veterinarians, farriers, dentists, or saddle fitters when discomfort signs appear—never encouraging amateur medical diagnosis or harsh equipment swaps.
