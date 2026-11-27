# Release & Rollback Runbook

Target Firebase Project: `horse-and-riders-compani-d2bd4`
Production URL: `https://horse-and-riders-compani-d2bd4.web.app`
Pre-Optimization Baseline Commit: `d1d6c77c3bf5d22fb93d91e7bb019835d985558e` (`1365c21~1`)

---

## 1. Staged Rollout Order (Do Not Reorder)

Deploy components strictly in this sequence after explicit owner authorization:

1. **`firestore:rules,storage`**
   `firebase deploy --project horse-and-riders-compani-d2bd4 --only firestore:rules,storage`
2. **`functions`**
   `firebase deploy --project horse-and-riders-compani-d2bd4 --only functions`
3. **`hosting`**
   `flutter build web --release --wasm --no-pub --dart-define-from-file=web_build_config.json && firebase deploy --project horse-and-riders-compani-d2bd4 --only hosting`

---

## 2. Old vs. New Client Compatibility During Transition

| Interface | Old Client (`d1d6c77`) vs. New Rules / Functions | New Client (`HEAD`) vs. Old Rules / Functions | Mitigation / Timing |
|---|---|---|---|
| **New Storage UID paths** (`/Riders_Photo/{uid}/{file}`, `/Horses_Photo/{uid}/{id}`, `/resources/pdfs/users/{uid}/{id}/{file}`) | N/A | **Fails `403`** until new `storage.rules` is deployed (`d1d6c77` lacks these match blocks). | Deploy `storage` **before** `hosting`. |
| **Legacy Storage paths** (`/Riders_Photo/{id}`, `/Horses_Photo/{id}`, `/resources/pdfs/{id}/{file}`) | Public `GET` continues working. Existing profile owners (even legacy docs lacking `ownerUid`) can upload/delete **when `contentType` metadata is `image/*` or `application/pdf`**. Unrefreshed old tabs calling `putData(bytes)` without `SettableMetadata(contentType)` (`application/octet-stream`), or uploading PDFs before `Resources/{id}` exists, receive `403`. | New client always sends explicit `contentType` and prefers UID-scoped paths. | Keep `rules -> functions -> hosting` window short; reload browser tab on `unauthorized` during cutover; if rolling back `hosting` to `d1d6c77`, roll back `storage` too. |
| **`previewMeta` & `fetchReadable`** | Unrefreshed old tabs omit `Authorization: Bearer <idToken>` and receive `401 Unauthorized`. `resolveImage` & `sharePreview` stay public and backward compatible. | New client attaches verified ID token; old functions simply ignore the extra header. | Prompt user reload or complete `hosting` deploy promptly after `functions`. |
| **`DictionaryPublic/catalogue` manifest** | Old client queries `DictionaryEntries` directly (unaffected). | `FirebaseDictionaryStore` handles `403` before initialization safely and falls back until seeded/published. | Fully compatible in both orders. |
| **Skill Tree V2 `SkillVerificationEvents`** | N/A (read-only/admin managed). | Updated [firestore.rules](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/firestore.rules) authorizes active accepted instructors (`instructorUids`) on `list` queries (`orderBy('at', descending: true).limit(20)`). | Deploy `firestore:rules` before smoke-testing coach verification timelines. |

---

## 3. Pre-Deploy Snapshot Capture (Run Immediately Before Deploying)

Before deploying to `hosting`, capture the currently live Hosting version ID so `hosting:clone` can roll back instantaneously:

1. Optional pre-deploy snapshot channel (saves current live release for 30 days):
   ```bash
   firebase hosting:clone \
     horse-and-riders-compani-d2bd4:live \
     horse-and-riders-compani-d2bd4:pre-release-backup \
     --project horse-and-riders-compani-d2bd4
   ```
   Then verify in Firebase Console → Hosting → Release history (live version ID) and note `<PRE_DEPLOY_VERSION_ID>`.

---

## 4. Rollback Artifacts & Commands

Local immutable rollback artifacts live in `tool/rollback/`:

- [firestore.rules](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/tool/rollback/firestore.rules) — byte-identical snapshot of `d1d6c77:firebase/firestore.rules`
- [storage.rules](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/tool/rollback/storage.rules) — byte-identical snapshot of `d1d6c77:firebase/storage.rules`
- [firebase.rollback.json](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/tool/rollback/firebase.rollback.json) — standalone config referencing only the rollback rules
- [rollback_helper.sh](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/tool/rollback/rollback_helper.sh) — dry-run by default; executes only when passed BOTH `--execute` and `--confirm-production`

### Per-Component Rollback Order (Reverse of Deploy: Hosting → Functions → Rules)

1. **Hosting only** (using captured channel or version ID):
   ```bash
   ./tool/rollback/rollback_helper.sh --component hosting --source-channel pre-release-backup --execute --confirm-production
   # or with an explicit version ID:
   ./tool/rollback/rollback_helper.sh --component hosting --hosting-version <PRE_DEPLOY_VERSION_ID> --execute --confirm-production
   ```
   *(Or click Roll back in Firebase Console → Hosting → Release history.)*
   **Important:** If rolling Hosting back to `d1d6c77` (`pre-268c792`), also roll back Storage rules (`--component rules`) so older clients that omit Storage `contentType` metadata are not blocked.

2. **Cloud Functions only** (deploys `functions/` from a clean detached git worktree at `d1d6c77` without modifying `main`):
   ```bash
   ./tool/rollback/rollback_helper.sh --component functions --execute --confirm-production
   ```

3. **Security Rules (`firestore:rules` + `storage`) only**:
   ```bash
   ./tool/rollback/rollback_helper.sh --component rules --execute --confirm-production
   ```

4. **Full stack rollback**:
   ```bash
   ./tool/rollback/rollback_helper.sh --component all --source-channel pre-release-backup --execute --confirm-production
   ```
