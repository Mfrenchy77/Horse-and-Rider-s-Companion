# Horse and Rider's Companion — Administration & Skill Tree Suggestions Architecture Proposal

> **Status:** Read-only Audit & Architecture Proposal. No Flutter code, Firestore security rules, Cloud Functions, custom claims, or production documents have been modified.

---

## 1. Existing Infrastructure Discovered

A read-only audit of the Flutter application, `packages/database_repository`, `functions/`, and `firebase/firestore.rules` found the following existing administrative, authorization, and navigation pieces:

### 1.1 Administrative Account (`horseandriderscompanion`)
- **Client constants:** [string_constants.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/Utilities/Constants/string_constants.dart#L4-L21) defines:
  - `StringConstants.HORSEANDRIDERCOMPANIONEMAIL = 'HorseAndRidersCompanion@gmail.com'`
  - `StringConstants.HORSEANDRIDERCOMPANIONNAME = "Horse And Rider's Companion"`
  - `AuthorizedEmails.emails = ['horseandriderscompanion@gmail.com', 'frenchfriedtechnology@gmail.com', 'mfrenchy77@gmail.com']`
- **Account deletion & horse ownership transfer:** [account_deletion.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/account_deletion.js#L40-L79) (`resolveAdminAccount`) and [`transferOwnedHorsesToAdmin`](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/account_deletion.js#L140-L182), wired in [index.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/index.js#L23-L31), read `process.env.ADMIN_ACCOUNT_EMAIL`.
  - When a user deletes their account, `resolveAdminAccount` looks up the administrative account by email via `auth.getUserByEmail(normalized)` and `db.collection('Rider_Profile').doc(profileId(normalized))`.
  - It is an **ordinary Firebase Auth user + `Rider_Profile` document**—it does not currently carry a special `admin` or `moderator` custom claim.
  - Owned horses are transferred to `currentOwnerId: adminAccount.email`, `ownerUid: adminAccount.uid`, and appended to the admin `Rider_Profile.ownedHorses` array. This behavior is also disclosed to users in [delete_page.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Delete/delete_page.dart#L64-L69).

### 1.2 Existing Editor, Moderation & Audit Hooks
- **Legacy `editor` flag on `RiderProfile`:** [rider_profile.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/models/rider_profile.dart#L49-L50) stores `bool? editor`. It is checked in:
  - [skill_tree_app_bar_overflow_menu.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTree/Widgets/skill_tree_app_bar_overflow_menu.dart#L18-L53) (to show *Toggle Edit Controls* in legacy Skill Tree).
  - [resource_update_skills_dialog.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Resources/Dialogs/CreateResourceDialog/resource_update_skills_dialog.dart#L27-L30) (to allow linking skills on a Resource).
- **Hardcoded email checks in `AppCubit`:** [app_cubit.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/Cubit/app_cubit.dart#L1564-L1579) (`canEditSkill` and `canEditResource`) checks `AuthorizedEmails.emails.contains(state.usersProfile?.email)`.
- **Article status helper (no admin UI):** [resource_repository.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/resource_repository.dart#L276-L286) defines `setArticleStatus({id, status})` with comment `/// Admin-only: set article status`, writing directly to `Resources/{id}`.
- **Immutable audit & notification patterns already in the codebase:**
  - `SkillVerificationEvents` subcollection in [connections.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/connections.js) and [firestore.rules](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/firestore.rules#L193-L198) demonstrates append-only server-written audit events.
  - `onRequestCreated` in [index.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/index.js#L648-L686) demonstrates Firestore-triggered FCM push + email notifications using `RiderProfiles/{email}/tokens`.
- **Absent today:** There are **no** existing Administration screens, Moderator roles, content reporting workflows, user management screens, or resource approval queues.

### 1.3 Existing Navigation & Repository Patterns
- **Navigation shell:** [navigation_view.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Navigator/navigation_view.dart#L220-L364) wraps a GoRouter `StatefulNavigationShell` ([routes.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/Routes/routes.dart#L158-L346)) with 3 primary branches:
  - Branch 0: `Profile` (`/Profile`, with subroutes `Settings`, `HorseProfile`, `ViewingProfile`, `About`, `PrivacyPolicy`, `Delete`)
  - Branch 1: `Skill Tree` (`/SkillTree`)
  - Branch 2: `Resources` (`/Resources`)
  - Responsive chrome switches between `BottomNavigationBar` (`< 600px`), compact `NavigationRail` (`600–1023px`), and extended `NavigationRail` (`>= 1024px`, matching `StringConstants.splitScreenBreakpoint`).
  - Secondary Profile actions live in [rider_drawer.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart#L242-L290) and [rider_profile_overflow_menu.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/RiderProfile/Widgets/rider_profile_overflow_menu.dart#L19-L41).
- **Repository abstraction (Skill Tree V2 pattern):** [skill_tree_v2_repository.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/skill_tree_v2_repository.dart) cleanly decouples UI/Cubits from Firebase via:
  - Abstract `*Store` interface (`SkillTreeV2Store`)
  - Production `Firestore*Store`
  - Test/preview `InMemory*Store`
  - Facade `*Repository` (`SkillTreeV2Repository`)

---

## 2. Existing Roles and Security Mechanisms

In [firestore.rules](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/firestore.rules):
- **`isVerifiedEditor()`** ([lines 33–36](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/firestore.rules#L33-L36)): Requires `request.auth != null && request.auth.token.email_verified == true && request.auth.token.get('editor', false) == true`.
  - Grants write access to legacy `Skills`, `Levels`, and `Resources`.
- **Protected profile fields:** `Rider_Profile` rules ([lines 201–215](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/firestore.rules#L201-L215)) prevent owners from setting or modifying `editor`, `ownerUid`, or `ownershipRosterVersion`.
- **Server-only collections:** `SkillFamilies`, `SkillsV2`, `CoachingConnections`, `SharedRidingEntries`, `DeletionJobs`, `SkillVerifications`, and `SkillVerificationEvents` have `allow write: if false;` (written exclusively via Cloud Functions / Admin SDK).
- **No `admin` or `moderator` custom claims** exist yet, and **no Flutter code** calls `getIdTokenResult()` to inspect Firebase Auth custom claims (`AppState` only reads `User` and `RiderProfile`).

---

## 3. Security Concerns and Gaps Identified

1. **Client-Side Hardcoded Email List (`AuthorizedEmails.emails`) & Case-Sensitivity Bug:**
   - [string_constants.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/Utilities/Constants/string_constants.dart#L5-L20) defines `HORSEANDRIDERCOMPANIONEMAIL` in mixed case (`HorseAndRidersCompanion@gmail.com`) and `AuthorizedEmails.emails` in lowercase (`horseandriderscompanion@gmail.com`), while `canEditSkill`/`canEditResource` perform exact `.contains(state.usersProfile?.email)`.
   - More importantly, `firestore.rules` does **not** grant privileges based on `AuthorizedEmails`; hardcoding admin emails in client Dart is neither maintainable nor a security boundary.
2. **UI vs. Rules Mismatch on `editor`:**
   - Flutter UI (`SkillTreeAppBarOverFlowMenu`, `UpdateResourceSkills`) checks the Firestore document field `usersProfile?.editor`, whereas `firestore.rules` checks the Auth token custom claim `request.auth.token.editor`. If the two are out of sync, the UI either hides valid tools or exposes buttons whose Firestore writes fail.
3. **Unenforced `Resources.setArticleStatus`:**
   - `ResourceRepository.setArticleStatus` writes `status` directly from the client, and `firestore.rules` ([lines 128–135](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/firestore.rules#L128-L135)) permits a `lastEditBy` owner to update any field on their own `Resources` doc—meaning an author could set `status: 'published'` without admin approval unless restricted in rules or via Cloud Function.
4. **Permissive Catch-All Rule for New Collections:**
   - [firestore.rules](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/firestore.rules#L339-L350) allows **any authenticated user** to read and write any collection not explicitly listed in the exclusion array. Any new collection (such as `SkillTreeSuggestions`) **must** have explicit `match` rules deployed before any client or function writes to it.

---

## 4. Proposed Administration Navigation

To keep the main app clean for riders, horse owners, and instructors while supporting mobile, desktop, and future admin modules:

### 4.1 Entry Point & Visibility
- Keep the 3 primary bottom-bar / rail destinations (`Profile`, `Skill Tree`, `Resources`) unchanged for all ordinary users and guests.
- Expose an **Administration** entry tile (`Icons.admin_panel_settings_outlined`) in:
  1. [rider_drawer.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart) (above `Settings`), and
  2. [rider_profile_overflow_menu.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/RiderProfile/Widgets/rider_profile_overflow_menu.dart) (so desktop users who don't open the drawer can access it in one click).
- **Visibility rule:** Render the entry point **only** when `!state.isGuest && state.user.emailVerified && (state.isAdmin || state.isModerator)`, where `isAdmin` and `isModerator` come from Firebase Auth `IdTokenResult.claims`—never from `AuthorizedEmails` or editable profile fields.

### 4.2 Routing & Responsive Shell (`/Administration`)
- Add a top-level (or Profile-branch) GoRoute `/Administration` (`AdministrationPage`) with nested module routes (e.g., `/Administration/Suggestions`, `/Administration/Suggestions/:suggestionId`).
- **Route guard:** If an unauthorized user navigates directly to `/Administration` via deep link or browser URL, immediately redirect to `/Profile` (and even if forced locally, Firestore rules and Cloud Functions reject all requests).
- **Responsive layout:**
  - **Mobile (`< 1024px`):** Module list → pushes `SkillTreeSuggestionsInboxPage` → pushes `SuggestionDetailPage`.
  - **Desktop / Tablet (`>= 1024px`):** Persistent left module rail + filterable inbox list + right detail/audit pane, using existing `AppSurfaceCard`, `AppTokens`, and `MaxWidthBox` design tokens.
- **Future expandability:** Each admin feature (`Skill Tree Suggestions`, future `Reported Content`, future `User & Role Management`, future `Resource Moderation`) registers as a module tile in `AdministrationPage` with role filtering (`adminOnly` vs. `staff`).

---

## 5. Proposed Administrator and Moderator Authorization

### 5.1 Mechanism: Firebase Auth Custom Claims
Use **Firebase Auth Custom Claims** as the single source of truth for authorization:
- `admin: true` (for Administrators)
- `moderator: true` (for Moderators)
- *(Retain existing `editor: true` for legacy Skill Tree compatibility until legacy `Skills` is retired.)*

**Why Custom Claims Fit Best:**
- Available directly in `firestore.rules` (`request.auth.token.get('admin', false) == true`) with **zero** extra `get()` document reads.
- Available in every Cloud Function (`request.auth?.token?.admin === true`).
- Tamper-proof (settable only via Firebase Admin SDK, never by clients).
- Readable in Flutter via `FirebaseAuth.instance.currentUser?.getIdTokenResult()`, exposed cleanly on the domain `User` model (`isAdmin`, `isModerator`) in `AuthenticationRepository`.

### 5.2 Role Capabilities Matrix

| Capability | Ordinary User / Instructor | Moderator (`moderator: true`) | Administrator (`admin: true`) |
| :--- | :---: | :---: | :---: |
| Submit Skill Tree suggestion | Yes (verified email) | Yes | Yes |
| View own submitted suggestions & public resolution note | Yes | Yes | Yes |
| View Administration section & Suggestions Inbox | **No** | Yes | Yes |
| View submitter identity & internal private notes | **No** | Yes | Yes |
| Claim suggestion (`under_review`), add private notes, request clarification (`needs_clarification`), recommend action | **No** | Yes | Yes |
| Approve (`approved_*`), decline (`declined_*`), or mark `published` | **No** | **No** *(or configurable later)* | **Yes** |
| Future: Review reported content | **No** | Yes | Yes |
| Future: Grant/revoke `moderator` / `admin` claims | **No** | **No** | **Yes** |
| Directly edit `SkillsV2` or `SkillFamilies` from the client | **No** | **No** | **No** *(Admin SDK / validated `curriculum/v2/` pipeline only)* |

### 5.3 Server-Side Rules Helpers (Proposed)
```js
function isAdmin() {
  return verifiedAuth() && request.auth.token.get('admin', false) == true;
}
function isModerator() {
  return verifiedAuth() && request.auth.token.get('moderator', false) == true;
}
function isStaff() {
  return isAdmin() || isModerator();
}
```
Initial bootstrap of `admin: true` on `horseandriderscompanion@gmail.com` (and any owner accounts) should be performed **only** via a local operator Admin SDK script—never via a client-callable endpoint.

---

## 6. Proposed Skill Tree Suggestions Data Model

Aligned with `docs/SKILL_TREE_CURRICULUM_GUIDE.md` (Section 7):

### 6.1 Collection: `SkillTreeSuggestions/{suggestionId}`
- **Access:** `allow create, update, delete: if false;` (written exclusively by Cloud Functions `submitSkillTreeSuggestion` and `reviewSkillTreeSuggestion` so validation, rate limiting, and audit events are atomic).
- **Read:** `allow get, list: if isStaff() || (verifiedAuth() && resource.data.submitterUid == request.auth.uid);`
- **Fields:**
  - `id` (`string`, doc ID)
  - `contributionCategory` (`string`: `missing_term_or_alias` | `component_or_example` | `level_adjustment_or_addition` | `new_skill_proposal` | `safety_or_wording_correction`)
  - `subject` (`string`: `rider` | `horse`)
  - `realm` (`string`: `Husbandry` | `In_Hand` | `Mounted` | `Other`)
  - `familyId` (`string?`)
  - `targetSkillId` (`string?`, auto-attached when opened from a skill)
  - `targetSkillName` (`string?`, snapshot for display)
  - `targetLevel` (`string?`: `introductory` | `intermediate` | `advanced`)
  - `title` (`string`, 5–120 chars)
  - `description` (`string`, 10–2000 chars)
  - `rationale` (`string?`, max 1000 chars)
  - `proposedAlias` (`string?`, max 120 chars)
  - `submitterUid` (`string`)
  - `submitterEmail` (`string`)
  - `submitterName` (`string`)
  - `status` (`string`: `submitted` | `under_review` | `needs_clarification` | `approved_as_alias_or_component` | `approved_as_level` | `approved_as_new_skill` | `published` | `declined_already_covered` | `declined_out_of_scope`)
  - `assignedToUid` (`string?`)
  - `publicResolutionNote` (`string?`, max 1000 chars — visible to submitter)
  - `createdAt`, `updatedAt`, `reviewedAt` (`timestamp`)
  - `reviewedByUid` (`string?`), `reviewedByName` (`string?`)

### 6.2 Private Subcollection: `SkillTreeSuggestions/{suggestionId}/AuditEvents/{eventId}`
- **Access:** `allow get, list: if isStaff(); allow write: if false;`
- **Why separate?** Keeps **private internal moderator/admin notes** (`privateNote`), assignment changes, and moderation history strictly invisible to the submitter and ordinary users.
- **Fields:** `id`, `type` (`submitted` | `status_changed` | `note_added` | `assigned`), `actorUid`, `actorName`, `actorRole` (`submitter` | `moderator` | `admin`), `fromStatus`, `toStatus`, `privateNote`, `publicNote`, `at` (`serverTimestamp`).

---

## 7. Proposed Submission and Review Workflow

### 7.1 Community Interface (Skill Tree V2)
1. **General Entry:** Add a `"Suggest an Improvement"` action button/menu item in `SkillTreeV2View` / `SkillTreeV2Header` (pre-populating current `subject` and selected `realm` / Category).
2. **Contextual Entry:** Add a `"Suggest Improvement for This Skill"` button in `SkillDetailV2Panel` (auto-attaching `targetSkillId`, `targetSkillName`, `subject`, `realm`, `familyId`, and `effectiveSelectedLevel`).
3. **Guest / Unverified Guard:** Guests or unverified accounts see a prompt to sign in / verify their email before submitting.
4. **Form & Confirmation:** Users pick a `contributionCategory`, enter a concise title, details, and optional rationale, submit via `SkillTreeSuggestionsRepository.submitSuggestion(...)`, and receive immediate confirmation feedback.

### 7.2 Server-Side Validation & Abuse Prevention (`submitSkillTreeSuggestion`)
- Requires `request.auth` + `email_verified == true`.
- Validates enum values (`contributionCategory`, `subject`, `realm`, `targetLevel`), string lengths, and verifies `targetSkillId` / `familyId` exist in `SkillsV2` / `SkillFamilies` when provided.
- **Abuse prevention:** Enforces a per-user rate limit (e.g., max 5 open `submitted` suggestions or max 10 submissions per 24 hours per `uid`) before creating the document and initial `AuditEvents` entry.
- **Isolation:** Never writes to `SkillsV2`, `SkillFamilies`, `SkillProgress`, or `SkillVerifications`.

### 7.3 Administrative & Moderator Review (`reviewSkillTreeSuggestion`)
- Callable requires `request.auth.token.admin === true || request.auth.token.moderator === true`.
- **Role enforcement in function:**
  - Moderators may transition `submitted` ↔ `under_review` ↔ `needs_clarification` and append `privateNote`s.
  - Only **Administrators** (`admin === true`) may set terminal approval/decline/published statuses (`approved_*`, `declined_*`, `published`).
- Every action atomically updates `SkillTreeSuggestions/{id}` and appends an immutable `AuditEvents` record.
- Approved curriculum edits continue to flow through version-controlled `curriculum/v2/*.json` → `node tool/validate_curriculum_v2.js` → Admin SDK publication.

---

## 8. Repository Architecture (Flutter & `packages/database_repository`)

Consistent with [skill_tree_v2_repository.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/skill_tree_v2_repository.dart):
- **Models (`packages/database_repository/lib/src/models/`):**
  - `SkillTreeSuggestion`, `SuggestionAuditEvent`, `SuggestionCategory`, `SuggestionStatus`.
- **Store Abstraction (`skill_tree_suggestions_store.dart`):**
  - `abstract interface class SkillTreeSuggestionsStore` (`submitSuggestion`, `fetchMySuggestions`, `fetchInboxSuggestions`, `fetchAuditEvents`, `reviewSuggestion`).
  - `CloudSkillTreeSuggestionsStore` (Firestore reads + `FirebaseFunctions` callable writes; no direct Firestore writes from UI).
  - `InMemorySkillTreeSuggestionsStore` (deterministic local fixture store for unit/widget tests and offline preview).
- **Repository (`skill_tree_suggestions_repository.dart`):**
  - `SkillTreeSuggestionsRepository` injected at app root via `RepositoryProvider`, keeping `SkillTreeV2` and `Administration` Cubits/widgets 100% decoupled from Firebase SDKs.

---

## 9. Recommended Phased Implementation

1. **Phase 2 — Authorization & Claims Foundation:**
   - Expose `isAdmin` / `isModerator` from `IdTokenResult.claims` in `AuthenticationRepository` and `AppState`.
   - Add `isAdmin()`, `isModerator()`, `isStaff()` helpers to `firebase/firestore.rules`, plus explicit rules for `SkillTreeSuggestions` (and fix `AuthorizedEmails` case/role alignment).
   - Provide an operator-only Admin SDK script to grant initial `admin: true` claims.
2. **Phase 3 — Suggestions Backend & Repository:**
   - Implement `submitSkillTreeSuggestion` and `reviewSkillTreeSuggestion` Cloud Functions with rate limiting and `AuditEvents` logging.
   - Implement `SkillTreeSuggestionsStore`, `CloudSkillTreeSuggestionsStore`, `InMemorySkillTreeSuggestionsStore`, and `SkillTreeSuggestionsRepository` in `packages/database_repository`.
3. **Phase 4 — Community Submission UI:**
   - Add `"Suggest an Improvement"` in `SkillTreeV2View` and `"Suggest Improvement for This Skill"` in `SkillDetailV2Panel` with confirmation UI.
4. **Phase 5 — Administration Shell & Suggestions Inbox:**
   - Add role-gated `/Administration` route, drawer/overflow menu entry, responsive mobile/desktop inbox with status filters, private notes, and audit timeline.
5. **Phase 6 (Future Expansion):**
   - Add `Reported Content`, `Resource Moderation` (enforcing `setArticleStatus` server-side), and `Moderator Management` modules inside `/Administration`.

---

## 10. Tests and Security Checks Required

- **Firestore Rules Emulator Tests (`firebase/firestore.rules.test.cjs`):**
  - Ordinary users cannot read other users' suggestions, cannot read `AuditEvents`, and cannot write directly to `SkillTreeSuggestions`.
  - Moderators/Admins can read `SkillTreeSuggestions` and `AuditEvents`, but cannot write directly to `SkillTreeSuggestions`, `SkillsV2`, or `SkillFamilies`.
- **Cloud Function Unit Tests (`functions/test/`):**
  - Unauthenticated or unverified-email users rejected.
  - Rate-limit rejection after threshold.
  - Moderators blocked from setting `approved_*` / `declined_*` / `published` statuses (`permission-denied`).
  - Admins allowed to set all review statuses; immutable `AuditEvents` created on every transition.
- **Flutter Unit & Widget Tests (`test/`):**
  - `Administration` menu item and `/Administration` route hidden/blocked for guests, riders, and instructors; visible for `admin` and `moderator`.
  - Community suggestion dialog auto-attaches skill context (`targetSkillId`, `subject`, `realm`, `targetLevel`) and submits via `InMemorySkillTreeSuggestionsStore`.
  - Admin inbox filters by status, displays private notes and audit history, and enforces Moderator vs. Admin action visibility.

---

## 11. Decisions Requiring Owner Approval

1. **Moderator Approval Authority:** Should Moderators be restricted to triaging (`under_review`, `needs_clarification`, internal notes) while only Administrators can `approve_*` / `decline_*`, or should trusted Moderators also be permitted to `decline_already_covered`?
2. **Custom Claims vs. Legacy `editor` Migration:** Approve migrating `AuthorizedEmails` + `RiderProfile.editor` checks to Firebase Auth custom claims (`admin`, `moderator`, `editor`) and keeping `admin` claim bootstrap strictly operator-only?
3. **Rate Limit & Submitter Visibility:** Approve limiting community suggestions (e.g., max 5 open `submitted` items / 10 per 24 hours per user) and allowing submitters to see their own suggestions' `status` and `publicResolutionNote`?
4. **Admin Notifications:** Should new suggestions trigger an FCM push / email notification to administrators (reusing the `index.js` pattern), or rely solely on the in-app inbox at first?
5. **Administration Entry Placement on Desktop:** Is placing the `Administration` link in `RiderDrawer` + `RiderProfileOverFlowMenu` sufficient for Phase 1, or would you also like a conditional 4th `NavigationRail` destination shown only to Admins/Moderators?
