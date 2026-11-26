# Dictionary foundation

## Scope and reused infrastructure

Read EQUESTRIAN_DICTIONARY_GUIDING_PRINCIPLES.md before editorial work.

The Dictionary uses the existing GoRouter configuration, AppCubit role/session state, midnight-teal AppSurfaceCard and AppScaffoldBackdrop, glass dialog routes, native-share/copy-link helper, Firebase callable HTTP protocol, verified administrator custom claim, private suggestion/audit pattern, and safePublicContributorName consent sanitizer. Skill Tree submission validation remains specific to curriculum. Dictionary submissions have their own schema because guests are welcome.

Public routes are /Dictionary and /Dictionary/:termSlug. /DictionaryReview is administrator-only. A direct public URL does not require login. Discovery is through Guest Welcome, the signed-in profile drawer, Skill Tree header, Resources overflow, and the Dictionary action beside Resources search. There is no fourth main navigation tab.

## Data and lifecycle

- DictionaryEntries/{slug} contains only published, whitelisted public fields. Stable id identifies a meaning; slug identifies its URL. Alternate spellings and synonyms belong to that meaning. Different meanings use different stable IDs and slugs.
- DictionaryDrafts/{id} stores the private editable version with editor UID, revision, and update time. Revisions/{revision} stores immutable snapshots.
- DictionarySuggestions/{id} stores proposal, kind, optional target meaning, private authenticated UID, explicit recognition consent, optional approved public name, and review status. AuditEvents stores administrator decisions and private clarification notes.
- DictionaryRateLimits/{dailyHmac} holds a transactional daily counter and expiry. Raw IP addresses and emails are not stored. Configure Firestore TTL on expiresAt before launch.
- DictionaryPublic/catalogue marks initialization. Before initialization both Flutter and sharePreview use the version-controlled public starter collection. First authorized publication initializes remaining starter entries atomically. Once initialized, an empty live catalogue is respected. A failed live read shows a retry state.

Fields include term, definition, explanation, synonyms, categories, usage, regionalUsage, examples, relatedTerms, skillIds, resourceIds, contextual, media, publication status, revision, and consented attributions. Public validation rejects email addresses and unsafe media URLs. The server never copies arbitrary request fields or private draft metadata into public documents.

The admin form supports new definitions, saved draft recovery, publication, and editing existing definitions. Stable URLs are locked after the first saved draft. Save and publish both require expectedRevision. Conflicting operations fail and request reload. A submitted contribution must be approved before it can be incorporated and credited. Approval alone does not publish.

The starter collection is one JSON file bundled by Flutter and loaded by Functions. It contains 11 independently worded meanings covering 12 starter terms and stable links to existing V2 skills. Empty Resource/media relationships can be supplied editorially as suitable content becomes available. Starter content requires owner editorial review before production release.

## Guest protection and consent

Production submitDictionarySuggestion requires Firebase App Check and permits five submissions per daily keyed IP bucket, plus a per-account bucket for authenticated users. Transactions enforce limits under concurrency. Client-generated random submission IDs make retries idempotent. The endpoint validates lengths, enums, a honeypot field, optional attribution, and the request origin address. Published data contains no contributor UID or private email.

Configure DICTIONARY_RATE_SECRET as a Functions secret and register the web application with Firebase App Check/reCAPTCHA. Web builds need --dart-define=DICTIONARY_RECAPTCHA_SITE_KEY=<public-site-key>. Configure native platform App Check providers for native release. The feature initializes App Check on its first submission request. These are release dependencies; no configuration or deployment was performed by this task.

The demo emulator bypass is limited to FUNCTIONS_EMULATOR. Test data must use project demo-horse-rules. Guest submissions are accepted without creating an account. Opt-in recognition begins unchecked and publishes only a separately supplied safe name. Existing recognition persists through unrelated editorial revisions. Consent withdrawal and moderation of names require an administrator workflow before broader contributor-recognition rollout.

## Discussion and notification interfaces

First milestone clarification is a private AuditEvents record with status needs_clarification. It does not send an email or expose discussions. The UI explicitly explains this limitation.

A later DictionaryDiscussionStore interface should provide listMessages(suggestionId, actor), appendMessage(suggestionId, body, visibility, actor), and recordConsentChange(suggestionId, actor, consent). Server authorization should allow assigned staff and the verified contributor to see contributor-visible messages. Guest follow-up would need a revocable, expiring opaque receipt; never use public suggestion IDs as access credentials.

A later DictionaryNotificationGateway should accept suggestionId, eventId, template, private recipient reference, and locale. Idempotency keys are event IDs. Delivery receipts belong to a private outbox and never change editorial status. Email opt-in and unsubscribe must be explicit. No general-purpose messaging system or notification service was added.

## Contextual learning and actions

DictionaryText and ContextualDictionaryText highlight published unambiguous terms in Dictionary explanations, Skill Tree V2 skill descriptions/criteria, and available in-app Educational Resource detail descriptions/articles. Published terms and approved synonyms are matched at Unicode word boundaries. Longer overlapping phrases win, ambiguous shared names are skipped, individual meanings are highlighted once, and a paragraph is capped at six links. Everyday ambiguous terms (green, collection, poll) are excluded in starter data. Accessible inline buttons open a concise glass definition and a full-entry link without moving the reading position.

