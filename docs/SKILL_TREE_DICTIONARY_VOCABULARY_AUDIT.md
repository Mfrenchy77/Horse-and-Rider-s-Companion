# Horse & Rider's Companion — Skill Tree Vocabulary & Dictionary Integration Audit

> **Status: PROPOSAL & EDITORIAL AUDIT ONLY (Not Approved / Not Published)**  
> **Scope:** Wave 3 local Skill Tree 2.0 curriculum ([curriculum/v2](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/v2/families.json): **33 Skill Families, 84 Active Skills, 187 Difficulty Standards, 84 Legacy Mappings**) compared against the canonical Dictionary starter source ([dictionary_seed.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/dictionary_seed.json): **28 published entries**) and matching engine ([dictionary_matcher.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_matcher.dart)).  
> **Companion Machine-Readable Proposal:** [skill_tree_dictionary_candidates_proposal.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/skill_tree_dictionary_candidates_proposal.json) (**56 proposed new entries** + **10 recommended updates to existing entries**).  
> **Governing Principles:** [EQUESTRIAN_DICTIONARY_GUIDING_PRINCIPLES.md](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/EQUESTRIAN_DICTIONARY_GUIDING_PRINCIPLES.md) & [SKILL_TREE_CURRICULUM_GUIDE.md](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/SKILL_TREE_CURRICULUM_GUIDE.md). No production Dictionary entries, curriculum JSON files, Cloud Functions, Firestore rules, or Known Terms preferences were modified.

---

## 1. Current Dictionary Coverage & Canonical Architecture

### Canonical Data Source & Publishing Workflow

- **Canonical Local Dictionary Source:** [dictionary_seed.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/dictionary_seed.json) (loaded by both Flutter as the offline/pre-initialization catalogue and by Cloud Functions / [publish_dictionary_seed.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/tool/publish_dictionary_seed.js)).
- **Live Sync & Editorial Workflow:** Published meanings live in Firestore `DictionaryEntries/{slug}` alongside `DictionaryPublic/catalogue` (`initialized: true`). Community members suggest terms or improvements via `submitDictionarySuggestion`; administrators triage, edit private `DictionaryDrafts/{id}`, and publish versioned revisions via `editDictionary` in [dictionary.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/dictionary.js).
- **Important Baseline Discovery:** Earlier audit doc [DICTIONARY_COVERAGE_AUDIT.md](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/DICTIONARY_COVERAGE_AUDIT.md) tracked **11** starter entries against **72** skills; since then, **17 additional entries** (from Batch 1 and Batch 2) were incorporated into [dictionary_seed.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/dictionary_seed.json), bringing the canonical seed baseline to **28 published entries** (**24** with `contextual: true`, **4** with `contextual: false`).
- **Stale Draft File Catch:** [batch_01_drafts.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/dictionary/batch_01_drafts.json) (`5` entries: `trot`, `posting-trot`, `trot-diagonal`, `canter-lead`, `aids`) is already **100% incorporated** into [dictionary_seed.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/dictionary_seed.json) (see Section 4).

### Inventory of All 28 Existing Published Seed Entries

| ID | Canonical Term | Contextual? | Current Synonyms | Categories | Wave 3 Mentions | Linked `skillIds` |
| :--- | :--- | :---: | :--- | :--- | :---: | :---: |
| `green` | Green | **No** | — | Training | 3 (3 skills) | 2 |
| `green-broke` | Green Broke | Yes | `green broken`, `green-broken` | Training | 0 (0 skills) | 2 |
| `canter` | Canter | Yes | `cantering`, `lope`, `loping` | Gaits | 148 (19 skills) | 3 |
| `ground-tie` | Ground Tie | Yes | `ground tying`, `ground-tie` | Handling | 3 (1 skills) | 1 |
| `groundwork` | Groundwork | Yes | `ground work` | Handling, Training | 11 (8 skills) | 2 |
| `half-halt` | Half Halt | Yes | `half-halt`, `half halts` | Riding | 10 (6 skills) | 1 |
| `collection` | Collection | **No** | — | Riding, Biomechanics | 12 (7 skills) | 4 |
| `shoulder-in` | Shoulder-In | Yes | `shoulder in` | Riding | 14 (3 skills) | 2 |
| `counter-canter` | Counter-Canter | Yes | `counter canter` | Gaits, Riding | 27 (7 skills) | 4 |
| `poll` | Poll | **No** | — | Anatomy | 13 (8 skills) | 2 |
| `withers` | Withers | Yes | — | Anatomy | 3 (3 skills) | 3 |
| `trot` | Trot | Yes | `jog`, `jogging`, `trotting` | Gaits, Riding | 203 (32 skills) | 3 |
| `posting-trot` | Posting Trot | Yes | `rising trot`, `post the trot` | Riding, Gaits | 8 (1 skills) | 2 |
| `trot-diagonal` | Trot Diagonal | Yes | `posting diagonal`, `trot diagonals`, `posting diagonals`, `correct diagonal` | Gaits, Riding | 5 (2 skills) | 2 |
| `canter-lead` | Canter Lead | Yes | `lope lead`, `canter leads`, `lope leads`, `inside lead`, `outside lead` | Gaits, Riding | 14 (6 skills) | 3 |
| `aids` | Aids / Cues | **No** | `aids`, `cues`, `rider aids`, `rider cues`, `natural aids`, `artificial aids` | Riding, Training | 119 (44 skills) | 3 |
| `rhythm` | Rhythm | Yes | — | Gaits, Biomechanics, Training | 98 (41 skills) | 5 |
| `rein-contact` | Rein Contact | Yes | `elastic contact`, `soft contact` | Riding, Training | 3 (3 skills) | 4 |
| `transitions` | Transitions | Yes | `upward transition`, `upward transitions`, `downward transition`, `downward transitions`, `direct transition`, `direct transitions`, `progressive transitions` | Riding, Training | 103 (28 skills) | 3 |
| `forehand` | Forehand | Yes | — | Anatomy, Biomechanics | 53 (14 skills) | 3 |
| `hindquarters` | Hindquarters | Yes | `haunches`, `hind end` | Anatomy, Biomechanics | 87 (25 skills) | 4 |
| `girth-cinch` | Girth / Cinch | Yes | `girth`, `cinch`, `front cinch` | Tack & Equipment, Safety | 33 (8 skills) | 3 |
| `quick-release-knot` | Quick-Release Knot | Yes | `safety knot`, `highwayman's hitch` | Handling, Safety | 3 (1 skills) | 2 |
| `vital-signs-tpr` | Vital Signs (TPR) | Yes | `TPR`, `vital signs`, `temperature pulse respiration` | Health & Welfare, Husbandry | 8 (2 skills) | 3 |
| `negative-reinforcement` | Negative Reinforcement | Yes | `pressure and release`, `R-` | Learning Theory, Training | 10 (1 skills) | 2 |
| `positive-reinforcement` | Positive Reinforcement | Yes | `R+`, `clicker training`, `reward-based training` | Learning Theory, Training | 7 (2 skills) | 2 |
| `self-carriage` | Self-Carriage | Yes | `self carriage` | Biomechanics, Riding | 18 (9 skills) | 4 |
| `longeing` | Longeing | Yes | `lunging`, `longe line`, `lunge line` | Handling, Training | 16 (5 skills) | 2 |

### Status of Prompt Investigation Examples (20 Terms Checked)

| Example Term | Current Status in `functions/dictionary_seed.json` | Wave 3 Coverage & Proposal Action |
| :--- | :--- | :--- |
| **Half-halt** | **Already Exists** (`half-halt`, `ctx: true`) | Update `half-halt` (Section 3): add missing hyphenated plural `"half-halts"` + missing skill links. |
| **Collection** | **Already Exists** (`collection`, `ctx: false`) | Adequate & well-guarded (`contextual: false` prevents noise on general English usage). |
| **Counter-canter** | **Already Exists** (`counter-canter`, `ctx: true`) | Update `counter-canter` (Section 3): add Wave 1 split skill IDs `*.mounted.counter_canter`. |
| **Self-carriage** | **Already Exists** (`self-carriage`, `ctx: true`) | Adequate (`18` Wave 3 hits across `9` skills); add Wave 3 `horse.in_hand.longeing` link. |
| **Pressure and release** | **Already Covered as Synonym** (`negative-reinforcement`) | Keep consolidated inside `negative-reinforcement`; add hyphenated `"pressure-and-release"` synonym. |
| **Reinforcement** | **Partially Covered** (`negative-reinforcement`, `positive-reinforcement` exist separately) | **Propose Priority A** `reinforcement` umbrella concept tying `R−`, `R+`, and schedules together. |
| **Independent seat** | Missing | **Propose Priority A** `independent-seat` (links directly to Wave 3 `rider.mounted.seat_balance`). |
| **Rein back** | Missing | **Propose Priority A** `rein-back`. |
| **Learned helplessness** | Missing | **Propose Priority A** `learned-helplessness` (critical welfare & shutdown safety entry). |
| **Engagement** | Missing | **Propose Priority B** `engagement`. |
| **Impulsion** | Missing | **Propose Priority B** `impulsion`. |
| **Straightness** | Missing | **Propose Priority B** `straightness` (keep bare `"straight"` excluded). |
| **Bend** | Missing | **Propose Priority B** `bend` (`contextual: false` on bare word; explicit multiword aliases). |
| **Lateral yielding** | Missing | **Propose Priority B** `lateral-movement` (aliases: `"lateral work"`, `"lateral yielding"`). |
| **Diagonal pairs** | Missing | **Propose Priority B** `diagonal-pairs` (covers trot & rein-back biomechanics cleanly). |
| **Habituation** | Missing | **Propose Priority B** `habituation`. |
| **Desensitization** | Missing | **Propose Priority B** `desensitization`. |
| **Asymmetry** | Missing | **Propose Priority B** `asymmetry` (covers both equine crookedness and rider hip/shoulder bias). |
| **Flying lead change** | Missing | **Propose Priority C** `flying-lead-change` (pairs with `rider/horse.mounted.flying_lead_changes`). |
| **Proprioception** | Missing from both Dictionary & Curriculum (`0` hits in `curriculum/v2/`) | **Propose Priority C** `proprioception` (optional biomechanics addition; flagged as `0` current curriculum hits). |

---

## 2. Missing Terminology (56 Proposals — Priorities A, B, and C)

All proposed candidates represent equestrian-specific concepts encountered across the **84 Wave 3 skills** (plus 1 optional biomechanics term, `proprioception`). Ordinary words are excluded from automatic contextual highlighting or omitted altogether (see exclusions below). No completion scores or numerical priority rankings are used.

### Priority A — Essential Educational Vocabulary (14 Proposed Entries)

Beginner-critical terminology affecting rider balance, safety, ground control, learning comprehension, and equine emergency or daily health recognition:

| ID / Slug | Canonical Term | Contextual Highlight? | Suggested Aliases / Synonyms | Categories | Wave 3 Occurrences | Clinical / Welfare Review? |
| :--- | :--- | :---: | :--- | :--- | :---: | :---: |
| `independent-seat` | **Independent Seat** | Yes | `balanced seat`, `following seat` | Riding, Biomechanics | 10 (6 skills) | No |
| `two-point-position` | **Two-Point Position** | Yes | `two-point`, `half-seat`, `light seat` | Riding | 13 (5 skills) | No |
| `rein-back` | **Rein Back** | Yes | `rein-back`, `backing up`, `reculer` | Riding, Handling, Gaits | 12 (3 skills) | No |
| `turn-on-the-forehand` | **Turn on the Forehand** | Yes | `turns on the forehand`, `disengage the hindquarters`, `yielding the hindquarters` | Riding, Handling | 17 (4 skills) | No |
| `turn-on-the-haunches` | **Turn on the Haunches** | Yes | `turns on the haunches`, `turn on the hindquarters`, `turn around the hindquarters` | Riding, Handling | 9 (4 skills) | No |
| `reinforcement` | **Reinforcement** | Yes | `positive and negative reinforcement`, `reinforcement schedule` | Learning Theory, Training | 27 (3 skills) | No |
| `learned-helplessness` | **Learned Helplessness** | Yes | `equine shutdown` | Learning Theory, Health & Welfare, Behavior | 5 (4 skills) | **Yes** |
| `colic` | **Colic** | Yes | `colicking`, `equine colic` | Health & Welfare, Husbandry | 7 (3 skills) | **Yes** |
| `lameness` | **Lameness** | Yes | `unsoundness` | Health & Welfare, Biomechanics | 7 (4 skills) | **Yes** |
| `choke` | **Choke** | **No** *(manual Define)* | `equine choke`, `esophageal choke` | Health & Welfare, Husbandry | 7 (3 skills) | **Yes** |
| `thrush` | **Thrush** | Yes | `hoof thrush` | Health & Welfare, Husbandry | 2 (2 skills) | **Yes** |
| `wither-clearance` | **Wither Clearance** | Yes | `gullet clearance` | Tack & Equipment, Health & Welfare | 2 (2 skills) | No |
| `blind-spot` | **Blind Spot** | Yes | `blind spots`, `equine blind spots` | Safety, Behavior | 3 (1 skills) | No |
| `forage` | **Forage** | Yes | `roughage` | Husbandry, Health & Welfare | 9 (2 skills) | No |

### Priority B — Important Intermediate Concepts (24 Proposed Entries)

Biomechanical qualities, communication cues, lateral fundamentals, learning-theory mechanisms, and key equine soundness concepts:

