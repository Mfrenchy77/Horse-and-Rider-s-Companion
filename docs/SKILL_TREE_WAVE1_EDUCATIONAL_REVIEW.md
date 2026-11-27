# Skill Tree — Wave 1: Educational Content Refinement Review

> **Status & Purpose:** Content-development and trainer review pass presenting **six representative educational examples** (side-by-side comparison of current vs. proposed content) for Matt French's professional evaluation **before** editing `curriculum/v2/*.json`. **No curriculum JSON files, skill IDs, family IDs, Flutter code, Firestore records, or progress states were modified.**

---

## 1. Philosophy, Educational Framework & Schema Alignment

This refinement pass treats our recovered Skill Tree philosophy as authoritative across [`SKILL_TREE_CURRICULUM_GUIDE.md`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/SKILL_TREE_CURRICULUM_GUIDE.md), [`SKILL_TREE_CURRICULUM_AUDIT_AND_DEVELOPMENT_PROPOSAL.md`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/SKILL_TREE_CURRICULUM_AUDIT_AND_DEVELOPMENT_PROPOSAL.md), and [`skill_tree_2_architecture_proposal.md`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/skill_tree_2_architecture_proposal.md):

- **Horsemanship is lifelong and nonlinear:** Skills never lock one another (`foundation`, `next`, `counterpart`, and `theory` remain helpful guidance, never gates).
- **Horse welfare takes priority:** Physical comfort, emotional safety, pain/stress recognition, and humane boundaries supersede performance polish or speed.
- **Independent development:** Horses and riders progress at different rates under independent profiles and without assuming one partner compensates for an unprepared partner unless specifically noted.
- **No completion scores or percentages:** Preserve exact states (`Not Started`, `Learning`, `Proficient`, and `Instructor Verified`) across meaningful difficulty tiers (`Introductory`, `Intermediate`, `Advanced`—no forced 3-level padding).
- **Complexity over speed:** Difficulty increases reflect deeper understanding, clearer coordination, finer observation, emotional self-regulation, and adaptability—never assuming a faster gait automatically marks higher horsemanship.
- **Technique neutrality across traditions:** Welcome English, Western, trail, ranch, driving, gaited, classical, and recreational horsemanship without mandating a single bit, halter, cueing formula, or training school.

### Applying the Four Rider & Five Horse Educational Lenses Within the Existing Schema

Rather than adding new database fields, UI checkboxes, or progress states, the revised examples weave all educational lenses directly into the validated V2 JSON fields (`functions/curriculum_validator.js`):

| Subject | Educational Lenses | Where Each Lens Lives in the Existing V2 Schema |
| :--- | :--- | :--- |
| **Rider** | **1. Understanding** *(purpose, principles, consequences)*<br>**2. Execution** *(clear aids/position, feel, release)*<br>**3. Observation** *(reading horse posture, balance, emotion, effort)*<br>**4. Adaptation** *(adjusting cues, pace, space, or task for the individual horse)* | • `purpose` & first `components[]` (*why & principles*)<br>• `components[]` (*what good feels like*, *common mistakes*, observable mechanics)<br>• `safety[]` & `components[]` (*early stress, fatigue, soreness, environment*)<br>• `learning` & `proficient` (*independent adaptive execution on a prepared horse*)<br>• `relatedSkills[]` (`theory`, `foundation`, `next`, `counterpart`) |
| **Horse** | **1. Understanding** *(comprehending light requests)*<br>**2. Confidence & Willingness** *(relaxed participation vs. tension/freeze)*<br>**3. Coordination & Balance** *(posture, rhythm, alignment)*<br>**4. Responsiveness** *(soft answers to fair communication)*<br>**5. Emotional & Physical Welfare** *(never treating horses as passive objects or using anthropomorphic labels)* | • `summary` & `purpose` (*why confidence and body coordination matter*)<br>• `safety[]` & `components[]` (*distinguishing comprehension from escape/freeze; ruling out physical pain*)<br>• `learning` & `proficient` (*observable equine posture, breathing, rhythm, willingness on fair requests*)<br>• `relatedSkills[]` (`counterpart`, `foundation`, `next`) |

### Overview of the Six Representative Examples

| # | Skill Example | Status | Current Levels | Proposed Levels | `standardVersion` Note |
| :---: | :--- | :--- | :--- | :--- | :--- |
| 1 | **Rider — Leading** (`rider.in_hand.leading`) | Existing Skill | `Intro`, `Int` (v1) | `Intro`, `Int` (v2) | Increment `Intro` & `Int` to `v2` (trot moved from `Intro` to `Int`) |
| 2 | **Rider — Longeing** (`rider.in_hand.longeing`) | Existing Skill | `Int`, `Adv` (v1) | `Intro` (new), `Int` (v2), `Adv` (v2) | `Intro` starts `v1`; increment `Int` & `Adv` to `v2` (gait/observation separation & wording fix) |
| 3 | **Rider — Canter** (`rider.mounted.canter`) | Existing Skill | `Intro` (v2), `Int` (v2), `Adv` (v1) | `Intro` (v2), `Int` (v2), `Adv` (v2) | `Intro`/`Int` editorial enrichments (`v2` unchanged); `Adv` increments to `v2` if counter-canter + flying-change nuance adjusts standard |
| 4 | **Rider — Training Principles & Progression** (`rider.theory.training_pyramid` in family `rider.theory.training_principles`) | Existing Flagship Skill & Family | `Intro`, `Int`, `Adv` (v1) | `Intro` (v2), `Int` (v2), `Adv` (v2) | Increment `Adv` to `v2` (removes mentoring requirement); companion note on `session_planning.advanced` |
| 5 | **Horse — In-Hand Yielding** (`horse.in_hand.yielding`) | **PROPOSED NEW SKILL** | *None* (only Rider has 3 yielding skills) | `Intro`, `Int` (v1) | New skill starting at `v1` (requires Trainer decision on family & consolidation) |
| 6 | **Horse — Rein Back** (`horse.mounted.rein_back`) | Existing Skill | `Int` (v1) only | `Intro` (new), `Int` (v2), `Adv` (new) | `Intro`/`Adv` start `v1`; `Int` upgrades to `v2` (diagonal rhythm & L-corridor framing) |

---

## 2. Example 1 — Rider: Leading (`rider.in_hand.leading` · Existing Skill)

### 2.1 Current Content (`skills_rider_in_hand.json`)

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
    - *Components:*
      1. **Position and rope management:** `"Keeping a safe shoulder-level position and slack/soft contact on the lead."`
      2. **Walk, halt, trot, and back-up:** `"Guiding smooth starts, halts, turns, brief trot jogs, and a few straight backward steps."`
    - *Learning:* `"Leads a quiet horse at walk and short trot with occasional crowding, lagging, or uneven rope handling."`
    - *Proficient:* `"Independently leads a cooperative horse at walk and trot, halts, turns, and asks for calm backward steps while maintaining safe spacing and soft contact."`
  - **`intermediate` (`v1`):**
    - *Overview:* `"Straight, balanced leading and turning for formal inspection (vet/lameness jogs) and handling busier environments."`
    - *Components:*
      1. **Inspection presentation:** `"Trotting straight on a loose lead without pulling the head, executing balanced turns away from the handler, and standing square/calmly."`
    - *Learning:* `"Presents a horse for straight trot-ups and turns with occasional loss of straightness or lead tension."`
    - *Proficient:* `"Independently presents a horse calmly for inspection—walking and trotting straight on a light lead, turning cleanly, and standing quietly—even with mild distractions."`

### 2.2 Identified Educational Weaknesses
1. **Unbalanced Entry Standard (`Intro` Bundles Trot):** Requiring `Introductory` learners to trot in-hand alongside a horse puts a complex coordination milestone into the entry level (and conflicts directly with `horse.in_hand.leading`, which puts trotting in `Intermediate`).
2. **Missing Understanding & Kinesthetic Feel:** Does not explain *why* handlers lead with their own body posture and rhythm ahead of rope pressure, what a relaxed draped lead feels like versus dragging or pulling the horse along, or why turns away from the handler are safer in tight doorways and for inspection turns.
3. **Missing Observation & Common Mistakes:** No guidance on spotting early crowding, drifting into personal space, looking back constantly at the horse's face (causing crookedness/slowing), or holding constant steady tension on the halter.
4. **Missing Off-Side Familiarity & Relationship Links:** Lacks `Intermediate` handling from both the near (left) and off (right) sides, lacks a `foundation` link from `catch_halter_turnout`, and has zero `theory` links.

