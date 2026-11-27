# Skill Tree — Wave 1: Educational Content Refinement Review (Revision 2)

> **Status & Purpose:** Revision 2 of the Wave 1 content-development and trainer review document, updated to incorporate **all seven points of trainer feedback from Matt French** plus a **code-verified assessment & `standardVersion` compatibility audit** prior to editing any curriculum JSON or application code. **No `curriculum/v2/*.json` files, skill IDs, family IDs, Flutter code, Firestore rules, Cloud Functions, or user/horse assessment records have been modified.**

---

## 1. Philosophy, Educational Framework & Overview of Revisions

This review treats the recovered Skill Tree philosophy across [`SKILL_TREE_CURRICULUM_GUIDE.md`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/SKILL_TREE_CURRICULUM_GUIDE.md), [`SKILL_TREE_CURRICULUM_AUDIT_AND_DEVELOPMENT_PROPOSAL.md`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/SKILL_TREE_CURRICULUM_AUDIT_AND_DEVELOPMENT_PROPOSAL.md), and [`skill_tree_2_architecture_proposal.md`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/skill_tree_2_architecture_proposal.md) as authoritative:

- **Horsemanship is lifelong and nonlinear:** Skills never lock one another (`foundation`, `next`, `counterpart`, and `theory` remain helpful guidance, never gates).
- **Horse welfare takes priority:** Physical comfort, emotional safety, pain/stress recognition, and humane boundaries supersede performance polish, speed, or pattern compliance.
- **Independent development:** Horses and riders progress at different rates under independent profiles.
- **Observable quality over arbitrary metrics:** No completion percentages or scores; difficulty tiers (`Introductory`, `Intermediate`, `Advanced`—without forced 3-level symmetry) evaluate understanding, coordination, communication, observation, welfare, and adaptability rather than minimum step counts, mandatory obstacle props, rigid conformation postures, or speed.
- **Method-neutral across disciplines:** Welcome Western, English, trail, ranch, driving, gaited, classical, positive-reinforcement, and recreational horsemanship without mandating a single bit, halter, line-handling fold, turning habit, or training philosophy.

### Educational Lenses Inside the Existing V2 Schema

| Subject | Educational Lenses | Where Each Lens Lives in Existing V2 JSON |
| :--- | :--- | :--- |
| **Rider** | **1. Understanding** *(purpose, principles, consequences)*<br>**2. Execution** *(clear aids/position, feel, release)*<br>**3. Observation** *(reading horse posture, balance, emotion, soundness)*<br>**4. Adaptation** *(adjusting approach, spacing, gear, or ask for the individual horse)* | • `purpose` & first `components[]` (*why & core principles*)<br>• `components[]` (*balanced feel*, *common mistakes*, observable mechanics)<br>• `safety[]` & `components[]` (*threshold signals, soundness, environment*)<br>• `learning` & `proficient` (*independent adaptive horsemanship*)<br>• `relatedSkills[]` (`theory`, `foundation`, `next`, `counterpart`) |
| **Horse** | **1. Understanding** *(comprehending light requests)*<br>**2. Confidence & Willingness** *(relaxed participation vs. tension/freeze)*<br>**3. Coordination & Balance** *(posture, rhythm, alignment suited to build)*<br>**4. Responsiveness** *(soft answers and settled pause on release)*<br>**5. Emotional & Physical Welfare** *(no anthropomorphism; checking pain/comfort first)* | • `summary` & `purpose` (*why comprehension and coordination matter*)<br>• `safety[]` & `components[]` (*distinguishing calm understanding from fear/escape/freeze; comfort checks*)<br>• `learning` & `proficient` (*observable equine responses, coordination, composure, and adaptation*)<br>• `relatedSkills[]` (`counterpart`, `foundation`, `next`) |

### Summary of Revision 2 Changes Across the Six Examples

| # | Skill Example | Status | Current Levels | Proposed Levels | Key Feedback Applied & Version Impact *(see [§8](#8-assessment-persistence--standardversion-compatibility-audit) before publishing)* |
| :---: | :--- | :--- | :--- | :--- | :--- |
| 1 | **Rider — Leading** (`rider.in_hand.leading`) | Existing Skill | `Intro`, `Int` (`v1`) | `Intro`, `Int` (`v2`) | `Intro` calm walk focus; `Int` versatility; removed rigid `"2–4"` step count; turning away framed as useful technique rather than universal rule. *(`proficient` edits require `v1 → v2` under current validator.)* |
| 2 | **Rider — Longeing** (`rider.in_hand.longeing`) | Existing Skill | `Int`, `Adv` (`v1`) | `Intro` *(NEW `v1`)*, `Int` (`v2`), `Adv` (`v2`) | Keeps 3 levels evaluating understanding, positioning, observation, communication, safety, and adaptability; **trot NOT mandatory at `Intro`**, **canter NOT mandatory at `Int`**, **ground poles NOT mandatory at `Adv`**; specific line folds framed as examples alongside safety rules. |
| 3 | **Rider — Canter** (`rider.mounted.canter`) | Existing Skill | `Intro` (`v2`), `Int` (`v2`), `Adv` (`v1`) | `Intro` (`v2` or `v3`), `Int` (`v2` or `v3`), `Adv` (`v2`) **+ Proposed Optional New Skill(s)** | Separates fundamental canter proficiency (`Canter`) from optional advanced applications (`Counter-Canter & Flying Lead Changes`, **PROPOSED NEW SKILL(S)**). Removes `Adv` flying-change requirement from fundamental `Canter`. |
| 4 | **Rider — Training Principles & Progression** (`rider.theory.training_pyramid` in `rider.theory.training_principles`) | Existing Family & Flagship Skill | `Intro`, `Int`, `Adv` (`v1`) | `Intro` (`v2` or `v1`), `Int` (`v2` or `v1`), `Adv` (`v2`) | Preserves method-neutral criteria across all traditions; removes mandatory `"mentor others"` requirement at `Adv` (with companion alignment for `session_planning` and other Theory `Adv` standards). |
| 5 | **Horse — In-Hand Yielding** *(3 Separate Skills)*:<br>• `horse.in_hand.yield_hindquarters`<br>• `horse.in_hand.yield_forequarters`<br>• `horse.in_hand.sidepass_in_hand` | **PROPOSED NEW SKILLS** *(3 standalone skills)* | *None* (Rider currently has 3 unlinked yielding skills) | 3 skills (`Intro`, `Int` `v1` — or `Int`-only options discussed in §6.6) | Replaces consolidated 1-skill draft with **3 distinct Horse skills**, recommends new parallel family `horse.in_hand.ground_control_yielding`, and establishes symmetric 1:1 Rider ↔ Horse `counterpart` links plus Horse mounted `next` progressions. |
| 6 | **Horse — Rein Back** (`horse.mounted.rein_back`) | Existing Skill | `Int` (`v1`) only | `Intro` *(NEW `v1`)*, `Int` (`v2`), `Adv` *(NEW `v1`)* | Keeps 3 levels distinguishing *fundamental understanding* (`Intro`), *developing coordination* (`Int`), and *advanced adaptability* (`Adv`); removes mandatory L-corridors/obstacles, minimum step counts, direct canter departures, and any single idealized conformation posture; preserves welfare guidance. |

---

## 2. Example 1 — Rider: Leading (`rider.in_hand.leading` · Existing Skill)

### 2.1 Current Content (`curriculum/v2/skills_rider_in_hand.json`)

- **Family:** `rider.in_hand.haltering_leading` (*Haltering & Leading*) · **ID:** `rider.in_hand.leading` · **Name:** `Leading`
- **Aliases:** `["Lead at walk", "Lead at trot", "Back up from ground", "Present for inspection", "Jogging in hand"]`
- **Summary:** `"Leading a horse calmly at walk, trot, halt, and rein-back from the ground, including presenting for veterinary or pre-purchase inspection."`
- **Purpose:** `"Forms the foundation for every ground interaction, safe movement around barns, and clear presentation for farriers or veterinarians."`
- **Safety:**
  - `"Walk beside the shoulder/throat area rather than directly in front or behind."`
  - `"Never wrap the lead rope around hands or fingers."`
- **Related Skills:** `counterpart: horse.in_hand.leading`, `next: rider.in_hand.turn_on_forehand`
- **Current Levels (`availableLevels: ["introductory", "intermediate"]`):**
  - **`introductory` (`v1`):**
    - *Overview:* `"Leading at walk and short trot, halting, turning, and asking for basic backward steps on a cooperative horse."`
    - *Components:* (1) *Position and rope management*; (2) *Walk, halt, trot, and back-up*.
    - *Learning:* `"Leads a quiet horse at walk and short trot with occasional crowding, lagging, or uneven rope handling."`
    - *Proficient:* `"Independently leads a cooperative horse at walk and trot, halts, turns, and asks for calm backward steps while maintaining safe spacing and soft contact."`
  - **`intermediate` (`v1`):**
    - *Overview:* `"Straight, balanced leading and turning for formal inspection (vet/lameness jogs) and handling busier environments."`
    - *Components:* (1) *Inspection presentation:* `"Trotting straight on a loose lead without pulling the head, executing balanced turns away from the handler, and standing square/calmly."`
    - *Learning:* `"Presents a horse for straight trot-ups and turns with occasional loss of straightness or lead tension."`
    - *Proficient:* `"Independently presents a horse calmly for inspection—walking and trotting straight on a light lead, turning cleanly, and standing quietly—even with mild distractions."`

### 2.2 Identified Educational Weaknesses
1. **`Introductory` Demands Trot Coordination Early:** Including in-hand trot inside `Introductory` creates a mismatch with beginners focused on calm walk spacing/communication and conflicts with `horse.in_hand.leading` (which places trot in `Intermediate`).
2. **Missing Understanding, Feel & Observation:** Does not explain *why* handler posture/breathing/rhythm communicate before rope pressure, what a relaxed non-restrictive lead feels like, or how to read early personal-space drift before tension escalates.
3. **Inspection Turn Technique Over-Prescribed:** Current `Intermediate` effectively embeds `"turns away from the handler"` inside the core component as if only one turn technique is valid, rather than treating turning away as a helpful technique for visibility, balance, and foot safety while prioritizing safe, uncrowded turns overall.
4. **Missing Versatility & Links:** `Intermediate` omits bilateral (left- and right-side) handling versatility, lacks `foundation` from `rider.in_hand.catch_halter_turnout`, and lacks `theory` links.

### 2.3 Proposed Revised Content (`rider.in_hand.leading`)