| ID / Slug | Canonical Term | Contextual Highlight? | Suggested Aliases / Synonyms | Categories | Wave 3 Occurrences | Clinical / Welfare Review? |
| :--- | :--- | :---: | :--- | :--- | :---: | :---: |
| `engagement` | **Engagement** | Yes | `hindquarter engagement` | Biomechanics, Riding, Training | 11 (7 skills) | No |
| `impulsion` | **Impulsion** | Yes | — | Biomechanics, Training | 4 (1 skills) | No |
| `straightness` | **Straightness** | Yes | — | Biomechanics, Training | 39 (19 skills) | No |
| `bend` | **Bend** | **No** *(manual Define)* | `lateral bend`, `inward bend`, `true bend` | Biomechanics, Riding | 48 (12 skills) | No |
| `flexion` | **Flexion** | **No** *(manual Define)* | `poll flexion`, `lateral flexion`, `jaw flexion` | Biomechanics, Riding | 12 (6 skills) | No |
| `suppleness` | **Suppleness** | Yes | `lateral suppleness`, `longitudinal suppleness` | Biomechanics, Training | 7 (7 skills) | No |
| `asymmetry` | **Asymmetry** | Yes | `natural crookedness`, `equine asymmetry`, `rider asymmetry` | Biomechanics, Training | 20 (9 skills) | No |
| `hollowing` | **Hollowing** | Yes | `hollow back`, `hollowed` | Biomechanics, Behavior | 12 (8 skills) | No |
| `lateral-movement` | **Lateral Movement** | Yes | `lateral work`, `lateral movements`, `lateral yielding`, `lateral yield` | Riding, Training, Biomechanics | 13 (9 skills) | No |
| `leg-yield` | **Leg Yield** | Yes | `leg-yield`, `leg yields`, `leg-yields` | Riding, Training | 8 (3 skills) | No |
| `sidepass` | **Sidepass** | Yes | `side-pass`, `side pass`, `sidepasses` | Riding, Handling | 12 (4 skills) | No |
| `simple-lead-change` | **Simple Lead Change** | Yes | `simple lead changes`, `simple change`, `simple changes` | Gaits, Riding | 16 (4 skills) | No |
| `cross-canter` | **Cross-Canter** | Yes | `cross canter`, `cross-cantering`, `disunited canter`, `cross-firing` | Gaits, Biomechanics | 9 (5 skills) | No |
| `diagonal-pairs` | **Diagonal Pairs** | Yes | `diagonal pair`, `two-beat diagonal`, `diagonal two-beat` | Gaits, Biomechanics | 6 (3 skills) | No |
| `ground-driving` | **Ground Driving** | Yes | `long-lining`, `long reining`, `two-line ground work` | Handling, Training | 7 (2 skills) | No |
| `training-pyramid` | **Training Pyramid** | Yes | `Training Scale`, `Skala der Ausbildung` | Training, Theory | 8 (1 skills) | **Yes** |
| `operant-conditioning` | **Operant Conditioning** | Yes | — | Learning Theory, Training | 5 (1 skills) | No |
| `classical-conditioning` | **Classical Conditioning** | Yes | `associative learning` | Learning Theory | 4 (1 skills) | No |
| `habituation` | **Habituation** | Yes | — | Learning Theory, Behavior | 8 (1 skills) | No |
| `desensitization` | **Desensitization** | Yes | — | Learning Theory, Behavior | 3 (2 skills) | No |
| `arousal-threshold` | **Arousal Threshold** | Yes | `arousal thresholds`, `sub-threshold` | Behavior, Learning Theory, Safety | 6 (3 skills) | No |
| `trigger-stacking` | **Trigger Stacking** | Yes | — | Behavior, Safety | 3 (1 skills) | No |
| `laminitis` | **Laminitis** | Yes | `founder`, `laminitic` | Health & Welfare, Husbandry | 1 (1 skills) | **Yes** |
| `digital-pulse` | **Digital Pulse** | Yes | `digital pulses` | Health & Welfare, Husbandry | 4 (2 skills) | **Yes** |

### Priority C — Specialized or Advanced Terminology (18 Proposed Entries)

Upper-level dressage/gait concepts, behavioral/welfare science frameworks, clinical triage anatomy, specialized gear, and `proprioception`:

| ID / Slug | Canonical Term | Contextual Highlight? | Suggested Aliases / Synonyms | Categories | Wave 3 Occurrences | Clinical / Welfare Review? |
| :--- | :--- | :---: | :--- | :--- | :---: | :---: |
| `flying-lead-change` | **Flying Lead Change** | Yes | `flying lead changes`, `flying change`, `flying changes` | Gaits, Riding | 19 (5 skills) | No |
| `travers` | **Travers** | Yes | `haunches-in` | Riding, Biomechanics | 18 (3 skills) | No |
| `shoulder-fore` | **Shoulder-Fore** | Yes | `shoulder fore` | Riding, Training | 7 (2 skills) | No |
| `ambling-gait` | **Ambling Gait** | Yes | `ambling gaits`, `ambling`, `running walk`, `tölt` | Gaits | 7 (3 skills) | No |
| `free-walk` | **Free Walk** | Yes | `stretchy walk` | Gaits, Riding | 9 (2 skills) | No |
| `cadence` | **Cadence** | Yes | — | Gaits, Biomechanics | 3 (2 skills) | No |
| `tempo` | **Tempo** | Yes | — | Gaits, Biomechanics | 25 (14 skills) | No |
| `counter-conditioning` | **Counter-Conditioning** | Yes | `counter conditioning` | Learning Theory, Training | 3 (1 skills) | No |
| `flooding` | **Flooding** | **No** *(manual Define)* | — | Learning Theory, Health & Welfare, Behavior | 1 (1 skills) | No |
| `five-domains-model` | **Five Domains Model** | Yes | `Five Domains` | Health & Welfare, Theory | 2 (1 skills) | **Yes** |
| `equine-pain-ethogram` | **Equine Pain Ethogram** | Yes | `pain ethogram`, `ridden horse pain ethogram` | Health & Welfare, Behavior | 1 (1 skills) | **Yes** |
| `capillary-refill-time` | **Capillary Refill Time** | Yes | `capillary refill`, `CRT` | Health & Welfare, Husbandry | 2 (1 skills) | **Yes** |
| `synovial-structure` | **Synovial Structure** | Yes | `synovial structures`, `tendon sheath`, `tendon sheaths` | Anatomy, Health & Welfare | 1 (1 skills) | **Yes** |
| `cavesson` | **Cavesson** | Yes | `longeing cavesson`, `lungeing cavesson` | Tack & Equipment, Handling | 3 (3 skills) | **Yes** |
| `surcingle` | **Surcingle** | Yes | `surcingles`, `longeing surcingle`, `belly surcingle`, `belly surcingles` | Tack & Equipment, Handling | 9 (4 skills) | No |
| `hackamore-bosal` | **Hackamore / Bosal** | Yes | `hackamore`, `bosal` | Tack & Equipment, Riding | 1 (1 skills) | No |
| `garrocha` | **Garrocha** | Yes | — | Riding, Tack & Equipment | 2 (2 skills) | No |
| `proprioception` | **Proprioception** | Yes | `proprioceptive` | Biomechanics, Theory | 0 (0 skills) | No |

### Intentionally Excluded Ordinary / High-Ambiguity Words

To prevent cluttering plain horsemanship explanations with misleading popovers, the following words found in the Skill Tree are **excluded** as standalone contextual entries (several remain reachable via safe multiword entries or manual selection):

- **Bare gait/posture everyday verbs & nouns:** `walk`, `halt`, `seat`, `lead`, `straight`, `contact`, `connection`, `balance`, `support`, `transition` *(already `transitions`)*
- **High-homograph medical/anatomical/environmental English words:**
  - `frog` & `sole` *(pond animal / shoe sole — address cleanly inside hoof-care skills or future unambiguous `"hoof frog"`)*
  - `bars` *(general nouns — address within bit/bridle explanation)*
  - `bend`, `flexion`, `choke`, `flooding` *(created as `contextual: false` meanings so users can manually select **"Define"** or search Dictionary without triggering highlights on `"knee flexion"`, `"bend safely"`, `"high-stress bends"`, or trail weather)*
  - `freeze`, `bracing`, `pacing`, `hollow`, `rack`, `threshold`, `shaping` *(general English verbs/nouns that misfire across non-technical clauses; specific `arousal-threshold` and `hollowing` cover the safe unambiguous forms)*

---

## 3. Existing Published Seed Entries Needing Improvement (10 Entries)

Every existing seed entry now passes `dictionary_seed_integrity_test.dart` (unique IDs/slugs, valid V2 `skillIds`, valid `relatedTerms`). However, auditing them against **Wave 1–3** and **contextual regex matching** identifies `10` non-breaking improvements (no `id` or `slug` changes):

| Existing Entry ID | Recommended Non-Breaking Improvement | New Synonyms to Add | New `skillIds` to Add |
| :--- | :--- | :--- | :--- |
| `counter-canter` | Add Wave 1 split skill IDs rider.mounted.counter_canter and horse.mounted.counter_canter (keep existing canter and steering_navigation links). | `counter canters` | `rider.mounted.counter_canter`, `horse.mounted.counter_canter` |
| `longeing` | Add Wave 3 Horse counterpart horse.in_hand.longeing plus bare verb/noun synonyms ("longe", "lunge") which appear in curriculum. | `longe`, `lunge` | `horse.in_hand.longeing`, `rider.theory.progressive_conditioning` |
| `half-halt` | Add "half-halts" (hyphenated plural matches 1 hit in curriculum where seed only had space-separated "half halts") plus horse.mounted.transitions and rider.theory.understanding_rider_aids. | `half-halts` | `horse.mounted.transitions`, `rider.theory.understanding_rider_aids`, `rider.theory.balance_weight` |
| `ground-tie` | Add "ground-tying" (hyphenated gerund matches 1 hit in horse.in_hand.standing_quietly) and "ground ties"; add counterpart link to rider.husbandry.safe_handling. | `ground-tying`, `ground ties` | `rider.husbandry.safe_handling` |
| `groundwork` | Add Wave 1/3 groundwork skills (longeing, ground driving, catching, yielding) so Glossary learners discover the full In-Hand category. | — | `rider.in_hand.longeing`, `horse.in_hand.longeing`, `rider.in_hand.ground_driving`, `horse.in_hand.yield_hindquarters` |
| `canter-lead` | Connect Wave 1 counter-canter and flying-lead-change split IDs plus singular "lead change" synonym. | — | `rider.mounted.counter_canter`, `rider.mounted.flying_lead_changes`, `horse.mounted.flying_lead_changes` |
| `negative-reinforcement` | Add hyphenated "pressure-and-release" synonym alongside existing space-separated "pressure and release", and link rider.in_hand.leading & trailer_loading. | `pressure-and-release` | `rider.in_hand.leading`, `rider.in_hand.trailer_loading` |
| `self-carriage` | Connect Wave 3 horse.in_hand.longeing, horse.mounted.canter, and rider.mounted.travers. | — | `horse.in_hand.longeing`, `horse.mounted.canter`, `rider.mounted.travers` |
| `girth-cinch` | Add "girths", "cinches", "girthiness", "girthy" (9 hits in Wave 3 husbandry & horse handling care), keeping explanation note on ulcer/tack discomfort intact. | `girths`, `cinches`, `girthiness`, `girthy` | `horse.in_hand.daily_care_handling` |
| `transitions` | Add singular forms ("transition", "progressive transition") and "within-gait transitions" plus rider.theory.understanding_rider_aids. | `transition`, `progressive transition`, `within-gait transitions` | `rider.theory.understanding_rider_aids` |

*Note on `green-broke`: Keeps `0` exact occurrences in `curriculum/v2/*.json` because the Skill Tree intentionally avoids labeling horses `green broke` without context—consistent with [EQUESTRIAN_DICTIONARY_GUIDING_PRINCIPLES.md](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/EQUESTRIAN_DICTIONARY_GUIDING_PRINCIPLES.md) ("avoid presenting them as safety guarantees"). Keep `green-broke` published for Resources and manual search.*

---

## 4. Potential Duplicate Entries & Scope Boundaries

1. **Superseded Batch 1 Draft File ([batch_01_drafts.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/dictionary/batch_01_drafts.json)):** Contains `5` draft records (`trot`, `posting-trot`, `trot-diagonal`, `canter-lead`, `aids`) that are **100% already published in [dictionary_seed.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/dictionary_seed.json)**. *Recommendation:* Do not re-import `batch_01_drafts.json`; archive or remove it in a future cleanup commit after checking test references in [dictionary_batch_01_drafts_test.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/test/dictionary/dictionary_batch_01_drafts_test.dart).
2. **Synonym Consolidations Preventing Duplicate Entries:**
   - `pressure and release` / `pressure-and-release` → **Keep inside** existing `negative-reinforcement` (do not create a separate `pressure-and-release` entry).
   - `long-lining` / `long reining` / `two-line ground work` → **Fold into** `ground-driving`.
   - `rising trot` / `jog` / `lope` / `haunches` / `girth` / `cinch` → **Already folded cleanly** into `posting-trot`, `trot`, `canter`, `hindquarters`, and `girth-cinch`.
   - `running walk` / `tölt` / `ambling` → **Fold into** single cross-breed `ambling-gait` entry instead of fragmented breed-by-breed entries.
   - `haunches-in` → **Synonym on** `travers`.
   - `gullet clearance` → **Synonym on** `wither-clearance`.
   - `founder` → **Synonym on** `laminitis`.
3. **Intentional Clean Splits (Distinct Meanings, Cross-Linked):**
   - `trot-diagonal` *(rider posting rhythm in trot)* vs. `diagonal-pairs` *(equine limb biomechanics shared by trot and rein-back)*.
   - `reinforcement` *(general learning-theory mechanism)* vs. existing `negative-reinforcement` and `positive-reinforcement`.
   - `habituation` *(passive calm familiarization)* vs. `desensitization` *(structured below-threshold progression)* vs. `counter-conditioning` *(actively shifting emotional valence)* vs. `flooding` *(forced inescapable exposure)*.
   - `withers` *(existing anatomy)* vs. `wither-clearance` *(saddle/blanket fit safety margin)*.

---

## 5. Suggested Definitions, Aliases, Examples, Welfare Notes & Skill References (56 Proposed Entries)

