import 'dart:io';
import 'dart:ui' as ui;

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_item.dart';
import 'package:horseandriderscompanion/Settings/resource_layout.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:super_banners/super_banners.dart';

import '../support/app_test_harness.dart';

void main() {
  testWidgets(
    'ResourcesItem clips upper image corners and New badge via AppSurfaceCard',
    (tester) async {
      final shotKey = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(440, 720);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final resource = Resource(
        id: 'res-clip-1',
        name:
            '7 Easy steps to starting in hand work - Part 2 Turn on the '
            'Forehand',
        url: 'https://debbylush.co.uk/article',
        description:
            'Once you have your start and stop controls established, '
            'you can then start with sideways controls.',
        lastEditBy: 'mfrench77@gmail.com',
        lastEditDate: DateTime.now(),
        usersWhoRated: [BaseListItem(id: 'u1', isSelected: true)],
      );

      await tester.pumpWidget(
        BlocProvider.value(
          value: harness.cubit,
          child: ResourceLayoutScope(
            layout: ResourceLayout.vertical,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: mainThemeDark,
              home: RepaintBoundary(
                key: shotKey,
                child: Scaffold(
                  body: AppScaffoldBackdrop(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ResourcesItem(
                        resource: resource,
                        isResourceList: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final surfaceCard = tester.widget<AppSurfaceCard>(
        find.byType(AppSurfaceCard),
      );
      expect(surfaceCard.borderRadius, AppTokens.radiusLg);
      expect(surfaceCard.padding, EdgeInsets.zero);

      final cardClip = tester.widget<ClipRRect>(
        find
            .descendant(
              of: find.byType(AppSurfaceCard),
              matching: find.byType(ClipRRect),
            )
            .first,
      );
      expect(cardClip.borderRadius, BorderRadius.circular(AppTokens.radiusLg));

      expect(
        find.descendant(
          of: find.byType(AppSurfaceCard),
          matching: find.byType(CornerBanner),
        ),
        findsOneWidget,
      );

      await tester.runAsync(() async {
        final boundary =
            shotKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File(
            '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch/resource_card_clipping.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      });
    },
  );
}
