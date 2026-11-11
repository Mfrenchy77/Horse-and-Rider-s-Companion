import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/View/app.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_page_header.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_item.dart';
import 'package:horseandriderscompanion/Settings/resource_layout.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';

import '../support/app_test_harness.dart';

void main() {
  testWidgets(
    'the Settings choice applies across resource surfaces and widths',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final settings = SettingsController(SettingsService());
      addTearDown(settings.dispose);
      await settings.loadSettings();
      final resource = Resource(id: 'guide', name: 'Training guide');
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: ResourcesItem(resource: resource, isResourceList: true),
            ),
          ),
          GoRoute(
            path: '/skill',
            builder: (_, _) => Scaffold(
              body: ResourcesItem(resource: resource, isResourceList: false),
            ),
          ),
          GoRoute(
            path: '/discussion',
            builder: (_, _) =>
                Scaffold(body: CommentPageHeader(resource: resource)),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => SettingsView(controller: settings),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider.value(
          value: harness.cubit,
          child: AppView(settingsController: settings, router: router),
        ),
      );
      await tester.pumpAndSettle();

      Rect image() => tester.getRect(find.byKey(const Key('ResourceImage')));
      Rect title() => tester.getRect(find.text('Training guide'));
      expect(title().top, greaterThan(image().bottom));

      router.go('/settings');
      await tester.pumpAndSettle();
      final selector = find.byType(DropdownButton<ResourceLayout>);
      await tester.ensureVisible(selector);
      expect(
        tester.widget<DropdownButton<ResourceLayout>>(selector).value,
        ResourceLayout.vertical,
      );
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Horizontal').last);
      await tester.pumpAndSettle();
      expect(settings.resourceLayout, ResourceLayout.horizontal);

      for (final path in ['/', '/skill', '/discussion']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(title().left, greaterThanOrEqualTo(image().right));
        expect(title().top, lessThan(image().bottom));
      }

      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpAndSettle();
      for (final path in ['/discussion', '/', '/skill']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(title().top, greaterThan(image().bottom));
      }
      expect(settings.resourceLayout, ResourceLayout.horizontal);

      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();
      expect(title().left, greaterThanOrEqualTo(image().right));
      expect(tester.takeException(), isNull);
    },
  );
}
