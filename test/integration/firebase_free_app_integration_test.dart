import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/TransferHorseDialog/cubit/transfer_horse_cubit.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryAuthGateway implements AuthGateway {
  _InMemoryAuthGateway(this._currentUser);

  User _currentUser;
  final StreamController<User> _controller = StreamController<User>.broadcast();

  @override
  Stream<User> get user => Stream.multi((multi) {
    multi.add(_currentUser);
    final sub = _controller.stream.listen(multi.add);
    multi.onCancel = sub.cancel;
  });

  @override
  User get currentUser => _currentUser;

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async =>
      'in-memory-token';

  @override
  Future<void> logOut() async {
    _currentUser = User.empty;
    _controller.add(_currentUser);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryRiderProfileStore implements RiderProfileStore {
  final Map<String, RiderProfile> _profiles = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void seed(RiderProfile profile) {
    _profiles[profile.email.toLowerCase()] = profile;
    _changes.add(null);
  }

  @override
  Future<void> createOrUpdateRiderProfile({
    required RiderProfile riderProfile,
  }) async {
    seed(riderProfile);
  }

  @override
  Stream<RiderProfile?> getRiderProfile({required String email}) {
    final key = email.toLowerCase();
    return Stream.multi((multi) {
      multi.add(_profiles[key]);
      final sub = _changes.stream.listen((_) => multi.add(_profiles[key]));
      multi.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> addOrUpdateOwnedHorse({
    required RiderProfile? riderProfile,
    required String? horseId,
  }) async {
    if (riderProfile == null || horseId == null) return;
    final current = _profiles[riderProfile.email.toLowerCase()] ?? riderProfile;
    final existing = List<BaseListItem>.from(current.ownedHorses ?? const []);
    if (!existing.any((h) => h.id == horseId)) {
      existing.add(BaseListItem(id: horseId, name: horseId));
    }
    seed(current.copyWith(ownedHorses: existing));
  }

  Future<void> addNote({
    required RiderProfile riderProfile,
    required BaseListItem note,
  }) async {
    final current = _profiles[riderProfile.email.toLowerCase()] ?? riderProfile;
    final notes = List<BaseListItem>.from(current.notes ?? const [])..add(note);
    seed(current.copyWith(notes: notes));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryHorseProfileStore implements HorseProfileStore {
  final Map<String, HorseProfile> _horses = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void seed(HorseProfile horse) {
    _horses[horse.id] = horse;
    _changes.add(null);
  }

  @override
  Future<void> createOrUpdateHorseProfile({
    required HorseProfile horseProfile,
  }) async {
    seed(horseProfile);
  }

  @override
  Stream<List<HorseProfile>> getAllUsersHorses({required List<String>? ids}) {
    final targetIds = (ids ?? const <String>[]).toSet();
    List<HorseProfile> resolve() =>
        targetIds.map((id) => _horses[id]).whereType<HorseProfile>().toList();
    return Stream.multi((multi) {
      multi.add(resolve());
      final sub = _changes.stream.listen((_) => multi.add(resolve()));
      multi.onCancel = sub.cancel;
    });
  }

  @override
  Stream<HorseProfile?> getHorseProfileById({required String id}) {
    return Stream.multi((multi) {
      multi.add(_horses[id]);
      final sub = _changes.stream.listen((_) => multi.add(_horses[id]));
      multi.onCancel = sub.cancel;
    });
  }

  @override
  Stream<HorseProfile?> getHorseProfile({required String? id}) =>
      id == null ? Stream.value(null) : getHorseProfileById(id: id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InMemoryRequestStore implements ConnectionRequestStore {
  final Map<String, ConnectionRequest> _items = {};
  final Map<String, String> _statuses = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<ConnectionRequest> pendingFor(String email) {
    final normalized = email.toLowerCase();
    return _items.entries
        .where(
          (e) =>
              (_statuses[e.key] ?? 'pending') == 'pending' &&
              e.value.partiesIds.contains(normalized),
        )
        .map((e) => e.value)
        .toList();
  }

  void markAccepted(String docId) {
    if (_items.containsKey(docId)) {
      _statuses[docId] = 'accepted';
      _changes.add(null);
    }
  }

  @override
  Stream<List<ConnectionRequest>> watchRequests({required String userEmail}) {
    return Stream.multi((multi) {
      multi.add(pendingFor(userEmail));
      final sub = _changes.stream.listen(
        (_) => multi.add(pendingFor(userEmail)),
      );
      multi.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> sendRequest(ConnectionRequest request) async {
    final docId = '${request.id}_${request.messageId}';
    if (_items.containsKey(docId)) return;
    _items[docId] = ConnectionRequest.fromMap(
      request.toMap()..['id'] = docId,
      idFromDoc: docId,
    );
    _statuses[docId] = 'pending';
    _changes.add(null);
  }

  @override
  Future<void> dismissRequest({
    required ConnectionRequest request,
    required String dismissalNote,
    String status = 'dismissed',
  }) async {
    _statuses[request.id] = status;
    _changes.add(null);
  }
}

class _MockSkillTreeStore extends Mock implements SkillTreeStore {}

class _MockResourcesStore extends Mock implements ResourcesStore {}

class _MockMessagesStore extends Mock implements MessagesStore {}

void main() {
  test(
    'AppCubit and TransferHorseCubit operate end-to-end without Firebase',
    () async {
      SharedPreferences.setMockInitialValues({});
      await SharedPrefs().init();

      final owner = RiderProfile(
        id: 'owner@example.com',
        name: 'Owner Rider',
        email: 'owner@example.com',
        isTrainer: true,
        ownedHorses: [BaseListItem(id: 'atlas', name: 'Atlas')],
        lastEditBy: 'Owner Rider',
        lastEditDate: DateTime(2026),
      );
      final buyer = RiderProfile(
        id: 'buyer@example.com',
        name: 'Buyer Rider',
        email: 'buyer@example.com',
        isTrainer: true,
        lastEditBy: 'Buyer Rider',
        lastEditDate: DateTime(2026),
      );
      final atlas = HorseProfile(
        id: 'atlas',
        name: 'Atlas',
        currentOwnerId: owner.email,
        currentOwnerName: owner.name,
        lastEditBy: owner.name,
        lastEditDate: DateTime(2026),
      );

      final riderStore = _InMemoryRiderProfileStore()
        ..seed(owner)
        ..seed(buyer);
      final horseStore = _InMemoryHorseProfileStore()..seed(atlas);
      final requestStore = _InMemoryRequestStore();
      final skillTreeStore = _MockSkillTreeStore();
      final resourcesStore = _MockResourcesStore();
      final messagesStore = _MockMessagesStore();

      when(skillTreeStore.getSkills).thenAnswer(
        (_) => Stream.value(const <Skill>[]),
      );
      when(resourcesStore.getResources).thenAnswer(
        (_) => Stream.value(const <Resource>[]),
      );

      final auth = _InMemoryAuthGateway(
        const User(
          id: 'u-buyer',
          email: 'buyer@example.com',
          name: 'Buyer Rider',
          isGuest: false,
          emailVerified: true,
        ),
      );

      final cubit = AppCubit(
        messagesRepository: messagesStore,
        connectionRequestRepository: requestStore,
        skillTreeRepository: skillTreeStore,
        resourcesRepository: resourcesStore,
        riderProfileRepository: riderStore,
        horseProfileRepository: horseStore,
        authenticationRepository: auth,
        fetchConnection: (id) async => {'id': id, 'version': 'v1'},
        submitCoachingAction: (payload) async {
          final action = payload['action'] as String?;
          final reqDocId = payload['requestDocId'] as String?;
          if (reqDocId != null) {
            requestStore.markAccepted(reqDocId);
          }
          if (action == 'accept' && payload['id'] == 'xfer_atlas') {
            horseStore.seed(
              atlas.copyWith(
                currentOwnerId: buyer.email,
                currentOwnerName: buyer.name,
              ),
            );
          }
          return {'id': payload['id'] ?? 'conn-1', 'status': 'accepted'};
        },
      );

      await pumpEventQueue();
      expect(cubit.state.usersProfile?.email, buyer.email);

      // 1. Logbook note update through RiderProfileStore without Firebase.
      await riderStore.addNote(
        riderProfile: buyer,
        note: BaseListItem(id: 'n1', name: 'Walk-trot transition'),
      );
      await pumpEventQueue();
      expect(cubit.state.usersProfile?.notes?.single.id, 'n1');

      // 2. Incoming coaching request -> badge count -> accept -> badge clears.
      final coachReq = ConnectionRequest(
        id: 'buyer_owner',
        messageId: 'm-coach',
        kind: ConnectionRequestKind.instructor,
        senderEmail: owner.email,
        senderName: owner.name,
        recipientEmail: buyer.email,
        recipientName: buyer.name,
        title: 'Instructor Request',
        summary: 'Coach request',
        parties: [owner.name, buyer.name],
        partiesIds: [owner.email, buyer.email],
        createdAt: DateTime(2026, 5),
      );
      await requestStore.sendRequest(coachReq);
      cubit.getConversations();
      await pumpEventQueue();
      expect(cubit.pendingRequestCount(), 1);

      await cubit.acceptConnectionRequest(
        cubit.pendingConnectionRequests().single,
      );
      await pumpEventQueue();
      expect(cubit.pendingRequestCount(), 0);

      // 3. TransferHorseCubit initiates transfer -> AppCubit accepts.
      final transferCubit = TransferHorseCubit(
        userProfile: owner,
        horseProfile: atlas,
        requestRepository: requestStore,
        riderProfileRepository: riderStore,
        submitCoachingAction: (payload) async => {
          'id': 'xfer_atlas',
          'status': 'pending',
        },
      );
      transferCubit.emit(
        transferCubit.state.copyWith(
          transferProfile: buyer,
          isTransferable: true,
        ),
      );
      await transferCubit.sendTransferRequest();
      await pumpEventQueue();
      expect(cubit.pendingRequestCount(), 1);

      await cubit.acceptConnectionRequest(
        cubit.pendingConnectionRequests().single,
      );
      await pumpEventQueue();
      expect(cubit.pendingRequestCount(), 0);
      expect(
        (await horseStore.getHorseProfileById(id: 'atlas').first)
            ?.currentOwnerId,
        buyer.email,
      );

      unawaited(transferCubit.close());
      unawaited(cubit.close());
    },
  );
}