### 2.3 Proposed Revised Content (`rider.in_hand.leading`)

- **Skill Name:** `Leading` *(unchanged)*
- **Aliases:** `["Lead at walk", "Lead at trot", "Back up from ground", "Present for inspection", "Jogging in hand", "Ground manners (leading)", "In-hand leading both sides"]`
- **Summary:** `"Communicating direction, pace, pauses, and safe boundaries while leading a horse on foot across familiar barn routines, busier settings, and veterinary/farrier inspections."`
- **Purpose:** `"Turns everyday leading from pulling or holding onto a horse into clear, calm two-way communication that protects both horse and handler in barns, doorways, pastures, and veterinary checks."`
- **Safety:**
  - `"Maintain a safe position near the horse's shoulder/throatlatch with clear exits—never walk directly in front of a rushing horse or inside kicking reach."`
  - `"Carry excess lead neatly folded or figure-eighted; never wrap a rope around fingers, wrists, or body, and turn the horse away from you during tight turns to avoid getting stepped on."`
  - `"Slow down, create space, or reset calmly if distractions spike rather than hauling on the halter or running beside an anxious horse."`
- **Related Skills:**
  - `{"skillId": "horse.in_hand.leading", "relation": "counterpart"}`
  - `{"skillId": "rider.in_hand.catch_halter_turnout", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "rider.in_hand.turn_on_forehand", "relation": "next"}`
  - `{"skillId": "rider.in_hand.obstacles_outings", "relation": "next"}`
  - `{"skillId": "rider.theory.equine_body_language", "relation": "theory"}`
  - `{"skillId": "rider.theory.timing_reinforcement", "relation": "theory"}`

### 2.4 Proposed Difficulty Criteria (`availableLevels: ["introductory", "intermediate"]`)

| Dimension | Proposed **Introductory** (`standardVersion: 2`) | Proposed **Intermediate** (`standardVersion: 2`) |
| :--- | :--- | :--- |
| **Overview** | Clear, calm **walk** communication (starts, halts, turns, narrow doorways, and a few calm steps back) with safe handler positioning and soft halter feel in familiar settings. *(Trot leading is not required.)* | Regulating walk and **trot** pace smoothly in varied/distracting environments, comfortable leading from either side, and presenting a horse squarely and straight on a loose lead for inspection. |
| **Educational Components** *(Understanding · Feel · Mistakes · Welfare)* | 1. **Understanding position & body language:** Walking beside the shoulder/neck rather than ahead or behind; noticing how changing your own walk energy and breathing signals go or whoa before touching the rope.<br>2. **Feel of a soft lead & prompt release:** Maintaining a relaxed J/drape in the lead; releasing immediately the instant the horse matches pace or shifts weight backward into a few calm steps back.<br>3. **Common mistakes & safety habits:** Staring back at the horse's face (which stops forward flow), pulling continuously rather than asking and releasing, walking backward to pull a horse forward, or letting a horse cut across your toes on narrow turns.<br>4. **Observing early space/attention cues:** Noticing ears, neck height, or subtle shoulder drift into your space and resetting boundaries calmly without anger. | 1. **Trot pace & straightness feel:** Matching an athletic trot cleanly beside the shoulder while letting the horse's head and neck swing naturally without restricting the mouth or chin.<br>2. **Inspection presentation & turns away:** Trotting straight away and back toward an observer (veterinarian/farrier/evaluator), balancing down to walk before turning the horse smoothly **away** from you, and standing balanced for visual appraisal.<br>3. **Bilateral handling & environmental adaptation:** Leading calmly from both left and right sides as terrain, gates, or traffic require, and recognizing early arousal around unfamiliar horses/vehicles so you widen spacing or pause purposefully.<br>4. **Welfare & soundness observation:** Spotting uneven head-nod, reluctance to walk/trot forward, or tense breathing as reasons to slow down or investigate rather than escalate force. |
| **Learning** | Guides a quiet horse at walk with reminders about shoulder position, slack rope timing, spacing around corners, or looking ahead instead of pulling. | Practices trot leading, off-side handling, or inspection trot-ups with occasional lead tension, uneven pace, cramped turns, or late adjustments around distractions. |
| **Proficient** | Independently leads a cooperative horse at walk in familiar spaces with safe positioning and relaxed rope handling; signals clear starts, calm halts, smooth turns, and 2–4 calm backward steps on light cues while maintaining comfortable personal space. | Independently leads a prepared horse smoothly at walk and controlled trot from either side, adapts spacing and composure calmly in varied settings, and presents the horse straight on a non-restrictive lead with balanced turns away from the handler and quiet halts for inspection. |

### 2.5 Educational Rationale
Removing trot from `Introductory` restores true beginner achievability and aligns `rider.in_hand.leading` (`Intro` walk / `Int` walk + trot) with `horse.in_hand.leading`. Beginners learn **why** posture and timely release replace dragging/pulling—and why reading personal-space drift early beats harsh correction—while `Intermediate` reserves genuine handler coordination (in-hand trot straightness without restricting head carriage, both-side handling, distraction judgment, and veterinary soundness awareness). No 3rd level (`Advanced`) is fabricated because higher groundwork complexities belong in `Longeing`, `Ground Driving`, and `In-Hand Obstacles & Outings`.

### 2.6 Questions for Matt's Professional Judgment
1. Confirm moving in-hand trot out of `Introductory` into `Intermediate` (`standardVersion: 2` on both levels so earlier instructor verifications remain preserved clearly)?
2. Confirm including comfortable **near- and off-side leading** under `Intermediate`?
3. Confirm keeping `rider.in_hand.leading` at **2 levels (`Intro`, `Int`)** rather than adding an artificial `Advanced` tier?

---

## 3. Example 2 — Rider: Longeing (`rider.in_hand.longeing` · Existing Skill)

### 3.1 Current Content (`skills_rider_in_hand.json`)

- **Family:** `rider.in_hand.longeing_long_lining` (*Longeing & Long-Lining*) · **ID:** `rider.in_hand.longeing` · **Name:** `Longeing`
- **Aliases:** `["Lunge walk and trot", "Lunge canter", "Lunging"]`
- **Summary:** `"Working a reasonably prepared horse on a circle with a longe line across gaits and transitions while maintaining safe handler positioning and line control."`
- **Purpose:** `"Allows assessment of movement, calm warm-up, and rhythmic transition practice from the ground."`
- **Safety:**
  - `"Never wrap the longe line around hands or fingers; wear gloves and safe footwear."`
  - `"Work in an enclosed, good-footing area and stay outside the kick zone."`
- **Related Skills:** `next: rider.in_hand.ground_driving`
- **Current Levels (`availableLevels: ["intermediate", "advanced"]`):**
  - **`intermediate` (`v1`):**
    - *Overview:* `"Safe line management, clear circle geometry, and transitions across walk, trot, and canter on a prepared horse."`
    - *Components:*
      1. **Line and equipment handling:** `"Gathering and paying out the line smoothly without dragging loops or tangling."`
      2. **Gait and transition control:** `"Maintaining a consistent circle size and guiding calm transitions across walk, trot, canter, and halt."`
    - *Learning:* `"Longes at walk, trot, and canter with occasional tangling, drifting circle size, or rushed transitions."`
    - *Proficient:* `"Independently and safely longes a prepared horse in both directions through walk, trot, and canter with smooth line handling, steady circle size, and calm transitions."`
  - **`advanced` (`v1`):**
    - *Overview:* `"Refining balance, bend, tempo changes, and figure adjustments (moving circles, ground poles) purposefully on the longe."`
    - *Components:*
      1. **Within-gait adjustments:** `"Asking for subtle lengthening/shortening, bending, and smooth transitions over poles without tension."`
    - *Learning:* `"Practices within-gait adjustments and moving circles with intermittent loss of rhythm or contact."`
    - *Proficient:* `"Independently shapes circle size, bend, and within-gait balance across gaits purposefully, maintaining relaxed responsiveness and clear communication."`

