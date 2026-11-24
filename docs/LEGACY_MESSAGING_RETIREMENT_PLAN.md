# Legacy Messaging Retirement Plan

## 1. Current Production State (Read-Only Inventory)

Verified against `horse-and-riders-compani-d2bd4` without modifying data:

- **Collections**: `Conversations` and `Conversations/{convId}/Messages`
- **Volume**: `4` conversations and `8` total messages (`4` legacy request messages, `4` chat messages)
- **Personally Identifiable Fields**:
  - `Conversations`: `createdBy`, `lastEditBy`, `parties`, `partiesIds`, `recentMessage`
  - `Messages`: `sender`, `senderId`, `senderProfilePicUrl`, `recipients`, `message`, `subject`, `requestItem`

## 2. Client & Backend Cutover

- Client connection/transfer requests now use `FirestoreConnectionRequestStore` (`Requests` + `CoachingConnections`) by default instead of writing to `Conversations`/`Messages`.
- `SupportMessageDialog` no longer writes to `Conversations`/`Messages` and opens email support (`mailto:horseandriderscompanion@gmail.com`) instead.
- `onMessageCreated` is removed from `functions/index.js`; push notifications for training/transfer requests continue through `onRequestCreated` (`Requests/{requestId}`).
- Account deletion (`requestAccountDeletion`) now includes the mandatory `legacyMessaging` step:
  - Conversations where no active participant remains are deleted along with their `Messages` subcollection.
  - Shared conversations with a surviving active participant anonymize all departing-user identifiers (`sender`, `senderId`, `senderProfilePicUrl`, `parties`, `partiesIds`, `createdBy`, `lastEditBy`, `recipients`, `requestItem`) and redact departing-user chat bodies without deleting another user's messages.

## 3. Staged Data Retirement (Dry-Run First; Requires Explicit Approval)

Because legacy conversations may contain historical request context or messages authored by other users, production documents are not bulk-deleted automatically.

When ready to execute full retirement:

1. **Create a Firestore backup** (`gcloud firestore export ... --project horse-and-riders-compani-d2bd4`).
2. **Run requests backfill dry-run** (and execute if `wouldCreate > 0`):
   ```bash
   node functions/backfill_requests.js --project horse-and-riders-compani-d2bd4
   ```
3. **Run legacy messaging retirement dry-run**:
   ```bash
   node functions/retire_legacy_messaging.js --project horse-and-riders-compani-d2bd4 --mode anonymize
   ```
4. **After explicit approval**, execute anonymization or post-verification purge:
   ```bash
   node functions/retire_legacy_messaging.js --project horse-and-riders-compani-d2bd4 --mode anonymize --execute --confirm-production
   # Optional full purge (refuses if any unmigrated pending requests remain):
   node functions/retire_legacy_messaging.js --project horse-and-riders-compani-d2bd4 --mode purge --execute --confirm-production
   ```
5. **Lock client reads** by copying `firebase/messaging-retirement.rules` rules for `Conversations`/`Messages` into `firebase/firestore.rules` and deploying rules + removing `onMessageCreated` in production (`firebase functions:delete onMessageCreated --region us-central1 --project horse-and-riders-compani-d2bd4`).
