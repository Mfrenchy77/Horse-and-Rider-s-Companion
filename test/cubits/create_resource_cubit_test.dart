import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:database_repository/database_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
      mediaStorage: CloudRepository(storage: MockStorage()),
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
  test('unwraps resolver hints and saves the original image URL', () async {
    const page = 'https://example.com/guide';
    const image = 'https://cdn.example.com/horse.jpg';
    final legacy = Uri.https('wsrv.nl', '/', {'url': image}).toString();
    final nested = Uri.https('wsrv.nl', '/', {'url': legacy}).toString();

    await http.runWithClient(
      () => cubit.getMetadata(page),
      () => MockClient((request) async {
        switch (request.url.path) {
          case '/previewMeta':
            return http.Response(
              jsonEncode({'title': 'Guide', 'image': legacy}),
              200,
            );
          case '/fetchReadable':
            return http.Response('{}', 200);
          case '/resolveImage':
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['hint'], image);
            return http.Response(jsonEncode({'proxiedUrl': nested}), 200);
          default:
            fail('Unexpected endpoint: ${request.url}');
        }
      }),
    );

    expect(cubit.state.imageUrl, image);
    expect(cubit.state.title, 'Guide');
    cubit
      ..imageUrlChanged(nested)
      ..titleChanged('My guide')
      ..recommendationChanged('  Clear examples  ')
      ..linkTypeChanged(ResourceType.externalArticle)
      ..resourceSkillsChanged('s0')
      ..resourceSkillsChanged('s1');
    await cubit.submit();
    final saved =
        verify(
              () => repo.createResourceWithServerTimestamps(
                resource: captureAny(named: 'resource'),
              ),
            ).captured.single
            as Resource;
    expect(saved.thumbnail, image);
    expect(saved.name, 'My guide');
    expect(saved.description, 'Clear examples');
    expect(saved.skillTreeIds, ['s0', 's1']);
    expect(
      Resource.fromJson(saved.toJson()).type,
      ResourceType.externalArticle,
    );
    expect(saved.isArticle, isFalse);
  });

  test(
    'requires a valid link, title and a known skill before writing',
    () async {
      cubit
        ..emit(
          cubit.state.copyWith(
            title: 'Guide',
            url: const Url.dirty('https://example.com/guide'),
          ),
        )
        ..resourceSkillsChanged('unknown');
      await cubit.submit();
      expect(cubit.state.error, contains('at least one related skill'));

      cubit
        ..resourceSkillsChanged('s0')
        ..urlChanged('not a link');
      await cubit.submit();
      expect(cubit.state.error, contains('valid URL'));
      verifyZeroInteractions(repo);
    },
  );

  test(
    'a response for a previous URL cannot replace the current draft',
    () async {
      final response = Completer<http.Response>();
      await http.runWithClient(() async {
        final pending = cubit.getMetadata('https://example.com/old');
        cubit
          ..urlChanged('https://example.com/new')
          ..titleChanged('My new title')
          ..recommendationChanged('My recommendation');
        response.complete(http.Response('{"title":"Old title"}', 200));
        await pending;
      }, () => MockClient((_) => response.future));
      expect(cubit.state.url.value, 'https://example.com/new');
      expect(cubit.linkPreview.name, 'My new title');
      expect(cubit.linkPreview.description, 'My recommendation');
    },
  );

  test('reports write failures and allows error reset', () async {
    cubit.emit(
      cubit.state.copyWith(
        title: 'Guide',
        url: const Url.dirty('https://example.com'),
        resourceSkills: [skills.first],
      ),
    );
    when(
      () => repo.createResourceWithServerTimestamps(
        resource: any(named: 'resource'),
      ),
    ).thenAnswer((_) async => throw Exception('offline'));
    await cubit.submit();
    expect(cubit.state.isError, isTrue);
    expect(cubit.state.error, contains('offline'));
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
        mediaStorage: CloudRepository(storage: MockStorage()),
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