### 3.2 Identified Educational Weaknesses
1. **All-Three-Gaits Entry Barrier & Gait-First Framing:** Entering at `Intermediate` requires walk, trot, **and canter** on a circle in both directions before any longeing achievement can be logged.
2. **Conflates Chasing Circles With Thoughtful Longeing:** Does not explicitly warn against spinning a horse mindlessly to *"tire it out"* / *"run off steam,"* nor explain the **"handler triangle"** (body position behind the drive line vs. standing rigidly in place or accidentally stepping in front of the horse's shoulder).
3. **Critical Joint/Welfare Safety Omissions:** Omits warnings about small circles creating high torque on developing, stiff, or unconditioned joints; omits mud/slick footing warnings; and omits caution around clipping a heavy longe snap directly to a bit ring without bridle/cavesson awareness.
4. **Missing Observation & Outcome-Blur Wording:** `Advanced` ends with *"maintaining relaxed responsiveness"* (horse behavior) instead of handler timing and adaptation; no guidance on reading posture, falling inward on the shoulder, fatigue, or lameness asymmetries; zero `theory` links and no Horse counterpart yet.

### 3.3 Proposed Revised Content (`rider.in_hand.longeing`)

- **Skill Name:** `Longeing` *(unchanged)*
- **Aliases:** `["Lunge walk and trot", "Lunge canter", "Lunging", "Circle work on a line", "Sending on a circle", "Longing"]`
- **Summary:** `"Safely positioning, handling line and cues, observing movement and relaxation, and shaping balanced circle work on a longe line—from quiet foundation sessions to purposeful gymnastic work."`
- **Purpose:** `"Develops clear ground communication, line safety, and an educated eye for equine rhythm, posture, and relaxation without a rider's weight—distinct from simply chasing a horse in circles."`
- **Safety:**
  - `"Fold extra line neatly in figure-eights (never loop around hands, fingers, or body); wear sturdy boots and gloves and hold whips safely without abrupt snapping."`
  - `"Work only in an enclosed space on level, non-slip footing, keeping circles large enough to protect the horse's joints and staying clear of kicking range."`
  - `"Attach the line thoughtfully using a well-fitted halter, longeing cavesson, or safe bridle setup—never clip a heavy snap onto a single bit ring in a way that yanks the bit through the mouth."`
  - `"Never chase an anxious, confused, or fatigued horse endlessly on small circles; limit repetitions and change directions evenly."`
- **Related Skills:**
  - `{"skillId": "rider.in_hand.leading", "relation": "foundation", "level": "intermediate"}`
  - `{"skillId": "rider.in_hand.ground_driving", "relation": "next"}`
  - `{"skillId": "rider.theory.progressive_conditioning", "relation": "theory"}`
  - `{"skillId": "rider.theory.balance_weight", "relation": "theory"}`
  - `{"skillId": "rider.theory.training_equipment", "relation": "theory"}`
  - `{"skillId": "rider.theory.timing_reinforcement", "relation": "theory"}`
  - *(Future `counterpart`: `horse.in_hand.longeing` when approved in Wave 3)*

### 3.4 Proposed Difficulty Criteria (`availableLevels: ["introductory", "intermediate", "advanced"]`)

| Dimension | Proposed **Introductory** *(NEW Level · `v1`)* | Proposed **Intermediate** (`v2`) | Proposed **Advanced** (`v2`) |
| :--- | :--- | :--- | :--- |
| **Overview** | Safe preparation, figure-8 line organization, quiet triangular positioning, and calm walk/halt (plus brief balanced trot) work on a large circle with a prepared horse. *(Canter on the longe is not required.)* | Coordinating consistent circle communication, posture, and balance across walk, trot, and appropriate canter—observing relaxation, bend, and symmetry and adapting circle size or pace thoughtfully. | Purposeful gymnastic and diagnostic longeing using moving circles, ground poles, subtle tempo/balance adjustments, and welfare-driven adaptations tailored to the individual horse. |
| **Educational Components** *(Lenses Inside Existing Schema)* | 1. **Why & what longeing is (not chasing):** Using body alignment and calm voice/line timing to invite attentive circle work rather than forcing speed to burn energy.<br>2. **Positioning & line feel:** Forming the "triangle" between your shoulder, whip/hand cue, and horse's hip/drive line; paying out and gathering smooth figure-8 coils without dropping loops near feet.<br>3. **Common mistakes & safety:** Stepping too far forward (accidentally blocking the shoulder into a halt/turn-in), letting the line sag on the dirt or jerk the face, or making tight circles on uneven footing. | 1. **Observing balance & symmetry:** Noticing shoulder-falling-in, braced neck/tail, left-versus-right stiffness, and how circle radius affects comfort.<br>2. **Calm communication across gaits:** Requesting smooth transitions (including controlled canter where arena size, footing, and the horse's conditioning make circling appropriate), inviting the horse to turn inward or halt quietly rather than yanking in.<br>3. **Common mistakes & session care:** Repeating nagging whip/voice cues when the horse already responded, over-working one side, or letting tension build without pausing to check comfort. | 1. **Moving circles & gymnastic tools:** Walking rectangular/oval tracks along the arena ("moving circles") so joints aren't stressed continuously, spiralling out/in smoothly, and using ground poles to encourage back lift.<br>2. **Timing & minimal cues:** Shaping subtle stride lengthenings/shortenings and balanced transitions with breath, torso rotation, and whispered elastic line feel.<br>3. **Welfare & physical assessment:** Differentiating conditioning fatigue or mild lameness from lack of focus and ending or adapting work immediately. |
| **Learning** | Sets up line and triangle position on a quiet horse at walk and brief trot with reminders on line coils, stepping behind the drive line, or avoiding sharp halts/pulls. | Coordinates walk, trot, and canter transitions with intermittent circle drift, missed body-angle cues, or slow observation when posture/tempo worsens. | Practices moving circles, poles, and subtle within-gait shaping with occasional uneven pacing, cramped spirals, or late cue adjustments. |
| **Proficient** | Independently prepares safe footing and attachments on a cooperative horse, manages the line cleanly without tangles or jerks, guides calm walk starts, gentle halts, and balanced trot stretches on a generous circle in both directions, and adjusts position calmly if the horse turns inward or slows. | Independently longes a prepared horse in both directions with poised positioning, subtle elastic line feel, and smooth transitions across walk, trot, and appropriate canter; accurately observes posture, balance, and tension cues and adapts circle size, pace, or direction accordingly. | Independently designs and executes purposeful longe sessions—moving circles around the arena, adjusting stride/bend cleanly over lines and poles, spotting subtle asymmetry or fatigue early, and adapting equipment or stopping thoughtfully for the individual horse's welfare. |

### 3.5 Educational Rationale
Separating **foundation handler mechanics & calm walk/trot circle work** (`Introductory`), **observational symmetry, balanced transitions & appropriate canter** (`Intermediate`), and **gymnastic/diagnostic shaping with moving circles and poles** (`Advanced`) resolves the steep `Intermediate` entry jump while ensuring difficulty scales on **handler skill, observation, and welfare judgment**, not simply gait. Including explicit conditional wording for canter (*where footing, space, and horse readiness make circling safe*) protects young, large, or arthritic horses.

### 3.6 Questions for Matt's Professional Judgment
1. Between **3 levels** (`Intro` NEW walk/trot, `Int` 3-gait observation/transitions, `Adv` moving circles/poles/within-gait shaping) vs. **2 levels** (`Int` walk/trot, `Adv` canter + shaping), do you prefer the 3-level structure drafted above?
2. Is keeping **canter at `Intermediate` explicitly conditional** on footing, circle diameter, and the horse's physical balance aligned with how you teach?
3. Are the safety guidelines on halter/cavesson/bridle attachment neutral enough across both English and Western trainers?

---

## 4. Example 3 — Rider: Canter (`rider.mounted.canter` · Existing Skill)

