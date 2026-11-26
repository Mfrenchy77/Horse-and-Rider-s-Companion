# Equestrian Dictionary — Curriculum Terminology Coverage Audit

> **Status:** Editorial Discovery & Gap Analysis (No definitions have been automatically published)  
> **Scope:** Skill Tree 2.0 (`curriculum/v2/*.json`: 32 Skill Families, 72 Skills, 149 Difficulty Standards) vs. current starter Dictionary (`functions/dictionary_seed.json`: 11 published entries)  
> **Governing Principles:** `AGENTS.md`, `docs/EQUESTRIAN_DICTIONARY_GUIDING_PRINCIPLES.md`, `docs/SKILL_TREE_CURRICULUM_GUIDE.md`

---

## 1. Executive Summary

The Equestrian Dictionary infrastructure now serves as the **single dynamic source of truth** for contextual highlighting and manual `"Define"` lookups across Skill Tree 2.0, Resources, and Dictionary explanations. Newly published terms and synonyms automatically become eligible for highlighting without any Flutter rebuild or hardcoded word list.

However, the starter glossary currently contains **11 terms**, leaving significant foundational horsemanship vocabulary across **all four Rider Categories (`Husbandry`, `In-Hand`, `Mounted`, `Theory & Knowledge`)** and **both Horse Categories (`In-Hand`, `Mounted`)** undefined.

| Metric | Current Baseline |
| :--- | :--- |
| Published starter Dictionary entries (`functions/dictionary_seed.json`) | **11** (8 `contextual: true`, 3 `contextual: false`) |
| Skill Tree 2.0 Skills analyzed | **72** across **32** Skill Families and **149** Difficulty Standards |
| High-priority missing terms identified | **45** (**15 P0**, **18 P1**, **12 P2**) |
| Existing starter entries missing Skill Tree links | **6 of 11** (`green`, `green-broke`, `ground-tie`, `collection`, `poll`, `withers`) |

---

## 2. Currently Defined Terminology (11 Starter Entries)

| ID | Canonical Term | Contextual? | Current Synonyms | Curriculum Hits (Skills) | Missing / Recommended Skill Links |
| :--- | :--- | :---: | :--- | :---: | :--- |
| `canter` | Canter | Yes | `cantering`, `lope`, `loping` | 79 (13) | Linked: `rider.mounted.canter`, `horse.mounted.canter`. Add: `rider.theory.gaits_footfalls`. |
| `counter-canter` | Counter-Canter | Yes | `counter canter` | 2 (2) | Linked: `rider.mounted.canter`. Add: `rider.mounted.steering_navigation`, `horse.mounted.steering_navigation`. |
| `ground-tie` | Ground Tie | Yes | `ground tying`, `ground-tie` | 1 (1) | **Currently unlinked.** Add: `horse.in_hand.standing_quietly`. |
| `groundwork` | Groundwork | Yes | `ground work` | 9 (6) | Linked: `rider.in_hand.leading`, `horse.in_hand.leading`. Add: `rider.in_hand.longeing`, `rider.in_hand.ground_driving`, `rider.theory.progressive_conditioning`. |
| `green-broke` | Green Broke | Yes | `green broken`, `green-broken` | 2 (2) | **Currently unlinked.** Add: `rider.theory.progressive_conditioning`, `rider.theory.ethical_training`. |
| `half-halt` | Half Halt | Yes | `half-halt`, `half halts` | 5 (3) | Linked: `rider.mounted.half_halt`. Add: `horse.mounted.transitions`, `rider.theory.understanding_rider_aids`. |
| `shoulder-in` | Shoulder-In | Yes | `shoulder in` | 15 (3) | Linked: `rider.mounted.shoulder_in`, `horse.mounted.shoulder_in`. Add: `rider.theory.bend_flexion_straightness`. |
| `withers` | Withers | Yes | — | 1 (1) | **Currently unlinked.** Add: `rider.theory.tack_fit_function`, `rider.husbandry.tack`, `rider.husbandry.blanketing`. |
| `collection` | Collection | **No** | — | 11 (5) | **Currently unlinked.** Add: `rider.theory.training_pyramid`, `rider.theory.balance_weight`, `rider.mounted.travers`, `horse.mounted.travers`. |
| `green` | Green | **No** | — | 3 (3) | **Currently unlinked.** Add: `rider.husbandry.safe_handling`, `rider.theory.training_pyramid`. |
| `poll` | Poll | **No** | — | 6 (2) | **Currently unlinked.** Add: `rider.theory.bend_flexion_straightness`, `rider.theory.tack_fit_function`. |

