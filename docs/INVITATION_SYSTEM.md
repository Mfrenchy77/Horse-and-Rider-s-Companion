# Horse & Rider's Companion — Invitation & Student Onboarding System

This document describes the architecture, security model, user workflows, configuration, and deployment/verification steps for the Invitation & Student Onboarding System.

---

## 1. Overview & Architecture

The invitation system supports organic growth while keeping **CoachingConnections** and **Requests** as the single source of truth for instructor–student relationships:

- **Two invitation categories:**
  - `general` (`Invite Someone`): available to any signed-in user with a verified email and Rider profile. Reusable up to 25 times (30-day default expiry). Welcomes recipients after registration/sign-in without automatically creating coaching relationships.
  - `student_connection` (`Invite Student`): restricted server-side to verified instructors/trainers (`Rider_Profile.isTrainer === true`). Single-use link (14-day default expiry) that prepares a **pending** coaching connection request after recipient signup/sign-in and requires explicit **Accept** or **Decline** consent.
- **Database independence (`packages/database_repository`):**
  - Pure-Dart models in `packages/database_repository/lib/src/models/invitation.dart`.
  - Backend-neutral `InvitationStore` interface and `InMemoryInvitationStore` in `packages/database_repository/lib/src/invitation_store.dart`.
  - Cloud Functions callable adapter `CloudInvitationStore` in `packages/database_repository/lib/src/cloud_invitation_store.dart`.
  - Flutter UI widgets in `lib/MainPages/Invitations/` contain zero direct Firebase or Firestore SDK imports.

---

## 2. Invitation Creation & Sharing

1. Signed-in verified users can open **Invite Share Dialog** from:
   - Rider Profile drawer (`Invite Student` when `isTrainer == true`, `Invite Someone`, `Invitations`)
   - Rider Profile overflow menu (`Invite Student` when `isTrainer == true`, `Invite Someone`, `Manage Invitations`)
   - **Invite student** action button in `RiderActionBar` on the instructor's own profile
2. Selecting **Create Link** calls `createInvitation` on Cloud Functions, which generates 192 bits of entropy (`crypto.randomBytes(24).toString('base64url')`), stores only its SHA-256 `tokenHash`, and returns the canonical share URL:
   - Production default: `https://horseandriderscompanion.com/invite/{token}` (configurable via `--dart-define=INVITE_BASE_URL=...`; local dev/emulator & Hosting preview origins are preserved automatically).
3. Sharing uses `share_helper.dart` (`tryNativeWebShare` via Web Share API when supported, supporting WhatsApp, SMS, email, and installed OS share targets, with clipboard **Copy Link** / **Copy Message** fallbacks).

---

## 3. Authentication & Context Preservation Flow

1. Unauthenticated visitors opening `/invite/{token}` view `InvitePage`:
   - `getInvitationPreview` resolves safe public inviter metadata (`inviterDisplayName`, sanitized HTTPS `inviterPhotoUrl`, `inviterIsTrainer`, optional `inviterLocation`, `personalMessage`, and derived availability).
   - No private emails or account existence indicators are returned for invalid/unknown/expired/revoked links.
2. When `/invite/{token}` loads, `PendingInvitationStorage` persists the token in `SharedPrefs` (with 7-day auto-expiry).
3. Tapping **Create Account** or **Sign In** passes `?invite={token}&mode=register|login` to `AuthPage`, which also persists the token and renders a banner reminding the user their invitation will resume.
4. Context survives:
   - Email/password registration and existing-account sign-in (`AuthView` routes non-guest logins back to `/invite/{token}`)
   - Google Sign-In and external OAuth redirects
   - Email verification wait (if signed in while unverified, `InvitePage` displays verification controls and automatically triggers redemption once `user.emailVerified` flips to `true`)
   - Page refresh / browser restart (`NavigationView` restores pending tokens for verified users once per session using loop guards in `PendingInvitationStorage`)
5. Once redeemed or terminal (`invalid`, `expired`, `revoked`, `used`, self-invite), `PendingInvitationStorage.clearToken()` clears the stored token to avoid stale redirects or duplicate prompts.

---

## 4. Student Connection Redemption & Explicit Acceptance

When a verified authenticated recipient redeems a `student_connection` invitation (`redeemInvitation`):

1. Validates the token, expiry, revocation status, single-use claim state, and prevents self-invitations.
2. Resolves the instructor exclusively from the trusted `Invitations` document (`inviterUid`, `inviterEmail`, `Rider_Profile`). URL query parameters hold no authority.
3. Bootstraps a minimal `Rider_Profile` for brand-new users if needed (`isTrainer: false`, `editor: false`, zero granted `instructorUids`).
4. Handles edge cases safely:
   - Existing `accepted` `CoachingConnections` record -> returns `already_connected`.
   - Existing `pending` `CoachingConnections` / `Requests` -> returns `pending_connection_existing` and presents the decision card (normalizing direction so the recipient can accept/decline).
   - Fresh or previously declined/cancelled relationship -> writes a **pending** `CoachingConnections/{sha256(['rider', learnerUid, coachUid, null])}` and matching **pending** `Requests/{connectionId}` (never auto-accepted, never modifying `instructorUids`).