AdaptiveAppBarActions measures its bounded action area with LayoutBuilder, preserves higher-priority actions, and moves remaining actions into overflow as width shrinks. Permission filtering happens at the caller. It is used by Dictionary and the existing Administration AppBar. Resources search offers a Dictionary handoff with the current query, without rebuilding the existing Resource search index.

## Share previews

Hosting rewrites /Dictionary and /Dictionary/** to the existing sharePreview function. It serves escaped Open Graph metadata, branding image, canonical link, and a Flutter bootstrap shell. It uses published entries only and returns generic noncached metadata for unpublished or missing meanings. Live social scraper behavior requires an authorized Hosting/Functions release; the handler is exercised locally.

## Content reference checks

The starter prose is original. Background checks used the Extension Horses explanation of the canter and the USDF terminology and half-halt references. The USDF sources describe dressage usage and do not define the sole legitimate training approach.

- [Extension Horses, Horse Canter](https://horses.extension.org/horse-canter/)
- [USDF Glossary of Judging Terms](https://www.usdf.org/EduDocs/Competition/2019Glossary__final9.2018.pdf)
- [USDF half-halt training reference](https://www.usdf.org/EduDocs/Training/Half-Halt_3.pdf)

## Community contributions and educational images

Registered, email-verified community members can submit three types of Dictionary contributions:

1. **Suggest a New Term** (`kind: 'new_term'`): structured fields (`term`, `definition`, categories, synonyms, examples, discipline usage, regional usage, explanation) plus up to 3 optional images.
2. **Suggest an Improvement** (`kind: 'correction'` / `'improvement'`): per-field diffing against the published revision, optional reason notes, and optional images.
3. **Contribute Images** (`kind: 'image_contribution'`): upload 1–3 educational images directly to a Dictionary entry without requiring wording edits.

Signed-out visitors see a clear account prompt with **Create a Free Account** (`/SignIn?mode=register`) and **Sign In** (`/SignIn?mode=login`) actions. Signed-in contributors can review the status of their own submissions and per-image moderation outcomes in **My Contributions**, backed by `DictionaryStore.loadMySuggestions`. Internal admin review notes (`AuditEvents`) and contributor emails remain strictly private.

### Image validation, processing, rights, and storage lifecycle

- **Client processing (`DictionaryImageProcessor`):** Validates magic bytes and file extensions (`PNG`, `JPEG`, `WebP`, max 10 MB), computes SHA-256 checksums to skip duplicate uploads, resizes images exceeding 2048 px while keeping crisp detail for illustrations and diagrams, displays upload progress, supports retries on interrupted uploads, and deletes removed temporary uploads.
- **Rights & opt-in attribution:** Image submissions require explicit confirmation (`rightsConfirmed: true`) that the contributor created or has permission to submit the images, grants non-exclusive display permission without copyright transfer, and understands moderation precedes publication. Public recognition (`recognitionConsent` + `publicName`) defaults unchecked and never exposes email addresses.
- **Private Storage isolation:** Contributors upload only into `dictionary_submissions/{uid}/{submissionId}/{fileName}` with `update: if false`. `submitDictionarySuggestion` enforces verified auth, UID/submission folder ownership, image existence/MIME/size checks, and max 3 images per submission.
- **Partial review & promotion:** Administrators can inspect thumbnails, classify images (`illustrative`, `photograph`, `diagram`), edit captions and explanations, approve or reject individual images independently alongside wording (`partially_approved`), preserve existing published images when incorporating, set the primary hero image, and publish. Rejected submission files are deleted on review, approved submission images are promoted to immutable `dictionary_public/{entryId}/{uuid}.{ext}` URLs on publish, remaining temp submission files are cleaned up after promotion, and `cleanupAbandonedDraftMedia` sweeps stale orphaned draft and submission files.
- **Public multi-image viewer:** Published entries display the primary image in `HeroHeader` and secondary images in `DictionaryMediaGallery`, opening the immersive `PhotoView` modal (`showProfilePhoto`) with captions, image type labels, educational explanations, and consented attribution.

## Local checks and release checklist

Flutter tests are in `test/dictionary/` (`dictionary_test.dart`, `dictionary_change_tracking_test.dart`, `dictionary_image_upload_test.dart`, `dictionary_hero_header_test.dart`, `dictionary_dynamic_refresh_test.dart`, and `dictionary_community_contributions_test.dart`). Functions tests are in `functions/test/dictionary.test.js`. Firestore security rule tests are in `firebase/firestore.rules.test.cjs`. Real transaction concurrency is tested by `functions/test/dictionary_emulator.js`, which refuses to run without the emulator environment.

Before production release (not executed by this task), deploy:
1. Cloud Functions (`submitDictionarySuggestion`, `editDictionary`, `sharePreview`)
2. Firestore security rules (`firebase/firestore.rules`)
3. Firebase Storage security rules (`firebase/storage.rules`)
4. Flutter web/app Hosting build (with `DICTIONARY_RECAPTCHA_SITE_KEY` / App Check configured)

Run focused Flutter tests, Flutter analysis, Functions lint/unit tests, then the Auth/Firestore emulator suites. Existing unfinished Logbook work and baseline navigation failures are outside this milestone.

Before release, obtain owner approval, review the starter wording, configure App Check and the rate-limit secret/TTL, verify the Firebase target, review rules and public field boundaries, build the normal application, test deep links on staging, and prepare a rollback of Hosting/Functions/rules. Drafts and submissions must survive a rollback. No production writes or deployment are part of this milestone.