---

## 3. Ambiguous Terms Requiring Contextual Restrictions (`contextual: false`)

Per `docs/EQUESTRIAN_DICTIONARY_GUIDING_PRINCIPLES.md`, everyday English words or multi-meaning equestrian terms should keep `contextual: false` so they never clutter prose with false positives, while remaining immediately accessible via **manual text selection ("Define")** and Dictionary search:

| Term | Ambiguity / Everyday Conflict | Recommended Handling |
| :--- | :--- | :--- |
| **Lead** | Canter *lead* (gait footfall) vs. *lead* rope vs. verb *to lead* | Create two distinct meanings (`canter-lead` with `contextual: true` for `"canter lead"`/`"lope lead"`, and `lead-rope` with `contextual: true` for `"lead rope"`). Keep bare `"lead"` `contextual: false`. |
| **Walk** / **Halt** / **Seat** | Common everyday verbs/nouns appearing 25–158 times across non-technical clauses | Set `contextual: false` on bare terms; allow auto-highlighting on specific multiword phrases (e.g., `"independent seat"`, `"square halt"`). |
| **Contact** / **Connection** | Everyday words (e.g. "contact your vet", "internet connection") | Set `contextual: false` on bare `"contact"` / `"connection"`; optionally auto-highlight `"rein contact"`. |
| **Bit** / **Tree** / **Frog** / **Sole** | Everyday English homographs ("a bit of", "tree branch", "frog", "sole") | Set `contextual: false`; users can select & `"Define"` anytime, and `"saddle tree"` or `"hoof frog"` can be distinct contextual phrases. |
| **Threshold** / **Shaping** / **Arousal** | Common general-English words used in learning theory | Set `contextual: false` on bare words; `"arousal threshold"` can be `contextual: true`. |
| **Green** / **Collection** / **Poll** | Already correctly configured as `contextual: false` in starter seed | Maintain `contextual: false`. |

---

## 4. Prioritized Missing Terminology Recommendations

All proposed definitions below follow the Dictionary's discipline-inclusive, observable, welfare-centered editorial standards and are **drafts for editorial review — not published**.

### P0 — Essential Foundational Terminology (15 Recommended Entries)

These terms appear repeatedly across introductory Husbandry, In-Hand, Mounted, and Theory skills and directly impact safety, communication, and cross-discipline clarity.

#### 1. Trot
- **Proposed short definition:** A symmetrical two-beat diagonal gait in which opposite front and hind legs move together, separated by a brief moment of suspension.
- **Synonyms & aliases:** `jog`, `jogging`, `trotting` *(with regional/discipline usage note explaining Western jog vs. English working/posting trot)*
- **Suggested categories:** `Gaits`, `Riding`
- **Recommended `contextual`:** `true`
- **Related Skill Tree IDs:** `rider.mounted.trot`, `horse.mounted.trot`, `rider.theory.gaits_footfalls`
- **Related terminology:** `canter`, `posting-trot`, `trot-diagonal`, `rhythm`
- **Educational justification:** Appears 124 times across 26 skills; unifying `trot` and Western `jog` mirrors the cross-discipline approach used for `canter`/`lope`.