- **Skill ID:** `rider.in_hand.leading` *(unchanged)* · **Name:** `Leading` *(unchanged)*
- **Aliases:** `["Lead at walk", "Lead at trot", "Back up from ground", "Present for inspection", "Jogging in hand", "In-hand leading both sides"]`
- **Summary:** `"Communicating direction, pace, pauses, and safe personal boundaries while leading a horse on foot—from calm everyday walk handling to versatile leading and straight, non-restrictive presentation across varied environments."`
- **Purpose:** `"Turns leading from pulling or holding onto a horse into clear, safe two-way communication that protects horse and handler during daily care, barn movement, outings, and veterinary or farrier checks."`
- **Safety:**
  - `"Keep a safe position near the horse's shoulder or throatlatch area with a clear exit route—avoid walking directly ahead of a rushing horse or inside kicking reach."`
  - `"Keep excess rope organized and off the ground (for example, neatly folded or in figure-eight loops); never wrap a lead rope around fingers, wrists, or body."`
  - `"Keep turns safe, balanced, and uncrowded so the horse does not swing into you or step on your feet (turning the horse away from you is often a useful technique in tight spaces or inspections)."`
  - `"Create space, slow down, or reset calmly when surroundings become stimulating rather than hauling continuously on the halter or running blindly alongside an anxious horse."`
- **Related Skills:**
  - `{"skillId": "horse.in_hand.leading", "relation": "counterpart"}`
  - `{"skillId": "rider.in_hand.catch_halter_turnout", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "rider.in_hand.turn_on_forehand", "relation": "next"}`
  - `{"skillId": "rider.in_hand.obstacles_outings", "relation": "next"}`
  - `{"skillId": "rider.theory.equine_body_language", "relation": "theory"}`
  - `{"skillId": "rider.theory.timing_reinforcement", "relation": "theory"}`

### 2.4 Proposed Difficulty Criteria (`availableLevels: ["introductory", "intermediate"]`)

| Dimension | Proposed **Introductory** (`v2` if `proficient` revised) | Proposed **Intermediate** (`v2`) |
| :--- | :--- | :--- |
| **Overview** | Clear, calm **walk** communication (starts, halts, turns, everyday doorways/aisles, and calm backward steps) with safe handler positioning and soft lead feel in familiar settings. *(Trot leading is not required.)* | Greater **versatility**—leading smoothly at walk and controlled trot, handling comfortably from either side, adapting proactively in busier environments, and presenting a horse straight and balanced on a loose, non-restrictive lead. |
| **Educational Components** *(Understanding · Execution · Feel · Observation · Welfare)* | 1. **Understanding handler posture & clear requests:** Walking beside the shoulder rather than dragging ahead or falling behind; recognizing how your own walk energy, orientation, and stillness signal starts and halts before touching the rope.<br>2. **Feel of a soft lead & timely release:** Keeping gentle slack/drape in the lead rather than steady tension, and releasing promptly when the horse matches pace or shifts weight smoothly into calm backward steps.<br>3. **Observing attention & space:** Spotting early crowding, drifting shoulders, or distraction (ears/neck/eye changes) and resetting personal space calmly.<br>4. **Common mistakes & safety:** Constantly turning to stare back at the horse's face (which stalls forward flow), pulling steadily instead of asking and releasing, walking backward to pull the horse forward, or wrapping excess line around hands. | 1. **Controlled pace & straight presentation:** Matching a controlled in-hand trot beside the shoulder while keeping a non-restrictive lead so the horse's head and neck can move naturally without pulling on the chin or mouth.<br>2. **Balanced turns & inspection versatility:** Choosing safe, clean turns suited to the setting and observer (e.g., for veterinary/lameness checks—using turning the horse away from you as a helpful technique when appropriate for clean line-of-sight and balance, without forcing a rigid single style) and allowing the horse to stand settled.<br>3. **Both-side handling & environmental adaptation:** Leading calmly from left or right sides as gates, slopes, traffic, or handlers require, and adjusting distance or pausing calmly around mild distractions.<br>4. **Soundness & comfort awareness:** Noticing reluctance to jog, uneven head motion, or tense breathing as welfare feedback rather than escalating force. |
| **Learning** | Practices calm walk starts, halts, turns, and light backward steps on a quiet horse with occasional reminders about shoulder position, slack rope timing, spacing around corners, or looking ahead. | Practices controlled trot leading, off-side handling, or inspection presentation with occasional lead tension, uneven pace, cramped turns, or late adjustments in busier settings. |
| **Proficient** | Independently leads a cooperative horse calmly at walk in familiar spaces with safe positioning and organized rope handling; communicates clear starts, settled halts, balanced turns, and calm backward steps on light cues while maintaining comfortable personal space. | Independently leads a prepared horse with versatility at walk and controlled trot from either side, adapts spacing and composure thoughtfully in busier settings, and presents the horse straight on a non-restrictive lead with safe, balanced turns and settled halts. |

### 2.5 Educational Rationale
Removing in-hand trot from `Introductory` centers early learning on **calm walk communication and feel**, while removing arbitrary `"2–4"` backward-step counts shifts focus to **light comprehension, weight shift, and release**. Framing `"turning away"` during inspections as a **useful technique**—rather than a universal mandate—respects real-world handler, horse, and veterinary preferences while keeping safety and straightness central. Keeping 2 levels preserves honesty (`Leading` does not need a padded `Advanced` tier).

### 2.6 Questions for Matt's Professional Judgment
1. Does keeping **`Introductory` focused on calm walk communication** and **`Intermediate` on versatility (trot, both sides, busier settings, straight inspection presentation)** align with how you assess handlers?
2. Does removing step counts and framing **turning away during inspections as a useful technique rather than a rigid requirement** strike the right practical balance?

---

## 3. Example 2 — Rider: Longeing (`rider.in_hand.longeing` · Existing Skill)

### 3.1 Current Content (`curriculum/v2/skills_rider_in_hand.json`)

- **Family:** `rider.in_hand.longeing_long_lining` (*Longeing & Long-Lining*) · **ID:** `rider.in_hand.longeing` · **Name:** `Longeing`
- **Aliases:** `["Lunge walk and trot", "Lunge canter", "Lunging"]`
- **Summary:** `"Working a reasonably prepared horse on a circle with a longe line across gaits and transitions while maintaining safe handler positioning and line control."`
- **Purpose:** `"Allows assessment of movement, calm warm-up, and rhythmic transition practice from the ground."`
- **Safety:**
  - `"Never wrap the longe line around hands or fingers; wear gloves and safe footwear."`
  - `"Work in an enclosed, good-footing area and stay outside the kick zone."`
- **Related Skills:** `next: rider.in_hand.ground_driving`
- **Current Levels (`availableLevels: ["intermediate", "advanced"]`):**
  - **`intermediate` (`v1`):** Required smooth line handling and transitions across **walk, trot, and canter** on a steady circle.
  - **`advanced` (`v1`):** Required within-gait lengthening/shortening, bending, moving circles, and **transitions over poles**, plus wording (`"maintaining relaxed responsiveness"`) that blurs handler skill with horse outcome.

### 3.2 Identified Educational Weaknesses
1. **Difficulty Equated With Gaits & Props:** Currently enters at `Intermediate` demanding walk, trot, *and canter*, and expects *ground poles* at `Advanced`—locking out thoughtful ground handlers whose horse, arena space, or goals don't involve circling at canter or jumping/crossing poles.
2. **Handler Mechanics & Intent Under-Explained:** Does not teach the *purpose* of thoughtful longeing versus blindly chasing a horse to burn energy, nor explain handler positioning relative to the horse's shoulder/drive line.
3. **Specific Line-Folding vs. True Safety:** Needs a clear line between non-negotiable safety (never wrapping the line around body/hands/fingers; keeping loops clear of feet; safe snap/bridle/cavesson attachment; joint-safe circle sizes on level footing) and handler-preferred coil methods (e.g., figure-8 or accordion folds as examples).
4. **Missing Observation & Subject Clarity at `Advanced`:** Needs stronger focus on reading rhythm, posture, asymmetry, tension, or fatigue, adapting proactively, and evaluating *handler* timing/adaptation rather than asserting the horse's emotional state.

### 3.3 Proposed Revised Content (`rider.in_hand.longeing`)

- **Skill ID:** `rider.in_hand.longeing` *(unchanged)* · **Name:** `Longeing` *(unchanged)*
- **Aliases:** `["Lunge walk and trot", "Lunge canter", "Lunging", "Circle work on a line", "Sending on a circle", "Longing"]`
- **Summary:** `"Safely preparing, positioning, managing equipment, communicating on a circle, observing movement and emotional state, and adapting circle work thoughtfully for the individual horse."`
- **Purpose:** `"Develops clear, humane ground communication, line safety, body-position awareness, and an educated eye for equine posture, rhythm, and comfort—distinct from simply sending a horse around in circles."`
- **Safety:**
  - `"Never wrap or loop a longe line around fingers, hands, wrists, or body, and never let loose coils drag where you or the horse can step into them; wear sturdy footwear and appropriate gloves."`
  - `"Choose an enclosed area with level, non-slip footing, keep circle sizes generous enough to protect joints, and stay outside the horse's kicking zone."`
  - `"Select and attach safe headgear thoughtfully (such as a well-fitted halter, longeing cavesson, or appropriate bridle setup)—never attach a heavy snap directly to a single bit ring in a way that pulls the bit painfully through the mouth."`
  - `"Never chase an anxious, confused, fatigued, or sore horse endlessly in tight circles; limit repetitions, work evenly both directions, and stop to investigate discomfort when needed."`
- **Related Skills:**
  - `{"skillId": "rider.in_hand.leading", "relation": "foundation", "level": "intermediate"}`
  - `{"skillId": "rider.in_hand.ground_driving", "relation": "next"}`
  - `{"skillId": "rider.theory.progressive_conditioning", "relation": "theory"}`
  - `{"skillId": "rider.theory.balance_weight", "relation": "theory"}`
  - `{"skillId": "rider.theory.training_equipment", "relation": "theory"}`
  - `{"skillId": "rider.theory.timing_reinforcement", "relation": "theory"}`

### 3.4 Proposed Difficulty Criteria (`availableLevels: ["introductory", "intermediate", "advanced"]`)

