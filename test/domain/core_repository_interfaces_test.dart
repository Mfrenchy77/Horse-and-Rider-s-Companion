import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Messages/cubit/new_group_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/cubit/horse_profile_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateTrainingPathDialog/Cubit/create_training_path_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';

class _InMemoryMessagesStore implements MessagesStore {
  final Map<String, Conversation> conversations = {};
  final Map<String, List<Message>> messages = {};

  @override
  Future<void> createOrUpdateMessage({required Message message}) async {
    messages.putIfAbsent(message.id ?? '', () => []).add(message);
  }

  @override
  Stream<List<Message>> getMessages({required String conversationId}) =>
      Stream.value(messages[conversationId] ?? const []);

  @override
  void deleteMessage({
    required Message messageToDelete,
    required String conversationId,
  }) {
    messages[conversationId]?.removeWhere(
      (m) => m.messageId == messageToDelete.messageId,
    );
  }

  @override
  Future<void> createOrUpdateConversation({
    required Conversation conversation,
  }) async {
    conversations[conversation.id] = conversation;
  }

  @override
  Stream<List<Conversation>> getConversations({required String userEmail}) =>
      Stream.value(
        conversations.values
            .where((c) => c.partiesIds.contains(userEmail))
            .toList(),
      );

  @override
  void deleteConversation({required Conversation conversation}) {
    conversations.remove(conversation.id);
  }
}

class _InMemorySkillTreeStore implements SkillTreeStore {
  final Map<String, TrainingPath> trainingPaths = {};
  final Map<String, Skill> skills = {};

  @override
  Future<void> createOrEditTrainingPath({
    required TrainingPath trainingPath,
  }) async {
    trainingPaths[trainingPath.id] = trainingPath;
  }

  @override
  Stream<TrainingPath?> getTrainingPathById({required String id}) =>
      Stream.value(trainingPaths[id]);

  @override
  Stream<List<TrainingPath>> getAllTrainingPaths() =>
      Stream.value(trainingPaths.values.toList());

  @override
  void deleteTrainingPath({required TrainingPath? trainingPath}) {
    if (trainingPath != null) trainingPaths.remove(trainingPath.id);
  }

  @override
  Future<void> createOrEditSkill({required Skill skill}) async {
    skills[skill.id] = skill;
  }

  @override
  Stream<List<Skill>> getSkillsFromCategory({required String id}) =>
      Stream.value(
        skills.values.where((s) => s.category.name == id).toList(),
      );

  @override
  Stream<List<Skill>> getSkills() => Stream.value(skills.values.toList());

  @override
  Stream<List<Skill>> getSkillsForRiderSkillTree() =>
      Stream.value(skills.values.where((s) => s.rider).toList());

  @override
  Stream<List<Skill>> getSkillsForHorseSkillTree() =>
      Stream.value(skills.values.where((s) => !s.rider).toList());

  @override
  void deleteSkill({required Skill? skill}) {
    if (skill != null) skills.remove(skill.id);
  }
}

class _InMemoryApiKeyProvider implements ApiKeyProvider {
  @override
  Future<String> getJsonLinkApiKey() async => '';

  @override
  Future<String> getLocationApiKey() async => '';

  @override
  Future<String> getMapsApiKey() async => '';

  @override
  Future<String> getZipCodeApiKey() async => '';
}

class _InMemoryHorseProfileStore implements HorseProfileStore {
  final Map<String, HorseProfile> horses = {};

  @override
  Future<void> createOrUpdateHorseProfile({
    required HorseProfile horseProfile,
  }) async {
    horses[horseProfile.id] = horseProfile;
  }

  @override
  Stream<List<HorseProfile>> getAllUsersHorses({required List<String>? ids}) {
    final idSet = (ids ?? const <String>[]).toSet();
    return Stream.value(
      horses.values.where((h) => idSet.contains(h.id)).toList(),
    );
  }

