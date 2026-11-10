import 'dart:typed_data';

import 'package:database_repository/database_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockResources extends Mock implements ResourcesRepository {}

class MockStorage extends Mock implements FirebaseStorage {}

void main() {
  late MockResources repo;
  late CreateResourceDialogCubit cubit;
  final user = RiderProfile(id: 'u', name: 'Rider', email: 'r@example.com');
  final skills = List.generate(
    3,
    (i) => Skill(
      id: 's$i',
      skillName: 'Skill $i',
      rider: true,
      position: i,
      lastEditBy: 'editor',
      lastEditDate: DateTime.utc(2025),
      category: i == 0 ? SkillCategory.Husbandry : SkillCategory.Mounted,
      difficulty: i == 0
          ? DifficultyState.Introductory
          : DifficultyState.Advanced,
      description: '',
      learningDescription: '',
      proficientDescription: '',
    ),
  );
  setUpAll(() => registerFallbackValue(Resource(id: 'fallback')));
  setUp(() {
    repo = MockResources();
    when(repo.newId).thenReturn('new-id');
    when(
      () => repo.createResourceWithServerTimestamps(
        resource: any(named: 'resource'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repo.createOrUpdateResource(resource: any(named: 'resource')),
    ).thenAnswer((_) async {});
    cubit = CreateResourceDialogCubit(
      isEdit: false,
      resource: null,
      skills: skills,
      usersProfile: user,
      resourcesRepository: repo,
      storage: MockStorage(),
    );
  });
  tearDown(() => cubit.close());

  test('rejects incomplete link and PDF forms', () async {
    await cubit.submit();
    expect(cubit.state.submitStatus, ResourceSubmitStatus.error);
    cubit.inputTypeChanged(ResourceInputType.pdf);
    await cubit.submit();
    expect(cubit.state.error, contains('PDF'));
    verifyZeroInteractions(repo);
  });
  test('saves valid links with author and selected skills', () async {
    cubit.emit(
      cubit.state.copyWith(
        title: 'Guide',
        url: const Url.dirty('https://example.com'),
        resourceSkills: [skills.first],
      ),
    );
    await cubit.submit();
    final saved =
        verify(
              () => repo.createResourceWithServerTimestamps(
                resource: captureAny(named: 'resource'),
              ),
            ).captured.single
            as Resource;
    expect(saved.id, 'new-id');
    expect(saved.url, 'https://example.com');
    expect(saved.skillTreeIds, ['s0']);
    expect(saved.authorId, user.email);
    expect(saved.lastEditBy, user.email);
    expect(cubit.state.submitStatus, ResourceSubmitStatus.success);
  });
  test('reports write failures and allows error reset', () async {
    cubit.emit(
      cubit.state.copyWith(
        title: 'Guide',
        url: const Url.dirty('https://example.com'),
      ),
    );
    when(
      () => repo.createResourceWithServerTimestamps(
        resource: any(named: 'resource'),
      ),
    ).thenAnswer((_) async => throw Exception('offline'));
    await cubit.submit();
    expect(cubit.state.isError, isTrue);
    cubit.clearError();
    expect(cubit.state.isError, isFalse);
    expect(cubit.state.error, isEmpty);
  });
  test('filters skills by category, difficulty and search', () {
    cubit.categoryFilterChanged(CategoryFilter.Husbandry);
    expect(cubit.state.filteredSkills?.map((s) => s?.id), ['s0']);
    cubit.difficultyFilterChanged(DifficultyFilter.Advanced);
    expect(cubit.state.filteredSkills, isEmpty);
    cubit.categoryFilterChanged(CategoryFilter.All);
    expect(cubit.state.filteredSkills, hasLength(2));
    expect(cubit.getSkillsForResource(ids: ['s1', 'missing']), [skills[1]]);
  });
  test('clearing a selected PDF clears both bytes and filename', () {
    cubit
      ..emit(
        cubit.state.copyWith(
          pdfBytes: Uint8List.fromList([1, 2]),
          pdfName: 'guide.pdf',
        ),
      )
      ..clearPickedPdf();
    expect(cubit.state.pdfBytes, isNull);
    expect(cubit.state.pdfName, isNull);
  });
  test(
    'editing a PDF preserves resource metadata and author identity',
    () async {
      await cubit.close();
      final original = Resource(
        id: 'pdf',
        url: 'https://example.com/guide.pdf',
        name: 'Guide',
        type: ResourceType.pdf,
        status: ResourceStatus.published,
        tags: ['health'],
        authorId: user.email,
        createdAt: DateTime.utc(2025),
      );
      cubit = CreateResourceDialogCubit(
        isEdit: true,
        resource: original,
        skills: skills,
        usersProfile: user,
        resourcesRepository: repo,
        storage: MockStorage(),
      )..titleChanged('Updated');
      await cubit.editResource();
      final saved =
          verify(
                () => repo.createOrUpdateResource(
                  resource: captureAny(named: 'resource'),
                ),
              ).captured.single
              as Resource;
      expect(saved.id, 'pdf');
      expect(saved.name, 'Updated');
      expect(saved.type, ResourceType.pdf);
      expect(saved.tags, ['health']);
      expect(saved.createdAt, original.createdAt);
      expect(saved.lastEditBy, user.email);
    },
  );
}