| Dimension | Proposed **Introductory** *(NEW Level · `v1`)* | Proposed **Intermediate** (`v2`) | Proposed **Advanced** (`v2`) |
| :--- | :--- | :--- | :--- |
| **Overview** | Safe preparation, safe line organization, understanding basic handler positioning ("triangle"/drive line), clear calm circle communication at **walk** (plus smooth halts and calm approaches/direction changes) on a cooperative horse, and noticing basic attention/tension cues. *(Trotting and cantering are not required at Introductory.)* | Reliable circle geometry, elastic non-restrictive line feel, coordinated transitions across walk and appropriate working gaits *(trot where appropriate; **canter is optional where space, footing, and horse readiness suit it—never mandatory**)*, active observation of rhythm, bend, and left/right symmetry, and thoughtful adaptation of pace, circle size, or rest. | Purposeful, adaptive longeing tailored to the individual horse's physical and mental needs—using minimal, well-timed cues, subtle within-gait or posture adjustments, varied circle placement/size *(such as moving circles along the arena, spirals, or **optional** ground poles—none mandatory)*, and sound diagnostic/welfare judgment. |
| **Educational Components** *(Understanding · Positioning · Communication · Observation · Safety · Adaptation)* | 1. **Purpose over chasing:** Understanding how calm body alignment and timely release invite attentive communication rather than blindly driving a horse to "burn off energy."<br>2. **Safe line organization & positioning:** Keeping coils safely organized off the ground (for example, neatly gathered folds or figure-8 coils) without ever wrapping hands/fingers; staying behind the horse's shoulder/girth line to ask forward and avoiding drifting ahead of the nose unintentionally.<br>3. **Calm walk starts, halts & invitations:** Maintaining soft elastic line feel, inviting the horse to halt cleanly on the circle or yield inward politely rather than yanking it in.<br>4. **Basic observation & common mistakes:** Recognizing rushing, braced neck, or stepping ahead of the drive line (accidentally stopping/turning the horse), and pausing or resetting circle position calmly. | 1. **Consistent geometry & elastic feel:** Offering smooth payout and take-up as circle distance changes, keeping gentle light communication on the line without sagging loops underfoot or steady pulling.<br>2. **Reading posture, balance & asymmetry:** Observing falling inward on the inside shoulder, stiff/raised neck, uneven stride lengths between left and right directions, and signs of mental overload.<br>3. **Coordinated transitions & adaptation:** Timing voice, posture, and optional whip alignment clearly for calm transitions between walk and faster gaits when appropriate for horse and footing—adjusting circle diameter, changing direction proactively, or offering a break instead of nagging.<br>4. **Common mistakes:** Repeating cues after the horse already responded, locking into one small spot until footing ruts, or demanding canter when space/balance isn't ready. | 1. **Minimal cues & within-gait refinement:** Communicating subtle lengthening/shortening, balance shifts, or bend invitations with breath, torso angle, energy modulation, and quiet line timing rather than overt gestures.<br>2. **Varied paths & optional gymnastic tools:** Walking rectangular or oval "moving circles" to reduce continuous joint torque, shaping gentle spirals, or using optional tools such as ground poles thoughtfully when helpful for a given horse's back/focus *(never as a fixed checklist)*.<br>3. **Diagnostic observation & welfare adaptation:** Distinguishing conditioning fatigue, stiffness, or mild lameness from lack of focus; adapting equipment, simplifying demands, or ending the session early in the horse's interest. |
| **Learning** | Sets up line and handler position at walk on a quiet horse with guidance on safe coil organization, staying behind the drive line, keeping loose line off the ground, or calming transitions. | Manages circle size, elastic contact, and transitions across suitable gaits with intermittent line tangles, missed posture/asymmetry cues, late release, or slow circle-size adjustments. | Practices minimal-cue adjustments, varied circle tracks, or subtle shaping with occasional uneven tempo, cramped turns, or delayed adaptation when fatigue or tension appears. |
| **Proficient** | Independently checks footing, space, and safe attachments, keeps the line organized safely without wrapping or dragging, maintains clear drive-line positioning to guide calm walk circles, halts, and direction changes in both directions on a cooperative horse, and recognizes basic signs of tension or confusion to reset calmly. *(Trot and canter are not required.)* | Independently longes a prepared horse safely in both directions with consistent circle size, elastic line feel, and clear, timely communication across walk and appropriate transitions *(without requiring canter)*; actively observes rhythm, balance, symmetry, and emotional state and adapts circle size, pace, or rests appropriately. | Independently plans and adapts purposeful longeing sessions for diverse prepared horses using subtle body/line timing, thoughtful within-gait or trajectory adjustments (such as moving circles or optional gymnastic setups), accurate observation of soundness, fatigue, and relaxation, and welfare-first adjustments to equipment or workload. *(Ground poles are optional, not required.)* |

### 3.5 Educational Rationale
Preserving **3 levels** while removing mandatory gait gates (`no mandatory trot at Intro`, `no mandatory canter at Int`, `no mandatory ground poles at Adv`) ensures progression measures **handler understanding, positioning, observation, communication, safety, and adaptability**—just as Matt requested. Treating figure-8 coils or specific equipment variations as examples prevents dogmatic technique grading while safeguarding strict safety essentials (no wrapping hands/body, safe attachments, non-slip enclosed footing, joint-protecting circle radii).

### 3.6 Questions for Matt's Professional Judgment
1. Does the 3-level breakdown—**Intro** *(safety, positioning, walk communication & observation)*, **Int** *(geometry, elastic feel, symmetry/balance observation, adaptive transitions without mandatory canter)*, and **Adv** *(subtle minimal-cue shaping, moving circles/adaptive planning, diagnostic welfare eye without mandatory poles)*—match your standard for progression?
2. Is the boundary between **non-negotiable safety essentials** (e.g., never wrapping line around hands/body, safe snap/bridle care) and **flexible example techniques** (e.g., coil style, cavesson/halter choice) clearly stated?

---

## 4. Example 3 — Rider: Canter (`rider.mounted.canter` · Existing Skill)

### 4.1 Current Content (`curriculum/v2/skills_rider_mounted.json`)

- **Family:** `rider.mounted.gaits_rhythm_transitions` (*Gaits, Rhythm & Transitions*) · **ID:** `rider.mounted.canter` · **Name:** `Canter`
- **Aliases:** `["Lope", "Canter depart", "Canter leads", "Lope leads", "Simple lead change", "Counter-canter", "Flying lead change"]`
- **Summary:** `"Riding the three-beat canter or lope in balance—progressing from establishing the gait to lead selection, simple lead changes, counter-canter, and flying changes."`
- **Purpose:** `"Allows riders to develop balanced three-beat feel early while progressing toward accurate lead control, balanced turns, and advanced lead changes."`
- **Safety:** `["Establish reliable walk/trot control and safe arena spacing before cantering."]`
- **Related Skills:** `counterpart: horse.mounted.canter`, `foundation: rider.mounted.trot (introductory)`, `theory: rider.theory.gaits_footfalls`, `next: rider.mounted.steering_navigation`
- **Current Levels (`availableLevels: ["introductory", "intermediate", "advanced"]`):**
  - **`introductory` (`v2`):** Establishing and maintaining balanced canter in a controlled downward transition; correct lead not required.
  - **`intermediate` (`v2`):** Selecting left/right leads, maintaining leads on turns/20 m circles, and simple lead changes.
  - **`advanced` (`v1`):** Requires **both deliberate counter-canter and clean, balanced flying lead changes** in order to achieve `Canter (Advanced)`.

### 4.2 Identified Educational Weaknesses
1. **Bundles Optional Specialized Applications Into Core `Canter (Advanced)`:** Requiring **flying lead changes** (and formal sustained counter-canter patterns) inside `rider.mounted.canter` conflates **fundamental canter horsemanship** (within-gait adjustability, uphill balance, rhythm, lead literacy, straightness, relaxation, and welfare adaptation across varied terrain/curves) with specialized event/training maneuvers that many skilled trail, endurance, driving-crosstrained, therapeutic, or young-horse riders neither need nor ask of every horse.
2. **Sparse Safety & Welfare Checks:** Needs explicit footing/turn-radius awareness and explicit welfare interpretation when a horse cross-canters, rushes, or refuses one lead (saddle fit, soreness, conditioning, rider crookedness).
3. **Missing Biomechanical Feel & Inclusivity:** Needs clearer kinesthetic guidance for `Introductory` (preparing calm walk/trot rather than running a faster trot into canter; allowing full seat or light/two-point seat on light contact or loose rein) and `Intermediate` (feeling which shoulder/hip advances without looking down; mentioning ~20 m circles only as one example alongside open curves).

### 4.3 Proposed Revised Content (`rider.mounted.canter`) — *Fundamental Canter Scope*

- **Skill ID:** `rider.mounted.canter` *(preserved)* · **Name:** `Canter` *(unchanged)*
- **Aliases:** `["Lope", "Canter depart", "Canter leads", "Lope leads", "Simple lead change", "Balanced canter", "Canter stride adjustability"]` *(note: `"Counter-canter"` and `"Flying lead change"` move to the dedicated proposed optional skill(s) when created—or remain searchable aliases on the new skill ID)*
- **Summary:** `"Preparing, following, and regulating the three-beat canter or lope with balance, rhythm, lead literacy, simple lead changes, and within-gait stride adjustability—prioritizing horse comfort and relaxation across disciplines."`
- **Purpose:** `"Develops hip suppleness, rhythmic core stability, accurate lead feel, and adaptable balance in the three-beat gait without equating speed or specialized arena tricks with advanced horsemanship."`
- **Safety:**
  - `"Establish calm walk and trot control, clear steering, and safe spacing from other horses or hazards before cantering."`
  - `"Evaluate footing, traction, slope, and turn radius before asking for canter; avoid tight turns or unbalanced departures on slick, deep, or rocky ground."`
  - `"Treat repeated rushing, cross-cantering, hollowing, or one-sided lead resistance as important feedback—slow down and assess saddle fit, physical soreness, conditioning, footing, or your own straightness."`
- **Related Skills:**
  - `{"skillId": "horse.mounted.canter", "relation": "counterpart"}`
  - `{"skillId": "rider.mounted.trot", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "rider.mounted.steering_navigation", "relation": "next"}`
  - `{"skillId": "rider.mounted.transitions", "relation": "next"}`
  - *(When approved & authored: `next` → `rider.mounted.counter_canter_lead_changes`)*
  - `{"skillId": "rider.theory.gaits_footfalls", "relation": "theory"}`
  - `{"skillId": "rider.theory.balance_weight", "relation": "theory"}`
  - `{"skillId": "rider.theory.pain_discomfort_fatigue", "relation": "theory"}`

### 4.4 Proposed Difficulty Criteria for Core `rider.mounted.canter` (`availableLevels: ["introductory", "intermediate", "advanced"]`)