> **Proposal Notice:** All `56` definitions below are draft proposals (`status: "proposed"`) awaiting owner/editorial review—especially the `13` items marked for clinical, welfare, or cross-philosophy review. Full JSON payloads sit in [skill_tree_dictionary_candidates_proposal.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/docs/skill_tree_dictionary_candidates_proposal.json).

### Priority A — Detailed Proposals (14 Entries)

#### 1. Independent Seat (`independent-seat` · Proposal — Not Approved)
- **Categories:** Riding, Biomechanics | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `balanced seat`, `following seat`
- **Concise Definition:** The rider's ability to stay centered and absorb the horse's motion with relaxed pelvis, core, and legs without hanging onto the reins or clamping defensively.
- **Educational Explanation:** An independent seat separates balance from communication: the rider's hands, legs, and weight can give quiet, clear cues because none of those body parts is desperately gripping to stay aboard. It applies equally whether riding a deep classical dressage seat, a relaxed Western seat, or a balanced light/two-point seat over trails and terrain.
- **Practical Example:** During walk and trot warm-ups, soften through your hips so you maintain an independent seat without stiffening onto the reins.
- **Cross-Tradition Usage:** Foundational across English, Western, trail, ranch, and therapeutic riding; enables non-restrictive rein feel and protects the horse's mouth and back.
- **Safety / Welfare Considerations:** Depending on the reins for balance pulls the horse's mouth and hollow-braces its back; build tempo gradually and use a neck strap or grab strap while developing balance.
- **Related Terminology:** `two-point-position`, `rein-contact`, `aids`, `asymmetry`
- **Related Skill Tree Skills:** `rider.mounted.seat_balance`, `rider.mounted.walk`, `rider.mounted.trot`, `rider.mounted.terrain_obstacles`

#### 2. Two-Point Position (`two-point-position` · Proposal — Not Approved)
- **Categories:** Riding | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `two-point`, `half-seat`, `light seat`
- **Concise Definition:** A forward, balanced riding position in which the seat lifts cleanly slightly out of the saddle so rider weight is absorbed symmetrically through flexible ankles, knees, and hips.
- **Educational Explanation:** Using two-point or a lighter half-seat relieves continuous saddle weight over the horse's lumbar back during brisk trots, canter conditioning, steep climbs, ground poles, and jumping. In genuine two-point, the rider stays balanced over their own base of support rather than tipping forward onto the horse's neck or bracing off the reins.
- **Practical Example:** Shift smoothly into a light two-point position on moderate uphill climbs while offering generous rein freedom for balance.
- **Cross-Tradition Usage:** Common across jumping, eventing, endurance, trail climbing, and conditioning work; half-seat keeps light tailbone brush without fully standing in stirrups.
- **Regional Usage:** Two-point and half-seat are common in North America; light seat or jumping position are common internationally.
- **Safety / Welfare Considerations:** Avoid standing rigidly straight or gripping knees; unlocked ankle and hip shock absorption protects both horse back comfort and rider stability on hills.
- **Related Terminology:** `independent-seat`, `forage`, `trot`, `canter`
- **Related Skill Tree Skills:** `rider.mounted.seat_balance`, `rider.mounted.canter`, `rider.mounted.terrain_obstacles`

#### 3. Rein Back (`rein-back` · Proposal — Not Approved)
- **Categories:** Riding, Handling, Gaits | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `rein-back`, `backing up`, `reculer`
- **Concise Definition:** A deliberate, unhurried movement in which a horse steps straight or along a guided line backward in symmetrical two-beat diagonal footfall pairs.
- **Educational Explanation:** Whether asked from the ground or under saddle, a healthy rein back shifts weight politely toward the hindquarters while keeping the jaw, poll, and back soft. Each step moves an opposite-side front and hind foot together. It serves practical horsemanship everyday—at gates, trailers, tight barn spaces, and trail turnarounds—without requiring fixed step counts or narrow corridor patterns at entry levels.
- **Practical Example:** Prepare a settled halt first, invite one or two calm diagonal steps of rein back, and soften promptly back to halt or walk.
- **Cross-Tradition Usage:** In mounted work, riders soften hands forward immediately once the horse yields backward rather than pulling continuously; in-hand backing uses clear personal-space cues.
- **Regional Usage:** Rein back (or rein-back) is common in English, classical, and European usage (reculer in French); back-up or backing is everyday Western and groundwork phrasing.
- **Safety / Welfare Considerations:** Stepping backward flexes hocks, stifles, and lumbar spine; repeated head-throwing, toe-dragging, or refusal warrants checking saddle fit, dental comfort, and hind-limb soundness—never see-saw or haul hard backward.
- **Related Terminology:** `diagonal-pairs`, `half-halt`, `transitions`, `turn-on-the-forehand`
- **Related Skill Tree Skills:** `rider.mounted.rein_back`, `horse.mounted.rein_back`, `rider.in_hand.leading`, `rider.theory.gaits_footfalls`

#### 4. Turn on the Forehand (`turn-on-the-forehand` · Proposal — Not Approved)
- **Categories:** Riding, Handling | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `turns on the forehand`, `disengage the hindquarters`, `yielding the hindquarters`
- **Concise Definition:** A stationary or slow-stepping maneuver—in-hand or under saddle—in which the horse steps its hindquarters laterally around a relatively steady front end.
- **Educational Explanation:** Practiced on both left and right sides, yielding the hindquarters teaches the horse to answer a light lateral leg or ground cue cleanly while the inside hind leg crosses politely in front of the outside hind leg. Handlers and riders use it to open gates, align beside mounting blocks, soften crookedness, and de-escalate crowding safely without twisting the horse backward.
- **Practical Example:** Ask from a quiet halt for a calm turn on the forehand to step the hips clear of the gate latch.
- **Cross-Tradition Usage:** In Western and groundwork traditions, yielding or disengaging the hindquarters also serves as a calming redirection; classical and English traditions treat it as a structured lateral foundation.
- **Safety / Welfare Considerations:** Avoid holding stiff backward rein pressure that traps the horse into running backward or pulling against the bit/halter; stand clear of the kicking arc when working from the ground.
- **Related Terminology:** `forehand`, `hindquarters`, `turn-on-the-haunches`, `leg-yield`
- **Related Skill Tree Skills:** `rider.in_hand.turn_on_forehand`, `horse.in_hand.yield_hindquarters`, `rider.mounted.turn_on_forehand`, `horse.mounted.turn_on_forehand`

#### 5. Turn on the Haunches (`turn-on-the-haunches` · Proposal — Not Approved)
- **Categories:** Riding, Handling | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `turns on the haunches`, `turn on the hindquarters`, `turn around the hindquarters`
- **Concise Definition:** A turning movement—on foot or from active walk under saddle—in which the horse steps its shoulders smoothly around steadier hindquarters without backing or spinning abruptly.
- **Educational Explanation:** Unlike a turn on the forehand, the hindquarters stay closer to the center of the arc while the outside front leg crosses smoothly around the inside front leg, preserving steady walk rhythm and forward intention. Across disciplines—from opening narrow trail gates to preparing balanced arena corners—quality is measured by preparation, clear shoulder guidance, sound footing judgment, and straight exits rather than arbitrary degree angles.
- **Practical Example:** Maintain active four-beat walk flow while guiding the shoulders calmly around the haunches to face the trail gate.
- **Cross-Tradition Usage:** English, trail, ranch, and classical horsemen all use controlled turns around the haunches; radius starts generous in introductory stages and becomes more compact as strength and coordination grow.
- **Safety / Welfare Considerations:** Keep footing non-slippery and keep the horse stepping forward in walk rather than wrenching the neck inward or pivoting forcefully on a twisted hock.
- **Related Terminology:** `hindquarters`, `turn-on-the-forehand`, `half-halt`, `lateral-movement`
- **Related Skill Tree Skills:** `rider.mounted.turn_on_haunches`, `horse.mounted.turn_on_haunches`, `rider.in_hand.yield_forequarters`, `horse.in_hand.yield_forequarters`

#### 6. Reinforcement (`reinforcement` · Proposal — Not Approved)
- **Categories:** Learning Theory, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `positive and negative reinforcement`, `reinforcement schedule`
- **Concise Definition:** Any training event that makes a horse's response more likely to happen again—either by removing mild motivating pressure (negative reinforcement) or adding a valued reward (positive reinforcement).
- **Educational Explanation:** Every time pressure releases right as a horse yields or a treat/scratch follows a desired try, reinforcement shapes future behavior. In learning theory, reinforcement strengthens behavior whereas punishment weakens it; effective trainers carefully time whichever quadrant fits the horse and task so the horse clearly knows what succeeded without confusion or escalating force.
- **Practical Example:** Immediate timing matters most in reinforcement: waiting three seconds after the horse stops rushing teaches less clearly than releasing on the very first calm step.
- **Cross-Tradition Usage:** Umbrella term linking pressure-and-release (R−) and reward-based training (R+) neutrally across all equestrian philosophies.
- **Safety / Welfare Considerations:** Accidental reinforcement—such as dropping the lead when a horse pulls away—quickly trains unwanted habits; slow down, simplify requests, and check comfort rather than relying on punishment.
- **Related Terminology:** `negative-reinforcement`, `positive-reinforcement`, `operant-conditioning`, `classical-conditioning`
- **Related Skill Tree Skills:** `rider.theory.how_horses_learn`, `rider.theory.timing_reinforcement`, `rider.in_hand.longeing`

#### 7. Learned Helplessness (`learned-helplessness` · Proposal — Not Approved)
- **Categories:** Learning Theory, Health & Welfare, Behavior | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `equine shutdown`
- **Concise Definition:** A welfare-compromising behavioral state in which a horse stops trying to respond, avoid, or escape after repeated exposure to unavoidable, excessive, or confusing aversive pressure.
- **Educational Explanation:** A shut-down horse may stand superficially still with dull eyes, tight muzzle, braced muscles, or slow shuffling steps—causing inexperienced observers to mistake exhaustion or psychological defeat for calm obedience. Genuine relaxation looks markedly different: soft breathing, blinking eyes, curious ear movement, and responsive, willing weight shifts.
- **Practical Example:** Never mistake a frozen horse that stops reacting out of learned helplessness for a genuinely confident horse during trailer loading or haltering.
- **Cross-Tradition Usage:** Essential welfare concept in behavioral science, ethical groundwork, desensitization, and safe catching/handling assessment.
- **Safety / Welfare Considerations:** Shutdown carries high welfare and safety risk because suppressed horses can either suffer silently with stress ulcers/pain or erupt suddenly when pushed past an unseen threshold.
- **Related Terminology:** `negative-reinforcement`, `flooding`, `arousal-threshold`, `habituation`
- **Related Skill Tree Skills:** `rider.theory.how_horses_learn`, `rider.theory.stress_fear_confidence`, `rider.theory.ethical_training`, `horse.in_hand.catching_turnout`, `rider.theory.training_pyramid`

#### 8. Colic (`colic` · Proposal — Not Approved)
- **Categories:** Health & Welfare, Husbandry | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `colicking`, `equine colic`
- **Concise Definition:** Abdominal pain in horses—a broad clinical sign ranging from mild gas cramping to life-threatening intestinal displacement or impaction requiring prompt veterinary assessment.
- **Educational Explanation:** Common outward signs include pawing, turning to look or bite at the flanks, curling the upper lip, restlessness, repeatedly lying down and getting back up, rolling, decreased appetite, quiet or absent gut sounds, elevated heart rate, and reduced or dry manure. Because mild episodes can worsen rapidly, baseline vital-sign tracking and early vet contact save lives.
- **Practical Example:** Withhold hay and grain from a horse showing signs of colic, note temperature/pulse/respiration and gut sounds, and call your veterinarian immediately.
- **Cross-Tradition Usage:** Educational symptom reference only—always consult a licensed veterinarian promptly and never administer pain medication before consulting your vet.
- **Safety / Welfare Considerations:** Safety priority: do not force a colicking horse to walk endlessly to exhaustion, and keep people clear if the horse drops suddenly to roll.
- **Related Terminology:** `vital-signs-tpr`, `forage`, `laminitis`, `capillary-refill-time`
- **Related Skill Tree Skills:** `rider.husbandry.health_monitoring`, `rider.husbandry.first_aid`, `rider.husbandry.feeding`

#### 9. Lameness (`lameness` · Proposal — Not Approved)
- **Categories:** Health & Welfare, Biomechanics | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `unsoundness`
- **Concise Definition:** An abnormality or asymmetry in a horse's gait or stance caused by pain, mechanical restriction, or neurological impairment in one or more limbs, hooves, or the spine.
- **Educational Explanation:** Lameness can range from obvious reluctance to bear weight to subtle shortened strides, head bobbing at trot, choppy downhill steps, or repeated resistance to one canter lead. Because subtle lameness is frequently misread as behavioral stubbornness, monitoring resting posture, straight in-hand trot-ups, digital pulses, and movement symmetry protects horse welfare.
- **Practical Example:** If trot rhythm stays uneven after checking for a packed stone in the hoof, stop riding and schedule a lameness assessment.
- **Cross-Tradition Usage:** Clinical and biomechanical assessment belongs with a licensed veterinarian and farrier; riders/handlers learn early observation rather than self-diagnosing.
- **Safety / Welfare Considerations:** Never mask lameness with medication or harsher training aids to keep riding; rest and professional diagnosis prevent chronic injury.
- **Related Terminology:** `rhythm`, `asymmetry`, `laminitis`, `equine-pain-ethogram`
- **Related Skill Tree Skills:** `rider.husbandry.health_monitoring`, `rider.in_hand.leading`, `rider.in_hand.longeing`, `rider.theory.pain_discomfort_fatigue`, `rider.theory.gaits_footfalls`

