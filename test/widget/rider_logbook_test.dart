import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/CommonWidgets/log_book_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/log_view_dialog.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

class _SharedRepository extends Mock implements ConnectionRepository {}

void main() {
  setUpAll(() => registerFallbackValue(BaseListItem()));

  testWidgets('owned horse log reads the rider entry and reflects edits', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    const email = 'rider@example.com';
    final horse = HorseProfile(
      id: 'atlas',
      name: 'Atlas',
      currentOwnerId: email,
      notes: [BaseListItem(id: 'legacy', name: 'Legacy horse note')],
    );
    BaseListItem note(String text, String horseId) => BaseListItem(
      id: 'shared',
      name: text,
      riderLog: RiderLogDetails(type: RiderLogType.training, horseId: horseId),
    );
    final rider = RiderProfile(
      id: 'rider',
      email: email,
      name: 'Rider',
      notes: [note('Shared training note', 'atlas')],
    );
    final cubit = harness.cubit;
    cubit.emit(
      cubit.state.copyWith(
        isGuest: false,
        usersProfile: rider,
        horseProfile: horse,
      ),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: LogViewDialog(
                name: 'Atlas',
                horseId: horse.id,
                notes: horse.notes,
                isRider: false,
                appContext: context,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Legacy horse note'), findsOneWidget);
    expect(find.text('Shared training note'), findsOneWidget);
    expect(horse.notes!.single.id, 'legacy');

    cubit.emit(
      cubit.state.copyWith(
        usersProfile: rider.copyWith(
          notes: [note('Edited training note', 'atlas')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shared training note'), findsNothing);
    expect(find.text('Edited training note'), findsOneWidget);

    cubit.emit(
      cubit.state.copyWith(
        usersProfile: rider.copyWith(
          notes: [note('Edited training note', 'sage')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edited training note'), findsNothing);

    cubit.emit(
      cubit.state.copyWith(
        usersProfile: rider.copyWith(
          notes: [note('Edited training note', 'atlas')],
        ),
        horseProfile: HorseProfile(
          id: 'atlas',
          name: 'Atlas',
          currentOwnerId: 'new@example.com',
          notes: horse.notes,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edited training note'), findsNothing);
    expect(find.text('Legacy horse note'), findsOneWidget);
  });

  testWidgets('new owner sees shared horse history and can refresh it', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    const email = 'new-owner@example.com';
    final horse = HorseProfile(
      id: 'atlas',
      name: 'Atlas',
      currentOwnerId: email,
    );
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(id: 'owner', email: email, name: 'Owner'),
        user: const User(id: 'owner', email: email, name: 'Owner'),
        horseProfile: horse,
      ),
    );
    final repository = _SharedRepository();
    var notes = [
      BaseListItem(
        id: 'shared',
        name: 'Practised on Atlas',
        extra: 'Previous rider',
        message: 'Alex',
        riderLog: const RiderLogDetails(
          type: RiderLogType.lesson,
          shared: true,
          authorRole: 'instructor',
        ),
      ),
    ];
    when(
      () => repository.history({'action': 'horseHistory', 'horseId': 'atlas'}),
    ).thenAnswer((_) async => notes);
    await tester.pumpWidget(
      RepositoryProvider<ConnectionRepository>.value(
        value: repository,
        child: BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: LogViewDialog(
                  name: horse.name,
                  horseId: horse.id,
                  notes: horse.notes,
                  isRider: false,
                  appContext: context,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Practised on Atlas'), findsOneWidget);
    expect(find.textContaining('Rider: Previous rider'), findsOneWidget);
    expect(find.textContaining('Added by instructor Alex'), findsOneWidget);

    notes = [];
    await tester.tap(find.text('Refresh shared history'));
    await tester.pumpAndSettle();
    expect(find.text('Practised on Atlas'), findsNothing);
    expect(find.text('No Entries in the Log'), findsOneWidget);
  });

  for (final width in [360.0, 1100.0]) {
    testWidgets('rider adds and inspects a horse-free lesson at width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      const email = 'rider@example.com';
      final profile = RiderProfile(
        id: 'rider',
        email: email,
        name: 'Morgan',
        ownedHorses: [BaseListItem(id: 'atlas', name: 'Atlas')],
        archivedHorses: [BaseListItem(id: 'retired', name: 'Retired')],
        studentHorses: [
          BaseListItem(id: 'sage', name: 'Sage'),
          BaseListItem(id: 'ghost', name: 'Ghost'),
        ],
        instructors: [
          BaseListItem(id: 'alex@example.com', name: 'Alex Trainer'),
        ],
        notes: [
          BaseListItem(
            id: 'feedback',
            name: 'Relax your shoulders',
            date: DateTime(2024),
            parentId: 'alex@example.com',
            imageUrl: 'LogTag.Training',
          ),
        ],
      );
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          usersProfile: profile,
          isGuest: false,
          user: const User(id: 'rider', email: email, name: 'Morgan'),
        ),
      );
      when(
        () => harness.horses.getAllUsersHorses(ids: ['ghost', 'sage']),
      ).thenAnswer(
        (_) => Stream.value([
          HorseProfile(id: 'sage', name: 'Sage'),
          HorseProfile(id: 'ghost', name: 'Ghost', archiveStatus: 'archived'),
        ]),
      );
      var failWrite = true;
      when(
        () => harness.riders.saveRiderLogEntry(
          email: email,
          entry: any(named: 'entry'),
          isEdit: any(named: 'isEdit'),
        ),
      ).thenAnswer((invocation) async {
        if (failWrite) throw StateError('Save failed');
        final entry = invocation.namedArguments[#entry] as BaseListItem;
        final current = harness.cubit.state.usersProfile!;
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            usersProfile: current.copyWith(
              notes: [
                ...current.notes!.where((note) => note.id != entry.id),
                entry,
              ],
            ),
          ),
        );
      });

      final journal = StreamController<List<BaseListItem>>.broadcast();
      addTearDown(journal.close);
      final repository = _SharedRepository();
      BaseListItem? shared;
      when(
        () => repository.watchJournal('rider'),
      ).thenAnswer((_) => journal.stream);
      when(() => repository.submit(any())).thenAnswer((invocation) async {
        final data =
            invocation.positionalArguments.single as Map<String, Object?>;
        expect(data['action'], 'saveJournal');
        final entry = BaseListItem(
          id: data['id']! as String,
          name: data['notes']! as String,
          parentId: email,
          date: DateTime.tryParse(data['date'] as String? ?? ''),
          riderLog: RiderLogDetails.fromMap({...data, 'shared': true}),
        );
        shared = entry;
        journal.add([entry]);
        final current = harness.cubit.state.usersProfile!;
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            usersProfile: current.copyWith(
              notes: current.notes!
                  .where((note) => note.id != entry.id)
                  .toList(),
            ),
          ),
        );
        return {'status': 'saved'};
      });
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RiderProfileRepository>.value(
              value: harness.riders,
            ),
            RepositoryProvider<HorseProfileRepository>.value(
              value: harness.horses,
            ),
            RepositoryProvider<ConnectionRepository>.value(value: repository),
          ],
          child: BlocProvider.value(
            value: harness.cubit,
            child: MaterialApp(
              home: Scaffold(
                body: LogBookButton(profile: profile, horseProfile: null),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text("Rider's Log Book"));
      await tester.pump();
      journal.add([]);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Added by instructor Alex Trainer'),
        findsOneWidget,
      );
      await tester.tap(find.text('Relax your shoulders'));
      await tester.pumpAndSettle();
      expect(find.text('Edit entry'), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add entry'));
      await tester.pumpAndSettle();
      expect(find.text('What would you like to log?'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<RiderLogType>), findsNothing);
      final lesson = find.byKey(const ValueKey('logType-lesson'));
      final reflection = find.byKey(const ValueKey('logType-reflection'));
      final date = find.byKey(const Key('logEntryDate'));
      final horse = find.byKey(const ValueKey('logEntryHorse-self'));
      if (width < 480) {
        expect(
          tester.getTopLeft(reflection).dy,
          greaterThan(tester.getTopLeft(lesson).dy),
        );
        expect(
          tester.getTopLeft(horse).dy,
          greaterThan(tester.getBottomLeft(date).dy),
        );
      } else {
        expect(tester.getTopLeft(reflection).dy, tester.getTopLeft(lesson).dy);
        expect(
          tester.getTopLeft(horse).dx,
          greaterThan(tester.getTopRight(date).dx),
        );
      }

      await tester.tap(date);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('logType-show')));
      await tester.pumpAndSettle();
      expect(find.text('Instructor (optional)'), findsNothing);
      await tester.tap(lesson);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('logEntryStudent')), findsNothing);
      final notes = find.widgetWithText(TextFormField, 'Notes');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Instructor (optional)'),
        'Alex',
      );
      await tester.enterText(notes, 'Practised transitions');
      final save = find.text('Save entry');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Save failed'), findsOneWidget);
      expect(find.text('Practised transitions'), findsOneWidget);

      failWrite = false;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final saved = harness.cubit.state.usersProfile!.notes!.last;
      expect(saved.riderLog?.type, RiderLogType.lesson);
      expect(saved.riderLog?.horse, isNull);
      expect(saved.riderLog?.instructor, 'Alex');
      expect(
        tester.getTopLeft(find.text('Practised transitions')).dy,
        lessThan(tester.getTopLeft(find.text('Relax your shoulders')).dy),
      );

      await tester.tap(find.text('Newest first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oldest first').last);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Practised transitions')).dy,
        greaterThan(tester.getTopLeft(find.text('Relax your shoulders')).dy),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Lesson'));
      await tester.pumpAndSettle();
      expect(find.text('Relax your shoulders'), findsNothing);
      await tester.tap(find.text('Practised transitions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('logType-show')));
      await tester.pumpAndSettle();
      final horseField = find.byKey(const ValueKey('logEntryHorse-self'));
      await tester.ensureVisible(horseField);
      await tester.tap(horseField);
      await tester.pumpAndSettle();
      expect(find.text('Sage'), findsOneWidget);
      expect(find.text('Retired'), findsNothing);
      expect(find.text('Ghost'), findsNothing);
      await tester.tap(find.text('Atlas').last);
      await tester.pumpAndSettle();
      final placing = find.widgetWithText(TextFormField, 'Placing (optional)');
      await tester.enterText(placing, '2nd');
      await tester.enterText(notes, 'Updated transitions');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'All entries'));
      await tester.pumpAndSettle();
      expect(find.text('Updated transitions'), findsOneWidget);
      expect(find.text('2nd'), findsOneWidget);
      var updated = shared!;
      expect(updated.id, saved.id);
      expect(updated.riderLog?.horseId, 'atlas');
      expect(updated.riderLog?.horse, 'Atlas');
      expect(updated.riderLog?.placing, '2nd');

      await tester.tap(find.text('Updated transitions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit entry'));
      await tester.pumpAndSettle();
      expect(find.text('Atlas'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('logType-reflection')));
      await tester.pumpAndSettle();
      expect(placing, findsNothing);
      await tester.ensureVisible(horseField);
      await tester.tap(horseField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Horse name'),
        'Milo',
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      updated = shared!;
      expect(updated.riderLog?.horse, 'Milo');
      expect(updated.riderLog?.horseId, isNull);
      expect(updated.riderLog?.placing, isNull);
      expect(find.text('2nd'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('trainer lesson uses the selected accepted student and horse', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    const email = 'coach@example.com';
    final profile = RiderProfile(
      id: 'coach',
      email: email,
      name: 'Coach',
      isTrainer: true,
      ownedHorses: [BaseListItem(id: 'own', name: 'Coach horse')],
    );
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: profile,
        user: const User(id: 'coach', email: email, name: 'Coach'),
      ),
    );
    final repository = _SharedRepository();
    final connections = StreamController<List<CoachingConnection>>.broadcast();
    when(() => repository.watch('coach')).thenAnswer((_) => connections.stream);
    when(
      () => repository.watchJournal('coach'),
    ).thenAnswer((_) => Stream.value([]));
    when(() => repository.submit(any())).thenAnswer((invocation) async {
      final data =
          invocation.positionalArguments.single as Map<String, Object?>;
      if (data['action'] == 'horseOptions') {
        expect(data['id'], 'accepted');
        return {
          'horses': [
            {'id': 'atlas', 'name': 'Atlas'},
          ],
        };
      }
      return {'status': 'accepted'};
    });
    final cubit = ConnectionsCubit(repository, harness.cubit);
    addTearDown(() async {
      await cubit.close();
      await connections.close();
    });
    await tester.pumpWidget(
      RepositoryProvider<ConnectionRepository>.value(
        value: repository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: harness.cubit),
            BlocProvider.value(value: cubit),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LogBookButton(profile: profile, horseProfile: null),
            ),
          ),
        ),
      ),
    );
    CoachingConnection link(String id, String status, String name) =>
        CoachingConnection(id, {
          'kind': 'rider',
          'status': status,
          'version': 'v1',
          'coach': email,
          'coachName': 'Coach',
          'sender': '$id@example.com',
          'recipient': email,
          'learner': '$id@example.com',
          'learnerName': name,
        });
    connections.add([
      link('accepted', 'accepted', 'Morgan'),
      link('pending', 'pending', 'Pending Rider'),
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Rider's Log Book"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('logType-lesson')));
    await tester.pumpAndSettle();
    final student = find.byKey(const Key('logEntryStudent'));
    await tester.ensureVisible(student);
    await tester.tap(student);
    await tester.pumpAndSettle();
    expect(find.text('Pending Rider'), findsNothing);
    await tester.tap(find.text('Morgan').last);
    await tester.pumpAndSettle();
    final horse = find.byKey(const ValueKey('logEntryHorse-accepted'));
    await tester.ensureVisible(horse);
    await tester.tap(horse);
    await tester.pumpAndSettle();
    expect(find.text('Coach horse'), findsNothing);
    await tester.tap(find.text('Atlas').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes'),
      'Worked on transitions',
    );
    final save = find.text('Save entry');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final requests = verify(() => repository.submit(captureAny())).captured;
    expect(requests, [
      {'action': 'horseOptions', 'id': 'accepted', 'version': 'v1'},
      allOf(
        containsPair('action', 'record'),
        containsPair('id', 'accepted'),
        containsPair('horseId', 'atlas'),
        containsPair('notes', 'Worked on transitions'),
      ),
    ]);
    expect(find.text('Worked on transitions'), findsNothing);
    expect(find.text('Rider logbook'), findsOneWidget);
  });
}
