# Develop This Skill — Editorial Authoring Guide

> **Purpose:** Permanent editorial reference for authoring **Develop This Skill** practical learning guides (`learningGuide` on V2 skills in `curriculum/v2/*.json`). Guides must reinforce clear horsemanship, horse welfare, cross-discipline inclusivity, and calm self-reflection—without adding assessment checklists or prescription.

---

## 1. Non-Negotiable Curriculum Boundaries

- **Educational guidance only:** `learningGuide` never modifies `availableLevels`, `levels.<level>.learning`, `levels.<level>.proficient`, `standardVersion`, `SkillProgress`, or `SkillVerifications`.
- **Zero completion pressure:** Never include mandatory repetition counts (e.g., *"perform 10 times cleanly"*), fixed training timelines (e.g., *"master in two weeks"*), or checklist quotas.
- **No locked progression:** Related links in the footer suggest connected ideas; they never lock or gate practice.

---

## 2. Recommended Guide Structure

Every `learningGuide` object follows this schema:

| Field | Quantity | Purpose | Target Size Budget |
| :--- | :--- | :--- | :--- |
| **`exercises[]`** | **2 items** (`1` Foundation/Introductory, `1` Progression/Intermediate or Adapted) | Concrete, adaptable activities focused on *understanding*, *feel*, and *what to observe* rather than mechanical drills. | `title`: ≤ 55 chars<br>`summary`: 200–340 chars (2 concise sentences)<br>`whatToNotice`: 110–190 chars (1 crisp question or observation) |
| **`commonDifficulties[]`** | **2 items** (`{issue, guidance}`) | High-frequency snags framed empathetically, paired with a safe, humane adjustment. | `issue`: ≤ 60 chars<br>`guidance`: 120–210 chars |
| **`trainerInsight`** | **1 concise observation** | Experienced horse-trainer perspective distilled into memorable plain speech. | 70–140 chars (1–2 lines) |
| **`welfareNote`** | **1 practical note** | Distinguishes genuine relaxation from freeze/shutdown and ties persistent resistance to comfort, stress, or soundness checks. Must complement—not duplicate—`skill.safety[]`. | 110–210 chars |
| **`relatedDictionaryTerms[]`** | **3–4 canonical slugs** | Valid slugs from `functions/dictionary_seed.json` that appear in footer quick-definition links. | 3–4 slugs |
| **`relatedSkillIds[]`** | **2 canonical skill IDs** | Counterpart skill (when one exists) plus 1–2 practical or Theory connections. | 2 IDs |
| **Total JSON per skill** | — | Keeps `curriculum/v2` draft payload well beneath single-document Firestore caps (`~2.0–2.1 KB` per skill). | **≤ 2.2 KB** serialized |

---

## 3. Exercise-Writing Principles

1. **Explain the purpose of the activity clearly:** A novice reader should understand *why* they are doing the exercise and what good communication feels like—not just step-by-step choreography.
2. **Focus on earliest soft responses:** Teach releasing on the earliest shift in weight, balance, softening jaw, or step rather than holding pressure until completion.
3. **Adapt cleanly to context:** Frame exercises using level, open footing or enclosed spaces rather than specialty props, arena letter sequences, or specialized gadgets. When an optional aid (like a neck strap or ground rail) helps beginners, frame it as optional.
4. **Build safety into plain prose:** Where footing, kicking arcs, open space behind a horse, or slower paces reduce risk, state it calmly inside the opening sentence.
5. **Preserve conservative safety margins:** Exercises involving inexperienced handlers, mounting/dismounting, trailing/loading, long lines, obstacles, or emergency situations must explicitly favor pausing, walking, simplifying, or seeking qualified in-person help over "working through" escalation.

---

## 4. Authentic Trainer Voice & Common Mistakes to Avoid

Write cleanly and naturally—like an observant trainer speaking beside the arena fence rather than textbook boilerplate.