#### 10. Choke (`choke` · Proposal — Not Approved)
- **Categories:** Health & Welfare, Husbandry | **Contextual Highlight:** `false` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `equine choke`, `esophageal choke`
- **Concise Definition:** An esophageal obstruction in which feed or foreign material lodges in the horse's throat/esophagus—not the windpipe—blocking normal swallowing.
- **Educational Explanation:** Unlike human airway choking, a horse with choke can usually still breathe, though feed-stained saliva draining from one or both nostrils, coughing, stretched neck, and repeated swallowing attempts signal urgency. Common triggers include bolting dry pellets without water, swollen unsoaked beet pulp, eating rapidly when stressed, or poor dental chewing. Remove all feed and water and contact a veterinarian promptly because secondary aspiration pneumonia is a serious complication.
- **Practical Example:** Soaking senior pellets into a soft mash helps prevent choke in horses with worn teeth or eager eating habits.
- **Cross-Tradition Usage:** Educational warning—requires prompt veterinary guidance; soak pelleted/beet-pulp mashes thoroughly when indicated and slow fast eaters.
- **Safety / Welfare Considerations:** Marked contextual=false to avoid false highlighting on non-medical English usage while remaining searchable and available via manual Define.
- **Related Terminology:** `forage`, `colic`, `vital-signs-tpr`
- **Related Skill Tree Skills:** `rider.husbandry.feeding`, `rider.husbandry.health_monitoring`, `rider.husbandry.first_aid`

#### 11. Thrush (`thrush` · Proposal — Not Approved)
- **Categories:** Health & Welfare, Husbandry | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `hoof thrush`
- **Concise Definition:** A common bacterial and fungal breakdown of tissue in the grooves alongside or center of the horse's hoof frog, marked by dark, foul-smelling discharge.
- **Educational Explanation:** Thrush thrives in damp, muddy, manure-soaked bedding or deep packed hoof crevices with little air circulation. Daily thorough hoof picking, dry footing, regular farrier trimming to open deep pockets, and targeted care recommended by a vet or farrier keep the frog healthy and firm. Advanced central-sulcus thrush can cause genuine heel soreness and reluctance during hoof handling.
- **Practical Example:** Clean the frog grooves daily while picking hooves so early thrush is caught before deep heel soreness develops.
- **Cross-Tradition Usage:** Routine stable and hoof hygiene concern; involve your farrier or veterinarian if bleeding, deep cleft pain, or persistent infection occurs.
- **Safety / Welfare Considerations:** Use cautious, mild farrier-recommended cleansers rather than caustic household chemicals that damage healthy hoof tissue.
- **Related Terminology:** `lameness`, `forage`
- **Related Skill Tree Skills:** `rider.husbandry.grooming`, `rider.husbandry.stable_care`, `horse.in_hand.hoof_handling`

#### 12. Wither Clearance (`wither-clearance` · Proposal — Not Approved)
- **Categories:** Tack & Equipment, Health & Welfare | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `gullet clearance`
- **Concise Definition:** The vertical and side-to-side space between a saddle gullet or blanket neckline and the horse's withers needed to protect delicate spinal tissues from pinching or pressure.
- **Educational Explanation:** With the rider seated in the saddle, adequate clearance lets the horse lift its back, move its shoulder blades freely, and carry weight without bruising the spinous processes or rubbing raw sores over the withers. Excessively tight blanket necks pull down hard on the withers when the horse lowers its head to graze—just as an overly narrow or wide saddle tree creates focal pressure.
- **Practical Example:** Always verify comfortable wither clearance once you are mounted, since saddle compression lowers the pommel under weight.
- **Cross-Tradition Usage:** Static clearance at halt is only a starting check; saddle pads, rider weight, and motion all reduce clearance under saddle.
- **Safety / Welfare Considerations:** Never stuff overly thick pads under a narrow saddle to fix low wither clearance—padding narrows space even more like wearing thick socks inside tight boots.
- **Related Terminology:** `withers`, `girth-cinch`, `forehand`
- **Related Skill Tree Skills:** `rider.husbandry.tack`, `rider.husbandry.blanketing`, `rider.theory.tack_fit_function`

#### 13. Blind Spot (`blind-spot` · Proposal — Not Approved)
- **Categories:** Safety, Behavior | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `blind spots`, `equine blind spots`
- **Concise Definition:** Zones directly in front of the horse's nose/forehead and directly behind the hindquarters/tail where equine eye placement prevents the horse from seeing clearly.
- **Educational Explanation:** Because a horse's eyes sit on the sides of its head, horses have broad nearly circular monocular vision with two key blind spots: a small triangle right beneath/in front of the muzzle and a narrow wedge straight behind the tail. Approaching toward the shoulder while speaking gently keeps you visible; darting silently into a blind spot easily startles a flight animal into defensive kicking or backing.
- **Practical Example:** Announce yourself softly toward the shoulder before walking around the hindquarters so you do not startle the horse in a blind spot.
- **Cross-Tradition Usage:** Universal safety basic taught before haltering, grooming, tying, or loading.
- **Safety / Welfare Considerations:** Pass either well out of kicking range behind the horse or very close with a calm hand maintaining steady contact along the hip.
- **Related Terminology:** `quick-release-knot`, `groundwork`
- **Related Skill Tree Skills:** `rider.husbandry.safe_handling`, `rider.theory.equine_body_language`, `rider.in_hand.obstacles_outings`

#### 14. Forage (`forage` · Proposal — Not Approved)
- **Categories:** Husbandry, Health & Welfare | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `roughage`
- **Concise Definition:** Fibrous plant feed—principally pasture grass, hay, or soaked hay cubes/pellets—that forms the healthy digestive foundation of a horse's diet.
- **Educational Explanation:** Horses evolved as continuous trickle grazers whose stomachs produce acid steadily and whose hindguts rely on microbial fiber fermentation. Prioritizing clean, mold-free forage offered frequently throughout day and night supports gut motility, reduces stomach ulcer and colic risk, satisfies natural chewing needs, and minimizes stable boredom.
- **Practical Example:** Inspect hay flakes daily for dust, mold, or toxic weeds before feeding because clean forage is the cornerstone of digestive health.
- **Cross-Tradition Usage:** Forage-first nutrition underpins English, Western, ranch, trail, endurance, and therapeutic stable management.
- **Safety / Welfare Considerations:** Sudden changes in hay batches or turning unacclimated horses onto lush high-sugar spring pasture raises colic and laminitis risk.
- **Related Terminology:** `colic`, `choke`, `laminitis`
- **Related Skill Tree Skills:** `rider.husbandry.feeding`, `rider.theory.ethical_training`, `rider.theory.pain_discomfort_fatigue`

### Priority B — Detailed Proposals (24 Entries)

#### 1. Engagement (`engagement` · Proposal — Not Approved)
- **Categories:** Biomechanics, Riding, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `hindquarter engagement`
- **Concise Definition:** Active flexion of the horse's hind-limb joints (hips, stifles, hocks) stepping forward under the body to carry more weight and lift the forehand.
- **Educational Explanation:** True engagement comes from increased hindquarter reach and joint bending rather than faster leg tempo or pulling the head backward with the reins. Transitions, gentle hill climbing, and exercises like shoulder-in build engagement progressively as conditioning develops.
- **Practical Example:** Well-timed transitions encourage hindquarter engagement so the horse steps up underneath itself instead of leaning onto the hands.
- **Cross-Tradition Usage:** Used across English, dressage, Western working/reining transitions, ranch work, and Working Equitation.
- **Safety / Welfare Considerations:** Demanding sustained engagement from an unconditioned or sore horse strains hocks, stifles, and lumbar muscles; build gradually in brief reps.
- **Related Terminology:** `hindquarters`, `impulsion`, `collection`, `self-carriage`
- **Related Skill Tree Skills:** `rider.theory.balance_weight`, `rider.mounted.canter`, `rider.mounted.shoulder_in`, `horse.mounted.transitions`

#### 2. Impulsion (`impulsion` · Proposal — Not Approved)
- **Categories:** Biomechanics, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** *(none)*
- **Concise Definition:** Controlled, elastic forward energy generated by engaged hindquarters moving cleanly through an unbraced, swinging back—distinct from hurried speed.
- **Educational Explanation:** A horse can rush frantically with zero impulsion (hollow back, flat legs, leaning forward) or carry tremendous quiet impulsion at a controlled tempo (elastic stride, alert responsiveness, light forehand). In training frameworks such as the Training Pyramid, impulsion builds upon rhythm, relaxation, and soft connection.
- **Practical Example:** Ask for balanced impulsion off a light leg aid without letting the trot quicken into rushing.
- **Cross-Tradition Usage:** Often misunderstood as going fast; applies to energetic, springy movement in any discipline rather than dressage alone.
- **Safety / Welfare Considerations:** Chasing speed against tight reins creates tension and joint concussion rather than genuine athletic impulsion.
- **Related Terminology:** `engagement`, `rhythm`, `collection`, `training-pyramid`
- **Related Skill Tree Skills:** `rider.theory.training_pyramid`, `rider.mounted.shoulder_in`, `rider.mounted.trot`

#### 3. Straightness (`straightness` · Proposal — Not Approved)
- **Categories:** Biomechanics, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** *(none)*
- **Concise Definition:** Alignment in which the horse's hind legs follow the track of its front legs cleanly on straight lines and curved arcs, using both sides evenly.
- **Educational Explanation:** Like humans, horses are naturally asymmetric and tend to bulge one shoulder or drift the hindquarters inward when unguided. Straightness on a circle means the spine mirrors the curve uniformly so inside and outside hind legs share carrying work fairly rather than letting the haunches fall out.
- **Practical Example:** Work on gradual straightness in walk and trot so the horse's hindquarters track behind the shoulders instead of drifting toward the rail.
- **Cross-Tradition Usage:** Key principle across vet trot-ups, groundwork, trail riding, and arena schooling. Everyday bare adjective "straight" is kept unhighlighted to avoid line-geometry noise.
- **Safety / Welfare Considerations:** Chronic crookedness overloads specific front tendons or hocks over time; symmetrical bilateral schooling supports long-term soundness.
- **Related Terminology:** `asymmetry`, `bend`, `engagement`, `training-pyramid`
- **Related Skill Tree Skills:** `rider.theory.bend_flexion_straightness`, `rider.theory.training_pyramid`, `rider.mounted.steering_navigation`, `rider.in_hand.ground_driving`

#### 4. Bend (`bend` · Proposal — Not Approved)
- **Categories:** Biomechanics, Riding | **Contextual Highlight:** `false` | **Editorial Review Needed:** No
- **Suggested Aliases:** `lateral bend`, `inward bend`, `true bend`
- **Concise Definition:** A smooth, slight lateral curve through the horse's entire spine—from poll to tail—matching the radius of a turn or lateral exercise without cranking just the neck.
- **Educational Explanation:** True bend relies on soft ribcage yielding around the rider's inside leg supported by the outside rein/leg boundaries. Over-bending only the neck sideways while the outside shoulder bulges out breaks alignment and unbalances the horse. Bare "bend" is kept non-contextual to avoid false hits on general phrases like "high-stress bends" or "bend safely".
- **Practical Example:** Encourage even bend around a generous circle instead of pulling the nose sharply inward while the outside shoulder drifts out.
- **Cross-Tradition Usage:** Gentle true bend matches circle size; tight turns demand slightly more bend, while straight lines use only subtle lateral alignment.
- **Safety / Welfare Considerations:** Never crank the neck sideways with inside rein force—an anatomical over-bend stresses cervical joints and blocks hind-leg forward step.
- **Related Terminology:** `flexion`, `straightness`, `asymmetry`, `shoulder-in`
- **Related Skill Tree Skills:** `rider.theory.bend_flexion_straightness`, `rider.mounted.steering_navigation`, `rider.mounted.shoulder_in`, `rider.mounted.travers`

#### 5. Flexion (`flexion` · Proposal — Not Approved)
- **Categories:** Biomechanics, Riding | **Contextual Highlight:** `false` | **Editorial Review Needed:** No
- **Suggested Aliases:** `poll flexion`, `lateral flexion`, `jaw flexion`
- **Concise Definition:** Soft, voluntary yielding at the horse's poll and jaw—laterally or longitudinally—without tilting the head, fixing the neck, or forcing posture.
- **Educational Explanation:** Unlike full-body bend along a curve, flexion refers specifically to joint softness at the poll/upper neck. Healthy longitudinal flexion lengthens the topline comfortably while allowing the horse's nose to stay slightly ahead of vertical; lateral flexion yields softly left or right for suppleness and safety checks. Bare "flexion" stays non-contextual to avoid matching anatomical "hock/knee flexion" clauses.
- **Practical Example:** Reward brief voluntary lateral flexion on a soft rein rather than holding sustained tension against a braced jaw.
- **Cross-Tradition Usage:** Both English soft contact and Western one-rein/give-to-pressure groundwork teach gentle voluntary flexion without force.
- **Safety / Welfare Considerations:** Forcing the chin tightly toward the chest (hyperflexion / rollkur) compromises airway comfort, vision, and welfare.
- **Related Terminology:** `bend`, `poll`, `self-carriage`, `hollowing`
- **Related Skill Tree Skills:** `rider.theory.bend_flexion_straightness`, `rider.theory.ethical_training`, `rider.mounted.leg_yield`

#### 6. Suppleness (`suppleness` · Proposal — Not Approved)
- **Categories:** Biomechanics, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `lateral suppleness`, `longitudinal suppleness`
- **Concise Definition:** Elastic, tension-free freedom of movement across the horse's muscles and joints—including both physical looseness and mental willingness.
- **Educational Explanation:** Longitudinal suppleness lets the back swing and the topline stretch forward and down (such as in free walk) as easily as stepping into shorter strides; lateral suppleness lets ribs and shoulders bend comfortably left and right. Without suppleness, exercises feel stiff, rushed, or mechanical.
- **Practical Example:** Alternating gentle serpentines with stretching free-walk breaks helps develop balanced suppleness before harder work.
- **Cross-Tradition Usage:** Matches the second rung of many training scales (relaxation/suppleness) and applies to warm-ups in every discipline.
- **Safety / Welfare Considerations:** Warm up gently—asking cold muscles for tight bends or collection risks strain and defensive bracing.
- **Related Terminology:** `hollowing`, `bend`, `rhythm`, `free-walk`
- **Related Skill Tree Skills:** `rider.theory.training_pyramid`, `rider.mounted.walk`, `horse.mounted.walk`, `rider.mounted.leg_yield`