| Dimension | Proposed **Introductory** *(Editorial Enrichment)* | Proposed **Intermediate** *(Editorial Enrichment)* | Proposed **Advanced** *(`v2` — Focused Fundamental Mastery, No Flying Changes Required)* |
| :--- | :--- | :--- | :--- |
| **Overview** | Preparing a calm depart from walk or trot, following the forward three-beat motion comfortably in a full or light/two-point seat (on light contact or a loose rein), and returning smoothly to trot or walk. *(Correct lead selection not required.)* | Preparing requested left and right leads from walk or trot, feeling which lead the horse is on without looking down, balancing curves and open turns smoothly, riding calm simple lead changes, and handling wrong leads or cross-cantering thoughtfully. | Refined fundamental canter mastery: regulating stride length and balance cleanly within the three-beat gait (without rushing), staying poised and aligned through varied lines, curves, terrain, or pace transitions suited to the horse, and adapting requests promptly for equine soundness and mental relaxation. *(Flying lead changes and formal counter-canter are separated into optional advanced applications.)* |
| **Educational Components** *(Understanding · Execution · Feel · Observation · Welfare)* | 1. **Calm preparation vs. running the trot:** Preparing a rhythmic walk or trot before asking rather than pushing faster until the horse falls onto the forehand into canter.<br>2. **Following 3-beat feel & non-restrictive balance:** Allowing hips/pelvis to sweep cleanly with the stride in either full seat or light/two-point seat without gripping knees or balancing on the reins.<br>3. **Controlled downward returns:** Exhaling, stabilizing the core, and returning smoothly to trot or walk while space remains safe. | 1. **Lead feel & anatomy without looking down:** Understanding the lead leg advances farther and recognizing the alternating forward swing of your corresponding hip/shoulder.<br>2. **Curves, alignment & simple changes:** Aligning your shoulders and weight cleanly around turns and generous circles (such as ~20 m arena circles or open sweeping curves) without leaning inward; riding calm simple changes through walk or trot.<br>3. **Constructive correction & welfare awareness:** Feeling an unintended wrong lead or disunited stride promptly, transitioning calmly back to rebalance instead of yanking, and noting persistent one-sided struggle as possible discomfort or rider bias. | 1. **Within-gait adjustability (never speed = ability):** Lengthening and shortening canter stride cleanly through seat, core tone, and release timing while maintaining calm three-beat rhythm rather than flattening/accelerating or pulling back.<br>2. **Uphill balance, straightness & adaptability:** Keeping balanced alignment across varied lines, turns, open space, and direct or progressive transitions appropriate to the horse's build and discipline—adapting contact, posture (seat vs. light seat), and pace thoughtfully.<br>3. **Observing subtle fatigue or tension:** Reading shortening breath, stiffening back, or late hind engagement early so work stays fair and constructive. |
| **Learning** | Departs for short stretches with guidance; seat, hands, or breathing occasionally brace during transitions, or trot speeds up before the depart. | Selects leads, balances curves, and rides simple changes with occasional wrong-lead starts, looking down to check, leaning inward, or hurried change transitions. | Practices within-gait lengthenings/shortenings and varied balanced canter work with intermittent flattening, bracing against the mouth, crookedness, or late posture adjustments. |
| **Proficient** | Independently prepares a balanced walk or trot, asks calmly for canter, follows the three-beat motion comfortably in full or light seat without balancing off the reins, guides simple lines/curves, and makes a controlled downward transition. *Correct lead selection is not required.* | Independently prepares and asks for left and right leads from walk or trot, identifies leads by feel, maintains steady three-beat balance through turns and generous curves on light contact or a loose rein, performs calm simple lead changes, and transitions smoothly to fix unintended or disunited leads. | Independently rides a relaxed, balanced three-beat canter/lope with clear within-gait stride adjustability (lengthening and shortening without rushing), straight alignment, smooth balance across varied lines and transitions suited to the horse and footing, and attentive welfare-based adaptation. *(Flying lead changes and sustained formal counter-canter are optional specialized applications, not required here.)* |

### 4.5 Proposed Separation for Optional Advanced Canter Applications *(PROPOSED NEW SKILL(S))*

> **Explicit Status Label:** **PROPOSED NEW SKILL PAIR (or Split Pair) — Does not currently exist in `curriculum/v2/`.**
> Preserves all 3 levels on `rider.mounted.canter` (critical for `curriculum_validator.js:600-610` protection of existing progress!) while freeing `Canter (Advanced)` to mean **fundamental mastery of the gait across all disciplines**, and housing specialized lead-change / counter-canter mechanics in its own optional, clearly labeled branch:

- **Recommended Option A — Single Optional Skill Pair: `Counter-Canter & Flying Lead Changes`**
  - **Proposed Rider ID:** `rider.mounted.counter_canter_lead_changes` *(in family `rider.mounted.gaits_rhythm_transitions`)*
  - **Proposed Horse ID:** `horse.mounted.counter_canter_lead_changes` *(in family `horse.mounted.gaits_rhythm_transitions`)*
  - **Foundation / Links:** `foundation: rider.mounted.canter (intermediate)` (or `advanced`), symmetric `counterpart` between Rider and Horse.
  - **Levels:**
    - **`Intermediate` (Counter-Canter Balance & Awareness):** Deliberately maintaining balanced counter-canter along shallow curves or lines with calm outside-bend alignment and relaxation without unintentional lead swaps. *(Optional for riders/horses whose work calls for counter-canter.)*
    - **`Advanced` (Clean Flying Lead Changes):** Preparing straightness, rhythm, and suspension timing to execute clean, calm, simultaneous front-and-hind flying lead changes in both directions without rushing, late hind changes, or tension—always respecting physical and mental readiness.
- **Alternative Option B — Separate Two Skills if Preferred:**
  - Keep **`Counter-Canter`** and **`Flying Lead Changes`** as two distinct optional skills if Matt prefers trail/dressage riders who teach counter-canter without flying changes—or Western riders who focus on flying changes without extended dressage counter-canter—to log each independently.
- **Safety & Compatibility Note for Existing `Canter (Advanced)` Verifications:** Check `rider.mounted.canter`'s `legacyIds` — it ONLY maps `["rider.mounted.canter"]` (`Introductory`). Separating flying changes out of `rider.mounted.canter.advanced` **broadens fairness** without deleting any level; companion updates to `horse.mounted.canter.advanced` would follow the exact same separation in Wave 2 so Rider & Horse stay aligned. See **[§8](#8-assessment-persistence--standardversion-compatibility-audit)** regarding the `v1 → v2` bump on `advanced`.

### 4.6 Questions for Matt's Professional Judgment
1. Do you prefer **Option A** (one optional skill pair: `Counter-Canter & Flying Lead Changes`) or **Option B** (two separate optional skills: `Counter-Canter` and `Flying Lead Changes`)?
2. Confirm that keeping `rider.mounted.canter` at 3 levels—with `Advanced` centered on **within-gait stride adjustability, uphill balance, varied curves/terrain, and welfare adaptation** rather than flying changes—matches your standard for advanced fundamental canter?

---

## 5. Example 4 — Rider: Training Principles & Progression (`rider.theory.training_pyramid` in Family `rider.theory.training_principles` · Existing Family & Flagship Skill)

> **Structural Note:** `Training Principles & Progression` (`rider.theory.training_principles`) is an existing **Skill Family** containing `rider.theory.training_pyramid` (*Understanding the Training Pyramid*), `rider.theory.progressive_conditioning` (*Progressive Training & Conditioning*), and `rider.theory.session_planning` (*Planning & Evaluating Training Sessions*).

### 5.1 Current Content & Weaknesses (`rider.theory.training_pyramid`)

- **Current Strengths Worth Preserving:** Explicitly introduces the six elements (rhythm, suppleness/relaxation, contact/connection, impulsion, straightness, collection) as an *"interdependent, adaptable framework rather than a rigid one-way ladder"* across Western, English, trail, ranch, driving, and general horsemanship.
- **Identified Weaknesses:**
  1. **Mandatory Mentoring in `Advanced`:** `Proficient` states *"Synthesizes the six interdependent elements with biomechanics and learning theory to evaluate complex training situations **and mentor others clearly across disciplines.**"* Experienced horsemen and horsewomen who develop horses independently without coaching people should not be blocked from `Advanced`. *(Same `"mentoring others"` pattern appears in `session_planning`, `timing_reinforcement`, `ethical_training`, `understanding_rider_aids`, and `training_equipment`.)*
  2. **Stronger Multi-Tradition Neutrality & Actionability:** Should clarify that riders using positive reinforcement, natural/ranch horsemanship, loose-rein Western/trail work, gaited breeds, or driving traditions can meet **every level** using plain movement/relaxation/learning principles without adopting dressage jargon or a rigid cueing school.
  3. **Missing Theory Links:** Lacks `foundation` to `rider.theory.how_horses_learn` and `next` links to `session_planning` and `transitions`.

### 5.2 Proposed Revised Content (`rider.theory.training_pyramid`)

- **ID:** `rider.theory.training_pyramid` *(preserved)* · **Recommended Display Name:** `Training Principles & the Training Pyramid` *(keeps `"Understanding the Training Pyramid"` in `aliases[]`)*
- **Aliases:** `["Understanding the Training Pyramid", "Training Scale", "Skala der Ausbildung", "Six elements of training", "Rhythm relaxation connection impulsion straightness collection", "Training principles"]`
- **Summary:** `"Applying core progressive horsemanship principles—and using the six Training Pyramid elements (rhythm, relaxation, connection, impulsion, straightness, collection) as a flexible, non-exclusive lens—to support calm, sound development across all disciplines."`
- **Purpose:** `"Equips equestrians across trail, ranch, Western, English, gaited, driving, and general horsemanship to evaluate physical and mental readiness, prioritize clarity and welfare over force, and adapt training thoughtfully to each horse."`
- **Safety:**
  - `"Never force collection, speed, or demanding exercises when a horse lacks mental relaxation, adequate warm-up, physical comfort, or steady rhythm."`
  - `"Do not mistake stiffly tucked heads, hurried tempo, or learned helplessness/shutdown for true relaxation, energy, or collection."`
  - `"Reassess comfort, hooves, dental health, tack fit, and emotional load whenever recurring tension disrupts rhythm or willingness."`
- **Related Skills:**
  - `{"skillId": "rider.theory.how_horses_learn", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "rider.theory.balance_weight", "relation": "next"}`
  - `{"skillId": "rider.theory.progressive_conditioning", "relation": "next"}`
  - `{"skillId": "rider.theory.session_planning", "relation": "next"}`
  - `{"skillId": "rider.mounted.half_halt", "relation": "next"}`
  - `{"skillId": "rider.mounted.transitions", "relation": "next"}`

### 5.3 Proposed Difficulty Criteria (`availableLevels: ["introductory", "intermediate", "advanced"]`)

