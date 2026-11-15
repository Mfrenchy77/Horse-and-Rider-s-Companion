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

## 3. Firestore Catch-All Rule Audit & Safe Replacement Plan

`firebase/firestore.rules` still contains a legacy catch-all rule (`match /{collection}/{document=**}`) for unmigrated collections. `SkillTreeSuggestions` has been added to its exclusion list so the explicit `SkillTreeSuggestions` and `AuditEvents` rules cannot be bypassed.

Codebase references that currently rely on the catch-all rule:
1. `RiderProfiles/{email}/tokens/{tokenId}` — FCM device tokens (`lib/Services/fcm_service.dart`, cleaned up by `functions/account_deletion.js`).
2. `Categories` — legacy resource categories (`packages/database_repository/lib/src/categoryy_repository.dart`).
3. `Sub_Categories` — legacy resource subcategories (`packages/database_repository/lib/src/sub_category_repository.dart`).
4. `Conversations` and `Conversations/{convId}/Messages` — legacy messaging (`packages/database_repository/lib/src/messages_repository.dart`).

### Safe Migration Path Before Enabling Default-Deny
1. Add explicit rules for `RiderProfiles/{email}/tokens/{tokenId}` (owner-only read/write via verified email or UID).
2. Add explicit rules for `Categories` and `Sub_Categories` (public or authenticated read, `isVerifiedEditor()` / `isAdmin()` write).
3. Add explicit participant-scoped rules (or deprecation freeze) for `Conversations` and `Conversations/{convId}/Messages`.
4. Verify with Firestore Rules Emulator tests and check production Firestore usage metrics for any unexpected collection reads/writes.
5. Replace `match /{collection}/{document=**}` with `allow read, write: if false;`.

## 4. Production Migration & Deployment Steps (Not Executed)

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
