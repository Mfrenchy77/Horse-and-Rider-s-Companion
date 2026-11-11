import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_list_of_profiles.dart';

import '../support/app_test_harness.dart';

void main() {
  testWidgets('owner can archive as deceased and restore from the archive', (
    tester,
  ) async {
    final actions = <Map<String, Object?>>[];
    final harness = await AppTestHarness.create(
      submitCoachingAction: (data) async {
        actions.add(data);
        return {'status': data['archiveStatus']};
      },
    );
    addTearDown(harness.close);
    const email = 'owner@example.com';
    final link = BaseListItem(id: 'atlas', name: 'Atlas', isCollapsed: false);
    final owner = RiderProfile(
      id: 'owner',
      email: email,
      name: 'Owner',
      ownedHorses: [link],
    );
    final horse = HorseProfile(
      id: 'atlas',
      name: 'Atlas',
      currentOwnerId: email,
    );
    final cubit = harness.cubit;
    cubit.emit(
      cubit.state.copyWith(
        isGuest: false,
        usersProfile: owner,
        horseProfile: horse,
      ),
    );
    Future<void> showProfile(RiderProfile rider) => tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [HorseProfileOverFlowMenu()]),
            body: RiderListOfProfiles(profile: rider),
          ),
        ),
      ),
    );
    await showProfile(owner);
    await tester.pumpAndSettle();
    expect(find.text('Owned horses'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Transfer'), findsNothing);
    expect(find.text('Remove horse'), findsNothing);
    await tester.tap(find.text('Archive horse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive as deceased'));
    await tester.pumpAndSettle();
    expect(actions.single, containsPair('archiveStatus', 'deceased'));

    final archivedOwner = RiderProfile(
      id: owner.id,
      email: owner.email,
      name: owner.name,
      archivedHorses: [link],
    );
    cubit.emit(
      cubit.state.copyWith(
        usersProfile: archivedOwner,
        horseProfile: HorseProfile(
          id: horse.id,
          name: horse.name,
          currentOwnerId: email,
          archiveStatus: 'deceased',
        ),
      ),
    );
    await showProfile(archivedOwner);
    await tester.pumpAndSettle();
    expect(find.text('Owned horses'), findsNothing);
    expect(find.text('Archived horses'), findsOneWidget);
    expect(find.text('Atlas'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore horse'));
    await tester.pumpAndSettle();
    expect(actions.last, containsPair('archiveStatus', 'active'));
  });
}