#### 7. Asymmetry (`asymmetry` · Proposal — Not Approved)
- **Categories:** Biomechanics, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `natural crookedness`, `equine asymmetry`, `rider asymmetry`
- **Concise Definition:** Natural one-sided preference or uneven muscular tension in either horse or rider—making left and right turns, leads, or straight tracking feel noticeably different.
- **Educational Explanation:** Just as riders favor a dominant hand or drop onto one hip, every horse naturally stiffens more easily on one side and hollows on the other. Recognizing both rider asymmetry and equine crookedness helps pairs work evenly in both directions without punishing the horse's stiffer side.
- **Practical Example:** Notice whether consistent outside shoulder drift comes from equine asymmetry or the rider collapsing one waist.
- **Cross-Tradition Usage:** Explains why alternating trot diagonals, practicing longeing both ways, and checking rider hip symmetry matter.
- **Safety / Welfare Considerations:** Sudden new asymmetry or acute one-sided resistance warrants checking lameness, dental balance, or saddle flocking before blaming habit.
- **Related Terminology:** `straightness`, `bend`, `independent-seat`, `lameness`
- **Related Skill Tree Skills:** `rider.mounted.seat_balance`, `rider.theory.balance_weight`, `rider.theory.bend_flexion_straightness`, `rider.in_hand.longeing`

#### 8. Hollowing (`hollowing` · Proposal — Not Approved)
- **Categories:** Biomechanics, Behavior | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `hollow back`, `hollowed`
- **Concise Definition:** A posture in which the horse drops its back downward, raises or tightens the neck/head defensively, and trails the hindquarters out behind rather than stepping smoothly underneath.
- **Educational Explanation:** Hollowing often appears during poorly prepared transitions, abrupt pulling on the mouth, heavy rider bouncing, or pinching saddles. Rather than forcing the head down mechanically, resolving hollowness addresses rider balance, gentle preparation, emotional comfort, and saddle/physical fit.
- **Practical Example:** Smooth downward half-halt preparation keeps the horse stepping smoothly rather than hollowing its back and tossing its head.
- **Cross-Tradition Usage:** Important visual and kinesthetic clue across transitions, mounting, backing, and gait work.
- **Safety / Welfare Considerations:** Sustained hollow movement strains the spine and sacroiliac structures; investigate back soreness, saddle fit, or heavy hands early.
- **Related Terminology:** `self-carriage`, `suppleness`, `wither-clearance`, `equine-pain-ethogram`
- **Related Skill Tree Skills:** `rider.mounted.transitions`, `horse.mounted.transitions`, `horse.mounted.rein_back`, `rider.theory.balance_weight`

#### 9. Lateral Movement (`lateral-movement` · Proposal — Not Approved)
- **Categories:** Riding, Training, Biomechanics | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `lateral work`, `lateral movements`, `lateral yielding`, `lateral yield`
- **Concise Definition:** Any controlled movement—on foot or mounted—in which the horse steps sideways or simultaneously forward and sideways to build coordination, suppleness, and body control.
- **Educational Explanation:** In Horse and Rider's Companion, in-hand yielding builds foundational lateral communication before mounted skills progress from leg yield and sidepass through shoulder-in and travers. Different lateral movements vary spinal bend, track count (two, three, or four tracks), and carrying effort.
- **Practical Example:** Practicing gentle lateral work at walk helps improve shoulder responsiveness before asking for trot figures.
- **Cross-Tradition Usage:** Cross-discipline umbrella covering both practical ranch/trail gating (sidepass) and gymnastic schooling (leg yield, shoulder-in, travers).
- **Safety / Welfare Considerations:** Keep early lateral segments short on level, non-slip footing so crossing hooves stay relaxed and balanced.
- **Related Terminology:** `leg-yield`, `sidepass`, `shoulder-in`, `travers`
- **Related Skill Tree Skills:** `rider.mounted.leg_yield`, `rider.mounted.shoulder_in`, `rider.mounted.travers`, `rider.in_hand.sidepass_in_hand`

#### 10. Leg Yield (`leg-yield` · Proposal — Not Approved)
- **Categories:** Riding, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `leg-yield`, `leg yields`, `leg-yields`
- **Concise Definition:** A progressive lateral movement in which the horse travels forward and sideways simultaneously along a diagonal line with a straight body or slight flexion away from the direction of movement.
- **Educational Explanation:** Grounded in walk before advancing to trot, leg yield teaches the horse to move calmly away from light inside leg cues toward an elastic outside rein without racing through the outside shoulder or trailing the haunches behind.
- **Practical Example:** Guide a relaxed walk leg yield away from the quarter line toward the rail while preserving even rhythm.
- **Cross-Tradition Usage:** Foundational gymanstic movement bridging stationary pivots into bend-demanding shoulder-in.
- **Safety / Welfare Considerations:** Avoid hauling backward on the reins while squeezing sideways; keep angle shallow enough that forward rhythm never stalls.
- **Related Terminology:** `lateral-movement`, `turn-on-the-forehand`, `shoulder-in`, `straightness`
- **Related Skill Tree Skills:** `rider.mounted.leg_yield`, `horse.mounted.leg_yield`, `rider.theory.bend_flexion_straightness`

#### 11. Sidepass (`sidepass` · Proposal — Not Approved)
- **Categories:** Riding, Handling | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `side-pass`, `side pass`, `sidepasses`
- **Concise Definition:** Stepping directly sideways with minimal forward or backward travel as front and hind legs cross evenly along a parallel track.
- **Educational Explanation:** Used in open space, alongside fences/mounting blocks, at trail gates, or optionally over a stable ground rail, a true sidepass balances shoulder and hip guidance so neither end rushes ahead or lags behind.
- **Practical Example:** Line up parallel beside the mounting block or trail gate and ask for three calm steps of sidepass.
- **Cross-Tradition Usage:** Core practical maneuver in Western, ranch, trail, Working Equitation, and ground manners.
- **Safety / Welfare Considerations:** Do not force tight sideways crossing over an optional ground pole before the horse clearly understands sideways cues in open space.
- **Related Terminology:** `lateral-movement`, `turn-on-the-forehand`, `leg-yield`
- **Related Skill Tree Skills:** `rider.mounted.sidepass`, `horse.mounted.sidepass`, `rider.in_hand.sidepass_in_hand`, `horse.in_hand.sidepass_in_hand`

#### 12. Simple Lead Change (`simple-lead-change` · Proposal — Not Approved)
- **Categories:** Gaits, Riding | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `simple lead changes`, `simple change`, `simple changes`
- **Concise Definition:** A deliberate change of canter lead accomplished calmly through an intermediate downward transition to walk or trot, rebalancing briefly, and departing onto the new lead.
- **Educational Explanation:** A smooth simple lead change gives intermediate riders and developing horses a clear, low-stress way to switch leads across serpentines, figure-eights, or trail turns without rushing into crooked flying swaps.
- **Practical Example:** Plan a balanced simple lead change through calm trot before riding the second loop of a figure-eight.
- **Cross-Tradition Usage:** In general riding and trail patterns, transitions pass through walk or trot; specific competition rules may define exact walk step limits.
- **Safety / Welfare Considerations:** Use clean downward transitions to rebalance rather than popping the horse awkwardly off the forehand into the opposite lead.
- **Related Terminology:** `canter-lead`, `flying-lead-change`, `counter-canter`, `transitions`
- **Related Skill Tree Skills:** `rider.mounted.canter`, `horse.mounted.canter`, `rider.mounted.steering_navigation`

#### 13. Cross-Canter (`cross-canter` · Proposal — Not Approved)
- **Categories:** Gaits, Biomechanics | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `cross canter`, `cross-cantering`, `disunited canter`, `cross-firing`
- **Concise Definition:** An unbalanced four-beat or jarring canter stride in which the horse leads with one side in front and the opposite side behind.
- **Educational Explanation:** Normally a horse's inside hind and inside fore share the same lead side. When cross-cantering (disunited canter), a horse may take left lead in front while staying on right lead behind, creating a rough rolling feel in the saddle. Transition calmly back to trot or walk to rebalance rather than pushing onward.
- **Practical Example:** If your horse lands in a rough cross-canter after a turn, smoothly bring it back to trot, check straightness, and ask cleanly again.
- **Cross-Tradition Usage:** Equally useful indicator in English, Western lope, trail, and breeding/young-horse conditioning.
- **Safety / Welfare Considerations:** Persistent cross-cantering or swapping behind alone often signals hock, stifle, sacroiliac, or saddle discomfort—investigate before repeating drills.
- **Related Terminology:** `canter-lead`, `canter`, `flying-lead-change`, `lameness`
- **Related Skill Tree Skills:** `rider.mounted.canter`, `horse.mounted.canter`, `rider.mounted.counter_canter`, `rider.theory.gaits_footfalls`

#### 14. Diagonal Pairs (`diagonal-pairs` · Proposal — Not Approved)
- **Categories:** Gaits, Biomechanics | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `diagonal pair`, `two-beat diagonal`, `diagonal two-beat`
- **Concise Definition:** Coordinated footfalls in which opposite-side front and hind legs (left front with right hind, alternating with right front and left hind) lift and land together—the mechanical basis of both trot and clean rein back.
- **Educational Explanation:** Recognizing diagonal pairs explains why trot and quality rein-back share a steady two-beat feel, whereas lateral pacing (same-side front and hind moving together) indicates stiffness, restricted walk neck freedom, or breed gait characteristics.
- **Practical Example:** In a clean rein back, the horse steps backward calmly in steady diagonal pairs rather than dragging toes or pacing laterally.
- **Cross-Tradition Usage:** Complements Trot Diagonal (which specifically covers rider posting rhythm) by explaining limb biomechanics across gaits.
- **Safety / Welfare Considerations:** Loss of clean diagonal pairs into lateral pacing at walk/rein-back often signals rider hand tension or physical stiffness.
- **Related Terminology:** `trot-diagonal`, `trot`, `rein-back`, `rhythm`
- **Related Skill Tree Skills:** `horse.mounted.rein_back`, `rider.theory.gaits_footfalls`, `horse.mounted.trot`

#### 15. Ground Driving (`ground-driving` · Proposal — Not Approved)
- **Categories:** Handling, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `long-lining`, `long reining`, `two-line ground work`
- **Concise Definition:** Guiding a horse from behind or diagonally behind-and-to-the-side using two long lines attached to a halter, cavesson, or bridle without a rider's weight.
- **Educational Explanation:** Ground driving teaches forward confidence, bilateral steering, straightness, transitions, and preparedness for riding or harness work. Handlers keep a safe offset outside direct kick range, manage both lines without wrapping fingers, and build comfortable line touch along the horse's barrel and hocks gradually.
- **Practical Example:** Ground driving around calm arena turns helps confirm steering clarity before mounting a young horse.
- **Cross-Tradition Usage:** Practiced across driving prep, young-horse starting, Classical In-Hand, and rehabilitative conditioning.
- **Regional Usage:** Ground driving and long-lining are common in North America; long reining and double lunging appear widely in Europe and the UK.
- **Safety / Welfare Considerations:** Never tie or clip two long lines rigidly when starting; verify a horse calmly accepts lines touching its hips and hocks with a skilled helper first.
- **Related Terminology:** `groundwork`, `longeing`, `surcingle`, `aids`
- **Related Skill Tree Skills:** `rider.in_hand.ground_driving`, `horse.in_hand.ground_driving`, `rider.theory.training_equipment`

#### 16. Training Pyramid (`training-pyramid` · Proposal — Not Approved)
- **Categories:** Training, Theory | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `Training Scale`, `Skala der Ausbildung`
- **Concise Definition:** An interdependent six-element framework—rhythm, relaxation (suppleness), connection (contact), impulsion, straightness, and collection—used to evaluate and guide progressive equine development.
- **Educational Explanation:** Originally organized in European classical/cavalry manuals, the Training Pyramid serves best as a flexible, cyclical reference rather than a rigid one-way staircase: riders regularly return to relaxation or rhythm whenever difficulty rises. It is one helpful model alongside behavioral learning theory and Western/ranch/gaited horsemanship principles—never the sole legitimate training philosophy.
- **Practical Example:** When straightness falls apart on a circle, look back down the Training Pyramid to check whether tension disrupted rhythm and relaxation first.
- **Cross-Tradition Usage:** Framed inclusively without dogma so trail, Western, ranch, gaited, and classical equestrians can apply its core balance and relaxation ideas.
- **Safety / Welfare Considerations:** Never use the pyramid to justify forced headsets or pushing collection before emotional calm and physical conditioning exist.
- **Related Terminology:** `rhythm`, `suppleness`, `rein-contact`, `impulsion`, `straightness`, `collection`
- **Related Skill Tree Skills:** `rider.theory.training_pyramid`, `rider.theory.balance_weight`, `rider.theory.progressive_conditioning`

#### 17. Operant Conditioning (`operant-conditioning` · Proposal — Not Approved)
- **Categories:** Learning Theory, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** *(none)*
- **Concise Definition:** Learning in which a horse changes how often it offers a voluntary behavior based on the immediate consequences—reinforcement or punishment—that follow.
- **Educational Explanation:** Every time a handler removes pressure (R−) or delivers a food/scratch reward (R+) right after a step, operant conditioning strengthens that step. Conversely, adding startling punishment (P+) or taking away something desirable (P−) suppresses behavior—carrying higher risk of fear or confusion when overused.
- **Practical Example:** Through clean operant conditioning, releasing halter tension on the very first calm step sideways builds rapid lightness.
- **Cross-Tradition Usage:** Scientific foundation explaining how timing and release create calm, willing communication across every discipline.
- **Safety / Welfare Considerations:** Relying primarily on punishment raises cortisol, suppresses communication signals, and undermines trust.
- **Related Terminology:** `reinforcement`, `negative-reinforcement`, `positive-reinforcement`, `classical-conditioning`
- **Related Skill Tree Skills:** `rider.theory.how_horses_learn`, `rider.theory.timing_reinforcement`

