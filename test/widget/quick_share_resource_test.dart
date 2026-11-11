import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_floating_action_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_overflow_menu.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

void main() {
  final skill = Skill(
    id: 'grooming',
    skillName: 'Grooming',
    rider: true,
    position: 0,
    lastEditBy: 'editor',
    lastEditDate: DateTime.utc(2025),
    category: SkillCategory.Husbandry,
    description: '',
    learningDescription: '',
    proficientDescription: '',
  );

  setUpAll(() => registerFallbackValue(Resource()));

  for (final width in [360.0, 1100.0]) {
    testWidgets('Add resource opens and shares at width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1150);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          usersProfile: RiderProfile(
            id: 'rider',
            email: 'rider@example.com',
            name: 'Rider',
          ),
          allSkills: [skill],
        ),
      );
      final pending = Completer<void>();
      when(harness.resources.newId).thenReturn('shared');
      when(
        () => harness.resources.createResourceWithServerTimestamps(
          resource: any(named: 'resource'),
        ),
      ).thenAnswer((_) => pending.future);

      await tester.pumpWidget(
        RepositoryProvider<ResourcesRepository>.value(
          value: harness.resources,
          child: BlocProvider.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: HorseAndRidersTheme().getDarkTheme(),
              home: const Scaffold(
                floatingActionButton: ResourcesFloatingActionButton(),
                body: ResourcesOverflowMenu(),
              ),
            ),
          ),
        ),
      );
      if (width < 840) {
        await tester.tap(find.byKey(const Key('addResourceButton')));
      } else {
        await tester.tap(find.byTooltip('Add, Edit or Sort Resources'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add'));
      }
      await tester.pumpAndSettle();
      final preview = find.byKey(const Key('communityResourcePreview'));
      final form = find.byKey(const Key('quickShareForm'));
      final url = find.byKey(const Key('resourceUrl'));
      final paste = find.byKey(const Key('pasteResourceUrl'));
      final share = find.byKey(const Key('shareResource'));
      Color? shareBackground() => tester
          .widget<Material>(
            find.descendant(of: share, matching: find.byType(Material)),
          )
          .color;
      Color? chipBackground(Type type, String label) {
        final chip = find.widgetWithText(type, label);
        final ink = tester.widget<Ink>(
          find.descendant(of: chip, matching: find.byType(Ink)),
        );
        return (ink.decoration! as ShapeDecoration).color;
      }

      expect(shareBackground(), ColorConst.mainPrimaryDark);
      expect(
        chipBackground(ChoiceChip, 'Website'),
        ColorConst.dividerDarkBlueGrey,
      );
      expect(
        chipBackground(ChoiceChip, 'Article'),
        ColorConst.cardDarkBlueGrey,
      );
      expect(
        chipBackground(ActionChip, 'Grooming'),
        ColorConst.cardDarkBlueGrey,
      );
      if (width < 840) {
        expect(
          tester.getTopLeft(preview).dy,
          greaterThan(tester.getBottomLeft(form).dy),
        );
        expect(
          tester.getTopLeft(paste).dy,
          greaterThan(tester.getTopLeft(url).dy),
        );
      } else {
        expect(
          tester.getTopLeft(preview).dx,
          greaterThan(tester.getTopRight(form).dx),
        );
        expect(
          tester.getTopLeft(paste).dx,
          greaterThan(tester.getTopLeft(url).dx),
        );
      }

      await tester.enterText(url, 'wrong');
      await tester.pump();
      expect(find.text('Enter a valid web URL'), findsOneWidget);
      expect(tester.widget<FilledButton>(share).onPressed, isNull);
      await tester.enterText(url, 'https://example.com/training');
      await tester.enterText(
        find.byKey(const Key('resourceTitle')),
        'A useful guide',
      );
      await tester.enterText(
        find.byKey(const Key('resourceRecommendation')),
        'Clear examples',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(share).onPressed, isNull);

      await tester.tap(find.widgetWithText(ActionChip, 'Grooming'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Article'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(
        chipBackground(ChoiceChip, 'Article'),
        ColorConst.dividerDarkBlueGrey,
      );
      expect(shareBackground(), ColorConst.mainAccentDark);
      expect(
        find.descendant(of: preview, matching: find.text('A useful guide')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: preview, matching: find.text('Clear examples')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: preview, matching: find.text('Grooming')),
        findsOneWidget,
      );
      await tester.ensureVisible(share);
      await tester.tap(share);
      await tester.pump();
      expect(find.text('Sharing…'), findsOneWidget);
      final saved =
          verify(
                () => harness.resources.createResourceWithServerTimestamps(
                  resource: captureAny(named: 'resource'),
                ),
              ).captured.single
              as Resource;
      expect(saved.name, 'A useful guide');
      expect(saved.description, 'Clear examples');
      expect(saved.skillTreeIds, ['grooming']);
      expect(saved.type, ResourceType.externalArticle);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Resource shared'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
