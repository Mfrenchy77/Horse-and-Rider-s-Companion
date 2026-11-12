# State management & side-effects

This codebase uses `flutter_bloc`.

The rule of thumb is:

- Widgets should be “dumb”. They collect user input and render state.
- Cubits own side-effects: repository calls, async flows, error mapping, and “busy” flags.

Avoid passing `BuildContext` into cubit methods unless you’re explicitly doing navigation.

If a cubit needs to notify the user, emit a message/error in state and let a top-level
listener (e.g. the one in `NavigationView`) show a SnackBar.

Why

- Prevents UI `setState` from interleaving with bloc/cubit emissions.
- Improves testability: we can unit-test cubits without building widgets.
- Keeps rebuild scopes smaller by using `context.select` / `BlocSelector`.

Patterns we use

1) UI opens a dialog → cubit does one thing

Example: horse management actions.

- UI gathers inputs in dialogs, then calls a single cubit method.
- Cubit sets an in-progress flag, performs the submit, emits a message/error.

See:

- [app_cubit.dart](/home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/App/Cubit/app_cubit.dart) (`submitHorseManageAction`)
- [horse_profile_overflow_menu.dart](/home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/HorseProfile/Widgets/horse_profile_overflow_menu.dart)

2) Feature cubits own feature side-effects

If a feature already has a cubit, prefer putting feature side-effects there instead of expanding `AppCubit`.

Example: connections + logbook.

- `ConnectionsCubit` owns coaching-connection submits for that feature.
- `LogbookCubit` owns logbook network calls and persistence.

See:

- [connection_repository.dart](/home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/Connections/connection_repository.dart)
- [logbook_cubit.dart](/home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/RiderProfile/Logbook/cubit/logbook_cubit.dart)
- [rider_logbook_page.dart](/home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart)

3) Avoid rebuilding on the whole `AppState`

Prefer watching only what you need:

- `context.select((AppCubit c) => c.state.isGuest)`
- `context.select((AppCubit c) => c.state.usersProfile?.editor ?? false)`

This is typically much cheaper than `BlocBuilder<AppCubit, AppState>`.

Dialog theming

If you need a dialog, prefer our app dialog wrapper instead of raw `AlertDialog` so:

- Ocean/Coral gradients stay consistent
- the dialog stays constrained like a dialog (not a full-screen panel)
- we avoid Flutter Web intrinsic sizing issues with complex content

See:

- [ocean_coral.dart](/home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/lib/Theme/ocean_coral.dart)

Testing

Cubits should have unit tests using `bloc_test` + `mocktail`.

Example:

- [logbook_cubit_test.dart](/home/matteo/Pictures/Projects/Horse-and-Rider-s-Companion/test/logbook/logbook_cubit_test.dart)

To run locally:

- `flutter test`

