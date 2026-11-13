import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/coaching_connection.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_failure.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/cubit/logbook_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/in_memory_logbook_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart';

import '../support/app_test_harness.dart';

void main() {
  group('Rider Logbook backend independence', () {
    const riderEmail = 'rider@example.com';
    const riderUid = 'rider-uid-1';

    RiderProfile buildRider() => RiderProfile(
      id: riderUid,
      email: riderEmail,
      name: 'Alex Rider',
    );

    BaseListItem buildLocalEntry(String id, String text) => BaseListItem(
      id: id,
      name: text,
      date: DateTime(2026, 5, 10),
      parentId: riderEmail,
      riderLog: const RiderLogDetails(
        type: RiderLogType.training,
        title: 'Flatwork',
        focus: 'Transitions',
      ),
    );

    test(
      'LogbookCubit creates, edits, deletes, and streams entries in memory',
      () async {
        final profileRepo = InMemoryLogbookRiderProfileRepository(
          initialProfiles: {riderEmail: buildRider()},
        );
        final connectionRepo = InMemoryLogbookConnectionRepository(
          defaultUid: riderUid,
          riderProfileRepository: profileRepo,
          horseOptionsByConnectionId: {
            'conn-1': const [
              {'id': 'h1', 'name': 'Apollo'},
            ],
          },
        );
        addTearDown(connectionRepo.dispose);

        final cubit = LogbookCubit(
          connectionRepository: connectionRepo,
          riderProfileRepository: profileRepo,
        );
        addTearDown(cubit.close);

        final journalEvents = <List<BaseListItem>>[];
        final sub = connectionRepo.watchJournal(riderUid).listen(
          journalEvents.add,
        );
        addTearDown(sub.cancel);

        // Local entry create & edit
        final createdLocal = buildLocalEntry('local-1', 'Initial notes');
        await cubit.saveLocalEntry(
          rider: profileRepo.profileFor(riderEmail)!,
          isEdit: false,
          entry: createdLocal,
        );
        expect(profileRepo.profileFor(riderEmail)?.notes?.length, 1);

        final editedLocal = buildLocalEntry('local-1', 'Updated notes');
        await cubit.saveLocalEntry(
          rider: profileRepo.profileFor(riderEmail)!,
          isEdit: true,
          entry: editedLocal,
        );
        expect(
          profileRepo.profileFor(riderEmail)?.notes?.single.name,
          'Updated notes',
        );

        // Shared journal create, edit, history, delete with realtime stream
        await cubit.saveSharedJournalEntry(
          id: 'shared-1',
          isEdit: false,
          shared: true,
          date: DateTime(2026, 5, 2),
          notes: 'Shared ride notes',
          details: const RiderLogDetails(
            type: RiderLogType.lesson,
            shared: true,
            horseId: 'h1',
            horse: 'Apollo',
            title: 'Jump school',
          ),
        );
        expect(
          connectionRepo.entriesFor(riderUid).single.name,
          'Shared ride notes',
        );

        await cubit.saveSharedJournalEntry(
          id: 'shared-1',
          isEdit: true,
          shared: true,
          date: DateTime(2026, 5, 2),
          notes: 'Edited shared notes',
          details: const RiderLogDetails(
            type: RiderLogType.lesson,
            shared: true,
            horseId: 'h1',
            horse: 'Apollo',
            title: 'Jump school',
          ),
        );
        expect(
          connectionRepo.entriesFor(riderUid).single.name,
          'Edited shared notes',
        );

        final horseHistory = await connectionRepo.history({
          'action': 'horseHistory',
          'horseId': 'h1',
        });
        expect(horseHistory.map((e) => e.id), ['shared-1']);

        final student = CoachingConnection('conn-1', {
          'version': 'v2',
          'kind': 'coaching',
          'status': 'accepted',
          'sender': 'coach@example.com',
          'recipient': riderEmail,
          'learner': riderEmail,
          'coach': 'coach@example.com',
          'learnerName': 'Alex Rider',
          'coachName': 'Coach',
        });
        final options = await cubit.fetchStudentHorseOptions(student);
        expect(options, {'horse:h1': 'Apollo'});

        await cubit.saveStudentLesson(
          student: student,
          recordId: 'lesson-1',
          notes: 'Verified skill work',
          isEdit: false,
          skillId: 'skill-1',
        );
        expect(
          profileRepo.profileFor(riderEmail)?.skillLevels?.any(
                (s) => s.skillId == 'skill-1' && s.verified,
              ),
          isTrue,
        );

        await cubit.deleteEntry(
          BaseListItem(
            id: 'shared-1',
            riderLog: const RiderLogDetails(
              type: RiderLogType.lesson,
              shared: true,
            ),
          ),
        );
        expect(
          connectionRepo.entriesFor(riderUid).map((e) => e.id),
          ['lesson-1'],
        );

        await pumpEventQueue();
        expect(journalEvents.first, isEmpty);
        expect(
          journalEvents.any(
            (e) => e.any((n) => n.name == 'Shared ride notes'),
          ),
          isTrue,
        );
        expect(journalEvents.last.map((e) => e.id), ['lesson-1']);
      },
    );

    test('LogbookCubit handles failed saves cleanly in memory', () async {
      final profileRepo = InMemoryLogbookRiderProfileRepository(
        initialProfiles: {riderEmail: buildRider()},
      );
      final connectionRepo = InMemoryLogbookConnectionRepository(
        defaultUid: riderUid,
      );
      addTearDown(connectionRepo.dispose);

      final cubit = LogbookCubit(
        connectionRepository: connectionRepo,
        riderProfileRepository: profileRepo,
      );
      addTearDown(cubit.close);

      connectionRepo.nextSubmitError = const ConnectionFailure('Network down');
      await expectLater(
        () => cubit.saveSharedJournalEntry(
          id: 'fail-1',
          isEdit: false,
          shared: true,
          date: DateTime(2026, 5, 3),
          notes: 'Unsaved draft',
          details: const RiderLogDetails(
            type: RiderLogType.training,
            shared: true,
          ),
        ),
        throwsA(isA<ConnectionFailure>()),
      );
      expect(cubit.state.actionInProgress, isFalse);
      expect(cubit.state.feedback, 'Network down');
      expect(connectionRepo.entriesFor(riderUid), isEmpty);

      profileRepo.nextSaveError = const ConnectionFailure('Disk write failed');
      await expectLater(
        () => cubit.saveLocalEntry(
          rider: profileRepo.profileFor(riderEmail)!,
          isEdit: false,
          entry: buildLocalEntry('fail-local', 'Draft'),
        ),
        throwsA(isA<ConnectionFailure>()),
      );
      expect(cubit.state.actionInProgress, isFalse);
      expect(profileRepo.profileFor(riderEmail)?.notes, isEmpty);
    });

    test(
      'LogbookCubit works identically with Firebase-backed '
      'RiderProfileRepository',
      () async {
        final firestore = FakeFirebaseFirestore();
        final firebaseProfileRepo = RiderProfileRepository(
          firestore: firestore,
        );
        await firebaseProfileRepo.createOrUpdateRiderProfile(
          riderProfile: buildRider(),
        );
        final connectionRepo = InMemoryLogbookConnectionRepository(
          defaultUid: riderUid,
        );
        addTearDown(connectionRepo.dispose);

        final cubit = LogbookCubit(
          connectionRepository: connectionRepo,
          riderProfileRepository: firebaseProfileRepo,
        );
        addTearDown(cubit.close);

        await cubit.saveLocalEntry(
          rider: buildRider(),
          isEdit: false,
          entry: buildLocalEntry('fb-1', 'Saved via Firestore repo'),
        );
        final saved = await firebaseProfileRepo.getRiderProfileByEmail(
          email: riderEmail,
        );
        expect(saved?.notes?.single.name, 'Saved via Firestore repo');
      },
    );

    testWidgets(
      'RiderLogbookPage renders and updates using only backend-neutral '
      'interfaces',
      (tester) async {
        final harness = await AppTestHarness.create();
        addTearDown(harness.close);

        final profileRepo = InMemoryLogbookRiderProfileRepository(
          initialProfiles: {riderEmail: buildRider()},
        );
        final connectionRepo = InMemoryLogbookConnectionRepository(
          defaultUid: riderUid,
          initialJournals: {
            riderUid: [
              BaseListItem(
                id: 'shared-entry-1',
                name: 'Initial shared note',
                date: DateTime(2026, 5, 4),
                parentId: riderEmail,
                isSelected: true,
                riderLog: const RiderLogDetails(
                  type: RiderLogType.lesson,
                  shared: true,
                  title: 'Dressage Lesson',
                ),
              ),
            ],
          },
        );
        addTearDown(connectionRepo.dispose);

        harness.cubit.emit(
          harness.cubit.state.copyWith(
            isGuest: false,
            user: const User(
              id: riderUid,
              email: riderEmail,
              name: 'Alex Rider',
            ),
            usersProfile: buildRider(),
          ),
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<LogbookConnectionRepository>.value(
                value: connectionRepo,
              ),
              RepositoryProvider<LogbookRiderProfileRepository>.value(
                value: profileRepo,
              ),
            ],
            child: BlocProvider.value(
              value: harness.cubit,
              child: const MaterialApp(
                home: RiderLogbookPage(email: riderEmail),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dressage Lesson'), findsOneWidget);

        // Realtime stream update from the in-memory repository updates the UI.
        connectionRepo.seedJournal(riderUid, [
          BaseListItem(
            id: 'shared-entry-2',
            name: 'Streamed note',
            date: DateTime(2026, 5, 5),
            parentId: riderEmail,
            isSelected: true,
            riderLog: const RiderLogDetails(
              type: RiderLogType.training,
              shared: true,
              title: 'Canter Poles',
            ),
          ),
        ]);
        await tester.pumpAndSettle();

        expect(find.text('Canter Poles'), findsOneWidget);
        expect(find.text('Dressage Lesson'), findsNothing);
      },
    );
  });
}