#### 18. Classical Conditioning (`classical-conditioning` · Proposal — Not Approved)
- **Categories:** Learning Theory | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `associative learning`
- **Concise Definition:** Learning through association in which a previously neutral cue or place (like a word, clicker sound, or calm corner) becomes linked with an expected outcome or emotional state.
- **Educational Explanation:** Horses form classical associations continuously—both helpful (a verbal cue predicting walk, or the rattle of a treat bucket signaling calm) and fearful (a sharp voice cue or cramped trailer triggering brace if repeatedly paired with stress). Pairing light signals ahead of tactile cues lets trainers fade physical pressure gently.
- **Practical Example:** Wait a split second after giving a soft voice cue before adding light rope feel so classical conditioning transfers response to the lighter signal.
- **Cross-Tradition Usage:** Pairs directly with operant timing across positive and negative reinforcement approaches.
- **Safety / Welfare Considerations:** Be mindful of unintended fearful associations (poisoned cues) when harsh pressure happens right alongside a normal halter or mounting cue.
- **Related Terminology:** `operant-conditioning`, `desensitization`, `habituation`, `reinforcement`
- **Related Skill Tree Skills:** `rider.theory.how_horses_learn`, `rider.theory.timing_reinforcement`

#### 19. Habituation (`habituation` · Proposal — Not Approved)
- **Categories:** Learning Theory, Behavior | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** *(none)*
- **Concise Definition:** A natural decrease in a horse's startle or attention response to a harmless repeated sound, sight, or touch once the horse learns nothing bad happens.
- **Educational Explanation:** Unlike intentional therapeutic counter-conditioning, everyday habituation occurs steadily when a horse encounters rustling leaves, fluttering tarps, clippers, or barn activity at a tolerable intensity where curiosity can replace alarm.
- **Practical Example:** Letting a green horse pause to sniff a stationary tarp before stepping over allows natural habituation instead of defensive leaping.
- **Cross-Tradition Usage:** Key distinction from flooding: true habituation lets the horse process below panic level rather than trapping it until it shuts down.
- **Safety / Welfare Considerations:** Repeating a loud frightening stimulus too intensely causes sensitization (growing fear) rather than calm habituation.
- **Related Terminology:** `desensitization`, `flooding`, `arousal-threshold`, `learned-helplessness`
- **Related Skill Tree Skills:** `rider.theory.how_horses_learn`, `horse.in_hand.obstacles_outings`, `rider.in_hand.obstacles_outings`

#### 20. Desensitization (`desensitization` · Proposal — Not Approved)
- **Categories:** Learning Theory, Behavior | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** *(none)*
- **Concise Definition:** Systematic, gradual exposure to an unfamiliar object, sound, or touch at low intensity—staying below the horse's fear threshold—so confidence builds step by step.
- **Educational Explanation:** Effective systematic desensitization pairs tiny manageable steps (such as seeing clippers turned on across the aisle before touching a shoulder) with prompt retreat of stimulus or pleasant reward as soon as the horse relaxes, progressing only while the horse stays curious and calm.
- **Practical Example:** Use patient desensitization with long lines sliding lightly across a green horse's legs before solo ground driving.
- **Cross-Tradition Usage:** Essential across trailer loading, spray bottles, medical prep, ground-driving lines, and obstacle schooling.
- **Safety / Welfare Considerations:** Do not trap a frightened horse in a small stall with scary objects—forcing exposure above threshold is flooding, not healthy desensitization.
- **Related Terminology:** `habituation`, `counter-conditioning`, `arousal-threshold`, `flooding`
- **Related Skill Tree Skills:** `rider.theory.how_horses_learn`, `horse.in_hand.ground_driving`, `horse.in_hand.trailer_loading`, `horse.mounted.object_handling`

#### 21. Arousal Threshold (`arousal-threshold` · Proposal — Not Approved)
- **Categories:** Behavior, Learning Theory, Safety | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `arousal thresholds`, `sub-threshold`
- **Concise Definition:** The stress or stimulation point past which a horse's emotional alarm overtakes calm attention, impairing learning and raising flight, freeze, or defensive reactions.
- **Educational Explanation:** Working below threshold—when the horse still blinks, breathes slowly, chews or looks softly, and eats/responds cleanly—keeps training safe and memorable. Once a horse crosses its arousal threshold (high rigid head, wide eye, held breath, prancing, or shutdown), handlers pause, increase distance, or simplify rather than pushing harder.
- **Practical Example:** Step back a few yards when passing noisy equipment so the horse stays under its arousal threshold and can think clearly.
- **Cross-Tradition Usage:** Bare "threshold" stays unhighlighted to avoid general vocabulary noise; "arousal threshold" and "sub-threshold" highlight accurately.
- **Safety / Welfare Considerations:** Ignoring early micro-signs near threshold invites explosive reactions or learned helplessness.
- **Related Terminology:** `trigger-stacking`, `desensitization`, `habituation`, `learned-helplessness`
- **Related Skill Tree Skills:** `rider.theory.stress_fear_confidence`, `rider.theory.how_horses_learn`, `rider.in_hand.obstacles_outings`, `horse.in_hand.trailer_loading`

#### 22. Trigger Stacking (`trigger-stacking` · Proposal — Not Approved)
- **Categories:** Behavior, Safety | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** *(none)*
- **Concise Definition:** The buildup of emotional stress when multiple mild worries occur close together without recovery time, eventually pushing a usually calm horse past its coping threshold.
- **Educational Explanation:** A horse might calmly tolerate a breezy day alone, a busy wash bay alone, and an unfamiliar arena alone—yet bolt at a flapping jacket after experiencing all three in one hour. Recognizing trigger stacking explains sudden unexpected spooks and helps riders adjust plans compassionately.
- **Practical Example:** Factor in wind, separation from herd mates, and clinic commotion as potential trigger stacking before asking a green horse for difficult tasks.
- **Cross-Tradition Usage:** Practical safety lens across trail outings, clinic environments, vet days, and mounted emergency prevention.
- **Safety / Welfare Considerations:** Building recovery pauses and ending on small positive steps prevents cumulative stress overload.
- **Related Terminology:** `arousal-threshold`, `learned-helplessness`, `desensitization`
- **Related Skill Tree Skills:** `rider.theory.stress_fear_confidence`, `rider.mounted.emergency_control`, `horse.in_hand.standing_quietly`

#### 23. Laminitis (`laminitis` · Proposal — Not Approved)
- **Categories:** Health & Welfare, Husbandry | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `founder`, `laminitic`
- **Concise Definition:** Painful inflammation of the sensitive laminae bonding the hoof wall to the coffin bone inside the horse's foot—a medical emergency that can cause permanent structural rotation if untreated.
- **Educational Explanation:** Early clues include bounding digital pulses, warm hooves, shifted weight rocking onto the hindquarters, choppy reluctant turns on hard ground, and metabolic sensitivity. Triggers include sudden excess sugars/starches (lush spring pasture or grain overload), endocrine illness, systemic infection, or severe weight-bearing overload on a limb.
- **Practical Example:** Restrict grazing and monitor digital pulses closely on horses prone to metabolic syndrome or spring-grass laminitis.
- **Cross-Tradition Usage:** Founder commonly refers to chronic mechanical sinking/rotation following acute laminitis; requires immediate veterinary and farrier care.
- **Safety / Welfare Considerations:** Never force a laminitic horse to exercise—keep on deep supportive bedding and call a veterinarian immediately.
- **Related Terminology:** `digital-pulse`, `lameness`, `forage`, `colic`
- **Related Skill Tree Skills:** `rider.husbandry.feeding`, `rider.husbandry.health_monitoring`

#### 24. Digital Pulse (`digital-pulse` · Proposal — Not Approved)
- **Categories:** Health & Welfare, Husbandry | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `digital pulses`
- **Concise Definition:** The arterial pulse felt along the back sides of the horse's fetlock and pastern supplying blood to the hoof, which grows noticeably stronger ("bounding") during hoof inflammation or abscess.
- **Educational Explanation:** Knowing what a faint, normal resting digital pulse feels like on your horse's healthy legs lets you recognize abnormal pounding warmth immediately when checking soreness, laminitis risk, stone bruises, or subsolar abscesses.
- **Practical Example:** Palpate the digital pulse at both front fetlocks if a horse suddenly steps gingerly over gravel.
- **Cross-Tradition Usage:** Standard part of intermediate Barn/Rider Health Monitoring alongside temperature, pulse, respiration, and capillary refill.
- **Safety / Welfare Considerations:** Strong bounding digital pulses across multiple feet warrant urgent veterinary attention to rule out acute laminitis.
- **Related Terminology:** `vital-signs-tpr`, `laminitis`, `lameness`
- **Related Skill Tree Skills:** `rider.husbandry.health_monitoring`, `rider.husbandry.grooming`

### Priority C — Detailed Proposals (18 Entries)

#### 1. Flying Lead Change (`flying-lead-change` · Proposal — Not Approved)
- **Categories:** Gaits, Riding | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `flying lead changes`, `flying change`, `flying changes`
- **Concise Definition:** An advanced maneuver in which a cantering horse switches its leading front and hind legs cleanly together during the moment of suspension without dropping into trot or walk.
- **Educational Explanation:** True flying changes require straight alignment, balanced collection/impulsion, and accurate stride-phase timing from the rider so front and hind legs swap simultaneously rather than leaving the hind legs behind (cross-cantering). They are an optional advanced specialization rather than a requirement for general horsemanship.
- **Practical Example:** Establish straight, balanced simple changes and counter-canter before introducing an isolated flying lead change across a diagonal.
- **Cross-Tradition Usage:** Used in dressage, show jumping/equitation, Working Equitation, and Western reining/ranch riding patterns.
- **Safety / Welfare Considerations:** Demanding repeated flying changes before strength and balance exist creates crooked rushing, sour tension, and hind-end strain.
- **Related Terminology:** `canter-lead`, `simple-lead-change`, `counter-canter`, `cross-canter`
- **Related Skill Tree Skills:** `rider.mounted.flying_lead_changes`, `horse.mounted.flying_lead_changes`, `rider.mounted.canter`

#### 2. Travers (`travers` · Proposal — Not Approved)
- **Categories:** Riding, Biomechanics | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `haunches-in`
- **Concise Definition:** An advanced lateral movement at walk or trot in which the horse bends slightly in the direction of travel, keeping the forehand along the track while carrying the hindquarters inward.
- **Educational Explanation:** Unlike shoulder-in (where bend faces away from travel), travers asks the horse to bend lightly toward the inside while moving along the rail on three or four tracks, increasing weight-bearing flexion on the inside hind leg. Because carrying load rises noticeably, work stays brief with frequent straight forward breaks.
- **Practical Example:** Use subtle outside-leg timing and a quiet inside seat bone to keep the forehand on the track during travers.
- **Cross-Tradition Usage:** Classical/English lateral gymnastic exercise directly preceding half-pass.
- **Safety / Welfare Considerations:** Never pull the head hard inward or crank the haunches over steeply; monitor hock and lumbosacral comfort carefully.
- **Related Terminology:** `shoulder-in`, `lateral-movement`, `collection`, `bend`
- **Related Skill Tree Skills:** `rider.mounted.travers`, `horse.mounted.travers`

#### 3. Shoulder-Fore (`shoulder-fore` · Proposal — Not Approved)
- **Categories:** Riding, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `shoulder fore`
- **Concise Definition:** A mild, preparatory version of shoulder-in bringing the horse's shoulders slightly off the track (far shallower than full three-track shoulder-in) to align the inside hind leg toward the center of mass.
- **Educational Explanation:** Shoulder-fore serves as an accessible intermediate stepping stone at walk or trot to straighten crooked horses, free the outside shoulder, and build strength gradually without over-taxing hocks or neck.
- **Practical Example:** Introduce a few strides of shallow shoulder-fore at walk before asking for full shoulder-in along the rail.
- **Cross-Tradition Usage:** Common across classical dressage, sport-horse schooling, and straightness training.
- **Safety / Welfare Considerations:** Keeping angle subtle protects young or stiff horses from dropping awkwardly onto the inside shoulder.
- **Related Terminology:** `shoulder-in`, `straightness`, `bend`, `lateral-movement`
- **Related Skill Tree Skills:** `rider.mounted.shoulder_in`, `horse.mounted.shoulder_in`

#### 4. Ambling Gait (`ambling-gait` · Proposal — Not Approved)
- **Categories:** Gaits | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `ambling gaits`, `ambling`, `running walk`, `tölt`
- **Concise Definition:** A smooth, symmetrical four-beat intermediate gait naturally performed by many gaited horse breeds in which footfalls strike independently with minimal vertical bounce.
- **Educational Explanation:** Instead of a two-beat diagonal trot, breeds such as Tennessee Walking Horses, Icelandic Horses (tölt), Paso Finos, Rocky Mountain Horses, and Standardbreds perform variations of rapid four-beat ambling gaits (running walk, rack, fox trot, etc.). Recognizing ambling footfalls ensures Skill Tree gait and rider seat standards treat gaited traditions inclusively while noticing when tension turns a pure walk into unintended stiff pacing.
- **Practical Example:** Study four-beat ambling gait footfalls alongside standard walk, trot, and canter so breed differences are evaluated accurately.
- **Cross-Tradition Usage:** Regional breed names vary widely; pace-like hard two-beat lateral stiffness in non-pacing breeds often signals tension or rider hand restriction.
- **Safety / Welfare Considerations:** Distinguish natural genetic smoothness from artificial mechanical shoeing/action devices or tense, hollow-backed pacing under tight reins.
- **Related Terminology:** `rhythm`, `trot`, `free-walk`, `independent-seat`
- **Related Skill Tree Skills:** `rider.theory.gaits_footfalls`, `rider.mounted.walk`, `rider.mounted.trot`

