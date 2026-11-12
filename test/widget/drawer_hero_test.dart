import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

import '../support/app_test_harness.dart';

void main() {
  testWidgets('drawer hamburger hero morphs to close', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (context) => Hero(
                tag: 'drawer-hamburger-x',
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                const SizedBox(height: 120),
                Align(
                  alignment: Alignment.topRight,
                  child: Hero(
                    tag: 'drawer-hamburger-x',
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(
                        // use a builder context later when tapped
                        tester.element(find.byType(Scaffold)),
                      ).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Open drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Close button should be present
    expect(find.byIcon(Icons.close), findsWidgets);

    // Tap close
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    // Drawer should be closed
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets(
    'profile drawer names its season and closes from its own button',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      SharedPrefs().setSeasonalMode(isSeasonal: true);
      final season = getThemeSeason().name;
      final seasonLabel = '${season[0].toUpperCase()}${season.substring(1)}';
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          usersProfile: RiderProfile(
            id: 'rider',
            email: 'a-long-email-address@example.com',
            name: 'Rider',
          ),
        ),
      );

      final scaffold = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp(
            theme: HorseAndRidersTheme().getLightTheme(),
            home: Scaffold(
              key: scaffold,
              drawer: const UserProfileDrawer(),
              body: const Text('Profile page'),
            ),
          ),
        ),
      );
      scaffold.currentState!.openDrawer();
      await tester.pumpAndSettle();
      expect(find.text(seasonLabel), findsOneWidget);

      await tester.tap(find.byTooltip('Close drawer'));
      await tester.pumpAndSettle();

      expect(scaffold.currentState!.isDrawerOpen, isFalse);
      expect(find.text('Profile page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
