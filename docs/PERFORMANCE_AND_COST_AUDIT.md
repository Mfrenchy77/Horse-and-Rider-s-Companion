# Horse & Rider's Companion — Comprehensive Performance, Scalability & Firebase Cost Audit

**Audit Date:** 2026-11-26  
**Scope:** End-to-end read-only architecture, Flutter/Web UI, Firestore, Firebase Storage, Cloud Functions, 9 Key User Journeys, Database Independence, and 100 / 1,000 / 10,000 DAU cost modeling.  
**Repository Baseline:** Local `main` (`958f1c8`). No application code, Cloud Functions, rules, or production data were altered during this audit.

---

## 1. Executive Summary

Horse & Rider's Companion already has strong architectural building blocks: clean separation of public vs. private profiles (`Public_Rider_Profile` / `Public_Horse_Profile`), versioned Skill Tree 2.0 curriculum snapshots, repository interfaces in `packages/database_repository`, an App Check–protected Dictionary contribution pipeline, and bounded preview caching in `CommunityPendingImage`.

However, the audit identified **two urgent security/abuse exposures** and **four major scalability & UX multipliers** that will degrade user experience and cause Firebase bills to scale nonlinearly as daily active usage and content grow:

1. **Critical Abuse, SSRF & Storage Rule Exposures (`P0`):**
   - `previewMeta`, `fetchReadable`, and `resolveImage` ([functions/index.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/index.js#L509-L677)) are public unauthenticated `onRequest` HTTP endpoints with `cors({origin: true})`, no App Check, no rate limiting, no scheme/private-IP SSRF guard, and (for `previewMeta` / `fetchReadable`) no fetch timeout or body-size limit. `sharePreview` ([functions/share_preview.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/share_preview.js#L25-L33)) also trusts `X-Forwarded-Host` before fetching `${origin}/index.html`.
   - `firebase/storage.rules` ([storage.rules](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/storage.rules#L21-L40)) lets any authenticated user overwrite or delete **any** user's `Riders_Photo/{riderId}`, `Horses_Photo/{horseId}`, or `resources/pdfs/{resourceId}/{fileName}` with **zero file-size limit** and **zero content-type validation**.

2. **Quadratic & Redundant Firestore Read Amplification (`P0`/`P1`):**
   - **Startup legacy `Skills` listener:** `AppCubit` ([app_cubit.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/Cubit/app_cubit.dart#L84)) opens an unbounded `.snapshots()` stream on the entire legacy `Skills` collection for every guest and user on startup, even though Skill Tree 2.0 is the default.
   - **Unbounded `Resources` stream & deep diff:** Once the Resources tab is opened, `AppCubit.loadResourcesIfNeeded` ([app_cubit.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/Cubit/app_cubit.dart#L1708)) streams the entire `Resources` collection (with embedded comments and voter arrays) for the rest of the session.
   - **Forced `Source.server` Dictionary reloads:** `FirebaseDictionaryStore.loadPublishedEntries` ([firebase_dictionary_store.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/firebase_dictionary_store.dart#L59-L86)) forces `Source.server`, and `DictionaryPage` ([dictionary_page.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_page.dart#L41-L51)) bypasses `DictionaryRepository.cachedEntries()`, repeating `1 + N_entries` server reads on every `/Dictionary` and `/Dictionary/:slug` navigation (plus **3× redundant reloads** in `DictionaryAdminPage`).
   - **Skill Tree 2.0 startup & save bursts:** Unguarded `syncProfile()` inside `SkillTreeV2View.build()` ([skill_tree_v2_view.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/skill_tree_v2_view.dart#L1267)), 5 sequential init awaits, redundant `active` doc checks, full 3-subcollection reloads on every self-assessment tap, and offstage `ProfileSkills` cascading re-fetches.
   - **Unconfigured Web offline persistence:** `cloud_firestore` Web persistence defaults to off, repeating full cold-load reads on every browser refresh.

3. **Flutter Web / CanvasKit UI Jank & Heavy Startup Bundle (`P1`):**
   - **Monolithic 57-field `AppState`:** Watchers without `buildWhen`/`select` appear at **63 sites** (including **4 nested unfiltered `BlocBuilder`s inside every `ResourcesItem` card** and mounted offstage `StatefulShellRoute` tabs).
   - **Nested full-viewport `BackdropFilter` passes:** `_GlassModalBarrier` ([app_dialog.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/Animations/app_dialog.dart#L118-L139)) animates **two nested `BackdropFilter`s (`sigma: 24 × 2`)** per frame on every dialog/sheet transition; `PersonalizedLogbookBackdrop` ([personalized_logbook_backdrop.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/CommonWidgets/personalized_logbook_backdrop.dart#L68-L100)) permanently stacks **two `BackdropFilter(sigma: 28)`** layers behind scrollable logbooks.
   - **Regex & decode hot spots in `build()`:** `DictionaryPage._detail` creates 4 fresh `.toList()` copies per `build()`, defeating the `Expando` regex cache and recompiling 352+ Unicode RegExps ([dictionary_page.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_page.dart#L624-L660)); `ResourceInfoBar` runs `jsonDecode` + Quill `Document.fromJson` on every article card rebuild; `SmartImage` double-multiplies DPR on `wsrv.nl` (`&w=targetWidth&dpr=dpr`), sets `cacheWidth: null` on Web, and defaults to `preferDirectFirst: true`.
   - **Bundle & asset bloat:** `main.dart.js` is **6.4 MiB (6.67 MB)** unsplit (`0` `deferred as` imports, served `no-cache`); `web/index.html` imports **4 unused Firebase v8.10.1 JS SDKs**; **`3.41 MB` (68%)** of `assets/` is completely unused (`error_color.png`, `Error.png`, duplicate logos); `web/images/dictionary-share-default.png` is **2.96 MB**.

4. **Cloud Functions Cold-Start Tax, Amplification & Storage Orphan Leaks (`P1`):**
   - **Global `jsdom` + `cheerio` load:** Top-level `require()` in [functions/index.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/index.js#L7-L9) adds **~297 ms** and **+56.1 MB RSS** (`130.5 MB` baseline vs. `256 MiB` container) to **all 23 Cloud Functions** even though only 1–3 link-scraping functions use them.
   - **`requestAccountDeletion` timeout cliff:** Scans the entire `Resources` collection plus `3 × N_resources` rating docs sequentially inside a default **60s** timeout ([account_deletion.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/account_deletion.js#L746-L808)).
   - **Unconditional public mirror rewrites & triple link preview:** Both profile sync triggers rewrite `Public_*` docs on private-only edits; Resource URL paste makes 3 sequential HTTP calls (`previewMeta` → `fetchReadable` → `resolveImage`).
   - **Storage bandwidth & orphans:** Only `dictionary_public/` sets `Cache-Control`; Rider/Horse/Cover uploads have no dimension cap or thumbnails; community dialog `dispose()` cleanup fails silently because `context.read` throws inside `dispose()`; `AddHorseDialogCubit` uploads to `DateTime.now()` then saves under `ViewUtils.createId()`; `cleanupAbandonedDraftMedia` is never wired or scheduled.

5. **Database Independence Status (`P2`):**
   - Core domain models and repository interfaces (`packages/database_repository`) are mostly clean, but **12 files in `lib/` import Firebase directly** (4 of them non-composition UI/facade files: `app.dart`, `profile_skills.dart`, `skill_tree_v2_view.dart`, `dictionary_repository.dart`, plus `connection_repository.dart` and `fcm_service.dart`), 20+ UI/Cubit files instantiate concrete Firebase stores as defaults, and `packages/database_repository` couples 5 Firebase SDKs + 2 legacy models (`mesage.dart`, `group.dart`) into a single package.

---

## 2. Baseline Measurements & Methodology

All findings below strictly distinguish between three evidence tiers:
- **Measured:** Directly observed from filesystem sizes, existing `build/web` artifacts, static AST/grep counts, or local Node v22.23.4 benchmark runs.
- **Code-Traced:** Exact control flow, Firestore queries, listeners, Storage RPCs, and rules counted by inspecting source files.
- **Estimated / Suspected:** Projected latency, frame drops, traffic multipliers, and monthly Firebase costs requiring live production telemetry to calibrate.

### 2.1 Measured Codebase, Asset & Build Footprint

| Category | Measured Value | Notes / Key Files |
|---|---|---|
| Dart source files (`lib/` + `packages/`) | **423 files** (`3.2 MB` `lib/`, `936 KB` `packages/`) | 0 `deferred as` lazy imports |
| Cloud Functions JS files (`functions/`, excl. `node_modules`) | **40 files** (`157 MB` incl. `node_modules`) | 23 exported Gen2 functions; 24 test files + 4 CLI scripts inside `functions/` not ignored by `firebase.json` |
| Bundled `assets/` (`pubspec.yaml:83`) | **5.0 MB** across 25 PNG files | **3.41 MB (68%) unused** (`assets/error_color.png` `2.1 MB`, `Error.png` `848 KB`, `horse_logo_and_text_dark copy.png` `288 KB`, `horse_logo_and_text_002.png` `84 KB`, etc.) |
| Active oversized images | `web/images/dictionary-share-default.png`: **2.96 MB**; `assets/horse_background.png`: **456.2 KB**; `assets/spring.png`: **276.6 KB** (`1160×2203` rendered at `24×24`) | Heavy decode & OG crawler risk |
| Bundled JSON curricula & seed | `curriculum/v2/`: **260 KB** (8 files; raw curriculum `218.2 KB`); `functions/dictionary_seed.json`: **44.8 KB** | 32 families, 72 skills, 28 starter dictionary entries (88 term+synonym patterns) |
| Web build output (`build/web`) | **54 MB** total on disk; `main.dart.js`: **6.67 MB (6.4 MiB)**; `canvaskit.wasm`: **7.28 MB**; `assets/NOTICES`: **1.54 MB** | Pre-built local artifact timestamp `2026-11-25`; client fetches one CanvasKit variant + `main.dart.js` (`Cache-Control: no-cache`) |
| Unused `pubspec.yaml` UI packages | **4 packages** (`auto_size_text`, `flutter_network_image`, `image_network`, `shimmer`) + misplaced `flutter_launcher_icons` | 0 imports in `lib/` |
| Static concurrency/listener counts | **34** `.snapshots()` definitions (**5** global); **30** `get()`/`exists()` calls in `firestore.rules`; **63** unfiltered `AppState` watchers; **14** `shrinkWrap: true` lists; **12** `lib/` files importing Firebase | Exact grep & source verification |

### 2.2 Measured Cloud Functions Cold-Start Module Cost (Node v22.23.4)

Measured locally in `functions/` by timing sequential `require()` calls matching [functions/index.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/index.js#L6-L30):

| Top-Level Import | Require Time Delta | RSS Memory Delta | Used By |
|---|---|---|---|
| Baseline Node v22 process | — | `48.9 MB` | All |
| `cors` (`index.js:6`) | `+3.6 ms` | `+1.3 MB` | 3 HTTP functions |
| `firebase-functions/v2/https` + `v2/firestore` (`index.js:10-11`) | `+138.7 ms` | `+23.7 MB` | All 23 functions |
| `firebase-admin` (`index.js:12`) | `+1.2 ms` | `+0.5 MB` | Sub-SDKs lazy |
| `cheerio` (`index.js:9`) | **`+88.9 ms`** | **`+6.4 MB`** | 3 of 23 functions (`previewMeta`, `fetchReadable`, `resolveImage`) |
| `@mozilla/readability` (`index.js:8`) | `+1.8 ms` | `+0.6 MB` | 1 of 23 (`fetchReadable`) |
| **`jsdom`** (`index.js:7`) | **`+206.5 ms`** | **`+49.1 MB`** | **1 of 23 (`fetchReadable`)** |
| **Total process baseline at boot** | **~`+440.7 ms`** | **`130.5 MB` RSS** | **Every single `256 MiB` function starts at ~51% RAM** |

---

## 3. Detailed Audit Findings

### 3.1 Flutter & Web Performance (Phase 2)

#### A. Rebuild Blast Radius (`Critical`)
- **Monolithic `AppState` (57 `props` fields):** [app_state.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/Cubit/app_state.dart#L73-L531) stores auth, rider/horse profiles, nav index, snackbar flags/messages, ads, legacy skills, resources, comments, and connection requests in one `Equatable` state.
- **63 unfiltered subscribers across `lib/`:**
  - `BlocBuilder` / `BlocConsumer<AppCubit, AppState>`: **44 of 60** omit `buildWhen`.
  - `context.watch<AppCubit>()`: **16 sites**.
  - `context.select<AppCubit, AppState>((c) => c.state)` selecting the entire state object: **3 sites** ([horse_profile.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/HorseProfile/horse_profile.dart#L22), [horse_profile_primary_view.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/HorseProfile/Widgets/horse_profile_primary_view.dart#L43), [tutorial_selector_dialog.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Onboarding/tutorial_selector_dialog.dart#L47)); [connection_panel.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/Connections/connection_panel.dart#L38-L40) calls both `context.select` and `context.watch` on adjacent lines.
  - **Highest fan-out:** Each `ResourcesItem` card nests **4 unfiltered `BlocBuilder<AppCubit, AppState>`s** (`ResourcesItem:32` → `ResourceInfoBar:156` → `ResourceRatingButtons:30` → `SaveResourceButton:15`). Every tab switch, snackbar clear, or search keystroke rebuilds **36+ `BlocBuilder`s** on a 9-card desktop screen. `SkillTreeV2View` ([skill_tree_v2_view.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/skill_tree_v2_view.dart#L1183-L1184)), `RiderProfileView` ([rider_profile.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/RiderProfile/rider_profile.dart#L91-L93)), **12 individual Horse profile field widgets**, and recursive `CommentItem`s ([comment_item.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Resources/Widgets/comment_item.dart#L98-L109)) all rebuild on every `AppState` emission.
  - **Offstage `StatefulShellRoute` multiplier:** [routes.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/Routes/routes.dart#L560) keeps all 3 navigation branches alive via `Offstage`. InheritedWidget updates still trigger `build()` on offstage subtrees.
  - **Other root rebuilds:** [settings_controller.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/Settings/settings_controller.dart#L34-L35) constructs fresh `ThemeData` instances on every getter call when `AppView` ([app.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/View/app.dart#L297-L307)) rebuilds; **14** sites call `MediaQuery.of(context)` instead of `MediaQuery.sizeOf(context)` (notably [navigation_view.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Navigator/navigation_view.dart#L247), rebuilding root nav chrome on keyboard inset animations).

#### B. Animations, Dialogs & CanvasKit GPU Cost (`Critical`)
- **Animated double full-viewport `BackdropFilter`:** `_GlassModalBarrier` ([app_dialog.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/Animations/app_dialog.dart#L118-L139)) renders **two nested `BackdropFilter`s** with animating `sigma = 24 * t` every frame (`300–320 ms` enter, `220–240 ms` exit) across every glass dialog and bottom sheet, and `_AppDialogRoute` ([app_dialog.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/Animations/app_dialog.dart#L419-L447)) uses `Opacity(...)` instead of `FadeTransition`. *(Suspected Web CanvasKit impact: drops below 30 FPS on software/mobile WebGL due to full-viewport dual blur passes per frame.)*
- **Double stacked `BackdropFilter(sigma: 28)` in Logbook:** `PersonalizedLogbookBackdrop` ([personalized_logbook_backdrop.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/CommonWidgets/personalized_logbook_backdrop.dart#L52-L100)) downloads a 32px photo and permanently stacks **two full-viewport `BackdropFilter(sigma: 28)`** layers behind scrollable logbooks instead of blurring the tiny source bitmap once (`ImageFiltered` or `wsrv.nl` `&blur=`).
- **`BranchSlideContainer` (`routes.dart:552-569`):** `AnimatedOpacity` wraps full branch `Navigator`s (`saveLayer` alpha compositing per frame during tab slides).

#### C. Expensive `build()` Work & Main-Thread Blocking (`High`)
- **Dictionary regex cache-buster:** [dictionary_page.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_page.dart#L624-L660) passes `entries: entries.where((other) => other.id != entry.id).toList()` to **4** `DictionaryText` widgets in `_detail()`. Because [dictionary_matcher.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_matcher.dart#L57-L100) keys its `_indexCache` `Expando` by `List` identity and compiles **one separate Unicode lookaround `RegExp` per term and synonym** (`88` RegExps today, growing linearly), every `build()` of `_detail()` recompiles **352+ Unicode RegExps synchronously on the UI thread**. The same pattern exists in `_EntryEditor._openPreview()` (`dictionary_admin_page.dart:2891-2896`).
- **Synchronous article JSON decode in `build()`:** `ResourceInfoBar` ([resource_info_bar.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Resources/Widgets/resource_info_bar.dart#L78-L90,L165)) runs `jsonDecode` + `quill.Document.fromJson(...).toPlainText()` + linear `state.allSkills` filtering inside `BlocBuilder.builder` on every card rebuild.
- **Quadratic comment tree scans:** `CommentItem` ([comment_item.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Resources/Widgets/comment_item.dart#L98-L109)) calls `cubit.getChildComments` (`O(R + C)`) + `.sort()` per comment inside an unfiltered `BlocBuilder`, yielding `O(C × (R + C))` per emit, plus `Visibility(maintainState: true)` keeping hidden action subtrees alive.
- **Deep map diffs & scroll-pixel allocations:** `AppCubit._sameResources` ([app_cubit.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/Cubit/app_cubit.dart#L2245-L2273)) serializes every `Resource` with `.toMap()` on every collection emission; `ProfileHeader` ([profile_header.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/CommonWidgets/profile_header.dart#L27)) calls `HorseAndRidersTheme().getTheme()` on every scroll frame (`shouldRebuild => true`); `MarkdownBioText.buildSpan` ([profile_design_tokens.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/Theme/profile_design_tokens.dart#L92-L110)) compiles 4 non-static `RegExp`s per line and runs twice per rebuild in `PrimaryRiderView`; `SkillTreeV2State` getters (`visibleSkills`, `realmFamilies`) re-filter and re-sort unmemoized; `DictionaryAdminPage` computes `O(m × n)` LCS `diffWords` synchronously inside `build()` (`dictionary_diff.dart:60-144`).

#### D. Images, Decoding & Rendering (`Critical`)
- **`SmartImage` double-DPR bug & Web fallback penalty ([smart_image.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/CommonWidgets/smart_image.dart#L64-L137)):**
  - `targetWidth = max(1, (maxLogicalWidth * dpr).round())` is then sent as `https://wsrv.nl/?...&w=$targetWidth&dpr=$dpr&we=1`. Since `wsrv.nl` multiplies `w` by `dpr`, it requests **`maxLogicalWidth × dpr²`** (e.g., `5,400 px` on a 3× phone, hitting `&we=1` and returning the full unresized file).
  - `cacheWidth: kIsWeb ? null : targetWidth` disables decoded resize caching on Web.
  - `preferDirectFirst: true` (default) causes Web clients to try direct XHR first (incurring CORS failures on third-party resource links or spawning DOM `<img>` PlatformViews via `WebHtmlElementStrategy.fallback` before proxying).
- **Unresized `Image.network` / `NetworkImage` / `Image.asset`:** `ProfileCover` → `HeroHeader(useSmartImage: false)` ([hero_header.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/CommonWidgets/hero_header.dart#L139-L146)), `ProfilePhoto` (`25–38 px` avatars, [profile_photo.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/CommonWidgets/profile_photo.dart#L45)), `InvitePage` inviter avatar ([invite_page.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Invitations/invite_page.dart#L432)), `_HorsePhotoCard` ([rider_list_of_profiles.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/RiderProfile/Widgets/rider_list_of_profiles.dart#L300)), `SeasonalDecorationWidget` (`assets/spring.png` `1160×2203` ≈ `10.2 MB` RGBA decoded for `24×24`, [seasonal_decoration.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/CommonWidgets/seasonal_decoration.dart#L26)), and `Logo` (`1653×831`, [logo.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/CommonWidgets/logo.dart#L21-L28)) omit `cacheWidth` / `ResizeImage`.

#### E. Lists, Virtualization, Leaks & Web Assets (`High`)
- **`shrinkWrap: true` & non-virtualized lists:** `SkillFamilyListV2` ([skill_family_list_v2.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/widgets/skill_family_list_v2.dart#L61-L70)), `ResourceCommentPage`'s `ScrollablePositionedList` ([resource_comment_page.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Resources/resource_comment_page.dart#L324-L328)), `DictionaryPage` browse (`SingleChildScrollView` + `Column`/`Wrap`), `DictionaryAdminPage` inbox (up to 100 heavy cards eagerly in `Column`), and `SkillDetailV2Panel` related resources (`Column` of full `ResourcesItem` cards).
- **Web startup drags:** [web/index.html](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/web/index.html#L57-L77) loads **4 unused Firebase v8.10.1 JS SDK modules** plus `flutter_inappwebview_web/web_support.js` eagerly; [bootstrap.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/bootstrap.dart#L27-L68) awaits Firebase, GoogleSignIn, SharedPrefs, and MobileAds sequentially and calls `FlutterNativeSplash.remove()` before `runApp()`; `3.41 MB` of unused assets are bundled via `- assets/` in `pubspec.yaml:83`.
- **Disposals / Leaks:** Undisposed `note` `TextEditingController` in `DictionaryAdminPage._review` ([dictionary_admin_page.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_admin_page.dart#L240)); unbounded zip-code listener fan-out in `ProfileSearchCubit.searchForHorseByLocation` ([profile_search_cubit.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/Dialogs/ProfileSearchDialog/Cubit/profile_search_cubit.dart#L401-L424)); undisposed `_router` in `App` ([app.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/View/app.dart#L164)); evicted `_Preview` notifiers in `SmartImage` never disposed; dead `circular_reveal_dialog.dart` allocates undisposed `CurvedAnimation`s per frame (0 current callers).

---

### 3.2 Firestore & Caching (Phase 3)

#### A. Snapshot Listeners Inventory (5 Active Global Listeners + N-way Screen Fan-Out)

| Scope | Collection / Query | Opened At | `.limit()`? | Finding / Cost Issue |
|---|---|---|---|---|
| **Global (all users + guests)** | `Skills` (entire legacy collection) | `app_cubit.dart:84, 1684` | **No** | Reads ~84+ docs on every startup/reload even though V2 is default |
| **Global (after 1st Resources tab open)** | `Resources` (entire collection incl. `comments` & `usersWhoRated`) | `app_cubit.dart:1708` | **No** | Streams & deep-diffs entire catalogue forever until app close |
| **Global (verified user)** | `Rider_Profile/{convertedEmail}` | `app_cubit.dart:239-240` | N/A (1 doc) | Expected |
| **Global (verified user)** | `Requests` (`partiesIds arrayContains email && status == 'pending'`) | `app_cubit.dart:3012`; `firestore_connection_request_store.dart:26-29` | **No** | Note: `USE_COMPOSITE_REQUEST_STORE=true` opens **3 simultaneous streams** (`composite_connection_request_store.dart:73-100`) |
| **Global (verified user)** | `CoachingConnections` (`participantUids arrayContains uid`, **no status filter**) | `app.dart:273`; `connection_repository.dart:231-232` | **No** | Streams historical declined/revoked/cancelled connections too |
| **Screen (Logbook)** | `SharedRidingEntries` (`riderUid == uid`) | `rider_logbook_page.dart:231` | **No** | Unbounded growth as user logs rides over months/years |
| **Screen (Skill Detail V2)** | `Resources` (`skillTreeIds arrayContains id`) — **1 stream per legacy ID** | `skill_detail_v2_panel.dart:527-547` | **No** | Opens **2–5+ concurrent streams per skill click** if Resources tab wasn't opened |
| **Screen (Profile Search)** | `Public_Horse_Profile` (`zipCode == zip`) + name/rider searches | `profile_search_cubit.dart:100-424` | **No** | Uses `.snapshots()` for one-shot search; ZIP radius opens **1 live listener per ZIP** (up to 50–150+ concurrent listeners!) |

#### B. Repeated/Duplicate Reads, Unbounded Queries & Rule/Index Bugs
1. **Skill Tree V2 duplicate bursts (`skill_tree_v2_view.dart:1267`, `skill_tree_v2_cubit.dart:50-118, 297`, `skill_tree_v2_repository.dart:121-167`):**
   - `build()` calls `syncProfile()` synchronously on every rebuild without an in-flight guard (`loadedProfileKey` is set *after* 3 awaits finish), causing **2–3× concurrent fetches** of `SkillProgress`, `SkillVerifications`, and `SkillVerificationEvents` on open.
   - `initialize()` executes 5 sequential awaits, and `_fetchAndVerifyAtomicSnapshot()` reads `SkillTreeCurriculumPublic/active` **before** checking `_cachedSnapshot` (so `fetchFamilies()` + `fetchSkills()` + `active` recheck = **3 reads of `active` + 1 rule read + `C` chunk reads** cold; **2 reads of `active`** on warm init).
   - `setSelfAssessment()` reloads all 3 subcollections on every tap, and `SkillTreeV2Sync` forces mounted/offstage `ProfileSkills` widgets to re-read `SkillProgress` + `SkillVerifications` too.
   - `SkillVerificationEvents` has no `.limit()` (reads entire history, client-slices `.take(5)`).
2. **Dictionary forced `Source.server` & Admin triple-reload:**
   - [firebase_dictionary_store.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/firebase_dictionary_store.dart#L59-L86) forces `GetOptions(source: Source.server)` on `DictionaryPublic/catalogue` + `DictionaryEntries`.
   - [dictionary_page.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_page.dart#L41-L51) calls `repository.load()` directly on every list and `/Dictionary/:slug` push instead of `cachedEntries()`.
   - [dictionary_admin_page.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_admin_page.dart#L151,L163-L185,L1982-L1984) calls `loadDrafts()` (full collection scan instead of `loadDraft(id)` = `1` doc), and Quick Approve & Publish triggers **3 full catalogue reloads + 2 full 100-doc suggestion reloads**.
3. **Security rules & indexing audit (`firebase/firestore.rules`):**
   - **30 `get()` / `exists()` calls** (`9 exists`, `21 get`). Subcollection reads on `SkillProgress`, `SkillVerifications`, and `SkillVerificationEvents` each bill **+1 parent profile rule read** (3 extra reads per profile skill sync); `SkillProgress` writes bill **+2 rule reads** (parent profile + `SkillsV2/{skillId}`).
   - **Verified bugs:**
     - **Missing `firestore.indexes.json`:** `Requests` query (`partiesIds` arrayContains + `status == 'pending'`) requires a composite index not tracked in source control (`firebase.json` has no `firestore.indexes`).
     - **Coach `list` failure on `SkillVerificationEvents` (`firestore.rules:108-120, 308, 360`):** Unconstrained `.get()` on `SkillVerificationEvents` fails `canReadVerificationEvent()` for coaches (per-doc `CoachingConnections` `get()` incompatible with `list` queries; `HybridCurriculumSkillTreeV2Store` swallows to `[]`).
     - **`TransferHorseCubit.getTransferProfile` (`transfer_horse_cubit.dart:87`):** Queries private `Rider_Profile` without `Public_Rider_Profile` fallback → `permission-denied`.
     - **`RiderProfileRepository.createOrUpdateRiderProfile` (`rider_profile_repository.dart:41-43`):** Calls `.set()` without `SetOptions(merge: true)`, risking stripping server-managed `ownerUid`/`instructorUids` and violating `firestore.rules:337-339`.
4. **Write amplification:** `syncPublicRiderProfile` ([public_rider_profile.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/public_rider_profile.js#L91-L107)) and `syncPublicHorseProfile` ([public_horse_profile.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/public_horse_profile.js#L65-L81)) unconditionally write/delete `Public_*` docs on every private edit (no `before` vs `after` public-payload diff), and `account_deletion.js` double-writes both source & public docs while triggers run. Client-side `saveResource`, `addLogEntry`, `reccomendResource`, and `CommentCubit.sendComment` overwrite entire documents rather than transactional field/subcollection writes.

#### C. Offline Persistence & Public Catalogue Caching Evaluation
- **Current Persistence:** `FirebaseFirestore.instance.settings` is never configured anywhere in `lib/` (`cloud_firestore: 7.1.0`), leaving Web persistence **disabled** (every browser refresh is a cold start) while `FirebaseDictionaryStore` explicitly bypasses Mobile persistence via `Source.server`.
- **Efficient Caching Architecture for Dictionary (`44.8 KB`) & Skill Tree V2 (`218.2 KB`):**
  - Both catalogues are small, read-mostly JSON bundles (`~50–65 KB` combined gzipped).
  - Instead of polling Firestore collections with `Source.server` or reading revision chunks + security-rule pointers on every reload:
    1. On admin publish (`editDictionary` / `publishSkillTreeCurriculumDraft`), upload immutable content-hashed JSON bundles (`public/dictionary/v{rev}-{sha}.json` & `public/curriculum/v{rev}-{sha}.json`) with `Cache-Control: public, max-age=31536000, immutable` (and optionally a tiny `{version, sha256, url}` pointer doc in Firestore or CDN-cached `manifest.json` with `max-age=300`).
    2. Cache `(version, jsonPayload)` in a provider-independent local cache store (`SharedPreferences` on mobile / IndexedDB on Web) with ETag / version check once per session (and instant stale-while-revalidate display).
  - **Result:** Drops cold-start and reload Firestore reads for Dictionary & Skill Tree 2.0 from **~30–115 reads** down to **0–1 read/session**.

---

### 3.3 Firebase Storage & Media (Phase 4)

- **Security Rules ([storage.rules](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/firebase/storage.rules#L21-L70)):**
  - `/Riders_Photo/{riderId}`, `/Horses_Photo/{horseId}`, `/resources/pdfs/{resourceId}/{fileName}` allow **any signed-in user** to read, overwrite, or delete **any** path (`request.auth != null`) with **no size cap** and **no `contentType` restriction**. `/covers/{userEmail}/**` checks email match, but has **no size limit**, **no MIME check**, and **no `email_verified` requirement**. (Contrast with `dictionary_*` rules, which enforce `<= 10 MB` and PNG/JPEG/WebP.)
- **Upload Resizing & Compression Gaps:**
  - **Rider / Horse Photos:** `imageQuality: 20` on `ImagePicker` has no `maxWidth`/`maxHeight` and is ignored on Web & PNGs; `CloudRepository._uploadPhoto` ([cloud_repository.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/cloud_repository.dart#L31-L83)) uploads raw full-resolution bytes with **no `SettableMetadata`** (missing both `contentType` and `cacheControl`).
  - **Dictionary Community Submissions:** `DictionaryImageProcessor.process` ([dictionary_media.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_media.dart#L262-L295)) re-encodes resized >2048px images as **lossless PNG**, then discards the resize if PNG > JPEG/WebP original size—so large JPEG photographs fall back to uploading up to `10 MB` unresized.
  - **Dictionary Admin Uploads & Article Covers:** `DictionaryAdminPage` ([dictionary_admin_page.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_admin_page.dart#L2723)) validates format/10 MB size only—never resizes or deduplicates; `CreateArticleCubit` uploads unresized covers.
- **`Cache-Control` & Thumbnails:**
  - Only `dictionary_public/{entryId}/` sets `Cache-Control: public, max-age=31536000, immutable` ([dictionary.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/dictionary.js#L563-L567)). All client `CloudRepository` uploads (`Riders_Photo/`, `Horses_Photo/`, `covers/`, `resources/pdfs/`, `dictionary_submissions/`, `dictionary_drafts/`) omit `cacheControl`.
  - **Zero server-generated thumbnails exist.** Avatars (`ProfilePhoto`), `_HorsePhotoCard`, `ProfileCover`, and `SmartImage` (due to `preferDirectFirst: true` and Web `cacheWidth: null` + double-DPR bug) fetch and decode full-resolution originals.
- **Orphaned Media Leaks (7 paths, 0 GCS lifecycle rules, 0 active cleanup jobs):**
  1. `dictionary_submissions/{uid}/{submissionId}/`: `DictionaryImageContributionDialog` ([dictionary_image_contribution_dialog.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_image_contribution_dialog.dart#L69-L86)) & `DictionarySuggestionDialog` call `context.read<MediaStorageRepository?>()` inside `dispose()` (which throws deactivated-widget error and falls back to `null` `widget.mediaStorage`), silently skipping abandoned temp-upload deletion; `account_deletion.js` also skips `dictionary_submissions/{uid}/`.
  2. `dictionary_drafts/{entryId}/`: `cleanupAbandonedDraftMedia` is implemented & tested ([dictionary.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/dictionary.js#L605-L645)) **but never exported in `functions/index.js` or scheduled**.
  3. `dictionary_public/{entryId}/`: Replaced or removed published entry images are never deleted from Storage.
  4. `Horses_Photo/`: New horse uploads to `Horses_Photo/${DateTime.now()}` ([add_horse_dialog_cubit.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/Dialogs/AddHorseDialog/Cubit/add_horse_dialog_cubit.dart#L34,L118,L354)) while doc ID is `ViewUtils.createId()`, leaving an orphan immediately and another if edited later; `deleteHorseProfile` never deletes Storage photos.
  5. `covers/` & `resources/pdfs/`: Neither `deleteResource` nor cover replacement deletes Storage files; `account_deletion.js` skips `resources/pdfs/`.

---

### 3.4 Cloud Functions (Phase 5)

- **Inventory Overview:** **23 Gen2 functions** (`us-central1`, Node `22`), **0 scheduled functions**, **0 Auth triggers**, `setGlobalOptions` unused (all default `minInstances: 0`, `maxInstances: 100`, `concurrency: 80`, `retry: false`; 21 run at `256 MiB`, 2 at `512 MiB` [`fetchReadable`, `resolveImage`]; `account_deletion` runs at default `60s` timeout despite `LOCK_TTL_SECONDS = 120`).
- **Top-Level Dependency Cold-Start Tax:** All 23 functions boot at **`130.5 MB RSS` (+440 ms)** because `functions/index.js:7-9` loads `jsdom`, `cheerio`, and `@mozilla/readability` globally. Running `jsdom` on `fetchReadable` at `concurrency: 80` (`512 MiB`) also creates OOM crash exposure on large HTML pages. Also, `firebase.json:116-122` fails to exclude `functions/test/` and CLI scripts (`backfill_*.js`, `scripts/`) from deployments.
- **Unauthenticated Public Endpoint Abuse / Cost Risks:**
  - `previewMeta`, `fetchReadable`, `resolveImage` ([index.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/index.js#L509-L677)): No auth, no App Check, no rate limit; open SSRF proxy; `previewMeta`/`fetchReadable` lack fetch timeouts and byte caps; `resolveImage` executes up to **24 outbound HTTP requests** per call (and `SmartImage` auto-triggers it on every dead resource thumbnail). `CreateResourceDialogCubit` calls all three **sequentially** on URL input (`getMetadata`).
  - `sharePreview` ([share_preview.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/share_preview.js#L25-L33,L119,L230-L280)): Intercepts all Hosting traffic matching `/Dictionary*`, `/SkillTree*`, `/Profile/Horse_Profile/*`, `/invite/*` (not user-agent filtered); reads private `Horse_Profile` instead of `Public_Horse_Profile`; returns `Cache-Control: no-store` on missing slugs/IDs/tokens (letting random-URL bots bypass CDN); fetches `${origin}/index.html` on **every invocation** without caching and trusts raw `X-Forwarded-Host` (SSRF if called directly on `*.a.run.app`).
  - `getInvitationPreview` ([invitations.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/invitations.js#L412-L419)): Unauthenticated, no App Check, no rate limit (`1–3` Firestore reads per valid-format probe).
- **Read/Write Amplification Inside Callables:**
  - `requestAccountDeletion` ([account_deletion.js](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/functions/account_deletion.js#L744-L808)): Full **`Resources` collection scan (`N_res`) + `3 × N_res` sequential `usersWhoRated` reads** + unbatched sequential updates/deletes inside a `60s` timeout.
  - `listMyInvitations` (`invitations.js:798-812`) & `submitSkillTreeSuggestion` (`suggestions.js:187-199`): Unbounded user queries sorted/counted in memory.
  - `coachingConnection`: Unbounded `SharedRidingEntries` scans (`horseHistory`/`studentHistory`), `Requests` fallback scan (`readRequestRecord`), and N+1 `Auth.getUserByEmail` + Firestore loop (`horseOptions`) inside transactions.
  - `saveSkillTreeCurriculumDraft` (`curriculum_drafts.js:53-79`): Scans ~104+ `SkillsV2`/`SkillFamilies` docs instead of active snapshot chunks.
  - `editDictionary` (`approve_and_publish`): `5 × K` sequential GCS RPCs in `promoteDraftMedia`.
- **Logging Volume:** Runtime logging is **clean and low-cost** — only **6 `logger.*` calls** exist across all runtime functions (all in `functions/index.js`: 5 error logs + 1 small `logger.info('Email notification stub skipped')` per `onRequestCreated`), with 0 verbose payload dumps. However, **Cloud Run request logs** on `sharePreview` will scale directly with Hosting page views and bot crawls.

---

### 3.5 End-to-End Audit of 9 Key User Journeys (Phase 6)

> Notation: Variable counts reflect dataset sizes at session time (`N_legacy_skills`, `N_skills_v2 ≈ 72`, `N_chunks ≈ 1`, `N_progress`, `N_verifications`, `N_events`, `N_dictionary_entries ≥ 28`, `M_patterns ≥ 88`, `N_resources`, `N_connections`, `N_pending_requests`, `N_shared_entries`, `N_suggestions ≤ 100`, `N_drafts`, `K ∈ [1..3]`).

1. **Initial Application Load (Guest & Returning Signed-In User)**
   - **Firestore:** Guest: **1 active listener** (`Skills` = `N_legacy_skills`), `0` writes. Signed-in verified user on `/`: **4 active listeners** (`Skills` = `N_legacy_skills`, `Rider_Profile/{email}` = `1`, `Requests` pending = `N_pending_requests`, `CoachingConnections` = `N_connections`) + `ProfileSkills` queries (`2 + N_chunks` or `1 + N_skills_v2`, plus `N_progress` + `N_verifications`) + `0–1` FCM token merge write (mobile).
   - **Network/CF/Main-thread:** `0` CFs (`sharePreview` runs on deep links). Web loads 4 dead Firebase v8 scripts + `main.dart.js` (`6.4 MiB`, `no-cache`). Mobile runs sequential `GoogleSignIn` + `MobileAds.initialize()` before `runApp()`. `AppCubit` sorts legacy `Skills` twice synchronously and `Requests` twice.
   - **Perceived-Perf Wins:** Remove v8 CDN tags & pre-`runApp` `MobileAds`; stop eager legacy `Skills` listener; enable Web persistence & single-bundle curriculum caching.

2. **Sign-In, Registration, Email Verification & Profile Setup**
   - **Firestore:** Registration (unverified): `0` reads/writes. Verification + Profile Setup: `1` initial `Rider_Profile` miss → `1` write (`Rider_Profile`) + `1` trigger write (`syncPublicRiderProfile` → `Public_Rider_Profile`) → triggers Journey 1 listeners.
   - **Network/CF:** Sign-in invokes redundant **2× `getIdTokenResult(false)`**; Sign-up makes 4 sequential Auth calls + `Timer.periodic(10s)` `firebaseUser.reload()` polling; `EditRiderProfileCubit` eagerly calls Remote Config `fetchAndActivate()` (`LocationLookupService.warmUp`); optional unresized `Riders_Photo` upload (`putData` without metadata).
   - **Main-thread/Wins:** `2×` `BackdropFilter` on verification & profile dialogs. Deduplicate `getIdTokenResult`, defer `warmUp()` to ZIP focus, pause 10s polling in background and reload immediately on app resume.

3. **Rider & Horse Profiles (Own, Other/Student, Editing, Training Logs)**
   - **Firestore:** Viewing other user: tries private `Rider_Profile` first (`1` wasted `permission-denied` RTT for non-connections) → `Public_Rider_Profile` (`1`) + `ProfileSkills`. Viewing horse: opens `1` live listener (private `Horse_Profile/{id}` → fallback `Public_Horse_Profile/{id}`) + optional owner profile. Profile Search opens live `.snapshots()` (**1 per ZIP code** in location search). Edit Horse: `2` client writes + `2` trigger writes; toggle public sharing opens temporary `Public_Horse_Profile` listener. Opening Rider Logbook: `1` unbounded `SharedRidingEntries` stream; Horse Logbook: `coachingConnection(horseHistory)` unbounded txn scan. Saving student lesson: `coachingConnection` txn + **2 duplicate `Source.server` `Rider_Profile` reloads** (`LogbookCubit` + `RiderLogbookPage`) + sequential `SkillProgress` txn loop for opt-in tags.
   - **Main-thread/Wins:** `PersonalizedLogbookBackdrop` (`2× BackdropFilter(sigma: 28)`); unresized `Image.network` `_HorsePhotoCard`; `PrimaryRiderView` layout `TextPainter` + 8 RegExps/line. Pre-blur logbook photo via `wsrv.nl`/`ImageFiltered`, query `Public_*` directly when unlinked, paginate `SharedRidingEntries`, use `.get()` in search.

4. **Skill Tree 2.0 Browsing & Progress Tracking**
   - **Firestore:** Init runs **5 sequential awaits** (curriculum `active` read `3×` + `1` rule read + `C` chunk reads + `contributors` + optional `Meta`, OR `106` reads unversioned fallback) + `SkillProgress` + `SkillVerifications` + unbounded `SkillVerificationEvents` (`+3` parent profile rule reads); unguarded `syncProfile()` inside `build()` multiplies this `2–3×` on mount! Selecting a skill when Resources tab hasn't been visited opens `1–5+` `Resources` `.snapshots()` listeners per legacy ID. Switching Rider ↔ Horse re-reads all 3 subcollections (no cache). Every self-assessment tap: `1` txn (`+2` rule reads) + **3 sequential subcollection reloads** + offstage `ProfileSkills` cascade (**another `1 + N_progress + N_verifications`**). Instructor verify: `5` server reads + `3` writes + same client reload cascade.
   - **Main-thread/Wins:** Unmemoized `visibleSkills`/`realmFamilies`, `shrinkWrap: true` family list, 6–15+ `ContextualDictionaryText` widgets running `M_patterns` RegExps. Add `Future.wait` + combined `fetchCurriculum()`, in-flight guard in `syncProfile()`, optimistic local self-assessment updates, per-profile cache, and delta `SkillTreeV2Sync`.

5. **Dictionary Browsing & Contextual Definitions**
   - **Firestore:** `/Dictionary` and `/Dictionary/:slug` bypass `cachedEntries()` and force `Source.server` (`1 + N_dictionary_entries` reads on **every** browse & term tap!). `ContextualDictionaryText` shares a 10-min RAM cache (1+N server reads on TTL expiry). Definition dialog reads `0` Firestore docs (uses in-memory entry; optional `SmartImage` hero fetch).
   - **Main-thread/Wins:** `DictionaryPage._load()` synchronously `jsonDecode`s `207 KB` of 6 curriculum JSONs on every open; **`DictionaryPage._detail` breaks `Expando` regex cache 4× per `build()` (352+ Unicode RegExp compilations)**; `/Dictionary` list is non-virtualized `Column`/`Wrap` without search debounce; definition dialog animates 2× `BackdropFilter(sigma: 24)`. Route `DictionaryPage` through `cachedEntries()`, pass `excludeEntryId` to `DictionaryText`, collapse RegExps into 1 alternation `RegExp`, and virtualize browse list.

6. **Dictionary Image Contributions**
   - **Firestore & CF:** `0` reads while picking/uploading; Submit runs `submitDictionarySuggestion` (`4` tx reads, `3` tx writes) + `2 × K` sequential GCS `exists`+`getMetadata` calls.
   - **Storage & Main-thread:** `K` sequential `putData` + `getDownloadURL` calls. Synchronous `sha256` on UI thread; PNG re-encode discards resize when > JPEG original; dialog `dispose()` silently skips temp-file cleanup. Hash in background isolate/WebCrypto, encode resized photos as WebP/JPEG, upload & validate `K` images concurrently.

7. **Community Editorial Review (`/DictionaryReview`)**
   - **Firestore & CF:** Open: `min(N_suggestions, 100) + 1 + N_dictionary_entries` (`Source.server`). Opening Quick Approve calls `loadDrafts()` (scans **all `N_drafts`** instead of `loadDraft(id)`). Confirming Quick Approve: `editDictionary(approve_and_publish)` (`7` server reads + `7` writes + `5 × K` sequential GCS RPCs), then **client executes a triple-reload (`2 × suggestions + 3 × (1 + N_dictionary_entries)`)**! Reject calls `_refresh()` (`+1` full reload; `_partialReview` calls `_refresh()` twice!).
   - **Main-thread/Wins:** Non-virtualized inbox of up to 100 cards with synchronous `O(m × n)` `diffWords()` DP tables + `3 × N` eager thumbnail loads; undisposed `note` controller in `_review`. Switch to `loadDraft(id)`, remove duplicate refreshes via optimistic inbox updates, virtualize with `ListView.builder`, memoize `diffWords`, and parallelize `promoteDraftMedia`.

8. **Invitations & Student Connections**
   - **Firestore & CF:** Create invite: `createInvitation` (`2R / 3W`). Manage invites: `listMyInvitations` (unbounded `Invitations` scan sliced in RAM). Landing `/invite/:code`: `getInvitationPreview` (`3R`; repeated after guest sign-up redirect). Redeem student invite: `redeemInvitation` (`8R / 5–6W` + triggers `syncPublicRiderProfile` & `onRequestCreated`). Accept/decline/revoke: `coachingConnection` (`3–4R` or fallback `Requests` scan / `2–4W` + profile mirror write).
   - **Main-thread/Wins:** `ConnectionPanel` watches full `AppCubit`; unresized `NetworkImage` avatar on `InvitePage`. Cache `InvitationPreview` across auth redirect, add `.limit(100)` + index on `listMyInvitations`, fix `ConnectionPanel` selector, add optimistic updates in `ConnectionsCubit`.

9. **Resources and Media**
   - **Firestore:** Opening Branch 2 opens permanent unbounded `Resources` stream (`N_resources` docs + embedded comments/votes). Recommend / Comment overwrite full `Resources/{id}` doc (non-transactional race risk); `rateComment` & `updateSkillLinks` run txns (`1R/1W`). Save Resource writes `Rider_Profile` (+ trigger write).
   - **Cloud Functions / Main-thread:** URL paste runs **3 sequential CFs** (`previewMeta` → `fetchReadable` → `resolveImage`) hitting the target webpage 3+ times and serializing full HTML `content` only to discard it. `SmartImage` auto-fires `resolveImage` on broken thumbnails. `ResourcesItem` stacks 4 unfiltered `BlocBuilder`s; `ResourceInfoBar` runs sync Quill `jsonDecode` in `build()`; `AppCubit._sameResources` deep-diffs every `Resource.toMap()` on every snapshot; `CommentItem` scans comments `O(C×(R+C))` in `ShrinkWrap` `ScrollablePositionedList`.
   - **Wins:** Merge into 1 `fetchLinkPreview` callable, move `comments`/`usersWhoRated` to subcollections + paginate `Resources`, replace `_sameResources` deep diff, add `buildWhen` on card widgets, and cache article snippets.

---

### 3.6 Database Independence Verification (Phase 8)

#### Direct Firebase Imports in `lib/` (**12 Files**)

| Status | File(s) | Coupling Finding |
|---|---|---|
| Acceptable composition/init/adapter layer (6) | `lib/main.dart`, `lib/firebase_options.dart`, `lib/Initialization/firebase_initialization.dart`, `lib/Initialization/firebase_emulators.dart`, `lib/MainPages/Dictionary/firebase_dictionary_store.dart`, `lib/MainPages/Delete/firebase_account_deletion_repository.dart` (`options.projectId`) | Expected Firebase adapters / composition root (note: `firebase_account_deletion_repository.dart` can read `projectId` from config/env instead of `FirebaseAuth.instance`) |
| **Violations in App/UI/Feature layer (6)** | 1. [app.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/View/app.dart#L2,L180-L187) (`FirebaseFirestore.instance.collection('CoachingConnections').doc(id).get()`)<br>2. [profile_skills.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/CommonWidgets/profile_skills.dart#L4,L101-L104) (`Firebase.apps.isNotEmpty`, `FirestoreSkillTreeV2Store`)<br>3. [skill_tree_v2_view.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/SkillTreeV2/skill_tree_v2_view.dart#L4,L63,L105) (`Firebase.apps`, downcasts `FirestoreSkillTreeV2Store`)<br>4. [dictionary_repository.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Dictionary/dictionary_repository.dart#L4,L20,L108,L144) (facade leaks `FirebaseFirestore?`)<br>5. [connection_repository.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/Connections/connection_repository.dart#L6-L8,L29,L51) (hardcoded `FirebaseFirestore.instance` & `FirebaseAuth.instance`, no store interface)<br>6. [fcm_service.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/Utilities/notifications/fcm_service.dart#L3-L4,L37,L52-L59) (direct `FirebaseFirestore.instance` token writes) | Must be moved behind repository/store interfaces injected at composition root |

- **Concrete fallback instantiation without Firebase imports (20+ UI/Cubit files):** Dialogs/Cubits instantiate `CloudRepository()`, `RiderProfileRepository()`, `HorseProfileRepository()`, `ResourcesRepository()`, `SkillTreeRepository()`, `FirestoreConnectionRequestStore()`, and downcast `is FirestoreSkillTreeV2Store` when DI context is absent.
- **`packages/database_repository` Lock-In:**
  - Single package depends on 5 Firebase SDKs (`cloud_firestore`, `firebase_auth`, `firebase_core`, `firebase_remote_config`, `firebase_storage`) and barrel-exports Firebase implementations + Firestore mappers alongside domain models.
  - 2 legacy models import `cloud_firestore` directly: [mesage.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/models/mesage.dart#L2) & [group.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/models/group.dart#L3); [skill_tree_draft_repository.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/skill_tree_draft_repository.dart#L3) imports `cloud_firestore` for `Timestamp`; [repository_exception.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/repository_exception.dart#L1) mixes generic exceptions with `FirebaseException`; [resource_repository.dart](file:///home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/packages/database_repository/lib/src/resource_repository.dart#L292-L313) leaks `DocumentSnapshot<Resource>?` pagination cursors; `invalidateCache()` is missing on `SkillTreeV2Store`; 6 stores hardcode `us-central1-$project.cloudfunctions.net`.
- **Caching Portability Assessment:**
  - `SkillTreeV2` snapshot cache currently lives *inside* `FirestoreSkillTreeV2Store` (provider-locked). Moving catalogue caching into `SkillTreeV2Repository` and `DictionaryRepository` backed by a generic `KeyValueCache` / `RemoteJsonCatalogueClient` interface keeps all caching strategies **100% portable** to Supabase/Postgres/S3/Cloudflare R2/REST.

---

## 4. Prioritized Remediation Table

| Issue | Evidence | User Impact | Cost Impact | Effort | Recommendation |
|---|---|---|---|---|---|
| **P0 — Open unauthenticated SSRF & proxy endpoints** | `functions/index.js:509-677` (`previewMeta`, `fetchReadable`, `resolveImage`); `share_preview.js:25-33,275` (`X-Forwarded-Host`) | Medium (crash/OOM risk on concurrent `jsdom`) | **Critical** (unbounded abuse / crawler / DoS billing up to 100 instances × 60s) | Low–Med | Require verified Firebase Auth (+ App Check) on `previewMeta`/`fetchReadable`/`resolveImage`; block private/loopback/metadata IPs, enforce HTTPS + 10s timeout + 2 MB body cap; allowlist `Host` + cache `/index.html` in `sharePreview`. |
| **P0 — Permissive Storage rules (no owner, size, or MIME checks)** | `firebase/storage.rules:21-40` (`Riders_Photo`, `Horses_Photo`, `resources/pdfs`, `covers`) | High (any user can overwrite another user's photos/PDFs) | **Critical** (arbitrary multi-GB abuse storage & egress) | Low | Enforce ownership (`uid` / owner / author claim), `contentType` allowlists (`image/*`, `application/pdf`), and max file sizes (`10 MB` images, `25 MB` PDFs) in `storage.rules`. |
| **P0 — Unbounded `Resources` stream & Dictionary `Source.server` full scans** | `app_cubit.dart:1708`; `firebase_dictionary_store.dart:59-86`; `dictionary_page.dart:41-51`; `dictionary_admin_page.dart:163-185,1982` | High (slow nav/tab loads + deep `.toMap()` UI stalls) | **Critical** (`1+N` server reads on every Dictionary view, `3×` admin reload, full `Resources` fan-out) | Medium | Route `DictionaryPage` through `cachedEntries()`, eliminate `Source.server`, remove admin triple-reload + `loadDrafts()` scan, move Dictionary & V2 curriculum to CDN/versioned JSON cache, paginate `Resources` & split `comments` subcollection. |
| **P0 — Eager global legacy `Skills` `.snapshots()` listener at startup** | `app_cubit.dart:84,1684,2208` | Medium (startup CPU double-sort on every cold launch) | **High** (~84+ reads on **every** guest/user session & Web reload) | Low | Gate legacy `Skills` listener behind `!FeatureFlags.skillTreeV2Enabled` or lazy load only on legacy route; read skill labels from V2 catalogue. |
| **P1 — `SkillTreeV2View.build` unguarded `syncProfile()`, 5-step waterfall & reload cascades** | `skill_tree_v2_view.dart:1267`; `skill_tree_v2_cubit.dart:50-118,297`; `skill_tree_v2_repository.dart:121-167`; `profile_skills.dart:88` | **Critical** (slow Skill Tree init, sluggish taps, Rider/Horse switch wait) | **High** (`2–3×` duplicate subcollection bursts + full reloads + offstage `ProfileSkills` cascade + double `active` read) | Low–Med | Add in-flight guard in `syncProfile()`, parallelize with `Future.wait`, coalesce `fetchFamilies`/`fetchSkills`, apply optimistic self-assessment updates, cache per-profile maps, pass deltas via `SkillTreeV2Sync`. |
| **P1 — Unfiltered `AppState` rebuilds (63 sites) & 4 nested card `BlocBuilder`s** | `app_state.dart:73-531`; `resource_item.dart:32`; `resource_info_bar.dart:156`; `skill_tree_v2_view.dart:1183`; `comment_item.dart:98`; `routes.dart:560` | **Critical** (jank during tabs, search, snackbars, scrolling across all 3 shell branches) | None | Medium | Replace unfiltered `BlocBuilder`/`watch` with `BlocSelector`/`context.select`/`buildWhen`; cache `_articleSnippet` & child-comment index outside `build()`; precompute `_sameResources` without `.toMap()`. |
| **P1 — Animated double full-viewport `BackdropFilter` & logbook blur** | `app_dialog.dart:118-139`; `app_design_system.dart:50`; `personalized_logbook_backdrop.dart:68-100` | **Critical** (<30 FPS dialog/sheet transitions & logbook scrolling on CanvasKit Web) | None | Low | Fade a single `BackdropFilter` via `FadeTransition` (fixed sigma) or lower sigma on Web; replace logbook's 2× `sigma: 28` full-screen blur with pre-blurred `ImageFiltered`/`wsrv.nl` `&blur=`. |
| **P1 — `SmartImage` double-DPR bug, Web `cacheWidth: null`, & unresized avatars/covers** | `smart_image.dart:64-137`; `hero_header.dart:139`; `profile_photo.dart:45,112`; `rider_list_of_profiles.dart:300`; `seasonal_decoration.dart:26` | **High** (10–20× excess decoded RAM/VRAM, CORS errors & DOM PlatformViews) | **High** (full-res multi-MB Firebase Storage egress instead of resized thumbnails) | Low | Fix `wsrv.nl` `w=` without double-DPR; use proxy first on Web; add `cacheWidth`/`ResizeImage` everywhere; downscale `spring.png`/`horse_background.png`. |
| **P1 — `DictionaryPage._detail` regex cache-buster & linear regex loop** | `dictionary_page.dart:624-660`; `dictionary_matcher.dart:57-100` | **High** (352+ Unicode RegExp compilations per build; O(M×L) on every text block) | None | Low (bug) / Med (engine) | Pass shared `entries` + `excludeEntryId` (instant fix); merge patterns into one alternation `RegExp`. |
| **P1 — `functions/index.js` top-level `jsdom` + `cheerio` load** | `functions/index.js:7-9` | Medium (`+297 ms` cold-start on every callable/SSR) | **Medium** (+49 MB RSS / 51% container RAM across all 23 functions; OOM risk on `fetchReadable`) | Low | Lazy-`require('jsdom')`/`Readability`/`cheerio` inside link-preview handlers only; exclude `test/` & scripts in `firebase.json`. |
| **P1 — `requestAccountDeletion` `1 + 3R` `Resources` scan inside 60s timeout** | `account_deletion.js:746-808`; `index.js:89-97` | High (account deletion fails with timeout as `Resources` grows) | **Medium–High** (4,000+ reads per deletion at 1k Resources) | Medium | Raise timeout (`300s`), batch writes, and denormalize/index user ratings instead of scanning all `Resources`. |
| **P1 — Client upload resizing gaps, missing `Cache-Control` & orphan leaks** | `cloud_repository.dart:39-97`; `dictionary_media.dart:262,816`; `dictionary_image_contribution_dialog.dart:69`; `add_horse_dialog_cubit.dart:34`; `dictionary.js:605` | **High** (multi-MB photo uploads stalled, repeat image downloads on Web) | **High** (unbounded orphaned Storage GB + uncached egress) | Low–Med | Encode resized photos as JPEG/WebP; run SHA-256 off main thread; set `Cache-Control` + `contentType` on uploads; fix `dispose()` storage ref & Horse ID mismatch; delete files on item delete; schedule `cleanupAbandonedDraftMedia`. |
| **P1 — `sharePreview` missing-slug `no-store` trap, private horse read & uncached HTML** | `share_preview.js:119,230-280`; `firebase.json:87-105` | High (every deep link hits CF + fetches `index.html`) | **High** (bots scanning random slugs bypass CDN & incur CF + Firestore reads) | Low | Cache `index.html` in module RAM, read `Public_Horse_Profile`, return short-TTL cache (`max-age=60`) on 404/not-found. |
| **P1 — 3 sequential Cloud Functions for Resource link preview** | `create_resource_dialog_cubit.dart:357-491`; `functions/index.js:509-677` | **High** (3–8s delay pasting a link; discards full Readability HTML) | **Medium** (3× CF invocations & outbound fetches; dead images auto-call `resolveImage`) | Medium | Consolidate into 1 `fetchLinkPreview` callable (1 HTML fetch, tiny payload) and guard `SmartImage` fallback retries. |
| **P1 — Web bundle & asset bloat (v8 SDKs, 3.41 MB dead PNGs, `6.4 MB` JS, `2.96 MB` OG PNG)** | `web/index.html:69-77`; `assets/*`; `web/images/dictionary-share-default.png`; `build/web/main.dart.js`; `bootstrap.dart:41,65` | **High** (slow Web TTI & mobile cold boot) | **Medium** (Hosting egress ~3–6 MB excess per cold visitor) | Low–Med | Remove dead Firebase v8 imports & 3.41 MB unused PNGs; compress OG image (<150 KB); lazy-init Ads/GoogleSignIn; defer-load admin/Quill/WebView routes. |
| **P1 — Rule/query correctness bugs & missing `firestore.indexes.json`** | `firestore.rules:108-120`; `rider_profile_repository.dart:43`; `transfer_horse_cubit.dart:87`; `skill_detail_v2_panel.dart:527` | High (coach event list silently empty; transfer lookup denied; overwrites risk failure) | Low | Low | Track `firestore.indexes.json` (incl. `Requests` index), fix `createOrUpdateRiderProfile` merge, use `Public_Rider_Profile` in transfer search, rework `SkillVerificationEvents` query/rules. |
| **P2 — Unconditional `syncPublicRiderProfile`/`syncPublicHorseProfile` trigger writes** | `public_rider_profile.js:91-107`; `public_horse_profile.js:65-81`; `account_deletion.js:314-379` | Low | **Medium** (100% write amplification on private profile edits & deletion) | Low | Diff `buildPublic*(before)` vs `buildPublic*(after)` and skip no-op `set`/`delete`; stop double-writing in deletion. |
| **P2 — Search & skill resource N+1 live `.snapshots()` streams + unbounded queries** | `profile_search_cubit.dart:401-424`; `skill_detail_v2_panel.dart:527`; `invitations.js:798`; `suggestions.js:187`; `connections.js:883,905` | Medium (memory & UI jitter during location search) | **Medium–High** (50–150+ streams on ZIP search; growing scans) | Low–Med | Convert `ProfileSearchCubit` to `.get()` + batched `whereIn`; add `.orderBy().limit()` on invitations/events/journal/suggestions. |
| **P2 — Unvirtualized & `shrinkWrap: true` lists** | `skill_family_list_v2.dart:61`; `resource_comment_page.dart:324`; `dictionary_page.dart:410`; `dictionary_admin_page.dart:734` | Medium–High (jank as Dictionary/Comments/Inbox grow) | Low | Medium | Replace `SingleChildScrollView` + `shrinkWrap` with `CustomScrollView` + `SliverList`/`SliverGrid`. |
| **P2 — Unconfigured Firestore Web persistence** | `bootstrap.dart` / `firebase_initialization.dart` | Medium (slower warm reloads) | **Medium–High** (full reload reads on every Web page refresh) | Low | Enable IndexedDB persistence on Web (`Settings(persistenceEnabled: true)`). |
| **P2 — 12 `lib/` Firebase imports & monolithic `database_repository` lock-in** | `app.dart:2`; `profile_skills.dart:4`; `skill_tree_v2_view.dart:4`; `dictionary_repository.dart:4`; `connection_repository.dart:6`; `fcm_service.dart:3` | Low | Zero direct cost; high future migration effort | Med–High | Move remaining Firestore/Core calls behind repository/cache interfaces; split domain contracts from Firebase package. |

---

## 5. Quick Wins vs. Architectural Improvements

### High-Leverage Quick Wins (< 1–2 Days Each)
- Add verified-Auth + SSRF/timeout/size guards to `previewMeta`, `fetchReadable`, `resolveImage`, allowlist `Host` + cache `index.html` + read `Public_Horse_Profile` in `sharePreview`, and tighten `firebase/storage.rules` sizes/MIME/owners.
- Lazy-`require` `jsdom`, `cheerio`, and `Readability` inside `functions/index.js`; ignore `test/` & CLI scripts in `firebase.json`.
- Remove the 4 unused Firebase v8 CDN imports in `web/index.html`, delete `3.41 MB` of unused assets in `assets/`, compress `dictionary-share-default.png` & `spring.png`, and remove unused `pubspec.yaml` packages.
- Fix `DictionaryPage._detail` (`excludeEntryId` instead of 4× `.toList()`), route `DictionaryPage` through `cachedEntries()`, eliminate `DictionaryAdminPage`'s `loadDrafts()` full scan and triple-reload, and dispose the `note` controller.
- Fix `SmartImage` double-DPR scaling (`&w=$maxLogicalWidth&dpr=$dpr`) + `preferDirectFirst: !kIsWeb` + add `cacheWidth` to avatars/horse cards/logo.
- Add `SetOptions(merge: true)` to `createOrUpdateRiderProfile`, fix `TransferHorseCubit` public profile fallback, check `before` vs `after` diff in `syncPublicRiderProfile`/`syncPublicHorseProfile`, gate eager legacy `Skills` stream, parallelize `SkillTreeV2Cubit.initialize()`, add `syncProfile()` in-flight guard, and cache per-profile V2 progress.
- Replace animated double `BackdropFilter` in `_GlassModalBarrier` and `PersonalizedLogbookBackdrop` (`wsrv.nl` `&blur=` or single `ImageFiltered`), enable Firestore Web persistence, and fix `dispose()` temp upload cleanup + `AddHorseDialogCubit` ID mismatch.

### Medium / Architectural Improvements (Planned Multi-File Batches)
- Publish versioned immutable JSON CDN bundles for Dictionary and Skill Tree 2.0 backed by a provider-independent persistent local cache (`0–1` Firestore read/session).
- Split `AppState` or apply targeted `BlocSelector` / `context.select` / `buildWhen` across the 63 unfiltered UI subscribers; virtualize Dictionary, Skill Tree V2, Comments, and Admin Inbox with slivers; combine `DictionaryMatcher` into a single-pass alternation `RegExp`.
- Paginate `Resources`, extract `comments` & `usersWhoRated` into subcollections/counters, paginate `SharedRidingEntries` & `SkillVerificationEvents`, and replace `requestAccountDeletion`'s `1 + 3R` full `Resources` scan.
- Consolidate `previewMeta` + `fetchReadable` + `resolveImage` into one `fetchLinkPreview` callable and add WebP/JPEG image resizing + thumbnail generation + scheduled orphan sweep (`cleanupAbandonedDraftMedia`).
- Split `packages/database_repository` into provider-independent domain contracts + Firebase adapter package and eliminate the 6 non-composition Firebase imports in `lib/`.

---

## 6. Recommended Implementation Order

Execute strictly in owner-authorized batches with targeted tests after each batch:

- **Batch 1 — Security, Abuse Prevention & Hard Correctness Bugs:** Harden `previewMeta`/`fetchReadable`/`resolveImage`, `sharePreview`, `firebase/storage.rules`, track `firestore.indexes.json`, and fix `createOrUpdateRiderProfile`, `SkillVerificationEvents` coach list rule/query, and `TransferHorseCubit`.
- **Batch 2 — Zero-Risk Asset, Cold-Start & Cache-Buster Quick Wins:** Clean `web/index.html` v8 scripts, prune `3.41 MB` unused assets + optimize OG/seasonal PNGs, lazy-load `jsdom`/`cheerio`, fix `DictionaryPage._detail` regex cache-buster + `cachedEntries()`, fix `DictionaryAdminPage` triple-reload/`loadDraft(id)`/leak, fix `SmartImage` DPR/`cacheWidth`, fix community upload `dispose()` + `AddHorseDialogCubit` ID mismatch + `Cache-Control`, wire scheduled `cleanupAbandonedDraftMedia`.
- **Batch 3 — Firestore Read/Write Cost Elimination & Caching:** Gate legacy `Skills` stream, enable Web Firestore persistence, parallelize & guard `SkillTreeV2Cubit` + optimistic assessment + delta `SkillTreeV2Sync`, diff-guard `syncPublic*` triggers, deploy provider-independent CDN JSON + local cache for Dictionary & Skill Tree 2.0, unify `fetchLinkPreview`, fix `requestAccountDeletion` `1 + 3R` scan & timeout.
- **Batch 4 — Flutter / CanvasKit Rendering Smoothness:** Fix animated double `BackdropFilter` & `PersonalizedLogbookBackdrop`, add `buildWhen`/`context.select` across `ResourcesItem`/`SkillTreeV2View`/Profiles/`CommentItem`, memoize `_articleSnippet`/`MarkdownBioText`/`diffWords`, single-pass `DictionaryMatcher`, convert primary lists to slivers.
- **Batch 5 — Scale-Ready Data Model, Media Thumbnails & Database Independence:** Paginate `Resources` + move `comments`/`ratings` to subcollections, paginate `SharedRidingEntries`, add server/client WebP thumbnails + full orphan cleanup on resource/horse deletes, add `deferred as` route splitting for Admin/Quill/WebView, and split `packages/database_repository` cleanly.

---

## 7. Risks & Regression-Test Requirements

| Change Area | Primary Regression Risk | Required Tests Before Shipping |
|---|---|---|
| Storage & Firestore Rules (`Batch 1`) | Breaking legitimate client photo/PDF uploads or coach verification views | Expand `firebase/storage.rules.test.cjs` and `firebase/firestore.rules.test.cjs` for `Riders_Photo`, `Horses_Photo`, `resources/pdfs`, `covers`, and coach `list` on `SkillVerificationEvents` under Firebase Emulator. |
| Public HTTP Endpoints (`Batch 1, 3`) | Social crawlers (Facebook/iMessage/X) failing previews if `sharePreview` or CORS headers break; `ResourceImage` fallback breaking | Add Node tests in `functions/test/share_preview.test.js` & `functions/test/` verifying allowed hosts, SSRF IP rejection, unauthenticated rejection on link scrapers, and bot OG tag rendering. |
| Catalogue & Subcollection Caching (`Batch 2, 3`) | Stale curriculum or Dictionary entries after admin publish; missing `ProfileSkills` updates after V2 save | Widget & integration tests in `test/dictionary/` and `test/widget/` verifying cache invalidation on revision change, offline asset fallback, and Profile ↔ Skill Tree 2.0 sync. |
| Profile Mirror Triggers & Deletion (`Batch 3`) | Public profiles drifting out of sync when `isPublic` or shared fields change; incomplete account deletion | Extend `functions/test/public_horse_profile.test.js`, `profile_privacy.test.js`, and `account_deletion_emulator.js`. |
| `BackdropFilter`, `buildWhen` & Slivers (`Batch 4`) | Dropped glass dialog visuals or missed UI updates when `AppState` fields change | Run `test/widget/glass_dialog_test.dart`, `test/dictionary/dictionary_definition_dialog_animation_test.dart`, and add widget rebuild-counter tests for `ResourcesItem` and `SkillTreeV2View`. |
| Media Resize & Deletion Cleanup (`Batch 2, 5`) | EXIF orientation/transparency loss or unintended deletion of still-referenced published images | Add tests in `test/dictionary/dictionary_image_performance_test.dart` & `functions/test/dictionary.test.js` verifying WebP/JPEG sizing, Storage metadata `Cache-Control`, and reference-safe cleanup. |

---

## 8. Firebase Cost Projections & Assumptions (100 / 1,000 / 10,000 DAU)

> **Important Distinction:** Per-journey Firestore read/write counts come from **Code-Traced** source behavior; dataset growth, DAU session frequency, image views, and monthly bills below are **Estimated** models under Firebase Blaze multi-region (`nam5`) list pricing (excluding external `wsrv.nl` third-party bandwidth and ignoring unpredictable unauthenticated bot/abuse spikes called out separately).

### 8.1 Pricing Basis & Modeling Assumptions
- **Blaze List Rates & Free Tiers (30-day month):**
  - Firestore (`nam5` multi-region conservative baseline): **\$0.06 / 100K reads** (after `50K/day = 1.5M/mo` free), **\$0.18 / 100K writes** (after `20K/day = 600K/mo` free). *(Single-region `us-central1` is ~$0.03/$0.09 — roughly half.)*
  - Cloud Storage: **\$0.12 / GB egress** (US multi-region, after `1 GB/day ≈ 30 GB/mo` free), **\$0.026 / GB-month storage** (after `5 GB` free).
  - Firebase Hosting: **\$0.15 / GB transfer** (after `360 MB/day ≈ 10.8 GB/mo` free; 10 GB storage free).
  - Cloud Functions Gen2 (`us-central1`): **\$0.40 / 1M invocations** (after `2M/mo` free) + CPU/GB-sec (after `400K GB-s` & `200K GHz-s` free).
- **Simulated Dataset Growth (Estimated as app scales with users):**
  - `100 DAU`: `N_legacy_skills = 84`, `N_resources = 60`, `N_dictionary_entries = 60`, `N_progress = 20`, `N_connections = 3`.
  - `1,000 DAU`: `N_legacy_skills = 84`, `N_resources = 350`, `N_dictionary_entries = 200`, `N_progress = 35`, `N_connections = 6`.
  - `10,000 DAU`: `N_legacy_skills = 84`, `N_resources = 2,000`, `N_dictionary_entries = 600`, `N_progress = 45`, `N_connections = 10`.
- **Assumed Average Daily Activity per DAU (Estimated):**
  - Average `1.5` cold starts/Web reloads per DAU/day (`80%` Web / `20%` Mobile); `75%` open Resources tab (`~10` real-time updates seen while open on current global listener); `60%` open Skill Tree V2 (`3` skill taps + `1` self-assessment); `35%` trigger Dictionary / contextual match + `1.5` `/Dictionary` or `/Dictionary/:slug` navigations; `5%` create/comment/recommend/logbook/invite actions. Average full-res image `1.2 MB` uncached vs. `120 KB` cached/resized thumbnail (`25%` cache-hit ratio uncached vs. `80%` with `Cache-Control`).

### 8.2 Estimated Monthly Usage & Cost: Current Architecture vs. Post-Optimization

| Scale Tier | Metric | Current Architecture (Estimated) | Optimized (Batches 1–5) | Reduction / Monthly Bill Impact |
|---|---|---|---|---|
| **100 DAU**<br>*(3,000 DAU-days/mo)* | Firestore Reads / mo | **~2.0M – 2.8M** (`~67K–93K/day`) | **~0.25M** (`~8K/day`, inside free tier) | **~88–91% fewer reads** |
| | Firestore Writes / mo | **~25K** | **~15K** | Within 600K/mo free tier |
| | Storage Egress / mo | **~35 – 60 GB** | **~4 – 7 GB** | **~88% less egress** |
| | Hosting + Functions | ~15 GB Hosting, ~12K CF calls | ~5 GB Hosting, ~4K CF calls | Mostly free tier |
| | **Est. Monthly Bill** | **~\$1.50 – \$5.50 / mo** *(already crosses Firestore & Storage free tiers!)* | **~\$0.00 – \$0.50 / mo** *(within Blaze free tiers)* | Clears Blaze free-tier cliff |
| **1,000 DAU**<br>*(30,000 DAU-days/mo)* | Firestore Reads / mo | **~45M – 70M** (`N_resources` & `N_dict` scaling quadratically!) | **~2.5M – 4.0M** | **~93–94% fewer reads** |
| | Firestore Writes / mo | **~280K** | **~160K** | `syncPublic*` diff saves ~40% |
| | Storage Egress / mo | **~400 – 650 GB** | **~35 – 65 GB** | **~90% less egress** |
| | Hosting + Functions | ~150 GB Hosting, ~130K CF calls | ~45 GB Hosting, ~40K CF calls | Lower CF RAM/duration |
| | **Est. Monthly Bill** | **~\$95 – \$140 / mo** | **~\$6 – \$13 / mo** | **~90% monthly cost reduction** |
| **10,000 DAU**<br>*(300,000 DAU-days/mo)* | Firestore Reads / mo | **~1.5B – 2.2B** *(if `Resources` hits 2,000 & Dict 600 unpaginated!)* | **~25M – 45M** | **~97–98% fewer reads** |
| | Firestore Writes / mo | **~2.8M** | **~1.6M** | Saves `~1.2M` mirror writes |
| | Storage Egress / mo | **~4,000 – 6,500 GB (4–6.5 TB)** | **~350 – 650 GB** | **~90% less egress** |
| | Hosting + Functions | ~1.5 TB Hosting (~$225), ~1.5M CF calls | ~450 GB Hosting (~$66), ~400K CF calls | Code-split + `cache-control` |
| | **Est. Monthly Bill** | **~\$1,650 – \$2,400+ / mo** | **~\$135 – \$210 / mo** | **~91% monthly cost reduction** |

> **Critical Abuse / Bot Multiplier Warning (Non-Linear Risk):** Because `previewMeta`, `fetchReadable`, and `resolveImage` (`functions/index.js:509-677`), `sharePreview` `no-store` missing slugs (`share_preview.js:230-246`), and `storage.rules` (`Riders_Photo` / `Horses_Photo` / `resources/pdfs`) are currently unprotected, even **a single external scraper, SEO crawler, or abusive actor** at 100 DAU can generate hundreds of dollars in Cloud Run/Firestore/Storage abuse charges overnight before real user traffic grows.

### 8.3 Primary Cost Drivers & Scaling Thresholds
1. **Firestore 50K/day Free-Tier Cliff:** Crossed at roughly **~60–100 DAU** today (mostly from eager legacy `Skills`, unpaginated `Resources`, `Source.server` Dictionary reloads, and `SkillTreeV2` duplicate bursts). With Batch 2–3 caching, 50K reads/day supports **~600–700 DAU**.
2. **`Resources` Document 1 MiB & Fan-Out Cliff:** Embedding unbounded `comments` + `usersWhoRated` arrays directly on `Resources/{id}` causes every live snapshot read and edit to multiply in bytes transferred and risks hitting Firestore's **1 MiB document limit** on active articles.
3. **`requestAccountDeletion` 60s Timeout Cliff:** Sequential `1 + 3R` `Resources` scanning fails once `Resources` reaches **~300–600 documents**.
4. **`fetchReadable` 512 MiB OOM Cliff:** Concurrent `new JSDOM(html)` parses on multi-MB web pages (`concurrency: 80`) risk container restarts and retries.
5. **Storage Egress & Orphan Accumulation:** Full-resolution images without thumbnails or `Cache-Control` become the #2 line item after Firestore reads once media uploads grow, reaching **$50–$80/mo** even at 1,000 DAU.

---

## 9. Outstanding Measurements Requiring Production Telemetry

The following runtime metrics cannot be measured from static source code or local headless tests and should be observed using **zero-cost native tools** (Firebase/Google Cloud Console + Chrome DevTools):

1. **Live Web CanvasKit Frame Times (FPS & Raster Jank):** Profile `_GlassModalBarrier` dialog open/close, `PersonalizedLogbookBackdrop` scrolling, and `DictionaryPage._detail` open on mid-tier Android Chrome & iOS Safari via Chrome DevTools Performance trace (no paid APM needed).
2. **Actual Wire Payload (`gzip`/`brotli`) & LCP/TTI:** Measure `main.dart.js`, `canvaskit.wasm`, and initial Firestore/CDN waterfall via Chrome DevTools Network panel throttling (`Fast 3G` / `Slow 4G`) against Hosting.
3. **Production Firestore Read/Write Breakdown by Operation:** Check GCP Console → Firestore → **Monitoring / Usage** (`Document Reads`, `Document Writes`, `Active Connections`) to establish true baseline daily reads per user and verify rule read multiplier.
4. **Actual `sharePreview` Bot vs. Human Traffic & Cold-Start p50/p95:** Check GCP Console → Cloud Run / Cloud Functions metrics for `sharePreview`, `previewMeta`, `fetchReadable`, `resolveImage`, and `coachingConnection` invocation counts, latency histograms, and container memory peaks.
5. **`SmartImage` Live Fallback & `resolveImage` Failure Rate:** Inspect `resolveImage` HTTP 200 invocation count in Cloud Run metrics to see how often dead external resource thumbnails are triggering backend scrapes.
6. **Current Storage Bucket Size, Egress & Orphan Ratio:** Inspect GCP Console → Cloud Storage → Bucket metrics (`Total Bytes`, `Network Egress`) and compare total objects in `dictionary_drafts/`, `dictionary_submissions/`, `dictionary_public/`, `Horses_Photo/`, `covers/`, and `resources/pdfs/` against active Firestore references.

---

## 10. Implemented Optimizations & Verified Results

The following security, performance, caching, and cost-reduction batches were implemented locally on `main` (without deploying to Firebase or pushing to GitHub):

### 10.1 Local Commit History

| Batch | Commit | Summary |
|---|---|---|
| **Batch 1.1** | `1365c21` | Hardened `previewMeta`, `fetchReadable`, and `resolveImage` against SSRF (`functions/link_preview.js` IP/DNS/redirect/size/time/rate limits + CORS allowlist + verified Firebase ID token enforcement on scrapers); lazy-loaded `jsdom`, `@mozilla/readability`, `cheerio`, and `cors`; hardened `sharePreview` (host allowlist, `Public_Horse_Profile`, `index.html` RAM cache, missing-slug CDN cache headers); added diff-guards to `syncPublicRiderProfile`/`syncPublicHorseProfile`; pruned test/script files via `firebase.json` `functions.ignore`. |
| **Batch 1.2** | `268c792` | Enforced ownership, email verification, MIME allowlists, and `10 MB` image / `25 MB` PDF size limits in `firebase/storage.rules` (UID-scoped + legacy fallbacks); aligned `CloudRepository`, `AddHorseDialogCubit` (`ViewUtils.createId()`, 1600 px image cap), `EditRiderProfileCubit` (1600 px cap), `CreateArticleCubit`, and `CreateResourceDialogCubit` (UID-scoped PDFs, `AuthGateway` token); expanded `account_deletion.js` Storage cleanup & emulator Storage tests. |
| **Batch 2** | `755625a` | Replaced stacked `BackdropFilter` passes in `_GlassModalBarrier` and `PersonalizedLogbookBackdrop` (`ImageFiltered`); cached light/dark `ThemeData` in `SettingsController`; replaced `.toMap()` diff in `AppCubit._sameResources` with direct field comparison; narrowed `AppCubit` rebuild selectors in `ResourcesItem`, `ResourceInfoBar` (plus bounded Quill snippet cache), `ResourceRatingButtons`, `SaveResourceButton`, `ConnectionPanel`, `NavigationView` (`MediaQuery.sizeOf`), and `SkillTreeV2View`; upgraded `DictionaryMatcher` to single-pass longest-first alternation `RegExp` + `excludeEntryId`; fixed `DictionaryPage._detail` regex cache-busting; fixed `SmartImage` double-DPR proxy URL (`&w=$logical&dpr=$dpr`) + LRU notifier cleanup + `cacheWidth` sizing across avatars/logos/seasonal icons/horse cards; scoped `_ReviewDialog` controller disposal inside `_ReviewDialogState`. |
| **Batch 3** | `93b134d` | Made legacy `Skills` collection stream lazy (`AppCubit.ensureLegacySkillsLoaded()`); enabled Firestore Web offline persistence (`FirebaseInitialization`); replaced N live `Resources` listeners in `SkillDetailV2Panel` with deduplicated one-shot fetches; added `SetOptions(merge: true)` on `RiderProfileRepository.createOrUpdateRiderProfile` and `Public_Rider_Profile` fallback on `getRiderProfileByEmail`; added versioned `DictionaryPublic/catalogue` manifest checks + `DictionaryLocalCache` + single-doc `loadDraft(id)` in `DictionaryAdminPage` + `DictionaryRepository.cachedEntries()` in `DictionaryPage`; added `SkillTreeV2Cubit` parallel init, `syncProfile()` deduplication, per-profile cache, optimistic `setSelfAssessment()`, `FirestoreSkillTreeV2Store` snapshot TTL & `.orderBy('at', descending: true).limit(20)` on verification events, and targeted `SkillTreeV2Sync` notifications; fixed `profile_redesign_test.dart` public horse fixture. |
| **Batch 4** | `047d9f4` | Offloaded SHA-256 hashing (`compute()` for buffers `>= 64 KB`) in `DictionaryImageProcessor`; captured `MediaStorageRepository` in `didChangeDependencies()` across Dictionary community contribution/suggestion dialogs so `dispose()` cleanup works reliably; parallelized `promoteDraftMedia` Storage copy/metadata RPCs in `functions/dictionary.js`; removed 4 unused Firebase v8 JS `<script type="module">` imports from `web/index.html`; removed unused `image_network` and `flutter_network_image` packages; deferred `AdsInitialization.initializeAds()` until after `runApp()`. |
| **Test & Safety Follow-up** | `9f31be6` | Added `isClosed` guards before async `emit()` calls in `SkillTreeV2Cubit`; guarded `functions/test/profile_privacy_emulator.test.js` with `node:test` emulator-env skipping so offline CI (`npm --prefix functions test`) passes cleanly while preserving full emulator execution. |
| **Audit Documentation** | `c42f41f` | Added Section 10 optimization and baseline verification summary. |
| **Stabilization & Routing** | `c5123a8` | Fixed `/SkillTree/Skills` parent redirect in `lib/App/Routes/routes.dart` so legacy `Skill:<id>` deep links preserve `?skillId=<id>` under Skill Tree 2.0; resolved all 4 remaining Flutter test failures (`test/card_visual_preview_test.dart`, `test/widget/horse_archive_test.dart`, `test/widget/resources_visual_test.dart`, `test/routes_flow_test.dart`). |
| **Emulator & Storage Rules** | `89e4f65` | Expanded `firebase/storage.rules.test.cjs` for legacy `ownerUid`-less `Rider_Profile` / `Horse_Profile` photos and `dictionary_submissions`; fixed stale contributor rate-limit UID reuse in `dictionary_emulator.js`, coach profile ID lookup in `invitations_emulator.js`, and async `syncPublicHorseProfile` convergence polling in `account_deletion_emulator.js`. |

### 10.2 Verified Measurements

- **Cloud Functions Cold-Start Module Load (`node v22.23.4`, `require('./functions/index.js')`):**
  - Baseline (Section 3.4): `130.5 MB RSS` (`+440 ms` / `+297 ms` module load overhead)
  - Post-optimization: **`74.9–75.0 MB RSS`** and **`93.2–112.3 ms` load time** (**~42.5% lower RSS** for non-scraper functions).
- **`DictionaryMatcher` Matching Performance (`test/widget/performance_batch2_test.dart`):**
  - Single-pass longest-first alternation `RegExp` over `100` paragraphs × `500` entries: **`0 ms`**.
- **Production Web Wasm Build (`flutter build web --release --wasm --no-pub --dart-define-from-file=web_build_config.json`):**
  - Succeeded cleanly in **`55.9 s`**: `index.html` **`3.3 KB`**, `main.dart.js` (JS fallback) **`6.5 MB`**, `main.dart.mjs` **`55 KB`**, `main.dart.wasm` **`6.1 MB`**, `flutter_bootstrap.js` **`13 KB`**, `26` bundled SVGs in `build/web/assets/assets/icons/skill_families/`.
- **Static Analysis & Test Coverage Summary:**
  - `flutter analyze --no-pub lib test packages` & `packages/database_repository` `dart analyze`: **0 issues**.
  - `npm --prefix functions run lint` (`eslint .`): **0 errors / warnings**.
  - Full CI suite (`python3 tool/check.py --no-pub`, exited `0`):
    - Flutter + package suite: **`+757 ~1: All tests passed!`** (`0` failures; `1` intentional test skip in existing suite; `database_repository` coverage `69.4%`).
    - Cloud Functions unit suite: **`145` passed, `0` failed, `1` skipped** (`profile_privacy_emulator.test.js`, offline guard).
  - Firebase Emulators (`auth,firestore,storage,functions`):
    - `firebase/storage.rules.test.cjs` + `functions/test/profile_privacy_emulator.test.js`: **`6` passed, `0` failed** (covers legacy `ownerUid`-less uploads, UID-scoped photos/PDFs, `covers`, `dictionary_drafts`/`dictionary_submissions`/`dictionary_public`, owner/instructor/public Firestore projections).
    - `functions/test/dictionary_emulator.js`: **passed**.
    - `functions/test/invitations_emulator.js`: **passed**.
    - `functions/test/account_deletion_emulator.js`: **passed** (`--project demo-account-deletion`).
    - Note: `firebase/firestore.rules.test.cjs` requires `@firebase/rules-unit-testing`, which is not installed in this offline workspace.

### 10.3 Remaining Deferred Items, Manual Rollout & Rollback Plan

- **Remaining architectural items from Section 5 (not implemented in this pass):** Splitting `packages/database_repository` away from Firebase dependencies across UI layers, paginating `Resources` with subcollection `comments`/`usersWhoRated` extraction, paginating `SharedRidingEntries`, scheduled `cleanupAbandonedDraftMedia` cron deployment, and deferred library loading for Web Admin/Quill routes.
- **Manual deployment order (requires explicit project owner approval; target `horse-and-riders-compani-d2bd4`):**
  1. `firebase deploy --only firestore:rules,storage` (compatible with both old and new Web builds, including legacy `ownerUid`-less `Rider_Profile` / `Horse_Profile` photos).
  2. `firebase deploy --only functions` (hardened scrapers, `sharePreview`, parallelized `promoteDraftMedia`, diff-guarded public mirrors, `account_deletion` Storage cleanup).
  3. `flutter build web --release --wasm --no-pub --dart-define-from-file=web_build_config.json && firebase deploy --only hosting`
- **Per-component rollback:**
  - Hosting: Roll back to the prior Hosting release in Firebase Console → Hosting → Release history (or `firebase hosting:rollback`).
  - Firestore & Storage Rules: `git checkout <prior-commit> -- firebase/firestore.rules firebase/storage.rules && firebase deploy --only firestore:rules,storage`.
  - Cloud Functions: `git checkout <prior-commit> -- functions/ && firebase deploy --only functions`.