5. On `InvitePage`, the recipient must explicitly click **Accept Connection** or **Decline** (`coachingConnection` callable). Only acceptance transitions `CoachingConnections.status` to `'accepted'`, grants `coachUid` into `Rider_Profile.instructorUids`, marks `Requests.status = 'accepted'`, and updates `Invitations.connectionStatus = 'accepted'`.
6. Declining via `InvitePage` or `RequestsBadgeButton` (`AppCubit.denyConnectionRequest`) transitions both `CoachingConnections`, `Requests`, and `Invitations` to declined/cancelled states.

---

## 5. Firestore Collections, Security Rules & Safeguards

### Collections (Server-Only)

- **`Invitations/{invitationId}`**: `id`, `tokenHash`, `inviterUid`, `inviterEmail`, `inviterProfileId`, `inviterDisplayName`, `inviterPhotoUrl`, `inviterIsTrainer`, `inviterLocation`, `type`, `relationshipRole`, `personalMessage`, `status`, `maxUses`, `redemptionCount`, `acceptedCount`, `declinedCount`, `claimedByUid`, `recipientDisplayName` (populated ONLY for student invites), `connectionId`, `connectionStatus`, `createdAt`, `updatedAt`, `expiresAt`, `revokedAt`.
- **`Invitations/{invitationId}/Redemptions/{recipientUid}`**: per-user redemption idempotency marker (`recipientUid`, `type`, `connectionId`, `redeemedAt`).
- **`InvitationTokens/{tokenHash}`**: SHA-256 hash lookup pointing to `{ invitationId, createdAt }`.
- **`InvitationRateLimits/{limitId}`**: rolling 24-hour rate limits (`create_{uid}` capped at **20/24h**, `redeem_{uid}` capped at **30/24h**).

### Firestore Rules (`firebase/firestore.rules`)

Direct client `read` and `write` access is denied (`allow read, write: if false;`) on `/Invitations/**`, `/InvitationTokens/{tokenHash}`, and `/InvitationRateLimits/{limitId}`. All operations run inside Cloud Functions Admin SDK transactions.

---

## 6. Configuration & Deployment Requirements

1. **Firestore Security Rules:** deploy updated `firebase/firestore.rules`.
2. **Cloud Functions:** deploy `createInvitation`, `getInvitationPreview`, `redeemInvitation`, `listMyInvitations`, `revokeInvitation`, `coachingConnection`, and `sharePreview`.
3. **Firebase Hosting:** deploy updated `firebase.json` (which routes `/invite/**` to `sharePreview` for Open Graph / WhatsApp / social link previews and falls back to `/index.html` for Flutter web deep links) and ensure custom domain `horseandriderscompanion.com` points to Firebase Hosting.
4. **Optional Flutter build define:** `--dart-define=INVITE_BASE_URL=https://horseandriderscompanion.com` (this is already the default when not running on localhost or a Firebase Hosting preview channel).

---

## 7. Manual Production Verification Checklist

1. **Instructor creates & shares student invite:**
   - Sign in as a trainer profile -> click **Invite student** -> add optional note -> **Create Link**.
   - Verify URL begins with `https://horseandriderscompanion.com/invite/`.
   - Share to WhatsApp/SMS/Notes and confirm Open Graph link preview renders instructor name and welcome text without exposing emails.
2. **Unauthenticated new-user onboarding (Student Invite):**
   - Open link in an incognito browser -> verify public preview loads cleanly on mobile & desktop showing **Create Account** / **Sign In** and acceptance notice.
   - Register a new account -> confirm email verification waits smoothly without losing the invite -> verify email -> confirm automatic return to `/invite/{token}` showing **Accept Connection** and **Decline** (and verify profile shows no active instructor before clicking Accept).
   - Click **Accept Connection** -> confirm relationship becomes active in **Connections and requests** and inviter's **Manage Invitations** shows `Accepted`.
3. **Decline & Revoke & General Invite:**
   - Test declining a second student invite -> verify no instructor relationship is added.
   - Test opening an invitation while signed out, signing into an existing verified account, and refreshing the page -> confirm idempotent recovery with zero redirect loops.
   - Test a **General Invitation** (`Invite Someone`) with a non-trainer user -> confirm onboarding works and creates zero connection requests, and **Manage Invitations** never reveals recipient identity.
   - Test **Revoke** on an active/pending invite -> confirm link renders **Invitation Revoked** cleanly.