### 4.1 Current Content (`skills_rider_mounted.json`)

- **Family:** `rider.mounted.gaits_rhythm_transitions` (*Gaits, Rhythm & Transitions*) · **ID:** `rider.mounted.canter` · **Name:** `Canter`
- **Aliases:** `["Lope", "Canter depart", "Canter leads", "Lope leads", "Simple lead change", "Counter-canter", "Flying lead change"]`
- **Summary:** `"Riding the three-beat canter or lope in balance—progressing from establishing the gait to lead selection, simple lead changes, counter-canter, and flying changes."`
- **Purpose:** `"Allows riders to develop balanced three-beat feel early while progressing toward accurate lead control, balanced turns, and advanced lead changes."`
- **Safety:** `["Establish reliable walk/trot control and safe arena spacing before cantering."]`
- **Related Skills:** `counterpart: horse.mounted.canter`, `foundation: rider.mounted.trot (introductory)`, `theory: rider.theory.gaits_footfalls`, `next: rider.mounted.steering_navigation`
- **Current Levels (`availableLevels: ["introductory", "intermediate", "advanced"]`):**
  - **`introductory` (`v2`):**
    - *Overview:* `"Establishing and maintaining the canter calmly with basic balance and a controlled downward transition; correct lead selection is not required."`
    - *Components:* 1 component (*Establishing and maintaining canter*).
    - *Learning:* `"Establishes canter for short stretches with guidance; seat or rein steadiness may waver during the depart or downward transition."`
    - *Proficient:* `"Independently establishes and maintains a balanced canter with basic steering for sustained stretches and makes a safe, controlled downward transition. Correct lead selection is not required at this level."`
  - **`intermediate` (`v2`):**
    - *Overview:* `"Recognizing and selecting requested leads in both directions, maintaining leads through turns and circles, and performing balanced simple lead changes."`
    - *Components:* 2 components (*Lead recognition and selection*, *Simple lead changes*).
    - *Learning:* `"Selects leads, rides turns, and practices simple lead changes with occasional wrong-lead departs, breaking gait on turns, or rushed transitions."`
    - *Proficient:* `"Independently recognizes and selects requested leads in both directions, maintains the lead and steady rhythm through turns and 20 m circles, and performs clean, balanced simple lead changes."`
  - **`advanced` (`v1`):**
    - *Overview:* `"Demonstrating refined canter control, including deliberate counter-canter and clean, balanced flying lead changes."`
    - *Components:* 2 components (*Counter-canter balance*, *Flying lead changes*).
    - *Learning:* `"Practices counter-canter and flying lead changes with occasional unintended lead swaps, late hind changes, crookedness, or tension."`
    - *Proficient:* `"Independently demonstrates refined canter control in both directions, maintaining balanced counter-canter through appropriate lines and executing clean, straight, balanced flying lead changes without rushing or tension."`

### 4.2 Identified Educational Weaknesses
1. **Sparse Safety & Physical Preparation Detail:** Only 1 safety bullet; lacks footing/turn-radius checks before cantering and lacks any welfare check when a horse repeatedly picks up the wrong lead, cross-canters, or rushes.
2. **Missing Kinesthetic Feel & Common Mistakes:** `Introductory` does not explain *what the three-beat rocking/forward seat motion feels like*, *preparing a calm walk or trot before asking* (vs. kicking a faster, unbalanced trot until the horse falls into canter), or accommodating both full seat and balanced light/two-point seat; `Intermediate` does not explain *feeling which shoulder/hip advances without looking down*.
3. **Arena-Centric `20 m Circle` Phrasing & `Advanced` Speed-vs.-Collection Clarity:** `Intermediate` refers strictly to `"20 m circles"` without open-space/large-circle flexibility for Western/trail riders; `Advanced` focuses on counter-canter + flying changes while omitting **within-gait canter stride adjustability** (distinguishing collected/energetic stride changes from speeding up).
4. **Missing Theory Links:** Only links to `gaits_footfalls`; missing links to `balance_weight` (outside-hind initiation & uphill balance) and `pain_discomfort_fatigue` (disunited/wrong-lead welfare red flags).

### 4.3 Proposed Revised Content (`rider.mounted.canter`)

- **Skill Name:** `Canter` *(unchanged)*
- **Aliases:** `["Lope", "Canter depart", "Canter leads", "Lope leads", "Simple lead change", "Counter-canter", "Flying lead change", "Balanced canter"]`
- **Summary:** `"Preparing, following, and shaping the asymmetric three-beat canter or lope—progressing from balanced seat and calm transitions to accurate lead feel, stride adjustability, counter-canter, and clean lead changes."`
- **Purpose:** `"Develops hip suppleness, rhythmic core stability, timing with the horse's three-beat stride, and progressive lead/balance awareness—prioritizing relaxation and soundness over speed."`
- **Safety:**
  - `"Establish reliable walk and trot steering, calm transitions, and clear arena or trail spacing before asking for canter."`
  - `"Check footing, traction, and turn radius carefully—avoid asking for canter or tight turns on slick, deep, or rocky ground."`
  - `"If a horse repeatedly rushes, cross-canters, or resists one lead despite clear preparation, slow down and investigate saddle fit, soundness, conditioning, or rider crookedness."`
- **Related Skills:**
  - `{"skillId": "horse.mounted.canter", "relation": "counterpart"}`
  - `{"skillId": "rider.mounted.trot", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "rider.mounted.steering_navigation", "relation": "next"}`
  - `{"skillId": "rider.mounted.transitions", "relation": "next"}`
  - `{"skillId": "rider.theory.gaits_footfalls", "relation": "theory"}`
  - `{"skillId": "rider.theory.balance_weight", "relation": "theory"}`
  - `{"skillId": "rider.theory.pain_discomfort_fatigue", "relation": "theory"}`

### 4.4 Proposed Difficulty Criteria (`availableLevels: ["introductory", "intermediate", "advanced"]`)

| Dimension | Proposed **Introductory** (`v2` editorial enrichment) | Proposed **Intermediate** (`v2` editorial enrichment) | Proposed **Advanced** (`v2` if standard broadens / clarifies) |
| :--- | :--- | :--- | :--- |
| **Overview** | Preparing a balanced depart, following the forward three-beat rocking motion calmly in a full seat or light seat (whether on soft contact or a loose rein), and returning smoothly to trot or walk. *(Correct lead selection is not required.)* | Preparing left- and right-lead departs from walk or trot, feeling which lead the horse is on without looking down, balancing turns/large circles, and riding clean simple lead changes. | Adjusting canter/lope stride length and balance while keeping calm 3-beat purity, sustaining straight counter-canter through curves, and executing clean lead changes suited to the horse's training. |
| **Educational Components** *(Understanding · Execution · Feel · Observation · Welfare)* | 1. **Preparation vs. running the trot:** Asking out of a calm, rhythmic trot or walk (not chasing a faster trot until the horse trips into canter).<br>2. **Following 3-beat feel & posture:** Letting the hips sweep forward gently with each stride, heels softly down, and hands elastic so the neck can nod rather than balancing off the mouth (full seat or two-point/light seat both valid).<br>3. **Controlled returns:** Breathing out, stabilizing the core, and gliding down to trot or walk smoothly before losing space. | 1. **Understanding & feeling leads:** Knowing the lead leg advances farther and feeling the slight alternating forward swing of your corresponding hip/shoulder without staring down at the horse's shoulder.<br>2. **Balanced departs & large curves:** Positioning subtle bend/alignment to free the inside shoulder for the requested lead and supporting rhythm through turns and large circles (~20 m or open turns) without leaning inward.<br>3. **Simple changes & welfare cues:** Transitioning smoothly through walk or a few trots to change leads calmly; noticing cross-cantering or one-sided difficulty early as potential physical feedback. | 1. **Stride adjustability (not speed):** Shortening and lengthening canter strides cleanly using seat, core, and rebalancing feel while keeping steady 3-beat tempo rather than accelerating or pulling flat.<br>2. **Counter-canter alignment:** Riding intentional counter-canter along shallow loops and turns with calm outside-bend alignment and steady rhythm.<br>3. **Clean lead changes & adaptation:** Timing simple changes through walk or clean, straight flying lead changes in the suspension phase on a prepared horse—adapting asks when balance, ground, or tension indicates the horse is unready. |
| **Learning** | Departs into canter for short stretches with guidance; seat, ankles, or hands occasionally brace during the depart or downward transition, or trot rushes beforehand. | Practices lead selection, curves, and simple changes with occasional wrong-lead departs, looking down to check, inward leaning on circles, or hurried change transitions. | Develops stride collection/extension, counter-canter, and flying changes with intermittent tension, flat acceleration, crookedness, late hind changes, or unintended lead swaps. |
| **Proficient** | Independently prepares a balanced walk or trot, asks calmly for canter, follows the three-beat rhythm comfortably in full or light seat without bracing on the reins, steers basic lines/curves, and makes a controlled downward transition. *Correct lead selection is not required.* | Independently prepares and asks for left and right leads from walk or trot, identifies leads by feel, maintains steady three-beat balance around turns and large circles (~20 m) on light contact or a loose rein, rides clean simple lead changes, and responds calmly if an unintended lead or cross-canter occurs. | Independently regulates canter balance and stride length without rushing, maintains relaxed, straight counter-canter along appropriate curves, and prepares and executes clean, straight flying lead changes (or refined simple changes where appropriate for the horse) without tension or loss of rhythm. |

