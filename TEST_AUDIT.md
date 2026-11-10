# Automated test audit

Verified on **November 9, 2026** against the current app, with training paths and
prerequisite UI disabled. The suite is runnable and passing, but significant
feature and integration coverage remains incomplete.

## Results

| Check | Result |
| --- | --- |
| Flutter unit, widget and fake-repository tests | **290 passed** |
| Firebase function handler tests | **29 passed** |
| Coverage-report calculation tests | **5 passed** |
| Dart analysis of app, tests and local packages | **0 errors, 0 warnings**; 23 informational notices |
| Firebase function lint | Passed |
| Production JavaScript web build | Passed |

The selected toolchain is Flutter **3.47.9**, Dart **3.13.7**. The project pin,
editor configuration and CI now match the live manifest's newer SDK requirements.
Backend checks locally used Node **22.16.0**; the functions manifest targets Node
20 and CI is configured for Node 20.19.0. The GitHub workflow itself was not run
from this session. No deployment was performed by these validation commands.

## Defects addressed in this test round

| Problem | Resulting behavior and regression coverage |
| --- | --- |
| A loaded rider profile granted permission to edit an unrelated horse | Horse progress requires the recorded current owner or an instructor relationship. Guests and unrelated riders are rejected. |
| Saved-horse lists could be stale after a transfer | The horse's current-owner field determines ownership; an old saved entry grants no permission, and a current owner need not wait for the saved list to refresh. |
| Transfer submission could crash without a recipient or use a stale lookup result | Recipient changes immediately invalidate old results. Older lookups are ignored, self-transfers are case-insensitive, and debounce timers are canceled on close. |
| Conversation metadata and the actual transfer request could get different message IDs | A single captured message is persisted and referenced by the conversation. Failure and duplicate-submission paths are guarded. |
| Comment votes mutated shared objects before persistence and could overlap | Voting copies the comment/vote data, applies all six vote transitions, updates state after success, preserves originals on failure, and blocks overlapping rating writes. |
| Skill routes could retain stale selection or the wrong search mode | Public URLs and encoded parameters are checked. Detail/list transitions update search mode; a missing skill clears the previous selection. Shell branch changes wait until route state is current. |
| SDK metadata from a different Flutter version produced misleading compiler failures | The test runner checks the project pin and generated metadata, and uses the selected SDK for child processes. |
| Failed or partial test runs could leave misleading coverage reports | Stale generated summaries are removed, external files are ignored, duplicate lines are merged, and failed runs are marked incomplete. |
| The release build referenced a missing Cupertino icon font | The asset dependency is included, and the rebuilt web bundle contains the font. See the [official package documentation](https://pub.dev/packages/cupertino_icons). |

The new tests also exercise comment creation/replies/edits and preserve author,
date, rating and parent metadata. Existing tests continue to cover authentication,
preferences, inputs, core repository persistence, onboarding, request actions,
resource/article creation, training logs and the disabled-feature boundaries.

## Confirmed unfinished functionality

These are limitations, not successful end-to-end feature checks:

- **Accepting horse transfers is not implemented.** The existing handler was a
  placeholder, and the acceptance code could incorrectly look up a rider using
  the horse ID. Acceptance now returns a clear error, stops loading and leaves
  ownership unchanged. A regression test explicitly checks that behavior.
- **Skill-tree edit-request acceptance has a placeholder handler.** It should
  not be treated as a working approval workflow.
- **Email notifications are a stub.** The backend logs the intended email;
  there is no configured mail provider in the implementation.

## Measured line coverage

| Component | Covered / measured lines | Coverage |
| --- | ---: | ---: |
| App | 3,540 / 10,523 | 33.6% |
| Authentication repository | 101 / 160 | 63.1% |
| Database repository | 799 / 1,478 | 54.1% |
| Form inputs | 49 / 64 | 76.6% |
| Cache | 9 / 9 | 100.0% |
| **Total** | **4,498 / 12,234** | **36.8%** |

**58 source files are absent from LCOV and excluded from those percentages.**
Archived training-path and prerequisite implementation tests contribute to the
measurements. A passing suite does not mean that every app feature works.

The generated [coverage summary](coverage/summary.md) lists the largest gaps
and every absent file. Machine-readable data is in
[summary.json](coverage/summary.json), and raw line coverage is in
[lcov.info](coverage/lcov.info). These generated outputs are ignored by Git and
are recreated by the runner.

## Next coverage priorities

1. **Profile search:** stream errors, cancellation, repeated results, switching
   search types, radius queries and closing the dialog during a lookup.
2. **Profile editing and uploads:** the actual forms, file selection, canceled
   uploads, Storage failures and mobile/web plugin behavior.
3. **Remaining AppCubit workflows:** larger relationship/request lifecycles,
   account deletion and persistence failures across multiple related records.
4. **Firebase integration:** rules, indexes, authentication, two-account request
   flows, Storage and push delivery in an emulator or isolated staging project.
5. **Device/browser end-to-end checks:** responsive behavior, real OAuth,
   offline/reconnection behavior, ads and native platform initialization.

The JavaScript web build passes. Flutter's WASM dry run still reports an
unsupported `dart:html` import in `flutter_keyboard_visibility_web`; a working
WebAssembly build has not been established.

## Repeat the checks

With the documented SDK and Node/npm available:

```sh
python3 tool/check.py
```

Use `--skip-functions` for Flutter-only checks. Run **Build web for validation**
from the VS Code Tasks menu for the separate release compilation. Full setup,
focused commands, coverage semantics and CI behavior are documented in
[TESTING.md](TESTING.md).
