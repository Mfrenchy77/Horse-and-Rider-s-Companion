import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_sale_panel.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

class _Repository extends Mock implements ConnectionRepository {}

void main() {
  testWidgets('owner publishes sale details that are visible to visitors', (
    tester,
  ) async {
    final repo = _Repository();
    final harness = await AppTestHarness.create(
      submitCoachingAction: repo.submit,
    );
    addTearDown(harness.close);
    const email = 'owner@example.com';
    final owner = RiderProfile(id: 'owner', email: email, name: 'Owner');
    harness.cubit.emit(
      harness.cubit.state.copyWith(isGuest: false, usersProfile: owner),
    );
    Future<void> show(HorseProfile horse) async {
      harness.cubit.emit(harness.cubit.state.copyWith(horseProfile: horse));
      await tester.pumpWidget(
        RepositoryProvider<ConnectionRepository>.value(
          value: repo,
          child: BlocProvider.value(
            value: harness.cubit,
            child: MaterialApp(
              home: Scaffold(
                appBar: AppBar(actions: const [HorseProfileOverFlowMenu()]),
                body: HorseSalePanel(horse: horse),
              ),
            ),
          ),
        ),
      );
    }

    await show(HorseProfile(id: 'atlas', name: 'Atlas', currentOwnerId: email));
    for (final action in [
      'List for sale',
      'Transfer ownership',
      'Invite trainer',
    ]) {
      expect(find.text(action), findsNothing);
    }
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Transfer ownership'), findsOneWidget);
    expect(find.text('Invite trainer'), findsOneWidget);
    Future<void> saveListing() async {
      await tester.tap(find.text('List for sale'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'General location'),
        'Bend',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sale description'),
        'School horse.',
      );
      await tester.tap(find.text('Save listing'));
      await tester.pumpAndSettle();
    }

    when(
      () => repo.submit(any()),
    ).thenThrow(const ConnectionFailure('Invalid connection ID.'));
    await saveListing();
    expect(harness.cubit.state.isError, isTrue);
    expect(
      harness.cubit.state.errorMessage,
      'Sale listings require an updated Firebase service.',
    );
    expect(find.byType(SnackBar), findsNothing);

    harness.cubit.clearErrorMessage();
    when(
      () => repo.submit(any()),
    ).thenAnswer((_) async => {'status': 'listed'});
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await saveListing();
    verify(
      () => repo.submit({
        'action': 'setSaleListing',
        'horseId': 'atlas',
        'listing': {
          'price': '',
          'location': 'Bend',
          'description': 'School horse.',
        },
      }),
    ).called(2);

    harness.cubit.emit(harness.cubit.state.copyWith(isGuest: true));
    await show(
      HorseProfile(
        id: 'atlas',
        name: 'Atlas',
        currentOwnerId: email,
        saleListing: (
          price: '',
          location: 'Bend',
          description: 'School horse.',
        ),
      ),
    );
    expect(find.text('For sale'), findsOneWidget);
    expect(find.text('Contact for price'), findsOneWidget);
    expect(find.text('School horse.'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });
}
