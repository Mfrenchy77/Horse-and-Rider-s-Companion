# Phase 2 Authorization & Claims Foundation — Operator Notes

## 1. Custom Claims & Token Refresh Behavior

- **Authoritative roles** come exclusively from Firebase Auth ID token custom claims:
  - `admin: true`
  - `moderator: true`
  - `editor: true`
- **Client enforcement**: `User` and `AppState` expose `isAdmin`, `isModerator`, `isEditor`, and `canAccessAdministration`. All four require `!isGuest && emailVerified`.
- **Token propagation**: Updating custom claims via Firebase Admin SDK does not mutate an already-issued ID token on active client sessions. Clients receive updated claims when:
  - the ID token naturally refreshes (typically within 1 hour),
  - the user signs out and signs back in, or
  - the app calls `AppCubit.refreshUserRoles()` (`AuthGateway.refreshRoles(forceRefresh: true)`).

## 2. Bootstrap Utility Credential Handling (`tool/grant_admin_claim.js`)

- Never hardcode service account keys or credentials in the repository.
- Run locally as an operator using `GOOGLE_APPLICATION_CREDENTIALS=/secure/path/service-account.json` (or `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099` for emulator testing).
- The script defaults to **dry-run** and preserves all unrelated custom claims.
- Production writes require `--uid <firebaseUid>`, `--confirm`, and `--allow-production`.
- The script refuses to execute inside Cloud Functions / Cloud Run environments.

## 3. Firestore Catch-All Rule Audit & Default-Deny Migration Plan

`firebase/firestore.rules` still contains a legacy catch-all rule (`match /{collection}/{document=**}`) for unmigrated collections:
- `allow read: if !(collection in [...]);` (allows **unauthenticated** reads on any unlisted collection!)
- `allow write: if request.auth != null && !(collection in [...]);` (allows any signed-in user, including anonymous/unverified users, to write to any unlisted collection!)

`SkillTreeSuggestions` is explicitly included in the exclusion list so the explicit `SkillTreeSuggestions` and `AuditEvents` rules cannot be bypassed.

### Collections Currently Dependent on the Catch-All Rule

1. **`RiderProfiles/{email}/tokens/{tokenId}`** (FCM device tokens)
   - **Used by**: `lib/Utilities/notifications/fcm_service.dart`, `functions/index.js`, `functions/account_deletion.js`.
   - **Current exposure**: High — any client can read or overwrite another user's FCM tokens via the catch-all rule.
   - **Target rule**: Allow `read, write` only when `verifiedEmailIs(email)` (plus existing Cloud Functions / Admin SDK access, which bypasses rules).
   - **Required regression tests**: Verified owner can register/delete their own token; other verified users, unverified users, and guests are denied read/write.
2. **`Categories` & `Sub_Categories`** (legacy resource taxonomy)
   - **Used by**: `packages/database_repository/lib/src/categoryy_repository.dart`, `packages/database_repository/lib/src/sub_category_repository.dart`.
   - **Current exposure**: Medium — any authenticated user (including unverified/guest) can overwrite or delete categories.
   - **Target rule**: `allow read: if true;` (or `verifiedAuth()` if authenticated-only), `allow write: if isVerifiedEditor() || isAdmin();`.
   - **Required regression tests**: Public/authenticated read succeeds; ordinary/unverified/guest writes fail; `editor` or `admin` writes succeed.
3. **`Conversations` & `Conversations/{convId}/Messages`** (legacy messaging)
   - **Used by**: `packages/database_repository/lib/src/messages_repository.dart`, `functions/index.js`, `functions/backfill_requests.js`.
   - **Current exposure**: High — any unauthenticated reader can read legacy private messages, and any authenticated user can write/tamper with any conversation.
   - **Target rule**: Participant-scoped access (`verifiedAuth()` + participant UID/email membership in `resource.data.parties` / `participants`), or `allow write: if false;` once legacy messaging is fully retired.
   - **Required regression tests**: Participants can read/write their conversation; non-participants and guests are denied.

### Safe Migration Sequence to Default-Deny
1. Add explicit rules and Firestore emulator tests for `RiderProfiles/{email}/tokens/{tokenId}`, `Categories`, `Sub_Categories`, and `Conversations`/`Messages`.
2. Audit production Firestore usage metrics for any unexpected collection reads/writes.
3. Replace `match /{collection}/{document=**}` with `allow read, write: if false;`.

## 4. Legacy Editor Authorization Audit & Migration

| Mechanism | Scope | What it actually authorizes | Notes |
| --- | --- | --- | --- |
| `editor: true` custom claim | Client + Firestore | UI edit controls AND backend writes to `Skills`, `Levels`, `SkillFamilies`, `SkillsV2`, and `Resources` (`isVerifiedEditor()`). | Authoritative source of truth. |
| `AuthorizedEmails.emails` (`lib/Utilities/Constants/string_constants.dart`) | Client UI only | Opens `CreateSkillDialog` (`canEditSkill`) and `Resource` edit UI (`canEditResource`). | Does **not** authorize Firestore writes to `Skills`/`SkillsV2`/`SkillFamilies`. |
| `RiderProfile.editor` | Client UI only | Shows `SkillTreeAppBarOverFlowMenu` edit toggle and `UpdateResourceSkills` dialog. | Blocked from client self-modification in `firestore.rules`; does **not** grant backend writes or Administration access. |

### Migration Sequence Before Removing Legacy Checks
1. Grant the `editor: true` custom claim explicitly (via `tool/grant_admin_claim.js --uid <UID> --grant editor --confirm --allow-production`) to each legitimate editor account currently relying on `AuthorizedEmails` or `RiderProfile.editor`.
2. Confirm affected users refresh their ID tokens.
3. Remove `AuthorizedEmails.emails` and `RiderProfile.editor` fallbacks from `AppCubit`, `SkillTreeAppBarOverFlowMenu`, and `UpdateResourceSkills` in a dedicated cleanup PR.

## 5. Production Migration & Deployment Steps (Not Executed)

When ready to deploy Phase 2 to production:
1. Deploy updated Firestore rules:
   ```bash
   firebase deploy --only firestore:rules --project <PRODUCTION_PROJECT_ID>
   ```
2. Inspect the target administrator UID (dry-run):
   ```bash
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json \
     node tool/grant_admin_claim.js --uid <ADMIN_UID> --grant admin
   ```
3. Grant the `admin` (and optionally `editor`) claim explicitly:
   ```bash
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json \
     node tool/grant_admin_claim.js --uid <ADMIN_UID> --grant admin --confirm --allow-production
   ```
4. Have the operator sign out/in (or trigger `refreshUserRoles()`) and verify `isAdmin == true` and `canAccessAdministration == true`.
5. Grant `moderator` or `editor` claims to additional trusted staff using the same explicit `--uid` workflow.