#### 2. Posting Trot
- **Proposed short definition:** A way of riding the trot in which the rider rises and sits smoothly in time with the horse's two-beat rhythm.
- **Synonyms & aliases:** `rising trot`, `posting` *(regional note: "rising trot" in UK/Commonwealth, "posting trot" in North America)*
- **Suggested categories:** `Riding`, `Gaits`
- **Recommended `contextual`:** `true` (for `"posting trot"`, `"rising trot"`)
- **Related Skill Tree IDs:** `rider.mounted.trot`, `rider.theory.gaits_footfalls`
- **Related terminology:** `trot`, `trot-diagonal`, `sitting-trot`
- **Educational justification:** Core introductory riding concept with major US/UK terminology divergence.

#### 3. Trot Diagonal
- **Proposed short definition:** The paired movement of one front leg and the opposite hind leg during the trot, used by posting riders to match their rise and sit to the horse's stride.
- **Synonyms & aliases:** `posting diagonal`, `diagonals`, `correct diagonal`
- **Suggested categories:** `Gaits`, `Riding`
- **Recommended `contextual`:** `true` (for `"trot diagonal"`, `"posting diagonal"`; keep bare `"diagonal"` `contextual: false` due to arena geometry usage)
- **Related Skill Tree IDs:** `rider.mounted.trot`, `rider.theory.gaits_footfalls`
- **Related terminology:** `trot`, `posting-trot`, `canter-lead`
- **Educational justification:** Appears 27 times across 7 skills; frequently confuses beginners who mix up diagonals and canter leads.

#### 4. Canter Lead
- **Proposed short definition:** The side whose front and hind legs reach farther forward during the canter or lope—typically matching the inside of a turn.
- **Synonyms & aliases:** `lope lead`, `correct lead`, `inside lead`, `outside lead`
- **Suggested categories:** `Gaits`, `Riding`
- **Recommended `contextual`:** `true` (for multiword phrases; keep bare `"lead"` `contextual: false`)
- **Related Skill Tree IDs:** `rider.mounted.canter`, `horse.mounted.canter`, `rider.theory.gaits_footfalls`
- **Related terminology:** `canter`, `counter-canter`, `cross-canter`
- **Educational justification:** Appears across 12+ skills; essential for understanding canter balance, turns, and counter-canter.

#### 5. Aids
- **Proposed short definition:** The signals a rider or handler uses to communicate with a horse, divided into natural aids (seat, legs, hands, voice) and artificial aids (such as whips or spurs).
- **Synonyms & aliases:** `rider aids`, `natural aids`, `artificial aids`, `cues`
- **Suggested categories:** `Riding`, `Training`
- **Recommended `contextual`:** `true` (for `"natural aids"`, `"artificial aids"`, `"rider aids"`; `false` for bare `"aids"` if desired)
- **Related Skill Tree IDs:** `rider.theory.understanding_rider_aids`, `rider.mounted.half_halt`, `rider.mounted.transitions`
- **Related terminology:** `half-halt`, `rein-contact`, `negative-reinforcement`
- **Educational justification:** Appears 29 times across 6+ skills; bridges English ("aids") and Western ("cues") vocabulary.

#### 6. Rein Contact
- **Proposed short definition:** A soft, steady, elastic connection between the rider's hands and the horse's mouth or nose through the reins, maintained without pulling or slack jerking.
- **Synonyms & aliases:** `contact`, `elastic contact`, `feel on the reins` *(note: Western disciplines often ride on a draped/light rein with intermittent feel)*
- **Suggested categories:** `Riding`, `Training`
- **Recommended `contextual`:** `true` for `"rein contact"`; `false` for bare `"contact"`
- **Related Skill Tree IDs:** `rider.theory.training_pyramid`, `rider.theory.understanding_rider_aids`, `rider.mounted.transitions`, `horse.mounted.trot`
- **Related terminology:** `half-halt`, `self-carriage`, `aids`
- **Educational justification:** Appears 22 times across 13 skills; **Matt's editorial review recommended** to ensure balanced framing across English steady contact and Western light-rein/draped-rein traditions.