  @override
  Stream<HorseProfile?> getHorseProfileById({required String id}) {
    return Stream.value(horses[id]);
  }

  @override
  Stream<List<HorseProfile>> getHorseByName({required String name}) {
    return Stream.value(
      horses.values.where((h) => h.name.startsWith(name)).toList(),
    );
  }

  @override
  Stream<List<HorseProfile>> getHorseByNickName({required String nickName}) {
    return Stream.value(
      horses.values
          .where((h) => (h.nickname ?? '').startsWith(nickName))
          .toList(),
    );
  }

  @override
  Stream<HorseProfile?> getHorseProfile({required String? id}) {
    return Stream.value(id == null ? null : horses[id]);
  }

  @override
  Stream<List<HorseProfile>> getHorseByZipCode({required String zipCode}) {
    return Stream.value(
      horses.values.where((h) => h.zipCode == zipCode).toList(),
    );
  }

  @override
  Future<void> deleteHorseProfile({required String id}) async {
    horses.remove(id);
  }
}

class _InMemoryResourcesStore implements ResourcesStore {
  final Map<String, Resource> resources = {};
  int _nextId = 1;

  @override
  String newId() => 'res-${_nextId++}';

  @override
  Future<void> createOrUpdateResource({required Resource resource}) async {
    resources[resource.id!] = resource;
  }

  @override
  Future<void> updateSkillLinks({
    required String id,
    required Set<String> added,
    required Set<String> removed,
  }) async {}

  @override
  Future<void> createResourceWithServerTimestamps({
    required Resource resource,
  }) async {
    resources[resource.id!] = resource;
  }

  @override
  Future<void> createArticle({required Resource resource}) async {
    resources[resource.id!] = resource;
  }

  @override
  Stream<List<Resource>> getResources() =>
      Stream.value(resources.values.toList());

  @override
  Stream<List<Resource>> getResourcesForSkill({required String skillId}) =>
      Stream.value(
        resources.values
            .where((r) => r.skillTreeIds.contains(skillId))
            .toList(),
      );

  @override
  Stream<List<Resource>> getResourcesOrderedByUpdatedAt() => getResources();

  @override
  Future<Resource?> getResourceById(String id) async => resources[id];

  @override
  Future<void> deleteResource({required Resource resource}) async {
    resources.remove(resource.id);
  }

