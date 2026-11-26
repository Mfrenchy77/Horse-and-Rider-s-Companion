import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

import '../support/app_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SkillTreeV2View app bar shows AppTitle wordmark on wide screens and '
    'compact logo on narrow screens while preserving navigation and actions',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;

      Widget buildApp() => BlocProvider<AppCubit>.value(
        value: harness.cubit,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: mainThemeDark,
          home: const SkillTreeV2View(),
        ),
      );

      // Wide viewport -> full AppTitle wordmark.
      tester.view.physicalSize = const Size(1024, 900);
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AppTitle), findsOneWidget);
      expect(
        find.byKey(const Key('skillTreeV2AppBarWordmark')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('skillTreeV2AppBarCompactLogo')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('skillTreeV2AppBarBackButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('skillTreeV2AppBarOverflowMenu')),
        findsOneWidget,
      );
      // Redundant 'Skill Tree' text should not appear inside the AppBar.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Skill Tree'),
        ),
        findsNothing,
      );

      // Narrow viewport -> compact horse-shield logo.
      tester.view.physicalSize = const Size(360, 900);
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byKey(const Key('skillTreeV2AppBarCompactLogo')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('skillTreeV2AppBarWordmark')), findsNothing);
      expect(
        find.byKey(const Key('skillTreeV2AppBarBackButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('skillTreeV2AppBarOverflowMenu')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