#### 7. Transitions
- **Proposed short definition:** Deliberate changes from one gait, speed, or frame to another, such as moving from walk to trot (upward) or trot to halt (downward).
- **Synonyms & aliases:** `upward transition`, `downward transition`, `direct transition`, `progressive transition`
- **Suggested categories:** `Riding`, `Training`
- **Recommended `contextual`:** `true` (for `"upward transition"`, `"downward transition"`, `"direct transition"`)
- **Related Skill Tree IDs:** `rider.mounted.transitions`, `horse.mounted.transitions`, `rider.mounted.half_halt`
- **Related terminology:** `half-halt`, `rhythm`, `balance`
- **Educational justification:** Appears 73 times across 19 skills—one of the highest-frequency training concepts in the curriculum.

#### 8. Rhythm
- **Proposed short definition:** The regularity and evenness of a horse's footfalls in a given gait, consistent in both tempo and beat spacing.
- **Synonyms & aliases:** `tempo`, `cadence` *(note in explanation that rhythm = regularity, tempo = speed of beats)*
- **Suggested categories:** `Gaits`, `Biomechanics`, `Training`
- **Recommended `contextual`:** `true`
- **Related Skill Tree IDs:** `rider.theory.training_pyramid`, `rider.theory.gaits_footfalls`, `horse.mounted.walk`, `horse.mounted.trot`, `horse.mounted.canter`
- **Related terminology:** `training-pyramid`, `relaxation`, `impulsion`
- **Educational justification:** Appears 86 times across 29 skills—the single most frequently referenced quality across all mounted skills.

#### 9. Forehand & Hindquarters (2 Complementary Entries)
- **Forehand:** The front portion of the horse—head, neck, shoulders, withers, and front legs—which naturally carries slightly more than half of the horse's body weight.
  - **Contextual:** `true` | **Categories:** `Anatomy`, `Biomechanics` | **Skills:** `rider.theory.balance_weight`, `rider.mounted.turn_on_forehand`, `horse.mounted.turn_on_forehand`
- **Hindquarters:** The back portion of the horse—croup, hips, thighs, and hind legs—which generates propulsion and carries greater load as balance develops.
  - **Synonyms:** `haunches`, `hind end` | **Contextual:** `true` | **Categories:** `Anatomy`, `Biomechanics` | **Skills:** `rider.theory.balance_weight`, `rider.mounted.turn_on_haunches`, `horse.mounted.turn_on_haunches`
- **Educational justification:** Essential anatomical anchor for weight distribution, pivots, and lateral work.

#### 10. Girth / Cinch
- **Proposed short definition:** The strap that passes beneath the horse's barrel behind the elbows to hold a saddle securely in place.
- **Synonyms & aliases:** `cinch`, `front cinch`, `girth` *(regional/discipline note: "girth" in English riding, "cinch" in Western riding)*
- **Suggested categories:** `Tack & Equipment`
- **Recommended `contextual`:** `true`
- **Related Skill Tree IDs:** `rider.husbandry.tack`, `rider.theory.tack_fit_function`, `rider.mounted.mounting`
- **Related terminology:** `withers`, `wither-clearance`, `saddle-fit`
- **Educational justification:** Directly serves both English and Western riders; key safety check before mounting.

#### 11. Quick-Release Knot
- **Proposed short definition:** A slip knot used when tying a horse that holds securely under steady tension yet releases immediately with a single pull on the free tail in an emergency.
- **Synonyms & aliases:** `safety knot`, `highwayman's hitch`, `bank robber's knot`
- **Suggested categories:** `Handling`, `Safety`
- **Recommended `contextual`:** `true`
- **Related Skill Tree IDs:** `rider.husbandry.safe_handling`, `horse.in_hand.standing_quietly`
- **Related terminology:** `ground-tie`, `halter`
- **Educational justification:** Core barn safety skill with direct horse-welfare consequences.