- **Good voice examples:**
  - *"Notice what changes in your own breathing and pace before you ever touch the lead rope."*
  - *"The release is part of the lesson, not simply the end of it."*
  - *"A quieter response may indicate true relaxation, but always read posture and breathing to rule out anxious shutdown."*
  - *"Real stability lives over your own pelvis and feet; hands stay light only when they are never asked to rescue your balance."*
- **Avoid these wording traps:**
  - **Synonym bloat:** Repeating `"calm"`, `"calmly"`, `"quiet"`, `"quietly"`, and `"unhurried"` four times in the same exercise. Vary verbs naturally (*"settled"*, *"relaxed"*, *"measured"*, *"even"*, *"soft"*) and let clarity carry the tone.
  - **Safety copy-paste:** Copying `skill.safety[]` verbatim into `welfareNote`. Keep `safety[]` focused on hazard prevention and `welfareNote` focused on behavioral signs, comfort checks, and avoiding escalation.
  - **AI padding:** Over-explaining obvious qualifiers (*"in an appropriately supportive, mutually respectful training environment"*). Say *"in a familiar enclosure"* instead.
  - **Treating compliance as comprehension:** Never write *"Wait until the horse gives in."* Distinguish soft chewing/blinking/breathing from frozen stillness or shut-down compliance.

---

## 5. Subject Separation (Rider vs. Horse Counterparts)

Counterpart skills share context but **never reuse identical paragraphs**:

- **Rider guides** evaluate and coach **human body awareness, timing, spatial safety, preparation, and release** (e.g., *posture before rope feel, unclamped legs, aligned leg channels, giving forward softness*).
- **Horse guides** focus on **the horse's developing understanding, relaxation, posture, physical symmetry, footfalls, and emotional composure** (e.g., *poll/jaw softness, respectful spacing near barn activity, comfortable lumbar/hock flexion, even diagonal pairs*).
- Cross-link mutual counterparts in `relatedSkillIds` so learners can jump seamlessly between human responsibility and equine experience.

---

## 6. Difficulty Levels & Theory Adaptation

- **Ordering by active tab:** Tag `exercises[].focusLevel` cleanly (`"introductory"`, `"intermediate"`, `"advanced"`) when an exercise maps primarily to a level, so selecting that chip surfaces the most relevant exercise first. Leave `focusLevel` `null` on single-level skills or universally relevant practice.
- **Physical vs. Theory & Knowledge skills:**
  - Practical Groundwork & Mounted skills use `"Foundation Exercise"` and `"Progression Exercise"` (or `"Refinement Exercise"` for Advanced-only skills like *Travers* or *Flying Lead Changes*).
  - **Theory & Knowledge (`rider.theory.*`) skills** must *not* invent artificial arena drills. Instead, customize `badge` tags accurately:
    - `"Observation Exercise"` (observing footfalls, ear/eye/breathing clusters, or saddle sweat marks from outside the saddle)
    - `"Scenario Check"` (evaluating a realistic barn dilemma—fatigue vs. disobedience, trigger stacking, gear fit)
    - `"Session Reflection"` / `"Practical Application"` (reviewing one's own timing, conditioning logs, or warm-up plan)

---

## 7. Cross-Discipline Neutrality & Dictionary Integration

- **All-equestrian phrasing:** Include English, Western, ranch, trail, driving, gaited, and therapeutic contexts neutrally. Refer to *"light contact or a soft rein"*, *"balanced seat or light two-point position"*, *"straight trot-up"* without requiring discipline-specific bits, halters, saddles, or training methods.
- **Dictionary integration:**
  - Pick **3–4 slugs** that appear naturally in the skill's context (not obscure terms unrelated to the exercise).
  - Verify every slug exists in `functions/dictionary_seed.json` and preview contextual matches so incidental phrases don't highlight unrelated entries (for example, write *"beside the horse's shoulder within an enclosed space"* rather than *"shoulder in an enclosed space"*, which matches *Shoulder-In*).