### 4.5 Educational Rationale
Upgrading all three levels incorporates the exact **4 Rider lenses**: *Understanding* why rushing trot hurts canter balance and how leads work biomechanically; *Execution* clarifying full/light seat and elastic follow on either contact or loose rein; *Observation* feeling leads without looking down and spotting disunited/wrong-lead stress; and *Adaptation* checking ground, symmetry, or stepping down to simple changes when flying changes aren't fair to the individual horse. Notice `Advanced` explicitly highlights **biomechanical balance and stride adjustability** rather than equating speed with difficulty.

### 4.6 Questions for Matt's Professional Judgment
1. Should **Flying Lead Changes** stay inside `Canter (Advanced)` (as framed above with adaptive phrasing for horses still in simple changes), **or** should we keep Flying Lead Changes as a dedicated Wave 4 skill pair (`Counter-Canter & Lead Changes`) so riders/horses pursuing classical counter-canter or ranch/trail balance aren't blocked from `Canter Advanced`?
2. Confirm explicitly welcoming **light seat / two-point** alongside full seat in `Canter (Introductory)`?
3. Should updating `Canter (Advanced)` increment `advanced.standardVersion` to `2` (because it adds within-gait stride adjustability alongside counter-canter and flying changes)?

---

## 5. Example 4 — Rider: Training Principles & Progression (`rider.theory.training_pyramid` within Family `rider.theory.training_principles` · Existing Family & Flagship Skill)

> **Structural Clarification:** In `curriculum/v2/`, **`Training Principles & Progression`** (`rider.theory.training_principles`) is an existing **Skill Family** containing three active skills:
> 1. `rider.theory.training_pyramid` — *Understanding the Training Pyramid*
> 2. `rider.theory.progressive_conditioning` — *Progressive Training & Conditioning*
> 3. `rider.theory.session_planning` — *Planning & Evaluating Training Sessions*
>
> Below is the full side-by-side refinement of its flagship skill **`rider.theory.training_pyramid`** (preserving its canonical ID), plus a concise companion update removing `"mentoring others"` from `rider.theory.session_planning.advanced`.

### 5.1 Current Content (`rider.theory.training_pyramid` in `skills_rider_theory.json`)

- **Family:** `rider.theory.training_principles` (*Training Principles & Progression*) · **ID:** `rider.theory.training_pyramid` · **Name:** `Understanding the Training Pyramid`
- **Aliases:** `["Training Scale", "Skala der Ausbildung", "Six elements of training", "Rhythm relaxation connection impulsion straightness collection"]`
- **Summary:** `"Understanding the six traditional Training Pyramid elements—rhythm, suppleness/relaxation, contact/connection, impulsion, straightness, and collection—as an interdependent, adaptable framework rather than a rigid one-way ladder."`
- **Purpose:** `"Gives equestrians across Western, English, trail, ranch, driving, and general horsemanship a shared language for evaluating movement quality, mental relaxation, and progressive development without treating any single framework as the only valid path."`
- **Safety:**
  - `"Never force advanced elements such as collection or high-energy impulsion before a horse is mentally relaxed, physically warmed up, and sound."`
  - `"Do not confuse tension or hurried speed with impulsion or collection."`
- **Related Skills:** `next: rider.theory.balance_weight`, `next: rider.theory.progressive_conditioning`, `next: rider.mounted.half_halt`
- **Current Levels (`availableLevels: ["introductory", "intermediate", "advanced"]`):**
  - **`introductory` (`v1`):** Focuses on naming and defining the 6 elements, recognizing interdependence, and seeing applicability across trail/ranch/Western/English/driving. *Proficient:* `"Accurately explains all six elements in plain language, describes how they interact, and gives examples of how the framework applies across different riding or handling goals."`
  - **`intermediate` (`v1`):** Observing relaxation vs. brace/forced head position and knowing when to cycle back to rhythm or relaxation. *Proficient:* `"Observes live or recorded horses and accurately identifies strengths and gaps across rhythm, relaxation, connection, impulsion, straightness, and early collection, explaining sensible next priorities."`
  - **`advanced` (`v1`):** Adapting emphasis for young/green/older/gaited/rehab horses and comparing models. *Proficient:* **`"Synthesizes the six interdependent elements with biomechanics and learning theory to evaluate complex training situations and mentor others clearly across disciplines."`**

### 5.2 Identified Educational Weaknesses
1. **Requires Teaching Others at `Advanced`:** `Proficient` requires `"mentor others clearly across disciplines"`. A skilled, ethical horsewoman who develops horses thoughtfully on her own without coaching students shouldn't fail `Advanced` for not mentoring people. *(The same phrase `"struggles to mentor..."` / `"mentors others"` also affects `session_planning`, `timing_reinforcement`, `ethical_training`, `understanding_rider_aids`, and `training_equipment`.)*
2. **Slightly Conceptual vs. Actionable at `Introductory`:** `Introductory` tests naming/explaining 6 terms well, yet could emphasize *practical everyday priority decisions* even earlier (knowing why relaxation comes before demanding precision, and why true connection works equally on a loose trail rein or light contact).
3. **Under-Connected to Learning Theory & Daily Riding:** Lacks explicit `foundation` link to `how_horses_learn` and `next` links to `session_planning`, `transitions`, and `pain_discomfort_fatigue`.

### 5.3 Proposed Revised Content (`rider.theory.training_pyramid`)

- **ID:** `rider.theory.training_pyramid` *(preserved)* · **Recommended Display Name:** `Training Principles & the Training Pyramid` *(keeps `"Understanding the Training Pyramid"` in `aliases[]`—non-breaking under Guide §8.2)*
- **Aliases:** `["Understanding the Training Pyramid", "Training Scale", "Skala der Ausbildung", "Six elements of training", "Rhythm relaxation connection impulsion straightness collection", "Training principles"]`
- **Summary:** `"Applying core progressive horsemanship principles—and using the six Training Pyramid elements (rhythm, relaxation, connection, impulsion, straightness, collection) as a flexible, non-exclusive lens—to support calm, sound development across all disciplines."`
- **Purpose:** `"Equips riders and handlers across trail, ranch, Western, English, gaited, and driving traditions to evaluate physical and mental readiness, prioritize foundations over force, and adapt training fairly to each horse."`
- **Safety:**
  - `"Never attempt collection, speed, or demanding lateral/jumping work when a horse lacks mental relaxation, physical warm-up, comfort, or basic rhythm."`
  - `"Do not mistake braced necks, hurried speed, or submissive shutdown for true relaxation, impulsion, or collection."`
  - `"Pause and check health, hooves, teeth, saddle fit, and emotional stress whenever recurring resistance breaks rhythm or relaxation."`