#### 12. Vital Signs (TPR)
- **Proposed short definition:** Baseline physical measurements—temperature, pulse (heart rate), and respiration—used to assess a horse's health and detect early signs of illness or distress.
- **Synonyms & aliases:** `TPR`, `temperature pulse respiration`, `equine vital signs`
- **Suggested categories:** `Health & Welfare`, `Husbandry`
- **Recommended `contextual`:** `true`
- **Related Skill Tree IDs:** `rider.husbandry.health_monitoring`, `rider.husbandry.first_aid`, `horse.in_hand.vet_handling`
- **Related terminology:** `capillary-refill`, `colic`, `lameness`
- **Educational justification:** Appears across Health Monitoring, First Aid, and Vet Handling; **Matt's editorial review recommended** for veterinary disclaimer wording and reference ranges.

#### 13. Negative Reinforcement (Pressure and Release)
- **Proposed short definition:** A learning process in which a behavior becomes more likely because a mild, motivating pressure is removed the instant the horse offers the desired response.
- **Synonyms & aliases:** `pressure and release`, `R-`
- **Suggested categories:** `Learning Theory`, `Training`
- **Recommended `contextual`:** `true`
- **Related Skill Tree IDs:** `rider.theory.how_horses_learn`, `rider.theory.timing_reinforcement`
- **Related terminology:** `positive-reinforcement`, `operant-conditioning`, `shaping`
- **Educational justification:** Appears 10 times across Theory skills; clarifying that "negative" means *subtraction of pressure* (not punishment) prevents widespread misunderstanding.

#### 14. Positive Reinforcement
- **Proposed short definition:** A learning process in which a behavior becomes more likely because a desirable reward (such as food or scratching) is added promptly after the horse offers the response.
- **Synonyms & aliases:** `R+`, `clicker training`, `reward-based training`
- **Suggested categories:** `Learning Theory`, `Training`
- **Recommended `contextual`:** `true`
- **Related Skill Tree IDs:** `rider.theory.how_horses_learn`, `rider.theory.timing_reinforcement`
- **Related terminology:** `negative-reinforcement`, `operant-conditioning`, `shaping`
- **Educational justification:** Appears 6 times in Theory skills; supports balanced, humane cross-tradition horsemanship.

#### 15. Longeing (Lunging)
- **Proposed short definition:** Working a horse on a circle at the end of a long line while the handler stands near the center, used for communication, rhythm, observation, and conditioning.
- **Synonyms & aliases:** `lunging`, `longe line`, `lunge line`
- **Suggested categories:** `Handling`, `Training`
- **Recommended `contextual`:** `true`
- **Related Skill Tree IDs:** `rider.in_hand.longeing`, `rider.theory.training_equipment`
- **Related terminology:** `groundwork`, `ground-driving`, `cavesson`
- **Educational justification:** Covers both US ("longeing") and international ("lunging") spellings and links directly to `rider.in_hand.longeing`.

---

### P1 — Common Intermediate Concepts (18 Recommended Entries)

