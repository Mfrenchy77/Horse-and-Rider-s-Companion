import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/link_metadata_service.dart';
import 'package:horseandriderscompanion/Utilities/location_lookup_service.dart';
import 'package:horseandriderscompanion/Utilities/notifications/push_notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockMessagesRepository extends Mock implements MessagesRepository {}

class _MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class _MockResourcesRepository extends Mock implements ResourcesRepository {}

class _MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class _MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class _MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

class _FakePushNotificationService implements PushNotificationService {
  final List<String> registeredEmails = [];

  @override
  Future<void> ensureRegistered(String userEmail) async {
    registeredEmails.add(userEmail);
  }
}

class _FakeLinkMetadataService implements LinkMetadataService {
  _FakeLinkMetadataService({this.result, this.resolvedImage});

  final LinkMetadataResult? result;
  final String? resolvedImage;

  @override
  Future<LinkMetadataResult?> fetchMetadata(String url) async => result;

  @override
  Future<String?> resolveImage(String pageUrl, {String? imageHint}) async {
    return resolvedImage ?? imageHint;
  }
}

class _InMemoryApiKeyProvider implements ApiKeyProvider {
  const _InMemoryApiKeyProvider({
    this.zipKey = 'zip-key',
    this.locationKey = 'loc-key',
  });

  final String zipKey;
  final String locationKey;

  @override
  Future<String> getMapsApiKey() async => 'maps-key';

  @override
  Future<String> getZipCodeApiKey() async => zipKey;

  @override
  Future<String> getLocationApiKey() async => locationKey;

  @override
  Future<String> getJsonLinkApiKey() async => 'json-key';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('External service boundaries', () {
    test(
      'AppCubit delegates device registration to injected '
      'PushNotificationService',
      () async {
        SharedPreferences.setMockInitialValues({});
        await SharedPrefs().init();
        final authRepo = _MockAuthenticationRepository();
        final riderRepo = _MockRiderProfileRepository();
        final skillRepo = _MockSkillTreeRepository();
        final resourcesRepo = _MockResourcesRepository();
        final pushService = _FakePushNotificationService();

        const user = User(
          id: 'u1',
          email: 'rider@example.com',
          name: 'Rider',
          isGuest: false,
          emailVerified: true,
        );
        final userController = StreamController<User?>.broadcast();
        addTearDown(userController.close);

        when(() => authRepo.currentUser).thenReturn(User.empty);
        when(() => authRepo.user).thenAnswer((_) => userController.stream);
        when(skillRepo.getSkills).thenAnswer(
          (_) => const Stream<List<Skill>>.empty(),
        );
        when(resourcesRepo.getResources).thenAnswer(
          (_) => const Stream<List<Resource>>.empty(),
        );
        when(
          () => riderRepo.getRiderProfile(email: 'rider@example.com'),
        ).thenAnswer(
          (_) => Stream.value(
            RiderProfile(id: 'u1', name: 'Rider', email: 'rider@example.com'),
          ),
        );

        final cubit = AppCubit(
          messagesRepository: _MockMessagesRepository(),
          skillTreeRepository: skillRepo,
          resourcesRepository: resourcesRepo,
          riderProfileRepository: riderRepo,
          horseProfileRepository: _MockHorseProfileRepository(),
          authenticationRepository: authRepo,
          pushNotificationService: pushService,
        );
        addTearDown(cubit.close);

        userController.add(user);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(pushService.registeredEmails, ['rider@example.com']);
      },
    );

    test(
      'CreateResourceDialogCubit uses injected LinkMetadataService',
      () async {
        final cubit = CreateResourceDialogCubit(
          isEdit: false,
          resource: null,
          skills: const [],
          usersProfile: RiderProfile(
            id: 'u1',
            name: 'Alex',
            email: 'alex@example.com',
          ),
          resourcesRepository: _MockResourcesRepository(),
          linkMetadataService: _FakeLinkMetadataService(
            result: const LinkMetadataResult(
              title: 'Equine Balance Guide',
              description: 'Core training principles',
              imageUrl: 'https://cdn.example.com/raw.jpg',
            ),
            resolvedImage: 'https://cdn.example.com/resolved.jpg',
          ),
        );
        addTearDown(cubit.close);

        cubit.urlChanged('https://example.com/guide');
        await cubit.getMetadata('https://example.com/guide');

        expect(cubit.state.title, 'Equine Balance Guide');
        expect(cubit.state.description, 'Core training principles');
        expect(cubit.state.imageUrl, 'https://cdn.example.com/resolved.jpg');
        expect(cubit.state.urlFetchedStatus, UrlFetchedStatus.fetched);
      },
    );

    test(
      'LocationLookupService works with an in-memory ApiKeyProvider',
      () async {
        final service = LocationLookupService(
          keysRepository: const _InMemoryApiKeyProvider(
            locationKey: 'custom-loc-key',
            zipKey: 'custom-zip-key',
          ),
        );

        expect(await service.getLocationApiKey(), 'custom-loc-key');
        expect(await service.getZipCodeApiKey(), 'custom-zip-key');
      },
    );
  });
}
