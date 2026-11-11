import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

void main() {
  testWidgets('comments dialog displays an already associated skill', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    const email = 'owner@example.com';
    final resource = Resource(
      id: 'guide',
      name: 'Leading guide',
      authorId: email,
      skillTreeIds: ['leading'],
    );
    final skill = Skill(
      id: 'leading',
      rider: true,
      position: 0,
      skillName: 'Lead at the walk',
      lastEditBy: 'editor',
      lastEditDate: DateTime.utc(2025),
      description: '',
      learningDescription: '',
      proficientDescription: '',
    );
    final app = harness.cubit;
    app.emit(
      app.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(id: 'owner', email: email, name: 'Owner'),
        allSkills: [skill],
        resource: resource,
        resources: [resource],
      ),
    );
    await tester.pumpWidget(
      RepositoryProvider<ResourcesRepository>.value(
        value: harness.resources,
        child: BlocProvider.value(
          value: app,
          child: const MaterialApp(home: ResourceCommentPage(id: 'guide')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Associated skills'));
    await tester.pumpAndSettle();

    final link = find.byKey(const ValueKey('resource-skill-leading'));
    expect(link, findsOneWidget);
    expect(
      find.descendant(of: link, matching: find.text('Lead at the walk')),
      findsOneWidget,
    );
    expect(tester.widget<CheckboxListTile>(link).value, isTrue);
  });

  testWidgets('resource owner can link a skill from the comments dialog', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    const email = 'owner@example.com';
    final resource = Resource(
      id: 'guide',
      name: 'Leading guide',
      authorId: email,
    );
    final skill = Skill(
      id: 'leading',
      rider: true,
      position: 0,
      skillName: 'Lead at the walk',
      lastEditBy: 'editor',
      lastEditDate: DateTime.utc(2025),
      description: '',
      learningDescription: '',
      proficientDescription: '',
    );
    final app = harness.cubit;
    app.emit(
      app.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(id: 'owner', email: email, name: 'Owner'),
        allSkills: [skill],
        resource: resource,
        resources: [resource],
      ),
    );
    when(
      () => harness.resources.updateSkillLinks(
        id: 'guide',
        added: any(named: 'added'),
        removed: any(named: 'removed'),
      ),
    ).thenAnswer((invocation) async {
      final links = invocation.namedArguments[#added] as Set<String>;
      final updated = resource.copyWith(skillTreeIds: links.toList());
      app.emit(app.state.copyWith(resource: updated, resources: [updated]));
    });
    await tester.pumpWidget(
      RepositoryProvider<ResourcesRepository>.value(
        value: harness.resources,
        child: BlocProvider.value(
          value: app,
          child: const MaterialApp(home: ResourceCommentPage(id: 'guide')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Associated skills'));
    await tester.pumpAndSettle();
    final update = find.widgetWithText(FilledButton, 'Update');
    expect(tester.widget<FilledButton>(update).onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'lead');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resource-skill-leading')));
    await tester.pumpAndSettle();
    await tester.tap(update);
    await tester.pumpAndSettle();

    verify(
      () => harness.resources.updateSkillLinks(
        id: 'guide',
        added: {'leading'},
        removed: {},
      ),
    ).called(1);
    expect(find.text('Associated skills'), findsNothing);
    expect(app.state.resource?.skillTreeIds, ['leading']);
  });
}