| # | Canonical Term | Short Definition (Draft) | Synonyms / Aliases | Categories | Contextual | Related Skill IDs | Editorial Review? |
| :- | :--- | :--- | :--- | :--- | :-: | :--- | :-: |
| 1 | **Leg Yield** | A lateral movement in which the horse travels forward and sideways with a nearly straight body (slight flexion away from the direction of travel). | `leg-yield`, `yielding laterally` | `Riding`, `Lateral Work` | Yes | `rider.mounted.leg_yield`, `horse.mounted.leg_yield` | No |
| 2 | **Turn on the Forehand** | A stationary or slow pivot in which the horse steps its hindquarters in a circle around a quiet, nearly stationary inside front foot. | `disengage the hindquarters`, `yielding the hindquarters` | `Riding`, `Handling` | Yes | `rider.mounted.turn_on_forehand`, `horse.mounted.turn_on_forehand`, `rider.in_hand.turn_on_forehand` | No |
| 3 | **Turn on the Haunches** | A turning movement in which the horse steps its forehand around active, stepping hind legs while maintaining rhythm and bend. | `turn on the hindquarters` | `Riding` | Yes | `rider.mounted.turn_on_haunches`, `horse.mounted.turn_on_haunches` | No |
| 4 | **Rein Back** | A symmetrical two-beat diagonal backward movement in which the horse steps back calmly without hollowing or rushing. | `backing up`, `back-up` | `Riding`, `Handling` | Yes | `rider.mounted.rein_back`, `horse.mounted.rein_back` | No |
| 5 | **Sidepass** | Moving directly sideways (perpendicular to the horse's spine) without forward or backward travel, often over a rail or to open a gate. | `side-pass`, `side pass` | `Riding`, `Handling` | Yes | `rider.mounted.sidepass`, `horse.mounted.sidepass`, `rider.in_hand.sidepass_in_hand` | No |
| 6 | **Ground Driving** | Guiding a horse from behind or beside the hindquarters using two long lines attached to a halter, cavesson, or bridle. | `long-lining`, `long reining`, `double lunging` | `Handling`, `Training` | Yes | `rider.in_hand.ground_driving`, `horse.in_hand.ground_driving` | No |
| 7 | **Self-Carriage** | The horse's ability to maintain its own balance, rhythm, and posture without leaning on the rider's hands or being held up by the reins. | `self carriage` | `Biomechanics`, `Riding` | Yes | `rider.theory.balance_weight`, `rider.theory.training_pyramid` | No |
| 8 | **Bend** | A uniform lateral curve of the horse's body from poll to tail matching the arc of a circle or curved line, without over-bending the neck. | `lateral bend`, `bending` | `Biomechanics`, `Riding` | **No** *(bare)*; Yes for `"lateral bend"` | `rider.theory.bend_flexion_straightness`, `rider.mounted.steering_navigation` | No |
| 9 | **Flexion** | A soft, lateral or longitudinal yielding at the poll and jaw without twisting the head or collapsing the neck. | `poll flexion`, `lateral flexion` | `Biomechanics`, `Riding` | Yes for `"poll flexion"`, `"lateral flexion"` | `rider.theory.bend_flexion_straightness` | No |
| 10 | **Straightness** | Alignment of the horse's hind feet tracking in line with its front feet on both straight lines and curves, distributing effort evenly left and right. | `tracking straight`, `natural crookedness` | `Biomechanics`, `Training` | Yes | `rider.theory.bend_flexion_straightness`, `rider.theory.training_pyramid` | No |
| 11 | **Impulsion** | Controlled, energetic forward thrust generated by engaged hindquarters and expressed through an elastic back—distinct from mere speed or rushing. | — | `Biomechanics`, `Training` | Yes | `rider.theory.training_pyramid`, `rider.mounted.shoulder_in` | No |
| 12 | **Training Pyramid** | A widely used six-stage classical training framework—rhythm, relaxation, connection, impulsion, straightness, and collection—used as one helpful guide among several horsemanship traditions. | `Training Scale`, `Skala der Ausbildung` | `Training`, `Theory` | Yes | `rider.theory.training_pyramid` | **Yes** *(non-dogmatic framing)* |
| 13 | **Habituation** | A gradual decrease in a horse's fear or startle response to a harmless stimulus after repeated calm, below-threshold exposure. | `desensitization` *(note nuance in explanation)* | `Learning Theory`, `Behavior` | Yes | `rider.theory.how_horses_learn`, `rider.in_hand.obstacles_outings` | No |
| 14 | **Operant Conditioning** | Learning through consequences—reinforcement (increasing behavior) and punishment (decreasing behavior)—which underlies pressure-and-release and reward-based training. | — | `Learning Theory` | Yes | `rider.theory.how_horses_learn`, `rider.theory.timing_reinforcement` | No |
| 15 | **Classical Conditioning** | Learning by associating a neutral cue (such as a voice word or click) with an existing stimulus or outcome. | `associative learning` | `Learning Theory` | Yes | `rider.theory.how_horses_learn` | No |
| 16 | **Two-Point Position** | A balanced forward riding position in which the rider's seat lifts slightly out of the saddle, supporting weight over two points of contact (the legs/stirrups) over terrain or obstacles. | `two-point`, `half-seat`, `jumping position` | `Riding` | Yes | `rider.mounted.trot`, `rider.mounted.terrain_obstacles` | No |
| 17 | **Colic** | Abdominal pain in horses, ranging from mild gas discomfort to life-threatening intestinal obstruction, always requiring prompt monitoring and veterinary evaluation. | — | `Health & Welfare` | Yes | `rider.husbandry.health_monitoring`, `rider.husbandry.feeding` | **Yes** *(welfare/vet disclaimer)* |
| 18 | **Lameness** | An irregularity or asymmetry in a horse's gait caused by pain, mechanical restriction, or neurological impairment in the limbs or back. | `off`, `unsoundness` | `Health & Welfare`, `Biomechanics` | Yes | `rider.husbandry.health_monitoring`, `rider.theory.pain_discomfort_fatigue`, `rider.theory.gaits_footfalls` | **Yes** *(vet assessment note)* |

---

### P2 — Advanced & Discipline-Specific Terminology (12 Recommended Entries)

| # | Canonical Term | Short Definition (Draft) | Synonyms / Aliases | Categories | Contextual | Related Skill IDs | Editorial Review? |
| :- | :--- | :--- | :--- | :--- | :-: | :--- | :-: |
| 1 | **Travers (Haunches-In)** | An advanced lateral movement in which the horse moves forward on three or four tracks with its hindquarters displaced inward and its body bent into the direction of travel. | `haunches-in`, `travers` | `Riding`, `Lateral Work` | Yes | `rider.mounted.travers`, `horse.mounted.travers` | No |
| 2 | **Half-Pass** | A collected lateral movement in which the horse travels forward and sideways across a diagonal line while bent in the direction of travel. | `appuyer`, `half pass` | `Riding`, `Lateral Work` | Yes | `rider.mounted.travers`, `rider.mounted.shoulder_in` | No |
| 3 | **Cross-Canter (Disunited Canter)** | An unbalanced canter in which the horse leads with one side in front and the opposite side behind, disrupting the normal three-beat footfall pattern. | `disunited`, `cross-firing` | `Gaits`, `Biomechanics` | Yes | `rider.theory.gaits_footfalls`, `rider.mounted.canter`, `horse.mounted.canter` | No |
| 4 | **Learned Helplessness** | A welfare-concerning state in which a horse stops trying to respond or escape after repeated unavoidable or inescapable aversive pressure—sometimes mistaken for calmness. | — | `Learning Theory`, `Health & Welfare` | Yes | `rider.theory.how_horses_learn`, `rider.theory.stress_fear_confidence`, `rider.theory.ethical_training` | **Yes** *(welfare sensitivity)* |
| 5 | **Five Domains Model** | A modern animal-welfare framework evaluating nutrition, physical environment, health, behavioral interactions, and the resulting mental state of the horse. | `Five Domains` | `Health & Welfare`, `Theory` | Yes | `rider.theory.ethical_training` | **Yes** *(cite Mellor et al. accurately)* |
| 6 | **Equine Pain Ethogram** | A structured set of observable facial and behavioral signs (such as ear position, eye tension, tail swishing, or gait changes) used to recognize discomfort in horses. | `pain ethogram`, `ridden horse pain ethogram` | `Health & Welfare`, `Behavior` | Yes | `rider.theory.pain_discomfort_fatigue`, `rider.theory.equine_body_language` | **Yes** *(clinical/behavioral accuracy)* |
| 7 | **Calming Signals** | Subtle, non-aggressive equine body-language behaviors (such as licking and chewing, head lowering, blinking, or turning away) associated with tension reduction or social communication. | `appeasement signals` | `Behavior` | Yes | `rider.theory.equine_body_language` | **Yes** *(evidence-supported vs. convention framing)* |
| 8 | **Cavesson** | A specialized fitted noseband/headpiece—often with rings on the noseband—used in groundwork, longeing, and in-hand training to guide the head without acting on the mouth. | `longeing cavesson`, `serreta` *(note welfare caution on harsh nosebands)* | `Tack & Equipment`, `Handling` | Yes | `rider.theory.training_equipment`, `rider.in_hand.longeing` | **Yes** *(welfare note)* |
| 9 | **Surcingle** | A wide strap fastened around the horse's barrel behind the withers, often equipped with rings for longeing or ground-driving lines. | `longeing surcingle`, `roller` | `Tack & Equipment`, `Handling` | Yes | `rider.theory.training_equipment`, `rider.in_hand.ground_driving` | No |
| 10 | **Garrocha** | A long wooden pole traditionally carried one-handed in Iberian riding and Working Equitation to test balance, steering, and horse composure. | — | `Discipline-Specific`, `Riding` | Yes | `rider.mounted.object_handling`, `horse.mounted.object_handling` | No |
| 11 | **Wither Clearance** | The vertical and lateral space between a saddle gullet or blanket neckline and the horse's withers needed to prevent painful pinching or pressure sores. | — | `Tack & Equipment`, `Health & Welfare` | Yes | `rider.husbandry.tack`, `rider.husbandry.blanketing`, `rider.theory.tack_fit_function` | No |
| 12 | **Thrush** | A bacterial and fungal infection of the grooves around the hoof frog, typically marked by dark foul-smelling discharge and associated with damp footing or infrequent hoof care. | — | `Health & Welfare`, `Husbandry` | Yes | `rider.husbandry.grooming`, `horse.in_hand.hoof_handling` | **Yes** *(veterinary/farrier note)* |

---

## 5. Opportunities to Connect Definitions with Resources

Once published in Firestore, Dictionary entries support `resourceIds[]`, and in-app Resource descriptions and comments automatically highlight contextual terms:

1. **Skill-Linked Resource Cross-Linking:** Any curated Resource tagged with `rider.mounted.canter`, `rider.mounted.half_halt`, `rider.mounted.shoulder_in`, or `rider.theory.*` can be referenced in the corresponding Dictionary entry's `resourceIds` during editorial review so learners can jump directly from a definition to vetted articles/videos.
2. **Safety & Husbandry Guides:** Associate existing First Aid, Vital Signs (TPR), Saddle Fit, and Safe Tying resources with `vital-signs-tpr`, `quick-release-knot`, `colic`, `withers`, and `wither-clearance`.
3. **Cross-Discipline Glossaries:** Add explicit `usage` and `regionalUsage` notes on `trot` (`jog`), `posting-trot` (`rising trot`), `girth-cinch` (`girth` vs. `cinch`), `aids` (`aids` vs. `cues`), and `rein-contact` (English steady contact vs. Western light/draped rein) to uphold the app's inclusive mission across all equestrian communities.

---

## 6. Recommended Next Steps for Editorial Review

1. **Backfill `skillIds` on the 6 unlinked starter entries** (`ground-tie`, `green-broke`, `collection`, `green`, `poll`, `withers`) via the Dictionary Admin workflow.
2. **Review and publish P0 batch first (15 entries)** — covers the highest-frequency vocabulary in Skill Tree 2.0 (`rhythm`, `trot`, `transitions`, `canter-lead`, `trot-diagonal`, `aids`, `rein-contact`, `girth-cinch`, `quick-release-knot`, `vital-signs-tpr`, `negative-reinforcement`, `positive-reinforcement`, `longeing`, `forehand`, `hindquarters`).
3. **Prioritize Matt's editorial review** on the 8 flagged clinical/welfare/philosophy entries (`rein-contact`, `vital-signs-tpr`, `training-pyramid`, `colic`, `lameness`, `learned-helplessness`, `five-domains-model`, `equine-pain-ethogram`, `calming-signals`, `cavesson`, `thrush`) before publication.