  @override
  Future<Comment> rateComment({
    required String resourceId,
    required String commentId,
    required String userEmail,
    required int vote,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> editResourceRating({
    required Resource resource,
    required BaseListItem userWhoRated,
  }) async {}

  @override
  Stream<List<Resource>> getPublishedArticles({
    List<String> tagsFilter = const [],
  }) => Stream.value(const []);

  @override
  Future<Resource?> getArticleById(String id) async => resources[id];

  @override
  Future<void> updateArticleContent({
    required String id,
    String? title,
    String? description,
    String? content,
    List<String>? tags,
    String? coverImageUrl,
  }) async {}

  @override
  Future<void> setArticleStatus({
    required String id,
    required ResourceStatus status,
  }) async {}
}

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
          messagesRepository: _InMemoryMessagesStore(),
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

    test(
      'AddHorseDialogCubit works with in-memory HorseProfileStore and '
      'RiderProfileStore',
      () async {
        final horseStore = _InMemoryHorseProfileStore();
        final riderStore = _InMemoryRiderProfileStore();
        final horse = HorseProfile(
          id: 'h1',
          name: 'Star',
          currentOwnerId: 'alex@example.com',
        );
        await horseStore.createOrUpdateHorseProfile(horseProfile: horse);
        final cubit = AddHorseDialogCubit(
          usersProfile: RiderProfile(
            id: 'u1',
            name: 'Alex',
            email: 'alex@example.com',
          ),
          horseProfile: horse,
          keysRepository: _InMemoryApiKeyProvider(),
          horseProfileRepository: horseStore,
          riderProfileRepository: riderStore,
        );
        addTearDown(cubit.close);

        await cubit.deleteHorseProfile(horseProfile: horse);

        expect(horseStore.horses, isEmpty);
        expect(cubit.state.status, FormStatus.success);
      },
    );

    test(
      'CommentCubit saves comments using an in-memory ResourcesStore',
      () async {
        final resource = Resource(
          id: 'r1',
          name: 'Balance Drill',
          url: 'https://example.com',
        );
        final resourcesStore = _InMemoryResourcesStore()
          ..resources['r1'] = resource;
        final cubit = CommentCubit(
          comment: null,
          resource: resource,
          usersProfile: RiderProfile(
            id: 'u1',
            name: 'Alex',
            email: 'alex@example.com',
          ),
          resourcesRepository: resourcesStore,
        );
        addTearDown(cubit.close);

        cubit.updateCommentMessage('Great drill!');
        await cubit.sendComment();

        expect(resourcesStore.resources['r1']?.comments, hasLength(1));
        expect(
          resourcesStore.resources['r1']?.comments?.first.comment,
          'Great drill!',
        );
      },
    );

    test(
      'NewGroupDialogCubit creates conversations via an in-memory '
      'MessagesStore',
      () async {
        final messagesStore = _InMemoryMessagesStore();
        final riderStore = _InMemoryRiderProfileStore();
        final cubit = NewGroupDialogCubit(
          messagesRepository: messagesStore,
          riderProfileRepository: riderStore,
          usersProfile: RiderProfile(
            id: 'u1',
            name: 'Alex',
            email: 'alex@example.com',
          ),
        );
        addTearDown(cubit.close);

        await cubit.createConversation(
          RiderProfile(id: 'u2', name: 'Sam', email: 'sam@example.com'),
        );

        expect(messagesStore.conversations, hasLength(1));
        expect(cubit.state.status, FormStatus.success);
      },
    );

    test(
      'CreateTrainingPathCubit saves training paths via an in-memory '
      'SkillTreeStore',
      () async {
        final skillStore = _InMemorySkillTreeStore();
        final cubit = CreateTrainingPathCubit(
          trainingPathRepository: skillStore,
          allSkills: const [],
          isForRider: true,
          user: RiderProfile(
            id: 'u1',
            name: 'Alex',
            email: 'alex@example.com',
          ),
        );
        addTearDown(cubit.close);

        cubit
          ..trainingPathNameChanged(name: 'Groundwork Basics')
          ..trainingPathDescriptionChanged(
            description: 'Foundational leading and yielding skills',
          );
        await cubit.createOrEditTrainingPath();

        expect(skillStore.trainingPaths, hasLength(1));
        expect(cubit.state.status, FormStatus.success);
      },
    );

    test(
      'HorseProfileCubit loads horse and owner using injected '
      'HorseProfileStore and RiderProfileStore',
      () async {
        final horseStore = _InMemoryHorseProfileStore();
        await horseStore.createOrUpdateHorseProfile(
          horseProfile: HorseProfile(
            id: 'h1',
            name: 'Star',
            currentOwnerId: 'owner@example.com',
          ),
        );
        final riderStore = _InMemoryRiderProfileStore({
          'owner@example.com': RiderProfile(
            id: 'u2',
            name: 'Owner',
            email: 'owner@example.com',
          ),
        });

        final cubit = HorseProfileCubit(
          horseId: 'h1',
          isGuest: false,
          usersProfile: RiderProfile(
            id: 'u1',
            name: 'Viewer',
            email: 'viewer@example.com',
          ),
          horseProfileRepository: horseStore,
          riderProfileRepository: riderStore,
        );
        addTearDown(cubit.close);

        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(cubit.state.horseProfile?.name, 'Star');
        expect(cubit.state.ownersProfile?.name, 'Owner');
      },
    );
  });
}