- **Related Skills:**
  - `{"skillId": "rider.theory.how_horses_learn", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "rider.theory.balance_weight", "relation": "next"}`
  - `{"skillId": "rider.theory.progressive_conditioning", "relation": "next"}`
  - `{"skillId": "rider.theory.session_planning", "relation": "next"}`
  - `{"skillId": "rider.mounted.half_halt", "relation": "next"}`
  - `{"skillId": "rider.mounted.transitions", "relation": "next"}`

### 5.4 Proposed Difficulty Criteria (`availableLevels: ["introductory", "intermediate", "advanced"]`)

| Dimension | Proposed **Introductory** (`v2` or `v1`) | Proposed **Intermediate** (`v2` or `v1`) | Proposed **Advanced** (`v2`) |
| :--- | :--- | :--- | :--- |
| **Overview** | Understanding how rhythm, mental/physical relaxation, soft connection, and patient progression guide everyday riding and groundwork across any discipline. | Observing real horses to diagnose which foundational principle needs attention (comfort, rhythm, relaxation, connection, or straightness) and choosing humane next priorities instead of forcing symptoms. | Synthesizing movement frameworks, learning theory, welfare ethics, and biomechanics to make nuanced, independent decisions for diverse, green, rehabilitating, or complex horses. |
| **Educational Components** *(Understanding · Observation · Adaptation)* | 1. **Flexible framework over checklists:** Naming the six Training Pyramid elements in plain terms while understanding it is one helpful guide among valid horsemanship traditions—never a rigid single ladder.<br>2. **Mental relaxation & connection:** Understanding why physical tension blocks learning and why true connection looks equally natural on a draped Western/trail rein or soft English contact.<br>3. **Common mistakes:** Pulling a horse's head into an artificial shape without back engagement, or pushing past confusion instead of resetting foundations. | 1. **Observing movement & tension clusters:** Spotting false framing, rushing, bracing through the back/jaw, crookedness, or hurried speed posing as impulsion.<br>2. **Cycling back & ethical adaptation:** Explaining how to drop intensity, widen turns, clarify groundwork cues, or check comfort when higher elements fall apart.<br>3. **Integrating learning theory:** Recognizing how unclear release timing (`timing_reinforcement`) disrupts rhythm and relaxation just as much as physical balance. | 1. **Conformation, discipline & career adaptation:** Tailoring priorities thoughtfully for young horses, senior horses, gaited/ambling breeds, draft/ranch types, or horses returning from injury—without dogma.<br>2. **Root-cause & multi-model synthesis:** Diagnosing subtle trade-offs across biomechanics, equine emotions, conditioning timelines, and professional care teams (`pain_discomfort_fatigue`) to adjust long-term goals ethically.<br>3. **Resisting external shortcuts:** Critically evaluating rushed barn norms, harsh gadgets, or competition timelines against long-term soundness and trust. |
| **Learning** | Recognizes terms like rhythm and relaxation, but still views the Training Pyramid as a strict step-by-step test or thinks collection equals headset height. | Identifies issues in theory or slow video, but still struggles in real time to trace downstream tension back to comfort, timing, or missing foundational rhythm. | Applies framework adjustments steadily to familiar horse types, while building deeper confidence weighing competing trade-offs in complex or unfamiliar situations. |
| **Proficient** | Plainly explains the six Training Pyramid elements and core training priorities, describes how mental relaxation and rhythm support any discipline, and avoids mistaking forced head position or speed for healthy progress. | Independently observes horses on the ground or under saddle, distinguishes true relaxation and elastic self-carriage from brace or hurried rushing, and selects practical, humane next training or comfort checks without escalating force. | Independently synthesizes movement frameworks, learning theory, conditioning science, and equine welfare to evaluate ambiguous or challenging horse situations—adapting goals, methods, and professional referrals smoothly across diverse horses and disciplines. *(No teaching or mentoring role required.)* |

*Companion Alignment Note (`rider.theory.session_planning.advanced`):* Under the same principle, `session_planning.advanced` currently states *"mentoring others in reflective evaluation."* Removing `"mentoring others"` shifts it cleanly to **diagnosing multi-factor stalls in complex horses, evaluating video/longitudinal session logs objectively, and adapting multi-week plans autonomously**.

### 5.5 Educational Rationale
Reframing `Understanding the Training Pyramid` around **practical decision-making, observation, and humane adaptation** keeps everyday trail and ranch riders just as engaged as classical riders, bridges biomechanics explicitly to learning theory, and ensures `Advanced` rewards **deep independent horsemanship judgment** rather than acting as a riding-instructor credential.

### 5.6 Questions for Matt's Professional Judgment
1. Keep the current display title `"Understanding the Training Pyramid"` or update it cleanly to `"Training Principles & the Training Pyramid"` (preserving ID `rider.theory.training_pyramid` and keeping the old name in `aliases[]`)?
2. Confirm removing `"mentoring others"` as a criterion across **all Theory `Advanced` levels** (`training_pyramid`, `session_planning`, `timing_reinforcement`, `ethical_training`, `understanding_rider_aids`, `training_equipment`) so self-directed learners can achieve `Advanced` without coaching other people?

---

## 6. Example 5 — Horse: In-Hand Yielding (`horse.in_hand.yielding` · PROPOSED NEW SKILL)

> **Explicit Status Label:** **PROPOSED NEW SKILL — Does not currently exist in `curriculum/v2/skills_horse_in_hand.json`.**
> Today, `Horse → In-Hand` contains 7 skills (`leading`, `standing_quietly`, `daily_care_handling`, `hoof_handling`, `vet_handling`, `trailer_loading`, `ground_driving`) and has **zero skills** tracking whether a horse calmly understands yielding its hindquarters, forequarters, or body sideways from the ground—leaving all three Rider In-Hand yielding skills (`turn_on_forehand`, `yield_forequarters`, `sidepass_in_hand`) with no Horse counterpart.

### 6.1 Current Adjacent Context (`curriculum/v2/`)

- **Rider Counterparts Currently Unlinked:**
  - `rider.in_hand.turn_on_forehand` (*Turn on the Forehand (In-Hand)* — `Intro`, `Int`)
  - `rider.in_hand.yield_forequarters` (*Turn on the Haunches (In-Hand)* — `Int` only)
  - `rider.in_hand.sidepass_in_hand` (*Sidepass (In-Hand)* — `Int` only)
- **Closest Current Horse Skill (`horse.in_hand.leading`):** Covers forward walk/trot, halt, turns, and straight backup on halter cues—does **not** cover lateral yielding of hindquarters, shoulders, or sidepass.

### 6.2 Identified Gap & Educational Weaknesses Without This Skill
1. **Unassessed Foundational Horse Competency:** Trainers and owners regularly ask *"Does this horse yield its hips and shoulders calmly on the ground without rushing, pinning ears, or bracing?"*—yet Horse profiles currently have nowhere to record it.
2. **Confusion Between Understanding and Escape/Avoidance:** When a horse swings its hindquarters violently around to evade heavy pressure, panics away from a stick/flag, or freezes/shuts down, inexperienced owners sometimes think the horse "knows how to yield." The curriculum needs a clear standard distinguishing **calm, soft, coordinated comprehension** from **fear-based displacement or avoidance**.

### 6.3 Proposed New Skill Content (`horse.in_hand.yielding`)

- **Proposed ID:** `horse.in_hand.yielding` · **Subject:** `horse` · **Category (`realm`):** `In_Hand`
- **Proposed Family:** `horse.in_hand.leading_manners` (*Leading & Ground Manners* · `sortOrder: 15`) *(alternative: add `horse.in_hand.ground_control_yielding` — see Q2 in §6.6)*
- **Name:** `In-Hand Yielding & Body Control`
- **Aliases:** `["Yield hindquarters in-hand", "Yield forequarters in-hand", "Turn on the forehand (in-hand)", "Turn on the haunches (in-hand)", "Sidepass (in-hand)", "Ground yielding (horse)"]`
- **Summary:** `"The horse's calm comprehension and coordinated lateral responsiveness when asked from the ground to yield its hindquarters, forequarters, or full body sideways."`
- **Purpose:** `"Reflects the horse's comfort, emotional composure, and understanding of light lateral ground communication—making gates, grooming positioning, saddling, trailers, and future mounted cues calmer and safer."`
- **Safety:**
  - `"Evaluate true relaxation and comprehension—never mistake rapid flinging, spinning in fear, or frozen compliance under relentless pressure for proficient yielding."`
  - `"Work on level, non-slip footing and release requests immediately on the first calm crossing step so the horse learns clarity instead of avoiding pressure."`
  - `"Treat persistent one-sided resistance, ear-pinning, or bracing as potential feedback about hoof, joint, hip/shoulder soreness, or handler clarity—check comfort before raising asks."`