| Dimension | Proposed **Introductory** | Proposed **Intermediate** | Proposed **Advanced** (`v2` — No Mentoring Required) |
| :--- | :--- | :--- | :--- |
| **Overview** | Understanding how core principles—calm mental state, steady rhythm, relaxation, soft non-restrictive connection, and patient progression—apply practically across any horsemanship tradition (using the Training Pyramid as one accessible guide, never a rigid checklist). | Observing horses in real situations to recognize which foundational principle needs attention (comfort, emotional composure, rhythm, relaxation, connection, or straightness) and choosing humane, practical next priorities instead of forcing symptoms. | Independently synthesizing movement principles, learning theory, conditioning limits, and equine welfare to guide complex, ambiguous, or varied horses across disciplines without dogma or coaching prerequisites. |
| **Educational Components** *(Method-Neutral Practical Principles)* | 1. **One useful map, not the only path:** Explaining the six Training Pyramid concepts in everyday words alongside core horse-first priorities (mental safety, clear cues, physical comfort)—recognizing how they translate equally to loose-rein trail riding, ranch work, driving, gaited horses, or arena riding.<br>2. **Relaxation before precision:** Understanding why tension blocks learning and why true connection does not require tight rein pressure.<br>3. **Common mistakes:** Treating elements as a strict one-way ladder, pulling a head down without back/emotional relaxation, or pushing through confusion. | 1. **Reading movement & tension clusters:** Spotting false framing, rushing passing as impulsion, braced backs/jaws, and crooked drifting on the ground or under saddle.<br>2. **Cycling back & ethical adjustment:** Knowing when to lower intensity, widen turns, clarify timing (`timing_reinforcement`), or investigate physical comfort.<br>3. **Tradition-agnostic comparison:** Seeing how different legitimate methods address rhythm, balance, and clarity without forcing identical posture or gear. | 1. **Adapting to individual horses & disciplines:** Prioritizing thoughtfully across young horses, senior horses, gaited/ambling breeds, heavy/draft or ranch types, positive-reinforcement programs, or horses returning from time off or injury.<br>2. **Root-cause synthesis & welfare judgment:** Weighing subtle interactions between soreness (`pain_discomfort_fatigue`), hoof/tack mechanics, learning history, and fitness timelines.<br>3. **Ethical stewardship:** Choosing long-term soundness and trust over rushed external timelines or mechanical shortcuts *(entirely independent of teaching or mentoring other people)*. |
| **Learning** | Recognizes terms like rhythm and relaxation, while sometimes viewing the Training Pyramid as a rigid step-by-step test or confusing neck flexion with balance. | Spots imbalances in theory or clear video, while still practicing real-time troubleshooting to trace tension back to timing, comfort, or foundational rhythm. | Applies adaptable, method-neutral principles comfortably to familiar horse types while refining balanced judgment across unfamiliar conformations, disciplines, or subtle multi-factor cases. |
| **Proficient** | Plainly explains core training priorities and the six Training Pyramid elements as one helpful, non-exclusive framework, describes how mental relaxation and rhythm support any riding or handling tradition, and avoids equating tight headset or speed with healthy training. | Independently observes horses on the ground or under saddle across contexts, distinguishes calm relaxation and balanced engagement from brace or rushing, and selects sensible, humane next adjustments or comfort checks without escalating force. | Independently synthesizes movement frameworks, learning theory, conditioning, and welfare ethics to evaluate complex horsemanship situations and adapt long-term training methods thoughtfully across diverse horses and traditions. *(No teaching or mentoring role required.)* |

*Companion Alignment Note (`rider.theory.session_planning.advanced`):* Under the same standard, `session_planning.advanced` removes `"mentoring others in reflective evaluation"` and evaluates autonomous longitudinal session review, spotting subtle multi-factor plateaus, and adapting multi-week conditioning/training plans across diverse horses.

### 5.4 Questions for Matt's Professional Judgment
1. Confirm removing `"mentoring others"` across **all Theory `Advanced` levels** (`training_pyramid`, `session_planning`, `timing_reinforcement`, `ethical_training`, `understanding_rider_aids`, `training_equipment`) so self-directed horsemen/horsewomen can earn `Advanced` without coaching other riders?
2. Keep the display title `"Understanding the Training Pyramid"` or rename cleanly to `"Training Principles & the Training Pyramid"` (preserving ID `rider.theory.training_pyramid`)?

---

## 6. Example 5 — Horse: In-Hand Yielding — Three Separate Proposed Horse Skills (`PROPOSED NEW SKILLS`)

> **Explicit Status Label:** **PROPOSED NEW SKILLS — None of these three skills currently exist in `curriculum/v2/skills_horse_in_hand.json`.**
> Following Matt's feedback, this replaces the earlier single-skill consolidation draft with **three separate, distinct Horse In-Hand skills** matching Rider In-Hand granularity (`rider.in_hand.turn_on_forehand`, `rider.in_hand.yield_forequarters`, `rider.in_hand.sidepass_in_hand`). Currently, all three Rider In-Hand yielding skills lack Horse counterparts.

### 6.1 Proposed Family Placement & Architecture

| Placement Option | Family Details | Pros & Cons | Technical Notes |
| :--- | :--- | :--- | :--- |
| **Recommended:** New Horse In-Hand Family **`horse.in_hand.ground_control_yielding`** (*Ground Control & Yielding*, `sortOrder: 15`) | Placed in `Horse → In_Hand` right after `horse.in_hand.leading_manners` (`sortOrder: 10`), housing all 3 new skills (`sortOrder: 10, 20, 30`). | • **Direct 1:1 structural parity** with Rider's `rider.in_hand.ground_control_yielding` (`sortOrder: 20`).<br>• Prevents overloading `Leading & Ground Manners` and matches how Horse & Rider already share mirrored family names across Mounted. | Adding `'horse.in_hand.ground_control_yielding': groundControlYielding` in [`skill_family_icon.dart`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/widgets/skill_family_icon.dart#L74-L107) reuses our existing SVG asset (just like the 6 shared Mounted families); fallback glyph works automatically if absent. |
| **Alternative:** Existing Family **`horse.in_hand.leading_manners`** (*Leading & Ground Manners*, `sortOrder: 10`) | Added as `sortOrder: 30, 40, 50` beneath `leading` and `standing_quietly`. | • Keeps total families fixed at 32 (4 Horse In-Hand families instead of 5).<br>• Slightly blurs everyday tie/leading manners with lateral gymnastic groundwork. | Requires zero icon-map edit in Dart. |

### 6.2 Symmetric Relationship Map (Three Distinct Horse ↔ Rider Pairs)

