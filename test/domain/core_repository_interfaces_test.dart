import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Messages/cubit/new_group_dialog_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessagesRepository extends Mock implements MessagesRepository {}

class _InMemoryRiderProfileStore implements RiderProfileStore {
  _InMemoryRiderProfileStore([Map<String, RiderProfile>? seed])
    : _profiles = Map<String, RiderProfile>.of(seed ?? {});

  final Map<String, RiderProfile> _profiles;

  @override
  Future<void> createOrUpdateRiderProfile({
    required RiderProfile riderProfile,
  }) async {
    _profiles[riderProfile.email] = riderProfile;
  }

  @override
  Future<void> addOrUpdateOwnedHorse({
    required RiderProfile? riderProfile,
    required String? horseId,
  }) async {}

  @override
  Future<void> saveContact({
    required String email,
    required BaseListItem contact,
    required bool add,
  }) async {}

  @override
  Future<void> saveRiderLogEntry({
    required String email,
    required BaseListItem entry,
    required bool isEdit,
  }) async {}

  @override
  Stream<RiderProfile?> getRiderProfile({required String email}) {
    return Stream.value(_profiles[email]);
  }

  @override
  Future<RiderProfile?> getRiderProfileByEmail({
    required String email,
    bool serverOnly = false,
  }) async {
    return _profiles[email];
  }

  @override
  Stream<RiderProfile?> getProfileByName({required String name}) {
    final match = _profiles.values.where((p) => p.name == name).firstOrNull;
    return Stream.value(match);
  }

  @override
  Stream<List<RiderProfile>> getProfilesByName({required String name}) {
    return Stream.value(
      _profiles.values.where((p) => p.name.startsWith(name)).toList(),
    );
  }

  @override
  Stream<List<RiderProfile>> getProfilesByZipcode({required String zipcode}) {
    return Stream.value(
      _profiles.values.where((p) => p.zipCode == zipcode).toList(),
    );
  }

  @override
  Future<void> deleteRiderProfile({required String email}) async {
    _profiles.remove(email);
  }
}

void main() {
  group('Core repository interfaces', () {
    test(
      'NewGroupDialogCubit works with an in-memory RiderProfileStore',
      () async {
        final store = _InMemoryRiderProfileStore({
          'alex@example.com': RiderProfile(
            id: 'u1',
            name: 'Alex',
            email: 'alex@example.com',
          ),
          'sam@example.com': RiderProfile(
            id: 'u2',
            name: 'Sam',
            email: 'sam@example.com',
          ),
        });
        final cubit = NewGroupDialogCubit(
          messagesRepository: _MockMessagesRepository(),
          riderProfileRepository: store,
          usersProfile: RiderProfile(
            id: 'u1',
            name: 'Alex',
            email: 'alex@example.com',
          ),
        );
        addTearDown(cubit.close);

        cubit
          ..nameChanged('Sam')
          ..searchProfilesByName();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.searchResult.map((r) => r?.email), [
          'sam@example.com',
        ]);
      },
    );
  });
}