- **Related Skills:**
  - `{"skillId": "rider.in_hand.turn_on_forehand", "relation": "counterpart"}` *(requires symmetric back-link when authored)*
  - `{"skillId": "rider.in_hand.yield_forequarters", "relation": "counterpart"}`
  - `{"skillId": "rider.in_hand.sidepass_in_hand", "relation": "counterpart"}`
  - `{"skillId": "horse.in_hand.leading", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "horse.mounted.turn_on_forehand", "relation": "next"}`
  - `{"skillId": "horse.mounted.turn_on_haunches", "relation": "next"}`
  - `{"skillId": "horse.mounted.sidepass", "relation": "next"}`

### 6.4 Proposed Difficulty Criteria (`availableLevels: ["introductory", "intermediate"]` — No Padded `Advanced`)

| Dimension | Proposed **Introductory** (`v1`) | Proposed **Intermediate** (`v1`) |
| :--- | :--- | :--- |
| **Overview** | Calmly understanding light ground cues from halt to step the hindquarters or shoulders aside 2–4 coordinated steps in both directions, pausing softly when the cue stops. | Smooth, balanced responsiveness through fuller 180–360° forehand/haunches pivots, walk-to-yield adjustments, and straight in-hand sidepass (in open space or over a low rail) on light cues. |
| **Educational Components** *(Five Horse Lenses)* | 1. **Understanding vs. escape/displacement:** Stepping deliberately across with relaxed breathing and soft eye, rather than flinging the hips wildly, backing rapidly, or crowding into the handler out of anxiety.<br>2. **Clean leg coordination & pause:** Stepping the inside leg smoothly in front of the supporting leg without tangling, then standing settled and attentive once pressure releases.<br>3. **Emotional & physical welfare cues:** Watching for mild tension (high head, breath-holding, ear-pinning) or persistent asymmetry between left and right sides that may point to physical stiffness or discomfort. | 1. **Rhythmic pivot & shoulder balance:** Keeping a steady four-beat walk quality through fuller ground turns around the forehand or haunches without spinning, dropping onto the forehand, or backing unintentionally.<br>2. **Coordinated straight sidepass:** Responding softly to balanced shoulder and rib/hip cues to cross both front and hind pairs sideways evenly without either end lagging.<br>3. **Confidence around context & rails:** Remaining relaxed when aligning at gates, tight spaces, or stepping cleanly over a ground pole without rushing or pawing. |
| **Learning** | Responds to fair lateral ground requests in familiar areas with mild hesitation, drifting forward or backward, hurried scrambling on one side, or brief tension before settling. | Performs fuller pivots and in-hand sidepass with intermittent lagging of shoulders or hindquarters, mild rushing, unevenness over a ground pole, or distraction in busier settings. |
| **Proficient** | Calmly understands light ground cues from halt to step its hindquarters and forequarters aside 2–4 coordinated, balanced steps in both directions, remaining soft in eye, jaw, and posture without fleeing, bracing, or crowding, and pausing quietly on release. | Reliably executes relaxed, balanced in-hand turns around the forehand and haunches, smooth adjustments from walk, and straight sidepass steps (open ground and over a ground rail) in both directions on light cues—staying calm, attentive, and physically coordinated without rushing or defensive tension. |

### 6.5 Educational Rationale
Consolidating Horse In-Hand yielding into **one 2-level capability** (`Intro` 2–4 soft steps of hindquarters/forequarters; `Int` fluid pivots & in-hand sidepass) avoids splitting Horse In-Hand into 3 tiny micro-skills while still pairing symmetrically with all 3 Rider In-Hand yielding skills (`turn_on_forehand`, `yield_forequarters`, `sidepass_in_hand`). Most importantly, it establishes a clear horsemanship boundary: **a frightened horse running away from pressure is never `Proficient`**. Leaving out `Advanced` respects our no-padding rule (advanced classical in-hand work belongs in a future specialized *Work in Hand* module).

### 6.6 Questions for Matt's Professional Judgment
1. Confirm **one consolidated Horse skill** (`horse.in_hand.yielding`) covering hindquarters, forequarters, and sidepass from the ground rather than 3 separate Horse In-Hand skills?
2. Should `horse.in_hand.yielding` live inside **`Leading & Ground Manners`** (`horse.in_hand.leading_manners`) or inside a new 5th Horse In-Hand family **`Ground Control & Yielding`** (`horse.in_hand.ground_control_yielding`) parallel to Rider?
3. Confirm capping at **`Introductory` + `Intermediate`** (no `Advanced` level for general horsemanship)?

---

## 7. Example 6 — Horse: Rein Back (`horse.mounted.rein_back` · Existing Skill)

> **Context Note:** Basic in-hand backward stepping (`back_up`) lives inside `horse.in_hand.leading` (`Introductory`). `horse.mounted.rein_back` evaluates under-saddle rein-back.

### 7.1 Current Content (`skills_horse_mounted.json`)

- **Family:** `horse.mounted.pivots_body_control` (*Pivots & Body Control*) · **ID:** `horse.mounted.rein_back` · **Name:** `Rein Back (Under Saddle)`
- **Aliases:** `["Back through L obstacle (under saddle)", "Rein back (under saddle)"]`
- **Summary:** `"The horse's ability to step calmly backward in a diagonal two-beat pattern on light requests—on straight lines or through narrow/L-shaped boundaries."`
- **Purpose:** `"Demonstrates softness, straightness, and cooperative maneuvering in tight spaces."`
- **Safety:** `["Reward single calm steps when introducing rein-back; never pull hard on the mouth."]`
- **Related Skills:** `counterpart: rider.mounted.rein_back`
- **Current Levels (`availableLevels: ["intermediate"]` — 1 level only, `v1`):**
  - *Overview:* `"Stepping calmly backward 3–5 diagonal steps in straight alignment and maneuvering backward through an L or corridor."`
  - *Components:* 1 component (*Diagonal two-beat backing: Stepping cleanly in diagonal pairs without raising the head, hollowing, or rushing.*).
  - *Learning:* `"Backs with occasional crookedness, hesitation, or boundary touches in an L."`
  - *Proficient:* `"Steps backward calmly in straight diagonal pairs on light requests—including through an L or corridor—without rushing, hollowing, or knocking boundaries."`

### 7.2 Identified Educational Weaknesses
1. **No `Introductory` Entry Milestone & `Int` Obstacle Bundling:** A green or recovering horse offering 2–4 calm, willing, straight backward steps on flat ground cannot be recognized until it also maneuvers through an L-shaped corridor.
2. **Mechanical Step-Counting & Partner Framing:** Focuses on *"3–5 diagonal steps"* and L-corridor obstacle navigation rather than emphasizing **willing mental comprehension**, **balance over the hindquarters**, **quiet pause afterward** (not leaking backward or leaping forward), and **welfare check** for physical back/hock/stifle/dental/saddle pain.
3. **Level Asymmetry With Rider Counterpart & Missing Progression Links:** `rider.mounted.rein_back` has `Intermediate` + `Advanced`, whereas `horse.mounted.rein_back` lacks `Advanced`—and `horse.mounted.rein_back` has zero internal Horse links to `horse.in_hand.leading` or `horse.mounted.transitions` (`foundation`) or `horse.mounted.object_handling` (`next`).

### 7.3 Proposed Revised Content (`horse.mounted.rein_back`)

