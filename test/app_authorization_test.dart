import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:mocktail/mocktail.dart';

import 'support/app_test_harness.dart';

class _FakeRiderProfile extends Fake implements RiderProfile {}

class _FakeResource extends Fake implements Resource {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRiderProfile());
    registerFallbackValue(_FakeResource());
  });

  late AppTestHarness harness;
  final rider = RiderProfile(id: 'r', name: 'Rider', email: 'r@example.com');
  final actions = <Map<String, Object?>>[];
  setUp(() async {
    actions.clear();
    harness = await AppTestHarness.create(
      submitCoachingAction: (action) async {
        actions.add(action);
        return {'status': 'pending'};
      },
    );
  });
  tearDown(() => harness.close());

  test(
    // ignore: lines_longer_than_80_chars
    'unfinished transfer acceptance reports an error without fetching a rider by horse ID',
    () async {
      await harness.cubit.acceptRequest(
        message: Message(
          id: 'conversation',
          messageId: 'message',
          date: DateTime.utc(2025),
          sender: 'Owner',
          subject: 'Transfer horse',
          message: 'Please accept ownership',
          recipients: const ['Rider'],
          senderProfilePicUrl: '',
          messageType: MessageType.TRANSFER_HORSE_REQUEST,
          requestItem: BaseListItem(id: 'horse-id', extra: 'owner@example.com'),
        ),
      );
      expect(harness.cubit.state.acceptStatus, AcceptStatus.waiting);
      expect(harness.cubit.state.isError, isTrue);
      expect(harness.cubit.state.errorMessage, contains('not implemented'));
      verifyZeroInteractions(harness.riders);
      verifyZeroInteractions(harness.horses);
      verifyZeroInteractions(harness.messages);
    },
  );

  test(
    'legacy instructor messages send a new request without editing profiles',
    () async {
      harness.cubit.emit(
        harness.cubit.state.copyWith(usersProfile: rider, isGuest: false),
      );
      await harness.cubit.acceptRequest(
        message: Message(
          id: 'conversation',
          messageId: 'message',
          date: DateTime.utc(2025),
          sender: 'Student',
          senderId: 'student@example.com',
          subject: 'Instructor request',
          message: 'Please be my instructor',
          recipients: const ['Rider'],
          senderProfilePicUrl: '',
          messageType: MessageType.INSTRUCTOR_REQUEST,
          requestItem: BaseListItem(id: 'student@example.com'),
        ),
      );
      expect(actions, [
        {
          'action': 'send',
          'kind': 'rider',
          'learnerEmail': 'student@example.com',
          'coachEmail': rider.email,
          'requestDocId': 'conversation',
          'fallbackRequestDocIds': [
            'conversation_message',
            'legacy_conversation_message',
          ],
        },
      ]);
      expect(harness.cubit.state.acceptStatus, AcceptStatus.submitted);
      expect(harness.cubit.state.errorMessage, contains('needs to accept'));
      verifyZeroInteractions(harness.riders);
      verifyZeroInteractions(harness.horses);
      verifyZeroInteractions(harness.messages);
    },
  );

  test('only a signed-in owner can archive a horse', () async {
    final horse = HorseProfile(
      id: 'atlas',
      name: 'Atlas',
      currentOwnerId: rider.email,
    );
    final cubit = harness.cubit;
    cubit.emit(cubit.state.copyWith(usersProfile: rider, horseProfile: horse));
    await cubit.setHorseArchive('deceased');
    expect(actions, isEmpty);
    cubit.emit(cubit.state.copyWith(isGuest: false));
    await cubit.setHorseArchive('deceased');
    expect(actions, [
      {
        'action': 'setHorseArchive',
        'horseId': 'atlas',
        'archiveStatus': 'deceased',
      },
    ]);
    expect(horse.currentOwnerId, rider.email);
    verifyZeroInteractions(harness.riders);
    verifyZeroInteractions(harness.horses);
  });

  test('guests cannot edit progress even when a profile is present', () {
    harness.cubit.emit(harness.cubit.state.copyWith(usersProfile: rider));
    expect(harness.cubit.isAuthorized(), isFalse);
  });
  test('signed-in rider can edit their own progress', () {
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        isForRider: true,
        usersProfile: rider,
      ),
    );
    expect(harness.cubit.isAuthorized(), isTrue);
  });
  for (final instructor in [true, false]) {
    test(
      'other rider progress requires an instructor relationship: $instructor',
      () {
        final other = RiderProfile(
          id: 'other',
          name: 'Other',
          email: 'other@example.com',
          instructors: instructor ? [BaseListItem(id: rider.email)] : [],
        );
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            isGuest: false,
            isForRider: true,
            isViewing: true,
            usersProfile: rider,
            viewingProfile: other,
          ),
        );
        expect(harness.cubit.isAuthorized(), instructor);
      },
    );
  }
  for (final relationship in ['owner', 'instructor', 'unrelated']) {
    test('horse progress permission for $relationship rider', () {
      final horse = HorseProfile(
        id: 'h',
        name: 'Horse',
        currentOwnerId: relationship == 'owner'
            ? rider.email
            : 'owner@example.com',
        instructors: relationship == 'instructor'
            ? [BaseListItem(id: rider.email)]
            : [],
      );
      final viewer = rider.copyWith(
        ownedHorses: relationship == 'owner'
            ? [BaseListItem(id: horse.id)]
            : [],
      );
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          isForRider: false,
          usersProfile: viewer,
          horseProfile: horse,
        ),
      );
      expect(harness.cubit.isAuthorized(), relationship != 'unrelated');
    });
  }
  test('no horse loaded does not grant horse-edit permission', () {
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        isForRider: false,
        usersProfile: rider,
      ),
    );
    expect(harness.cubit.isAuthorized(), isFalse);
  });

  test('a stale saved-horse entry does not authorize the previous owner', () {
    final oldOwner = rider.copyWith(ownedHorses: [BaseListItem(id: 'h')]);
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        isForRider: false,
        usersProfile: oldOwner,
        horseProfile: HorseProfile(
          id: 'h',
          name: 'Horse',
          currentOwnerId: 'new-owner@example.com',
        ),
      ),
    );
    expect(harness.cubit.isAuthorized(), isFalse);
  });

  test(
    'the recorded current owner can edit before saved-horse lists refresh',
    () {
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          isForRider: false,
          usersProfile: rider,
          horseProfile: HorseProfile(
            id: 'h',
            name: 'Horse',
            currentOwnerId: rider.email,
          ),
        ),
      );
      expect(harness.cubit.isAuthorized(), isTrue);
    },
  );

  test(
    'AppState.copyWith clears nullable fields only when clear flags are set',
    () {
      final horse = HorseProfile(id: 'h', name: 'Horse');
      final viewed = RiderProfile(
        id: 'v',
        name: 'Viewed',
        email: 'v@example.com',
      );
      final owner = RiderProfile(
        id: 'o',
        name: 'Owner',
        email: 'o@example.com',
      );
      final resource = Resource(id: 'res', name: 'Resource');

      final populated = harness.cubit.state.copyWith(
        horseProfile: horse,
        viewingProfile: viewed,
        ownersProfile: owner,
        resource: resource,
        horseManageHorseId: 'h',
      );
      expect(populated.horseProfile, horse);
      expect(populated.viewingProfile, viewed);
      expect(populated.ownersProfile, owner);
      expect(populated.resource, resource);
      expect(populated.horseManageHorseId, 'h');

      // Omitting clear flags preserves existing values
      final unchanged = populated.copyWith();
      expect(unchanged.horseProfile, horse);
      expect(unchanged.viewingProfile, viewed);
      expect(unchanged.ownersProfile, owner);
      expect(unchanged.resource, resource);
      expect(unchanged.horseManageHorseId, 'h');

      // Setting clear flags clears the fields to null
      final cleared = populated.copyWith(
        clearHorseProfile: true,
        clearViewingProfile: true,
        clearOwnersProfile: true,
        clearResource: true,
        clearHorseManageHorseId: true,
      );
      expect(cleared.horseProfile, isNull);
      expect(cleared.viewingProfile, isNull);
      expect(cleared.ownersProfile, isNull);
      expect(cleared.resource, isNull);
      expect(cleared.horseManageHorseId, isNull);
    },
  );

  test(
    'resetFromHorseProfile, resetFromViewingProfile, and resetFromResource '
    'clear only their target state and preserve parent state',
    () {
      final horse = HorseProfile(id: 'h', name: 'Horse');
      final viewed = RiderProfile(
        id: 'v',
        name: 'Viewed',
        email: 'v@example.com',
      );
      final owner = RiderProfile(
        id: 'o',
        name: 'Owner',
        email: 'o@example.com',
      );
      final resource = Resource(id: 'res', name: 'Resource');
      final comment = Comment(
        id: 'c1',
        comment: 'Great',
        rating: 5,
        date: DateTime.utc(2025),
        user: BaseListItem(id: 'u1', name: 'User'),
        parentId: null,
        editedDate: null,
        resourceId: 'res',
        usersWhoRated: const [],
      );

      harness.cubit.emit(
        harness.cubit.state.copyWith(
          usersProfile: rider,
          viewingProfile: viewed,
          viewingProfielEmail: viewed.email,
          horseProfile: horse,
          horseId: horse.id,
          ownersProfile: owner,
          isViewing: false,
          isForRider: false,
          resource: resource,
          resourceComments: [comment],
        ),
      );

      // While isViewing is false (viewing a horse), determineCurrentProfile
      // returns usersProfile rather than the cached parent viewingProfile.
      expect(harness.cubit.determineCurrentProfile(), rider);

      // Resetting from horse profile clears horse state but preserves
      // viewingProfile and restores isViewing: true.
      harness.cubit.resetFromHorseProfile();
      expect(harness.cubit.state.horseProfile, isNull);
      expect(harness.cubit.state.ownersProfile, isNull);
      expect(harness.cubit.state.horseId, isEmpty);
      expect(harness.cubit.state.isForRider, isTrue);
      expect(harness.cubit.state.isViewing, isTrue);
      expect(harness.cubit.state.viewingProfile, viewed);
      expect(harness.cubit.determineCurrentProfile(), viewed);

      // Resetting from viewing profile clears viewingProfile and restores
      // determineCurrentProfile() to usersProfile.
      harness.cubit.resetFromViewingProfile();
      expect(harness.cubit.state.viewingProfile, isNull);
      expect(harness.cubit.state.viewingProfielEmail, isEmpty);
      expect(harness.cubit.state.isViewing, isFalse);
      expect(harness.cubit.state.isForRider, isTrue);
      expect(harness.cubit.determineCurrentProfile(), rider);

      // Resetting from resource clears resource and resourceComments.
      harness.cubit.resetFromResource();
      expect(harness.cubit.state.resource, isNull);
      expect(harness.cubit.state.resourceComments, isEmpty);
    },
  );

  test('deleteAccount clears sensitive profile state', () async {
    when(
      () => harness.riders.deleteRiderProfile(email: rider.email),
    ).thenAnswer((_) async {});

    final horse = HorseProfile(id: 'h', name: 'Horse');
    final viewed = RiderProfile(
      id: 'v',
      name: 'Viewed',
      email: 'v@example.com',
    );
    final owner = RiderProfile(
      id: 'o',
      name: 'Owner',
      email: 'o@example.com',
    );

    harness.cubit
      ..emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          usersProfile: rider,
          horseProfile: horse,
          horseId: horse.id,
          viewingProfile: viewed,
          viewingProfielEmail: viewed.email,
          ownersProfile: owner,
          isViewing: true,
          isForRider: false,
        ),
      )
      ..emailChanged(rider.email);

    await harness.cubit.deleteAccount();

    expect(harness.cubit.state.usersProfile, isNull);
    expect(harness.cubit.state.horseProfile, isNull);
    expect(harness.cubit.state.viewingProfile, isNull);
    expect(harness.cubit.state.ownersProfile, isNull);
    expect(harness.cubit.state.horseId, isEmpty);
    expect(harness.cubit.state.viewingProfielEmail, isEmpty);
    expect(harness.cubit.state.isViewing, isFalse);
    expect(harness.cubit.state.isForRider, isTrue);
    expect(harness.cubit.state.isGuest, isTrue);
  });

  test(
    'levelSelected updates rider skill level without mutating const lists '
    'in place and persists exactly once (including error handling)',
    () async {
      final savedProfiles = <RiderProfile>[];
      when(
        () => harness.riders.createOrUpdateRiderProfile(
          riderProfile: any(named: 'riderProfile'),
        ),
      ).thenAnswer((invocation) async {
        savedProfiles.add(
          invocation.namedArguments[#riderProfile] as RiderProfile,
        );
      });

      final initialRider = RiderProfile(
        id: 'r1',
        name: 'Rider One',
        email: 'r1@example.com',
      );
      final skill = Skill(
        id: 'skill-1',
        skillName: 'Mounting',
        position: 1,
        rider: true,
        lastEditBy: 'admin',
        description: 'Mount safely',
        learningDescription: 'Learning to mount',
        proficientDescription: 'Mounts smoothly',
        lastEditDate: DateTime.utc(2025),
      );

      harness.cubit
        ..emit(
          harness.cubit.state.copyWith(
            usersProfile: initialRider,
            skill: skill,
            isForRider: true,
            isViewing: false,
          ),
        )
        ..levelSelected(levelState: LevelState.PROFICIENT);
      await Future<void>.delayed(Duration.zero);

      // Should persist exactly once (no duplicate _persistRiderProfileChanges)
      expect(savedProfiles, hasLength(1));
      expect(savedProfiles.single.skillLevels, hasLength(1));
      expect(
        savedProfiles.single.skillLevels!.single.levelState,
        LevelState.PROFICIENT,
      );
      expect(savedProfiles.single.notes, hasLength(1));
      // Original profile lists were not mutated in place
      expect(initialRider.skillLevels, isEmpty);
      expect(initialRider.notes, isEmpty);

      // Failure condition: repository error emits isError state
      when(
        () => harness.riders.createOrUpdateRiderProfile(
          riderProfile: any(named: 'riderProfile'),
        ),
      ).thenThrow(Exception('write failed'));

      harness.cubit.levelSelected(levelState: LevelState.LEARNING);
      await Future<void>.delayed(Duration.zero);

      expect(harness.cubit.state.isError, isTrue);
      expect(
        harness.cubit.state.errorMessage,
        contains('Failed to update'),
      );
    },
  );

  test(
    'sortComments does not mutate state lists in place '
    'and safely handle null comment ratings',
    () {
      final c1 = Comment(
        id: 'c1',
        comment: 'First',
        rating: null,
        date: DateTime.utc(2025),
        user: BaseListItem(id: 'u1', name: 'User 1'),
        parentId: null,
        editedDate: null,
        resourceId: 'res-1',
        usersWhoRated: const [],
      );
      final c2 = Comment(
        id: 'c2',
        comment: 'Second',
        rating: 10,
        date: DateTime.utc(2025, 1, 2),
        user: BaseListItem(id: 'u2', name: 'User 2'),
        parentId: null,
        editedDate: null,
        resourceId: 'res-1',
        usersWhoRated: const [],
      );
      final originalComments = <Comment>[c1, c2];

      harness.cubit.emit(
        harness.cubit.state.copyWith(resourceComments: originalComments),
      );

      // Sorting comments by Best handles null rating as 0 without crashing
      // and does not mutate originalComments in place.
      harness.cubit.sortComments(CommentSortState.Best);
      expect(
        harness.cubit.state.resourceComments.map((c) => c.id).toList(),
        ['c2', 'c1'],
      );
      expect(originalComments.map((c) => c.id).toList(), ['c1', 'c2']);
      expect(
        identical(harness.cubit.state.resourceComments, originalComments),
        isFalse,
      );

      harness.cubit.sortComments(CommentSortState.Worst);
      expect(
        harness.cubit.state.resourceComments.map((c) => c.id).toList(),
        ['c1', 'c2'],
      );
    },
  );

  test(
    'reccomendResource handles null rating and const usersWhoRated '
    'without mutating original Resource in place',
    () async {
      Resource? savedResource;
      when(
        () => harness.resources.createOrUpdateResource(
          resource: any(named: 'resource'),
        ),
      ).thenAnswer((invocation) async {
        savedResource = invocation.namedArguments[#resource] as Resource;
      });

      final resource = Resource(
        id: 'res-1',
        name: 'Test Resource',
        usersWhoRated: const [],
      );

      harness.cubit.emit(
        harness.cubit.state.copyWith(usersProfile: rider),
      );

      await harness.cubit.reccomendResource(resource: resource);

      expect(savedResource, isNotNull);
      expect(savedResource!.rating, 1);
      expect(savedResource!.usersWhoRated, hasLength(1));
      expect(savedResource!.usersWhoRated!.single.id, rider.email);
      // Original resource was not mutated in place
      expect(resource.rating, isNull);
      expect(resource.usersWhoRated, isEmpty);
    },
  );
}