Notice [`curriculum_validator.js`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/curriculum_validator.js#L525-L535) strictly requires every `counterpart` edge to be **bidirectional and cross-subject**—meaning when authored, each existing Rider In-Hand skill receives its matching `counterpart` link back to its new Horse skill:

| Proposed Horse Skill | Symmetric `counterpart` | Internal Horse `foundation` Links | Internal Horse `next` Links *(to Mounted)* |
| :--- | :--- | :--- | :--- |
| **5A. Yielding the Hindquarters (In-Hand)** (`horse.in_hand.yield_hindquarters`) | `rider.in_hand.turn_on_forehand` *(Turn on the Forehand (In-Hand))* | `horse.in_hand.leading` (`introductory`) | `horse.in_hand.yield_forequarters`, `horse.in_hand.sidepass_in_hand`, `horse.mounted.turn_on_forehand` |
| **5B. Yielding the Forequarters (In-Hand)** (`horse.in_hand.yield_forequarters`) | `rider.in_hand.yield_forequarters` *(Turn on the Haunches (In-Hand))* | `horse.in_hand.leading` (`introductory`), `horse.in_hand.yield_hindquarters` (`introductory`) | `horse.in_hand.sidepass_in_hand`, `horse.mounted.turn_on_haunches` |
| **5C. Lateral Yielding / Sidepass (In-Hand)** (`horse.in_hand.sidepass_in_hand`) | `rider.in_hand.sidepass_in_hand` *(Sidepass (In-Hand))* | `horse.in_hand.yield_hindquarters` (`introductory`), `horse.in_hand.yield_forequarters` (`introductory`) | `horse.mounted.sidepass`, `horse.mounted.leg_yield` |

*(No skill locks another—a horse being evaluated for forequarter yielding or sidepass first never gets blocked by `foundation` links.)*

---

### 6.3 Skill 5A — Proposed New Skill: **Yielding the Hindquarters (In-Hand)** (`horse.in_hand.yield_hindquarters`)

- **Aliases:** `["Turn on the forehand (in-hand)", "Disengage the hindquarters (in-hand)", "Move the hips over (in-hand)", "Yield hindquarters (in-hand)"]` *(Alternative canonical slug: `horse.in_hand.turn_on_forehand`.)*
- **Summary:** `"The horse's calm comprehension, emotional composure, and coordinated hindquarter crossing when asked from the ground to step its hips aside around steadier shoulders."`
- **Purpose:** `"Builds respectful personal space, calmness during gating/saddling/vet prep, hind-end balance awareness, and clear groundwork readiness for mounted turning and lateral cues."`
- **Safety:**
  - `"Distinguish true calm understanding from flinging the hips in fear, spinning to escape, kicking out, or shutting down under excessive pressure."`
  - `"Work on level, non-slip footing and pause/release immediately when the horse makes a calm crossing effort."`
  - `"Repeated one-sided bracing, tail-wringing, or reluctance to step across can indicate hip, stifle, hock, or back discomfort—assess soundness rather than escalating pressure."`
- **Difficulty Criteria (`availableLevels: ["introductory", "intermediate"]`):**

| Dimension | Proposed **Introductory** (`v1`) | Proposed **Intermediate** (`v1`) |
| :--- | :--- | :--- |
| **Overview** | From halt or a quiet pause, calmly understanding light ground requests in both directions to step the hindquarters aside around relatively steady shoulders and settle softly when the cue releases—without flight, spinning, or bracing. | Smooth, rhythmic, coordinated hindquarter yielding in both directions from halt or active walk with minimal unwanted forward/backward drift, calm adaptability in varied practical settings (gates, trails, tight spaces), and immediate relaxation on release. |
| **Educational Components** *(Five Horse Lenses)* | 1. **Calm understanding vs. escape:** Stepping smoothly with relaxed jaw/breathing and steady attention rather than whipping the hips away in alarm, pinning ears, or freezing.<br>2. **Developing crossing coordination & pause:** Crossing the inside hind leg comfortably in front of the outside hind without tangling or rushing, then pausing quietly on release.<br>3. **Early comfort awareness:** Showing manageable left/right differences naturally while distinguishing stiffness from sudden discomfort. | 1. **Balance from walk or halt:** Shifting cleanly between straight forward walk and coordinated hindquarter yielding without tripping, dropping heavily onto the forehand, or backing out.<br>2. **Adaptability & light responsiveness:** Answering subtle changes in handler posture or light touch calmly in unfamiliar or tighter contexts (such as opening space at a gate or beside a trailer). |
| **Learning** | Responds in familiar spaces with brief hesitation, crowding, drifting forward or backward, hurried steps on one side, or mild tension before settling. | Connects walk and fuller hindquarter turns in both directions with intermittent forward/backward drift, uneven crossing rhythm, or mild tension around distractions. |
| **Proficient** | Calmly understands light ground cues from halt to step its hindquarters aside cleanly in both directions with soft expression, comfortable posture, and balanced crossing steps—without fleeing, rushing, or bracing—and settles quietly when the cue releases. | Smoothly and reliably yields its hindquarters around steadier shoulders from halt or walk in both directions on light ground cues, maintaining balanced rhythm, minimal unwanted drift, and relaxed attentiveness across everyday and busier settings. |

---

### 6.4 Skill 5B — Proposed New Skill: **Yielding the Forequarters (In-Hand)** (`horse.in_hand.yield_forequarters`)

- **Aliases:** `["Turn on the haunches (in-hand)", "Move the shoulders over (in-hand)", "Forequarter yield (in-hand)", "Yield shoulders in-hand"]`
- **Summary:** `"The horse's calm comprehension and coordinated shoulder crossing when asked from the ground to step its forequarters aside around steadier hindquarters without crowding or rushing backward."`
- **Purpose:** `"Develops respectful shoulder boundaries, balanced forehand lightness, and foundational understanding that supports trailer positioning, gate alignment, and mounted turns on the haunches."`
- **Safety:**
  - `"Distinguish calm understanding from head-tossing, running backward in worry, or crowding forward into the handler's space."`
  - `"Maintain clear, polite spacing and check shoulder, neck, hoof, or knee comfort if a horse repeatedly stiffens or resists stepping across in one direction."`
- **Difficulty Criteria (`availableLevels: ["introductory", "intermediate"]` — or `["intermediate"]`-only option in §6.6):**

| Dimension | Proposed **Introductory** (`v1`) | Proposed **Intermediate** (`v1`) |
| :--- | :--- | :--- |
| **Overview** | From halt or quiet walk, calmly understanding light ground requests to step the shoulders aside in both directions without throwing the head up, rushing backward, or walking into the handler, and pausing softly on release. | Coordinated, balanced shoulder yielding around relatively quiet hindquarters in both directions from halt or walk on light requests—staying relaxed, avoiding unwanted backward drift or pivoting on a stuck hind leg, and adapting calmly in varied spaces. |
| **Educational Components** *(Five Horse Lenses)* | 1. **Confidence with shoulder requests:** Accepting requests near the head, neck, or shoulder calmly (an area where sensitive horses easily feel trapped or pushed backward) rather than backing abruptly or raising the head defensively.<br>2. **Clean foreleg stepping & boundary respect:** Stepping the outside front leg calmly around/across while respecting the handler's space and settling promptly when pressure releases. | 1. **Active hindquarter organization:** Allowing the hind feet to remain relatively anchored without twisting awkwardly or stepping steadily backward while shoulders cross smoothly.<br>2. **Walk-to-yield flow & real-world composure:** Coordinating smooth shoulder redirection during leading, alignment at gates, or handling in busier environments on light cues. |
| **Learning** | Steps shoulders aside in familiar spaces with occasional backward steps, raised head/neck tension, drifting toward the handler, or hesitation on the stiffer side. | Guides fuller forequarter yields and walk redirections in both directions with intermittent backward drift, rushed front steps, or uneven bend. |
| **Proficient** | Calmly understands light ground requests to step its shoulders aside in both directions with relaxed head/neck posture, polite personal-space respect, and settled pauses on release—without rushing backward or crowding. | Smoothly and reliably yields its forequarters around relatively steady hindquarters from halt or walk in both directions on light ground requests, maintaining balanced foreleg crossing, relaxed posture, and adaptability in varied settings without unintended backing. |

---

### 6.5 Skill 5C — Proposed New Skill: **Lateral Yielding / Sidepass (In-Hand)** (`horse.in_hand.sidepass_in_hand`)

- **Aliases:** `["Sidepass (in-hand)", "Sidepass from the ground (horse)", "Full-body lateral yield (in-hand)", "Yielding sideways (in-hand)"]` *(Alternative canonical slug: `horse.in_hand.lateral_yielding`.)*
- **Summary:** `"The horse's calm comprehension and balanced full-body coordination when stepping sideways from the ground with shoulders and hindquarters moving evenly together."`
- **Purpose:** `"Integrates front- and hind-end ground communication into smooth, parallel sideways movement for gates, mounting blocks, tight maneuvering, and future mounted lateral balance."`
- **Safety:**
  - `"Introduce sideways coordination gradually on open, level, non-slip ground—release promptly on small straight steps rather than squeezing harder when either end lags."`
  - `"Never use ground rails or obstacles until the horse understands light sideways cues calmly in open space; investigate back, rib, hoof, or limb soreness if consistent asymmetry or tension persists."`
- **Difficulty Criteria (`availableLevels: ["introductory", "intermediate"]` — or `["intermediate"]`-only option in §6.6):**

| Dimension | Proposed **Introductory** (`v1`) | Proposed **Intermediate** (`v1`) |
| :--- | :--- | :--- |
| **Overview** | Calmly understanding light ground cues on open ground to coordinate both shoulders and hindquarters sideways in both directions with developing straightness, staying emotionally relaxed without panicking or running forward/backward, and pausing quietly on release. *(No rails or obstacles required.)* | Reliable, coordinated, balanced sideways stepping in both directions with shoulders and hindquarters staying largely parallel on light ground requests, calmly adaptable across everyday practical contexts *(such as aligning beside a mounting block, gate, or **optional** ground rail)*. |
| **Educational Components** *(Five Horse Lenses)* | 1. **Understanding combined sideways cues:** Translating light simultaneous/alternating ground requests into calm sideways steps rather than spinning the hips or escaping forward/backward.<br>2. **Developing alignment & calm pause:** Beginning to move front and hind ends together comfortably (recognizing one end often tries to lead early on) and settling peacefully when released.<br>3. **Emotional composure:** Keeping relaxed breathing, ear/eye softness, and unhurried rhythm without feeling hemmed in. | 1. **Even, parallel lateral coordination:** Crossing both front and hind pairs rhythmically sideways in both directions with minimal shoulder or hip lag and minimal unwanted forward/backward drift.<br>2. **Adaptability in practical contexts:** Applying light sideways alignment calmly around barn doors, mounting areas, trail gates, or optional ground poles without pawing, rushing, or losing composure.<br>3. **Soundness & comfort check:** Maintaining willing back/rib suppleness on both sides. |
| **Learning** | Attempts sideways steps on open ground with shoulders or hindquarters lagging, occasional forward/backward drifting, hurried bursts, or mild tension between left and right sides. | Moves sideways in both directions with intermittent unevenness between front and hind crossing, minor forward/backward drift, or distraction around gates, mounting blocks, or rails. |
| **Proficient** | Calmly understands light ground cues on open, flat ground to step both front and hind ends sideways in both directions with unhurried composure, developing straightness, and a relaxed pause when released—without fleeing, crowding, or rushing. | Smoothly and reliably steps sideways in both directions on light ground cues with front and hind quarters staying calmly parallel and coordinated, maintaining steady unhurried rhythm and composure across varied practical contexts *(with any rail or obstacle context remaining optional)*. |

### 6.6 Questions for Matt's Professional Judgment
1. **Family Placement:** Do you prefer adding **`horse.in_hand.ground_control_yielding`** (*Ground Control & Yielding*, matching Rider) or placing these three skills inside **`horse.in_hand.leading_manners`**?
2. **Naming Clarity:** For Skill 5A, do you prefer `Yielding the Hindquarters (In-Hand)` (`horse.in_hand.yield_hindquarters`) or `Turn on the Forehand (In-Hand)` (`horse.in_hand.turn_on_forehand`)? Similarly for 5B (`Yielding the Forequarters (In-Hand)`) and 5C (`Lateral Yielding / Sidepass (In-Hand)`)?
3. **Level Parity:** Should **5B (Yielding Forequarters)** and **5C (Lateral Yielding / Sidepass)** include **both `Introductory` + `Intermediate`** as drafted above (giving green horses credit for early calm understanding on open ground), or match Rider's current `Intermediate`-only setup? *(Note: if we add `Introductory` here, we can align `rider.in_hand.yield_forequarters` and `rider.in_hand.sidepass_in_hand` in Wave 2 without removing any existing Rider level.)*

---

## 7. Example 6 — Horse: Rein Back (`horse.mounted.rein_back` · Existing Skill)

> **Context Note:** Basic in-hand backing sits inside `horse.in_hand.leading` (`Introductory`). `horse.mounted.rein_back` evaluates under-saddle rein-back.

### 7.1 Current Content (`curriculum/v2/skills_horse_mounted.json`)

- **Family:** `horse.mounted.pivots_body_control` (*Pivots & Body Control*) · **ID:** `horse.mounted.rein_back` · **Name:** `Rein Back (Under Saddle)`
- **Aliases:** `["Back through L obstacle (under saddle)", "Rein back (under saddle)"]`
- **Summary:** `"The horse's ability to step calmly backward in a diagonal two-beat pattern on light requests—on straight lines or through narrow/L-shaped boundaries."`
- **Purpose:** `"Demonstrates softness, straightness, and cooperative maneuvering in tight spaces."`
- **Safety:** `["Reward single calm steps when introducing rein-back; never pull hard on the mouth."]`
- **Related Skills:** `counterpart: rider.mounted.rein_back`
- **Current Levels (`availableLevels: ["intermediate"]` — 1 level only, `v1`):**
  - *Overview:* `"Stepping calmly backward 3–5 diagonal steps in straight alignment and maneuvering backward through an L or corridor."`
  - *Learning:* `"Backs with occasional crookedness, hesitation, or boundary touches in an L."`
  - *Proficient:* `"Steps backward calmly in straight diagonal pairs on light requests—including through an L or corridor—without rushing, hollowing, or knocking boundaries."`

### 7.2 Identified Educational Weaknesses
1. **Conflates Entry Understanding With Tight Obstacle Maneuvering:** Only has `Intermediate`, requiring both `"3–5 diagonal steps"` and an L-shaped corridor obstacle before any under-saddle backing progress can be logged.
2. **Rigid Arbitrary Targets:** Fixed step counts (`"3–5"`), mandatory L-corridor patterns, and (in Revision 1) direct canter departures and overly specific idealized head/poll posture do not honor differences across conformations, breeds, ages, or disciplines.
3. **Missing Welfare & Graduated Progression:** Needs explicit physical comfort screening (hocks, stifles, lumbar back, teeth, saddle fit) plus three clear stages: *fundamental understanding* (`Introductory`), *developing coordination* (`Intermediate`), and *advanced adaptability* (`Advanced`).

### 7.3 Proposed Revised Content (`horse.mounted.rein_back`)

- **Skill ID:** `horse.mounted.rein_back` *(unchanged)* · **Name:** `Rein Back (Under Saddle)` *(unchanged)*
- **Aliases:** `["Back up (under saddle)", "Back through L obstacle (under saddle)", "Rein back (under saddle)", "Reculer (horse)"]`
- **Summary:** `"The horse's calm comprehension, developing diagonal coordination, and adaptable balance when stepping backward under saddle—progressing from quiet foundational understanding to steady two-beat rhythm and versatile real-world balance."`
- **Purpose:** `"Builds attentive softness to light under-saddle requests, thoughtful body coordination, hindquarter weight acceptance, and calm confidence for everyday maneuvering, gates, trails, and balanced transitions."`
- **Safety:**
  - `"Introduce under saddle only after the horse halts settled under a rider and steps back calmly in-hand; release pressure immediately on calm tries rather than pulling continuously on the mouth."`
  - `"Practice on level, non-slip footing with open, clear space behind so the horse feels safe."`
  - `"Stepping backward requires healthy flexion of the hocks, stifles, and lumbar spine—if a horse persistently hollows, tosses its head, drags toes, or refuses despite clear, light requests, check hock/stifle/back comfort, dental wear, and saddle fit rather than escalating force."`
- **Related Skills:**
  - `{"skillId": "rider.mounted.rein_back", "relation": "counterpart"}`
  - `{"skillId": "horse.in_hand.leading", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "horse.mounted.transitions", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "horse.mounted.object_handling", "relation": "next"}`

### 7.4 Proposed Difficulty Criteria (`availableLevels: ["introductory", "intermediate", "advanced"]`)

| Dimension | Proposed **Introductory** *(NEW Level · `v1`)*<br>*(Fundamental Understanding)* | Proposed **Intermediate** (`v2`)<br>*(Developing Coordination)* | Proposed **Advanced** *(NEW Level · `v1`)*<br>*(Advanced Adaptability)* |
| :--- | :--- | :--- | :--- |
| **Overview** | **Fundamental understanding:** From a settled halt in calm, open space, calmly understands a light under-saddle request to shift weight back and take unhurried backward steps with comfortable, unbraced posture, then settles quietly into halt when the request releases. *(No minimum step count or obstacle patterns.)* | **Developing coordination:** Steps backward willingly in rhythmic **diagonal two-beat pairs** on light cues with comfortable, functional posture suited to the horse's individual build—showing straightness and responsiveness to light alignment adjustments, and returning calmly to halt or quiet walk. *(No mandatory L-corridors or step counts.)* | **Advanced adaptability:** Maintains poised, balanced diagonal coordination through varied backing demands—such as gentle curves, changes in alignment, varied footing or slight grades, busier environments, or optional practical obstacles (such as gates or tight boundaries)—and transitions smoothly and calmly between backing, halt, and appropriate forward movement (walk or trot) without tension or discomfort. *(No direct canter departure or one idealized head/neck posture required.)* |
| **Educational Components** *(Five Horse Lenses)* | 1. **Comprehension & composure over step counts:** Understanding light weight/rein/seat cues to yield backward calmly rather than panicking, bracing against the mouth, or running backward out of anxiety.<br>2. **Quiet settled pause:** Stopping calmly when cues release instead of continuing backward unexpectedly or lunging forward.<br>3. **Early comfort recognition:** Showing honest effort within comfortable posture natural to the horse's build, flagging stiffness or confusion gently rather than pushing into pain. | 1. **Two-beat diagonal coordination:** Moving diagonal front-and-hind pairs evenly and cleanly without dragging toes, pacing laterally, or rushing backward.<br>2. **Functional posture & alignment responsiveness:** Remaining soft through jaw, back, and balance appropriate to the horse's conformation/breed (without forcing an artificial frame) and responding politely to gentle shoulder or hip straightening requests.<br>3. **Smooth halt & forward exits:** Finishing backward movement quietly into balanced halt or unhurried walk. | 1. **Adaptable balance across terrain & curves:** Keeping steady diagonal rhythm, hindquarter weight acceptance, and emotional poise across curved backing paths, subtle terrain/grade variations, distracting venues, or optional practical tight-space tasks.<br>2. **Seamless gait transitions:** Stepping calmly from halt or walk into backing and moving smoothly forward again into balanced walk or trot on light requests without hollowing, rushing, or bracing. |
| **Learning** | Responds from halt with brief hesitation, crooked hindquarters, raised head or braced back, dragging feet, or stepping backward/forward unevenly when released. | Backs smoothly on flat straight lines with intermittent rushing, dragged hooves, stiffening, uneven alignment responses, or choppy exits into halt/walk. | Practices curved paths, varied terrain/settings, optional narrow boundaries, and smooth walk/trot transitions out of rein-back with occasional loss of straightness, rushed exits, or mild brace. |
| **Proficient** | Calmly understands light under-saddle requests from a settled halt on open ground to step smoothly backward unhurriedly within comfortable, unbraced posture natural to its build, and settles quietly into halt on release without panicking, hollowing defensively, or rushing. | Steps backward willingly in balanced, rhythmic two-beat diagonal pairs on light cues—staying comfortable and unbraced for its build, answering light alignment adjustments calmly, and transitioning quietly back to halt or walk without rushing, dragging, or bracing. | Consistently backs with poised, balanced diagonal coordination and soft responsiveness across varied alignments, curves, gentle terrain, busier environments, or optional tight spaces, and transitions smoothly between backing, halt, and balanced walk or trot on light requests without defensive tension or loss of comfort. |

### 7.5 Educational Rationale
Distinguishing **`Introductory` (fundamental comprehension & calm pause)**, **`Intermediate` (developing diagonal rhythm, straightness & functional comfort)**, and **`Advanced` (adaptability across curves, terrain, optional tight contexts & walk/trot transitions)** creates a deeply practical horsemanship arc without turning rein-back into a rigid obstacle test, step counter, dressage frame mandate, or canter-departure trick. Respecting conformation diversity ensures Quarter Horses, Warmbloods, Morgans, Thoroughbreds, gaited horses, and drafts are all judged on **relaxation, functional balance, and sound mechanics**, not one identical silhouette.

### 7.6 Questions for Matt's Professional Judgment
1. Does the progression across the 3 levels—**Intro** *(fundamental understanding)* → **Int** *(developing diagonal coordination)* → **Adv** *(advanced adaptability & walk/trot flow)*—fit all horse types cleanly?
2. Confirm aligning `rider.mounted.rein_back` cleanly in Wave 2 so Riders also aren't locked into mandatory L-corridor patterns?

---

## 8. Assessment Persistence & `standardVersion` Compatibility Audit

> **Why This Audit Was Necessary:** Before publishing any curriculum revision, we inspected the actual persistence, validation, Cloud Function, security rule, and Flutter UI implementations—without assuming that incrementing `standardVersion` is harmless.

### 8.1 How Publishing Touches Curriculum vs. User & Horse Assessment Data

1. **Publish paths never alter user or horse assessment records:**
   - **Admin UI / Cloud Function publish** ([`functions/curriculum_revisions.js:573-644`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/curriculum_revisions.js#L573-L644)) snapshots immutable revisions (`SkillTreeCurriculumRevisions`) and mirrors changes **only** to `SkillFamilies` and `SkillsV2`.
   - **CLI publish** ([`tool/publish_curriculum_v2.js:100-125`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/tool/publish_curriculum_v2.js#L100-L125)) writes **only** to `SkillFamilies` and `SkillsV2`. Neither path reads, resets, or modifies `SkillProgress`, `SkillVerifications`, or `SkillVerificationEvents`.
2. **Preservation rules enforced by backend & Dart validators:**
   - Verified in [`functions/curriculum_validator.js:575-643`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/curriculum_validator.js#L575-L643) and [`packages/database_repository/lib/src/curriculum_import_validator.dart:939-968`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/curriculum_import_validator.dart#L939-L968):
     - Published skill IDs, `subject`, existing `legacyIds`, and existing `availableLevels` **cannot be deleted**.
     - `standardVersion` **cannot decrease** below the published value (even on revision rollback, [`functions/curriculum_revisions.js:1158-1185`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/curriculum_revisions.js#L1158-L1185) increments `standardVersion` forward to `curVer + 1` when `proficient` differs).
     - **Important Validator Rule (`standardVersion` Trigger):** Editing `proficient.trim()` by even a single character on an existing published level **forces `standardVersion > publishedVersion`** when saving/publishing an Admin Draft ([`curriculum_validator.js:630-639`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/curriculum_validator.js#L630-L639)) and automatically checks *"Mark as revised standard"* in [`curriculum_draft_dialogs.dart:469-481,898-934`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/widgets/curriculum_draft_dialogs.dart#L469-L481). By contrast, editing `overview`, `components[]`, `learning`, `summary`, `purpose`, `safety[]`, `aliases[]`, or `relatedSkills[]` does **not** force a `standardVersion` bump.
     - **CLI Gap:** [`tool/validate_curriculum_v2.js`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/tool/validate_curriculum_v2.js#L35-L42) invokes `validateCurriculum` *without* `publishedSkills`, so CLI publishing does not automatically verify `standardVersion` bumps against Firestore unless checked explicitly or mirrored via the Admin flow.

### 8.2 Exact Impact on Self-Assessed `Learning` and `Proficient` (`SkillProgress`)

- **Verified Data Schema & Rules:**
  - Inspected [`packages/database_repository/lib/src/models/skill_progress_v2.dart:16-124`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/models/skill_progress_v2.dart#L16-L124), [`skill_tree_v2_repository.dart:389-444`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/skill_tree_v2_repository.dart#L389-L444), and [`firebase/firestore.rules:52-90`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/firestore.rules#L52-L90).
  - Under `Rider_Profile/{id}/SkillProgress/{skillId}` and `Horse_Profile/{id}/SkillProgress/{skillId}`, each level stores **only**:
    - `state` (`'LEARNING'` or `'PROFICIENT'`)
    - `updatedAt`, `updatedByUid`, `updatedByName`
  - **`SkillProgress` does NOT store `standardVersion`**—and [`firestore.rules:63-65`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/firestore.rules#L63-L65) strictly locks `hasOnly(['state', 'updatedAt', 'updatedByUid', 'updatedByName'])`.
- **What Happens When Curriculum Content or `standardVersion` Changes:**
  - **Existing `Learning` and `Proficient` records are 100% preserved** and remain editable as long as `skill.status == 'active'` and the level stays in `availableLevels`.
  - **Edge Case — Silent Semantic Drift:** Because self-assessments have no `standardVersion` field, a rider or horse marked `Proficient` under `v1` silently continues showing `Proficient` under `v2` with **zero notice** in the UI that the criteria changed. *(Example: if a skill's `proficient` bar expanded significantly—say adding canter or flying changes—an earlier `Proficient` record could look misleading; conversely, when we remove over-prescribed hurdles like trot from `Leading Intro` or L-corridors from `Rein Back Int`, existing `Proficient` records remain cleanly valid.)*

### 8.3 Exact Impact on `Instructor Verified` Records (`SkillVerifications` & `SkillVerificationEvents`)

- **Verified Data Schema:**
  - Inspected [`functions/connections.js:1109,1139-1173`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/connections.js#L1109) and [`skill_progress_v2.dart:127-328`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/models/skill_progress_v2.dart#L127-L328).
  - Unlike `SkillProgress`, both `SkillVerifications/{skillId}.levels.<level>` and immutable `SkillVerificationEvents` **DO record `standardVersion`** (copied from `SkillsV2.{skillId}.levels.{level}.standardVersion` at the time the instructor clicked *Verify Proficient*).
- **What Happens When `definition.standardVersion` Increments (`v1 → v2`):**
  1. **Firestore records stay intact:** Existing `Instructor Verified` records are **never deleted, downgraded, or unverified**.
  2. **UI Behavior Across Screens:**
     - **Only ONE widget inspects `standardVersion`:** Inside [`skill_detail_v2_panel.dart:763-772`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart#L763-L772), when `verification!.standardVersion < definition.standardVersion`, the level section still shows the green `Verified by <Instructor>` chip AND displays the notice (`Key('verificationEarlierStandardNote')`):
       > *"Verified under Standard v1 (current: v2)."*
     - **Every other screen ignores `standardVersion` and treats the level as fully Verified:**
       - [`skill_detail_v2_panel.dart:298-299,427-435`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart#L427-L435) (level tabs still show `· Verified`)
       - [`skill_detail_v2_panel.dart:348-363`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart#L348-L363) (verification audit log does not show `standardVersion`)
       - [`skill_family_list_v2.dart:644-646,688-691`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/widgets/skill_family_list_v2.dart#L644-L646) (green verified pills on skill rows)
       - [`skill_tree_v2_helpers.dart:192-201,278-283`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart#L192-L201) (`computeAbilitySummary` and `SkillFamilyProgressSummary` count it as both `verified` and `proficient`)
       - [`profile_skills.dart:596,607-618,1200-1203`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/CommonWidgets/profile_skills.dart#L596-L620) (`Profile` dashboard badges & counts)
  3. **CRITICAL UX / WORKFLOW GAP DISCOVERED — Instructors Cannot Smoothly Re-Verify After a Version Bump:**
     - **Backend already supports in-place re-verification:** [`functions/connections.js:1100-1173`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/connections.js#L1100-L1173) allows calling `verifySkillLevel` when `previousLevel` exists—updating `SkillVerifications` cleanly to the new `standardVersion` and logging `previousVerification` inside the new `verified` event (without logging a revocation).
     - **However, the Flutter UI blocks this path!** [`skill_detail_v2_panel.dart:884-901`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart#L884-L901) hides the *"Verify Proficient"* button whenever `isVerified == true` (`if (!isVerified)`) and shows **only *"Revoke verification"***!
     - **Consequence:** Today, if `standardVersion` bumps `v1 → v2`, every previously verified student/horse sees *"Verified under Standard v1 (current: v2)."*—and if an instructor wants to confirm them under `v2`, the UI forces the instructor to click **"Revoke verification"** first (which creates a jarring *"removed verification"* journal/activity entry) before re-verifying!
     - **Conclusion:** Incrementing `standardVersion` is **data-safe**, **NOT UX-harmless** until the UI exposes a positive *"Confirm under current standard (vY)"* button when `verification.standardVersion < definition.standardVersion`.

### 8.4 Compatibility Summary Matrix

| Curriculum Edit Type | `Learning` (`SkillProgress`) | `Proficient` (`SkillProgress`) | `Instructor Verified` (`SkillVerifications`) | Triggers Validator `standardVersion` Bump? | Observed UI Impact & Caveat |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Edit `summary`, `purpose`, `safety[]`, `overview`, `components[]`, `learning`, `aliases[]`, `relatedSkills[]` only** | Preserved (`100%`) | Preserved (`100%`) | Preserved (`100%`), version matches | **No** *(optional checkbox in Draft UI)* | Zero stale-version notes; richest educational value (`purpose`, `safety[]`, `components[]`, `learning`) deploys cleanly with zero disruption. |
| **Edit `proficient` text on an existing level** *(even minor rewording)* | Preserved (`100%`), **unversioned** | Preserved (`100%`), **unversioned** *(no version notice)* | Preserved (`100%`); counts as Verified everywhere | **Yes — Mandatory** in Admin Draft/Publish ([`curriculum_validator.js:631`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/curriculum_validator.js#L631)) | Shows `"Verified under Standard v1 (current: v2)."` in detail panel; **blocked from smooth UI re-verification** without revoking first unless fixed. |
| **Add a missing level** *(e.g., `Intro` on Longeing; `Intro` & `Adv` on Horse Rein Back)* | Existing levels preserved; new level starts `Not Started` | Existing levels preserved | Existing levels preserved; `v1` on new level | Only on existing levels whose `proficient` changes | Safe, additive; existing learners keep `Int`/`Adv` progress intact. |
| **Narrow/broaden scope fairly** *(e.g., removing L-corridors from Rein Back Int; moving flying changes out of Canter Adv)* | Preserved (`100%`) | Preserved (`100%`) — prior `Proficient` stays fair/valid | Preserved (`100%`) | Yes, if `proficient` text changes | Less restrictive than old standard, so prior verifications remain genuinely earned *(note: `Canter Adv` holders originally met flying changes too)*. |
| **Add brand-new standalone skills** *(3 Horse In-Hand yielding skills; optional Flying Changes skill)* | Unchanged; new skills start `Not Started` | Unchanged | Unchanged | Starts at `v1` | Purely additive; legacy mappings (`legacyIds`) unaffected. |
| **Retire a skill (with optional `replacedBy`)** | Historical read preserved; edits blocked by [`firestore.rules:75`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/firestore.rules#L75) | Preserved historically | Preserved historically | N/A | Shows retired banner + replacement link. *(None of the 6 examples require retiring any skill.)* |

### 8.5 Unresolved Technical & Policy Questions for Matt's Approval

1. **Re-Verify UI Action Before Publishing Version Bumps (`SkillDetailV2Panel`):** Should we add a clean, non-destructive **"Confirm under current standard (vY)"** button inside [`skill_detail_v2_panel.dart:884-901`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart#L884-L901) (visible only to connected instructors when `isVerified && verification.standardVersion < definition.standardVersion`, wired straight to the existing `verifySkillLevel` Cloud Function with zero revocation event) **before** publishing curriculum waves that increment `standardVersion`?
2. **Self-Assessment Versioning Policy (`SkillProgress`):** Are you comfortable keeping `SkillProgress` **unversioned** (simple, zero schema/rules migration, silent continuity across edits), **or** would you want optional future `standardVersion` tracking on self-assessments so riders see a gentle *"Updated standard available to review"* reminder when a skill changes materially?
3. **Validator Behavior on Editorial Copy Tweaks (`curriculum_validator.js:631-638`):** Because any whitespace-trimmed character change to `proficient` forces a `standardVersion` bump, confirm our intended rule for future waves:
   - **Rule A (Recommended once Re-Verify UI is added):** Increment `standardVersion` whenever `proficient` wording changes (matching the existing validator), keeping `"Verified under Standard v1 (current: v2)"` honest while instructors can cleanly confirm `v2` if desired.
   - **Rule B (Optional future refinement):** Reserve `standardVersion` increments strictly for *substantive standard changes* vs. minor grammar fixes, updating the Admin validator checkbox if needed—or keep `proficient` wording untouched unless the standard truly changes.
4. **Badge Continuity Confirmation:** Confirm that preserving full **`Verified` badges and counts** everywhere on Profiles, Family Lists, and Summaries after a standard bump (showing only the informational `"Verified under Standard vX (current: vY)"` note inside the skill detail panel) reflects how you want earlier student/horse achievements honored.

---

## 9. Recurring Curriculum-Wide Standards for Subsequent Waves

Subject to Matt's approval on these six refined examples and the §8 technical questions, the following guardrails will govern Waves 2–5 across the remaining curriculum:

1. **Observable Understanding, Coordination, Willingness, Welfare & Adaptability First:** Write every standard around what can genuinely be observed or felt—never prescribed show patterns, mandatory step counts, rigid prop lists (poles, L-corridors), or one conformation-specific posture ideal.
2. **Separate Safety Essentials From Helpful Technique Examples:** Keep genuine safety boundaries explicit (rope wrapping, footing, kick zones, non-abusive headgear attachment, soundness pain checks) while presenting style choices (figure-8 vs. folded coils, turning away on inspections, cavesson vs. halter) as helpful techniques/examples.
3. **Decouple Complexity From Gait & Optional Specializations:** Ensure neither Horse nor Rider tiers equate trot/canter speed or specialized competitive maneuvers (like flying changes) with universal horsemanship progression; separate optional advanced branches cleanly where needed.
4. **Apply Four Rider Lenses & Five Horse Lenses Inside Existing JSON Fields:** Richly populate `purpose`, `safety[]`, `overview`, `components[]` (including feel, observation, common mistakes, and welfare checks), `learning`, and `proficient` without adding UI bloat or checklists.
5. **Preserve Method Neutrality & Remove Teaching Prerequisites:** Keep English, Western, trail, ranch, driving, gaited, and positive-reinforcement traditions equally welcome, and remove mandatory `"mentoring others"` requirements from all Theory `Advanced` tiers.
6. **Maintain 1:1 Horse ↔ Rider Structural & Graph Parity:** Complete missing Horse counterparts (beginning with the 3 separate In-Hand yielding skills), add `theory` links across practical skills, add internal Horse `foundation`/`next` links, and enforce symmetric `counterpart` links via `node tool/validate_curriculum_v2.js`.
7. **Disciplined `standardVersion` Governance:** Resolve the instructor re-verify UI gap (§8.5 Tech Q1) prior to publishing `v2` standards so existing `Learning`, `Proficient`, and `Instructor Verified` records stay seamlessly respected and actionable.

---

*Ready for Matt French's review and approval on the revised six examples, proposed new skill structures, and §8 technical compatibility questions before modifying any curriculum JSON, Firestore rules, or UI code.*