#### 5. Free Walk (`free-walk` · Proposal — Not Approved)
- **Categories:** Gaits, Riding | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `stretchy walk`
- **Concise Definition:** A relaxed, ground-covering four-beat walk on a long or loose rein in which the horse stretches its head and neck willingly forward and down while swinging evenly over its back.
- **Educational Explanation:** Riding between an active working walk and a genuine free walk tests back suppleness, mental relaxation, and whether the horse keeps clear four-beat rhythm without constant rein support.
- **Practical Example:** Allow the reins to lengthen smoothly so the horse can stretch forward and down into a swinging free walk.
- **Cross-Tradition Usage:** Valued in English dressage tests, warm-ups, trail cool-downs, and Western relaxation walks alike.
- **Safety / Welfare Considerations:** Avoid holding rigid elbows or nagging legs during free walk, which blocks neck nod and causes tight hurrying.
- **Related Terminology:** `suppleness`, `self-carriage`, `rhythm`, `rein-contact`
- **Related Skill Tree Skills:** `rider.mounted.walk`, `horse.mounted.walk`

#### 6. Cadence (`cadence` · Proposal — Not Approved)
- **Categories:** Gaits, Biomechanics | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** *(none)*
- **Concise Definition:** The marked rhythm, springiness, and expressive balance of a horse's strides produced by clear impulsion and self-carriage.
- **Educational Explanation:** While basic rhythm simply means regular beat spacing, cadence adds elastic lift and airiness—most visible in developed trot and canter work without rushing or stiffness.
- **Practical Example:** Preserve pure cadence across within-gait trot lengthenings rather than letting strides flatten into rushing.
- **Cross-Tradition Usage:** Common in upper-level flatwork and biomechanics; should never be confused with hurried high knee action from tension.
- **Safety / Welfare Considerations:** True cadence requires relaxation and conditioning; forcing animated steps through heavy bits/spurs creates joint stress.
- **Related Terminology:** `rhythm`, `impulsion`, `tempo`, `self-carriage`
- **Related Skill Tree Skills:** `horse.mounted.trot`, `horse.mounted.transitions`, `horse.mounted.shoulder_in`

#### 7. Tempo (`tempo` · Proposal — Not Approved)
- **Categories:** Gaits, Biomechanics | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** *(none)*
- **Concise Definition:** The rate or speed of a horse's footfall beats—how quickly steps repeat per minute—distinct from stride length or rhythm regularity.
- **Educational Explanation:** A horse can rush a quick tempo with short choppy steps or keep a calm, consistent tempo while lengthening or shortening stride length. Controlling tempo separates hurried running from authentic athletic adjustability.
- **Practical Example:** Keep a steady trot tempo into the corner instead of accelerating to lengthen stride.
- **Cross-Tradition Usage:** Helpful across all gaits, ground driving, longeing, and trot diagonal symmetry.
- **Safety / Welfare Considerations:** Soreness or rider anxiety often shows up first as sudden speeding tempo before an obvious gait break.
- **Related Terminology:** `rhythm`, `cadence`, `transitions`
- **Related Skill Tree Skills:** `rider.mounted.trot`, `horse.mounted.trot`, `rider.mounted.transitions`, `rider.theory.gaits_footfalls`

#### 8. Counter-Conditioning (`counter-conditioning` · Proposal — Not Approved)
- **Categories:** Learning Theory, Training | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `counter conditioning`
- **Concise Definition:** Deliberately changing a horse's learned emotional response to a worrying stimulus from fear or tension to calm anticipation by repeatedly pairing low-level exposure with something positive (such as food, scratching, or gentle rest).
- **Educational Explanation:** Counter-conditioning differs from simple habituation or desensitization by actively building a pleasant association (e.g., an oral syringe or trailer step predicts a tasty reward) while staying calmly below arousal threshold.
- **Practical Example:** Combine sub-threshold exposure with pleasant scratches or small food rewards as counter-conditioning for a horse worried about clippers.
- **Cross-Tradition Usage:** Used widely in veterinary prep, cooperative care, head-shyness rehabilitation, and trailer confidence.
- **Safety / Welfare Considerations:** If the horse refuses a reward because worry is too high, move farther away and lower intensity first.
- **Related Terminology:** `desensitization`, `classical-conditioning`, `positive-reinforcement`, `arousal-threshold`
- **Related Skill Tree Skills:** `rider.theory.how_horses_learn`, `horse.in_hand.vet_handling`

#### 9. Flooding (`flooding` · Proposal — Not Approved)
- **Categories:** Learning Theory, Health & Welfare, Behavior | **Contextual Highlight:** `false` | **Editorial Review Needed:** No
- **Suggested Aliases:** *(none)*
- **Concise Definition:** Forcing continuous, inescapable exposure to a frightening stimulus at high intensity—preventing flight or relief—until the horse stops reacting out of exhaustion or shutdown.
- **Educational Explanation:** Sometimes mistaken for "desensitization," flooding traps the horse past its arousal threshold (such as tying tightly while waving tarps relentlessly). Rather than true trust, flooding commonly creates high cortisol spikes, traumatic sensitization, defensive explosions, or learned helplessness. Marked contextual=false so weather/water discussions never false-highlight.
- **Practical Example:** Avoid flooding a panicked horse in a tight stall; step back below threshold where genuine curiosity and calm choices can develop.
- **Cross-Tradition Usage:** Included strictly as a welfare contrast against humane sub-threshold desensitization.
- **Safety / Welfare Considerations:** High risk of severe injury to both horse and handler plus lasting behavioral trauma.
- **Related Terminology:** `learned-helplessness`, `desensitization`, `habituation`, `arousal-threshold`
- **Related Skill Tree Skills:** `rider.theory.how_horses_learn`, `horse.in_hand.obstacles_outings`

#### 10. Five Domains Model (`five-domains-model` · Proposal — Not Approved)
- **Categories:** Health & Welfare, Theory | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `Five Domains`
- **Concise Definition:** A contemporary animal-welfare framework evaluating Nutrition, Physical Environment, Health, and Behavioral Interactions—and how those four physical/social areas shape the horse's fifth domain: Mental State.
- **Educational Explanation:** Developed by animal welfare scientist David Mellor and colleagues, the Five Domains moves welfare beyond merely preventing starvation or overt cruelty to promoting positive mental experiences (comfort, foraging choice, companionship, confidence, and agency) alongside pain and stress mitigation.
- **Practical Example:** Evaluate stall confinement, turnout buddies, and tight nosebands through the Five Domains Model to spot hidden welfare stress.
- **Cross-Tradition Usage:** Academic/scientific welfare standard applied to barn management, training equipment audits, and ethical training decisions.
- **Safety / Welfare Considerations:** Supports evidence-based evaluation of housing, nutrition, gear, and training stress.
- **Related Terminology:** `forage`, `learned-helplessness`, `equine-pain-ethogram`
- **Related Skill Tree Skills:** `rider.theory.ethical_training`, `rider.husbandry.stable_care`

#### 11. Equine Pain Ethogram (`equine-pain-ethogram` · Proposal — Not Approved)
- **Categories:** Health & Welfare, Behavior | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `pain ethogram`, `ridden horse pain ethogram`
- **Concise Definition:** A structured, research-backed catalog of subtle facial, postural, and behavioral cues—such as fixed stare, pinned ears, exposed sclera, mouth-opening, tail swishing, or crooked gait changes—used to recognize musculoskeletal pain in horses.
- **Educational Explanation:** Research led by Sue Dyson (including the 24-behavior Ridden Horse Pain Ethogram) showed that clusters of these subtle behaviors correlate reliably with underlying orthopedic or saddle pain rather than naughtiness. Recognizing clustered signs prompts riders to stop, check tack fit, and involve a veterinarian.
- **Practical Example:** Use principles from the Equine Pain Ethogram—like tense eyes, open mouth, and tail swishing—as early warning signs to check comfort first.
- **Cross-Tradition Usage:** Practical observation tool connecting daily handling/riding behavior to early pain screening rather than formal clinical diagnosis.
- **Safety / Welfare Considerations:** Do not label pain-ethogram clusters as attitude problems or try to restrain mouth opening with tighter nosebands.
- **Related Terminology:** `lameness`, `hollowing`, `five-domains-model`, `asymmetry`
- **Related Skill Tree Skills:** `rider.theory.pain_discomfort_fatigue`, `rider.theory.equine_body_language`, `rider.husbandry.health_monitoring`

#### 12. Capillary Refill Time (`capillary-refill-time` · Proposal — Not Approved)
- **Categories:** Health & Welfare, Husbandry | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `capillary refill`, `CRT`
- **Concise Definition:** A simple circulation check performed by pressing gently on the horse's pink upper gum until it blanches white, then counting how quickly pink color returns (normally 1 to 2 seconds).
- **Educational Explanation:** Assessed alongside gum color/moistness and heart rate in routine health monitoring, delayed capillary refill (over 2 seconds) or dark red, pale, muddy, or bluish gums can indicate dehydration, shock, or systemic illness requiring immediate veterinary evaluation.
- **Practical Example:** Check gum moistness and capillary refill time along with TPR when monitoring a horse suspected of colic or heat stress.
- **Cross-Tradition Usage:** Part of intermediate vital-sign monitoring; always handle the mouth gently from a safe shoulder angle.
- **Safety / Welfare Considerations:** Educational reference only; abnormal CRT or discolored gums warrant urgent veterinary contact.
- **Related Terminology:** `vital-signs-tpr`, `colic`, `digital-pulse`
- **Related Skill Tree Skills:** `rider.husbandry.health_monitoring`, `horse.in_hand.vet_handling`

#### 13. Synovial Structure (`synovial-structure` · Proposal — Not Approved)
- **Categories:** Anatomy, Health & Welfare | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `synovial structures`, `tendon sheath`, `tendon sheaths`
- **Concise Definition:** Fluid-filled protective capsules—including joint capsules, tendon sheaths, and bursae—that lubricate moving equine joints and lower-limb tendons.
- **Educational Explanation:** Even a tiny puncture wound near a fetlock, hock, knee, or digital flexor tendon sheath can introduce bacteria directly into a synovial structure, causing life-threatening septic arthritis or tenosynovitis. Recognizing high-risk anatomical zones stops handlers from scrubbing deep punctures or waiting too long to call a veterinarian.
- **Practical Example:** A small puncture right over a fetlock tendon sheath may involve a synovial structure and needs urgent veterinary evaluation even if bleeding is minimal.
- **Cross-Tradition Usage:** Critical anatomical triage knowledge in intermediate equine First Aid.
- **Safety / Welfare Considerations:** Never inject unapproved salves or flush deeply into suspected synovial punctures before veterinary examination.
- **Related Terminology:** `lameness`, `colic`, `capillary-refill-time`
- **Related Skill Tree Skills:** `rider.husbandry.first_aid`, `rider.husbandry.leg_wraps`

#### 14. Cavesson (`cavesson` · Proposal — Not Approved)
- **Categories:** Tack & Equipment, Handling | **Contextual Highlight:** `true` | **Editorial Review Needed:** Yes
- **Suggested Aliases:** `longeing cavesson`, `lungeing cavesson`
- **Concise Definition:** A fitted headpiece featuring a structured noseband—often equipped with swivel rings—used in longeing and classical in-hand groundwork to communicate directly around the nose without pulling on a bit.
- **Educational Explanation:** Well-fitted soft leather or padded cavessons sit smoothly below the cheekbone and protect a young or sensitive horse's mouth from line drag during circle work. Handlers also distinguish gentle flat/leather cavessons from harsh serrated metal nosebands (serreta) that risk skin or nasal-bone damage.
- **Practical Example:** Attach the longe line to the center ring of a padded cavesson so circle cues do not yank sideways on the bit.
- **Cross-Tradition Usage:** Common in English, classical, and European longeing; well-fitted flat rope or leather halters also serve safely when fitted thoughtfully.
- **Safety / Welfare Considerations:** Ensure at least two fingers of space under the noseband so chewing and breathing stay relaxed; avoid rigid metal-edged nosebands.
- **Related Terminology:** `longeing`, `groundwork`, `hackamore-bosal`, `poll`
- **Related Skill Tree Skills:** `rider.theory.training_equipment`, `rider.in_hand.longeing`, `horse.in_hand.longeing`

#### 15. Surcingle (`surcingle` · Proposal — Not Approved)
- **Categories:** Tack & Equipment, Handling | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `surcingles`, `longeing surcingle`, `belly surcingle`, `belly surcingles`
- **Concise Definition:** A wide strap fastened securely around the horse's barrel behind the withers—either used as a belly strap on blankets or equipped with upper rings for ground driving and groundwork.
- **Educational Explanation:** When used for long-lining or longeing prep, a padded surcingle guides two long lines cleanly along the horse's sides without requiring a full saddle. Just like a girth or cinch, it needs spine/wither clearance over a pad and gradual tightening.
- **Practical Example:** Place a clean pad beneath the training surcingle and check wither clearance before threading ground-driving lines.
- **Cross-Tradition Usage:** Dual context covers both training surcingles/rollers (Europe/UK) and belly surcingles under turnout/stable blankets.
- **Safety / Welfare Considerations:** Adjust blanket belly surcingles so a flat hand fits cleanly beneath; sagging loops invite hoof entrapment while tight straps pinch.
- **Related Terminology:** `girth-cinch`, `wither-clearance`, `ground-driving`, `longeing`
- **Related Skill Tree Skills:** `rider.theory.training_equipment`, `rider.in_hand.ground_driving`, `horse.in_hand.ground_driving`, `rider.husbandry.blanketing`