- **Skill Name:** `Rein Back (Under Saddle)` *(unchanged)*
- **Aliases:** `["Back up (under saddle)", "Back through L obstacle (under saddle)", "Rein back (under saddle)", "Reculer (horse)"]`
- **Summary:** `"The horse's willing comprehension, calm posture, and coordinated diagonal balance when stepping backward under saddle—progressing from quiet flat steps to steered alignment and uphill departures."`
- **Purpose:** `"Develops attentive softness to light seat/rein/leg requests, straightness, hindquarter weight acceptance, and calm spatial confidence for gates, trails, and collected transitions."`
- **Safety:**
  - `"Introduce under saddle only after the horse halts calmly under weight and steps back willingly in-hand; release pressure on each calm try rather than pulling steadily on the mouth."`
  - `"Practice on level, non-slip footing with clear open space behind so the horse stays confident."`
  - `"Backing requires real flexion of the hocks, stifles, and lumbar spine—if a horse suddenly hollows, tosses its head, drags toes, or refuses backward steps, assess hock/stifle/back comfort, dental wear, and saddle fit before asking again."`
- **Related Skills:**
  - `{"skillId": "rider.mounted.rein_back", "relation": "counterpart"}`
  - `{"skillId": "horse.in_hand.leading", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "horse.mounted.transitions", "relation": "foundation", "level": "introductory"}`
  - `{"skillId": "horse.mounted.object_handling", "relation": "next"}`

### 7.4 Proposed Difficulty Criteria (`availableLevels: ["introductory", "intermediate", "advanced"]`)

| Dimension | Proposed **Introductory** *(NEW Level · `v1`)* | Proposed **Intermediate** (`v2`) | Proposed **Advanced** *(NEW Level · `v1`)* |
| :--- | :--- | :--- | :--- |
| **Overview** | Calmly understanding a light under-saddle cue from a settled halt to take a few willing, unhurried backward steps on open ground with relaxed neck/back and a quiet pause afterward. *(Obstacle corridors not required.)* | Stepping backward smoothly in straight **diagonal two-beat pairs** with soft poll/back and balanced responsiveness to gentle shoulder/hip alignment cues—both in open space and through tight/L-shaped boundaries—returning quietly to halt or walk. | Sustaining calm uphill engagement and balance through longer or curved backing lines and executing smooth, relaxed direct transitions from rein-back into balanced walk, trot, or canter. |
| **Educational Components** *(Five Horse Lenses)* | 1. **Understanding & willingness over step-counting:** Shifting weight calmly back on a light cue rather than resisting, throwing the head up, or running backward to escape contact.<br>2. **Balanced halt & release:** Stopping cleanly when the cue releases instead of continuing to back unexpectedly or leaping forward out of tension.<br>3. **Early comfort awareness:** Recognizing signs of physical strain or confusion (hollowed back, tight tail, dragging toes, crookedness) early so sessions remain small and positive. | 1. **Rhythmic diagonal coordination:** Stepping evenly in two-beat diagonal footfalls (hind-and-opposite-fore moving cleanly without dragging hooves or rushing).<br>2. **Steered straightness & obstacle composure:** Responding softly to light shoulder/hip alignment cues when stepping back around a turn, beside a gate, or between corridor rails without rushing or clenching.<br>3. **Smooth halt/walk exits:** Completing backward steps into a square or balanced halt before stepping quietly forward. | 1. **Self-carriage & curved backing:** Maintaining relaxed poll carriage, swinging back, and rounded haunches across extended lines, serpentine curves, or subtle elevation changes.<br>2. **Uphill forward departures:** Transitioning straight and willingly from calm rein-back directly into balanced walk, trot, or canter (appropriate to the horse's training) without hollowing or lunging forward. |
| **Learning** | Offers 1–3 backward steps from halt with brief hesitation, crooked hindquarters, raised neck/hollow back, or stepping back inconsistently after pressure releases. | Backs smoothly on straight open lines, with occasional rushing, dragged toes, hollowing during tighter alignment turns, or knocking corridor boundaries when redirected. | Practices curved/extended lines and direct forward transitions from rein-back with intermittent loss of straightness, lowered haunches engagement, or tense lunging into the upward gait. |
| **Proficient** | Calmly understands light under-saddle requests from a settled halt to step smoothly backward a few unhurried steps on open, flat ground with soft breathing, relaxed neck/back, and a quiet pause on release without hollowing or rushing. | Steps calmly and willingly backward in balanced, rhythmic diagonal pairs on light requests—maintaining soft posture and responsive shoulder/hip alignment on straight lines and through tight/L-shaped spaces—and returns quietly to halt or walk without bracing, rushing, or knocking boundaries. | Carries smooth, engaged, balanced diagonal rhythm across extended or gently curved backing lines and transitions calmly and directly from rein-back into balanced forward gaits on light cues without hollowing, rushing, or tension. |

### 7.5 Educational Rationale
Adding **`Introductory`** honors green and recovering horses (valuing a few willing, soft, unhurried steps on flat open ground rather than forcing L-corridors on day one), upgrading **`Intermediate`** shifts focus from counting 3–5 steps to **diagonal coordination, soft posture, and cooperative alignment response**, and adding **`Advanced`** restores parity with `rider.mounted.rein_back` while honoring equine physical engagement (`hock/stifle/back` welfare safety note).

### 7.6 Questions for Matt's Professional Judgment
1. Confirm **3 levels (`Intro`, `Int`, `Adv`)** on `horse.mounted.rein_back` (and do you want `rider.mounted.rein_back` also given a matching `Introductory` level during Wave 2 so straight flat steps sit below L/corridor steering for riders too)?
2. Confirm keeping basic **in-hand backing** inside `horse.in_hand.leading` (`Intro`) while `horse.mounted.rein_back` covers under-saddle backing?

---

## 8. Recurring Curriculum-Wide Improvements Identified Across These Examples

If you approve the editorial approach modeled in these six examples, the same consistent improvements can be applied systematically across the remaining curriculum in subsequent waves:

1. **Apply the Four Rider Lenses & Five Horse Lenses Uniformly Inside Existing V2 Schema:** Every remaining practical skill (~48 older Rider/Horse practical skills) can be enriched cleanly inside existing `summary`, `purpose`, `safety[]`, `components[]`, `learning`, and `proficient` fields—with zero new UI complexity, zero checklists, and zero completion percentages.
2. **Teach "Feel, Observation & Common Mistakes" Explicitly:** Follow the `v2` Gait model across pivots, lateral work, husbandry, and horse skills—naming what balanced feel looks/feels like, predictable mistakes (constant pressure, staring down/back, skipping prep, misreading freeze as calm), and clear boundaries (*what is NOT required yet* at lower levels).
3. **Separate Difficulty Complexity From Gait Speed:** Audit every remaining skill where higher levels currently rely on gait alone (`rider.in_hand.leading`, `rider.in_hand.longeing`, `rider.mounted.leg_yield`, `rider.mounted.rein_back`, `rider.mounted.trot.introductory`) so difficulty reflects independence, coordination, observation, adaptability, and judgment.
4. **Embed Welfare, Physical Pain & Emotional Thresholds Into Practical Skills:** Strengthen safety arrays (raising `Horse` skills from ~1.0 safety bullet to 2–3 actionable welfare/safety guardrails) so riders and owners consistently rule out saddle, hoof, dental, joint, or arousal triggers before escalating requests.
5. **Purge Residual Subject-Blur & Anthropomorphism:** Update the remaining 10 Rider `proficient` standards that evaluate horse state (*"relaxation," "without drifting," "no backward steps"*) and any Horse standards leaning on human pattern ownership or mechanical phrasing.
6. **Remove Mandatory Mentoring Clauses From Theory `Advanced` Standards:** Ensure all Theory skills (`training_pyramid`, `session_planning`, `timing_reinforcement`, `ethical_training`, `understanding_rider_aids`, `training_equipment`) reward independent analytical mastery and stewardship rather than formal teaching roles.
7. **Complete the `relatedSkills` Knowledge Graph Carefully:** Populate missing `theory` links (currently 5/57 practical skills) and internal Horse `foundation`/`next` links (currently missing on 19/22 Horse skills), always running `node tool/validate_curriculum_v2.js` and tracking genuine standard adjustments cleanly via `standardVersion`.

---

*Awaiting Matt's review and feedback on the six examples and questions above before modifying any curriculum JSON files.*