#### 16. Hackamore / Bosal (`hackamore-bosal` · Proposal — Not Approved)
- **Categories:** Tack & Equipment, Riding | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `hackamore`, `bosal`
- **Concise Definition:** Bitless bridle designs that communicate through gentle pressure around the nose, chin groove, and poll rather than through a bit inside the horse's mouth.
- **Educational Explanation:** In traditional Western vaquero horsemanship, the true hackamore features a braided rawhide or leather bosal suspended by a hanger with horsehair mecate reins—emphasizing light feel, release, and progressive neck-rein self-carriage. Modern mechanical or sidepull hackamores operate differently; mechanical shanks multiply leverage strongly over delicate nasal bones if misused.
- **Practical Example:** Check that any hackamore or bosal rests comfortably above the fragile nasal tip without pinching cheeks or multiplying harsh poll leverage.
- **Cross-Tradition Usage:** Covers bitless riding thoughtfully across Western vaquero, trail, endurance, and general horsemanship.
- **Regional Usage:** Bosal refers specifically to the rigid nosepiece of a traditional Western jaquima/hackamore; sidepulls and English mechanical hackamores are distinct designs.
- **Safety / Welfare Considerations:** "Bitless" does not automatically mean mild—fit height above the delicate cartilage of the nose carefully and avoid heavy steady leverage.
- **Related Terminology:** `rein-contact`, `aids`, `poll`, `cavesson`
- **Related Skill Tree Skills:** `rider.husbandry.tack`, `rider.theory.tack_fit_function`, `horse.mounted.transitions`

#### 17. Garrocha (`garrocha` · Proposal — Not Approved)
- **Categories:** Riding, Tack & Equipment | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** *(none)*
- **Concise Definition:** A lightweight wooden pole carried one-handed in traditional Iberian ranch work and Working Equitation to test rider balance, steering clarity, and horse composure.
- **Educational Explanation:** Carrying and maneuvering a long pole smoothly around markers or rings while riding one-handed shows how well horse and rider coordinate via seat, leg, and poise rather than needing two hands on the reins.
- **Practical Example:** Introduce the garrocha quietly at walk from the ground before carrying it beside the saddle at trot or canter.
- **Cross-Tradition Usage:** Discipline-specific object-handling application—optional rather than required for general foundational horsemanship.
- **Safety / Welfare Considerations:** Desensitize gradually to the long pole moving near the horse's eye and hip; drop or pause cleanly rather than poking or trapping the horse.
- **Related Terminology:** `independent-seat`, `aids`, `sidepass`
- **Related Skill Tree Skills:** `rider.mounted.object_handling`, `horse.mounted.object_handling`

#### 18. Proprioception (`proprioception` · Proposal — Not Approved)
- **Categories:** Biomechanics, Theory | **Contextual Highlight:** `true` | **Editorial Review Needed:** No
- **Suggested Aliases:** `proprioceptive`
- **Concise Definition:** The body's internal sensory awareness of limb position, joint angle, weight shift, and movement in space without having to look directly at the feet.
- **Educational Explanation:** Developing proprioception benefits both partners: calm riders build proprioceptive feel for saddle symmetry, trot diagonals, and canter leads without staring down, while thoughtful groundwork, varied terrain, and slow pole work heighten a horse's sure-footed awareness of where all four hooves step.
- **Practical Example:** Slow, unhurried walking over uneven ground poles encourages equine proprioception and thoughtful hoof placement.
- **Cross-Tradition Usage:** Note: does not currently appear verbatim in curriculum/v2/*.json (0 current hits); proposed as optional scientific biomechanics vocabulary.
- **Safety / Welfare Considerations:** Fatigue impairs proprioception in both horse and rider—finish demanding footwork tasks cleanly before tired stumbling begins.
- **Related Terminology:** `independent-seat`, `trot-diagonal`, `canter-lead`, `asymmetry`
- **Related Skill Tree Skills:** `rider.mounted.seat_balance`, `rider.mounted.trot`, `rider.theory.balance_weight`, `horse.mounted.terrain_obstacles`

---

## 6. Skill Tree References Coverage Matrix

| Skill Tree Subject & Category | Linked Existing Entries (`dictionary_seed.json`) | Linked Proposed Wave 3 Candidates |
| :--- | :---: | :---: |
| **Rider → Husbandry** (10 skills) | 5 (`green`, `withers`, `girth-cinch`, `quick-release-knot`, `vital-signs-tpr`) | 15 (`colic`, `lameness`, `choke`, `thrush`, `wither-clearance`, `blind-spot`, `forage`, `laminitis`, `digital-pulse`, `five-domains-model`, `equine-pain-ethogram`, `capillary-refill-time`, `synovial-structure`, `surcingle`, `hackamore-bosal`) |
| **Rider → In-Hand** (9 skills) | 2 (`groundwork`, `longeing`) | 15 (`rein-back`, `turn-on-the-forehand`, `turn-on-the-haunches`, `reinforcement`, `lameness`, `blind-spot`, `straightness`, `asymmetry`, `lateral-movement`, `sidepass`, `ground-driving`, `habituation`, `arousal-threshold`, `cavesson`, `surcingle`) |
| **Rider → Mounted** (20 skills) | 15 (`canter`, `half-halt`, `collection`, `shoulder-in`, `counter-canter`, `trot`, `posting-trot`, `trot-diagonal`, `canter-lead`, `aids`, `rein-contact`, `transitions`, `forehand`, `hindquarters`, `girth-cinch`) | 27 (`independent-seat`, `two-point-position`, `rein-back`, `turn-on-the-forehand`, `turn-on-the-haunches`, `engagement`, `impulsion`, `straightness`, `bend`, `flexion`, `suppleness`, `asymmetry`, `hollowing`, `lateral-movement`, `leg-yield`, `sidepass`, `simple-lead-change`, `cross-canter`, `trigger-stacking`, `flying-lead-change`, `travers`, `shoulder-fore`, `ambling-gait`, `free-walk`, `tempo`, `garrocha`, `proprioception`) |
| **Rider → Theory & Knowledge** (15 skills) | 20 (`green`, `green-broke`, `canter`, `collection`, `poll`, `withers`, `trot`, `posting-trot`, `trot-diagonal`, `canter-lead`, `aids`, `rhythm`, `rein-contact`, `forehand`, `hindquarters`, `girth-cinch`, `negative-reinforcement`, `positive-reinforcement`, `self-carriage`, `longeing`) | 36 (`rein-back`, `reinforcement`, `learned-helplessness`, `lameness`, `wither-clearance`, `blind-spot`, `forage`, `engagement`, `impulsion`, `straightness`, `bend`, `flexion`, `suppleness`, `asymmetry`, `hollowing`, `leg-yield`, `cross-canter`, `diagonal-pairs`, `ground-driving`, `training-pyramid`, `operant-conditioning`, `classical-conditioning`, `habituation`, `desensitization`, `arousal-threshold`, `trigger-stacking`, `ambling-gait`, `tempo`, `counter-conditioning`, `flooding`, `five-domains-model`, `equine-pain-ethogram`, `cavesson`, `surcingle`, `hackamore-bosal`, `proprioception`) |
| **Horse → In-Hand** (13 skills) | 4 (`ground-tie`, `groundwork`, `quick-release-knot`, `vital-signs-tpr`) | 15 (`turn-on-the-forehand`, `turn-on-the-haunches`, `learned-helplessness`, `thrush`, `sidepass`, `ground-driving`, `habituation`, `desensitization`, `arousal-threshold`, `trigger-stacking`, `counter-conditioning`, `flooding`, `capillary-refill-time`, `cavesson`, `surcingle`) |
| **Horse → Mounted** (17 skills) | 11 (`canter`, `collection`, `shoulder-in`, `counter-canter`, `trot`, `canter-lead`, `rhythm`, `transitions`, `forehand`, `hindquarters`, `self-carriage`) | 21 (`rein-back`, `turn-on-the-forehand`, `turn-on-the-haunches`, `engagement`, `suppleness`, `hollowing`, `leg-yield`, `sidepass`, `simple-lead-change`, `cross-canter`, `diagonal-pairs`, `desensitization`, `flying-lead-change`, `travers`, `shoulder-fore`, `free-walk`, `cadence`, `tempo`, `hackamore-bosal`, `garrocha`, `proprioception`) |

---

## 7. Contextual Highlighting & Known Terms Architecture Review

Inspected [dictionary_matcher.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_matcher.dart), [dictionary_text.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_text.dart), [known_terms_repository.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/known_terms_repository.dart), and [skill_detail_v2_panel.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart):

1. **Where Contextual Highlighting Renders in Skill Tree 2.0:**
   - Wraps narrative body copy in `ContextualDictionaryText`: `skill.summary`, `Purpose: ...`, `skill.safety` bullet bar, `level.overview`, `component.description`, `level.learning`, and `level.proficient`.
   - Intentionally does **not** wrap headings/chips (`skill.name`, family headers, `aliases`, or `component.title`), preserving visual calm across mobile, tablet, and desktop layouts.
   - Note on `five-domains-model` and `equine-pain-ethogram`: In current Wave 3 Skill Tree text, those exact strings appear inside `aliases[]` and `component.title` rather than inside `component.description`. They are still valid searchable Dictionary entries, manual `"Define"` targets, and ready to highlight across Resource articles and future curriculum copy.
2. **Matching Precision, Longest-Match Priority & Ambiguity Guards:**
   - Single-pass longest-first alternation bounded by Unicode word assertions `(?<![\p{L}\p{N}_])...(?![\p{L}\p{N}_])` prevents partial-word false positives inside unrelated words (verified `0` hits on our general-English trap sentence covering `"walk"`, `"bend"`, `"flexion"`, `"choke"`, `"flooding"`, `"green"`, `"collection"`, `"poll"`, `"aids"`, `"contact"`, `"lead"`, `"straight"`, `"threshold"`).
   - **Important Engine Finding — Exact Surface Forms Required in `synonyms[]`:** While *manual* lookup (`lookupSelectedDictionaryTerm`) normalizes internal hyphens to spaces, **automatic contextual matching (`_CompiledDictionaryIndex`) matches exact lowercase `term` and `synonyms[]` strings only—without auto-hyphenation or auto-pluralization**. That is why entries like `half-halt` need explicit `"half-halts"`, `ground-tie` needs `"ground-tying"`, `negative-reinforcement` needs `"pressure-and-release"`, and proposed `turn-on-the-forehand` includes `"turns on the forehand"`.
   - **Zero Ambiguity Collisions Verified:** Validation across all `84` combined terms + synonyms (`28` existing + `56` proposed) confirmed **0 shared lowercase keys**, ensuring no contextual entry is silently disabled by `meaningsByName[lower].length > 1`.
3. **Density & Overlap Check Across All 84 Skills:**
   - `DictionaryText` highlights each canonical meaning **at most once per text block**, capped at `maxMatches = 6`, with non-overlapping longer phrases beating shorter sub-phrases.
   - Simulated across all **1,156** `ContextualDictionaryText` strings in Wave 3 using all `84` combined entries: **0 blocks exceeded 6 unique matches** (maximum observed was `6` matches in `rider.theory.training_pyramid` Introductory component 1).
4. **Layout, Zero Extra Reads & Known Dictionary Terms Preferences:**
   - Inline `WidgetSpan` underlined accent links open crisp glass popovers at reading position on mobile, tablet, and desktop without layout reflow bugs, while `SelectionArea` enables manual **"Define"** even for `contextual: false` meanings (`green`, `collection`, `poll`, `aids`, `bend`, `flexion`, `choke`, `flooding`).
   - `ContextualDictionaryText` listens reactively to cached `DictionaryRepository.entriesNotifier` and `KnownTermsRepository.instance` (`dictionary_known_terms_v1_<uid>`), incurring **zero additional Firestore reads during Skill Tree rendering**.
   - **Guest Isolation Preserved:** `KnownTermsRepository.activeUserId == null` keeps Known Terms disabled in guest mode—guests see full contextual highlighting and definitions but cannot mark terms known or alter preferences.

---

## 8. Recommended Controlled Import Order

1. **Stage 0 — Existing Seed Refinements & Archive Decision:**
   - Apply the `10` non-breaking synonym and `skillIds` updates in [dictionary_seed.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/dictionary_seed.json) (zero slug/meaning changes).
   - Retire/remove superseded [batch_01_drafts.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/curriculum/dictionary/batch_01_drafts.json) when updating Dictionary tests.
2. **Stage 1 — Priority A Import (14 Entries):**
   - Matt reviews the `5` flagged Priority A clinical/welfare definitions (`learned-helplessness`, `colic`, `lameness`, `choke`, `thrush`); publish approved entries cleanly through the admin draft/revision flow.
3. **Stage 2 — Priority B Import (24 Entries, Suggested in Two Groups of 12):**
   - Group B1 (12 riding & biomechanics terms: `engagement`, `impulsion`, `straightness`, `bend`, `flexion`, `suppleness`, `asymmetry`, `hollowing`, `lateral-movement`, `leg-yield`, `sidepass`, `diagonal-pairs`).
   - Group B2 (12 canter, learning theory & hoof health terms: `simple-lead-change`, `cross-canter`, `ground-driving`, `training-pyramid`, `operant-conditioning`, `classical-conditioning`, `habituation`, `desensitization`, `arousal-threshold`, `trigger-stacking`, `laminitis`, `digital-pulse`). Review `training-pyramid`, `laminitis`, and `digital-pulse`.
4. **Stage 3 — Priority C Import (18 Entries):**
   - Matt reviews the `5` clinical/welfare/gear entries (`five-domains-model`, `equine-pain-ethogram`, `capillary-refill-time`, `synovial-structure`, `cavesson`) and confirms whether `proprioception` should publish now or wait until future curriculum copy adopts it.

