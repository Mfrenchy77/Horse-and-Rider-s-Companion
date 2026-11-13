import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';

void main() {
  testWidgets(
    'Phase A design system components render cleanly and keep destructive '
    'distinct',
    (tester) async {
      final shotKey = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 960);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: mainThemeDark,
          home: RepaintBoundary(
            key: shotKey,
            child: Scaffold(
              body: AppScaffoldBackdrop(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSectionHeader(
                              title: 'Design System',
                              actionLabel: 'View All',
                              showArrow: true,
                              onAction: () {},
                            ),
                            const SizedBox(height: 12),
                            const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AppStatusBadge(
                                  label: 'Proficient',
                                  icon: Icons.verified,
                                  tone: AppStatusTone.success,
                                ),
                                AppStatusBadge(
                                  label: 'Learning',
                                  icon: Icons.school_outlined,
                                  tone: AppStatusTone.coral,
                                ),
                                AppStatusBadge(
                                  label: 'Warning',
                                  icon: Icons.warning_amber_rounded,
                                  tone: AppStatusTone.warning,
                                ),
                                AppStatusBadge(
                                  label: 'Error',
                                  icon: Icons.error_outline,
                                  tone: AppStatusTone.error,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                AppPrimaryButton(
                                  label: 'Save Changes',
                                  icon: Icons.check,
                                  onPressed: () {},
                                ),
                                AppOutlinedButton(
                                  label: 'Cancel',
                                  icon: Icons.close,
                                  onPressed: () {},
                                ),
                                AppDestructiveButton(
                                  label: 'Delete',
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const TextField(
                              decoration: InputDecoration(
                                labelText: 'Rider Name',
                                hintText: 'Enter full name',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const AppFeedbackBanner(
                        message: 'Profile updated successfully.',
                      ),
                      const SizedBox(height: 16),
                      AppEmptyState(
                        title: 'No entries yet',
                        description: 'Start logging rides to track progress.',
                        actionLabel: 'Add Entry',
                        onAction: () {},
                      ),
                      const SizedBox(height: 16),
                      AppErrorState(
                        message: 'Unable to load records right now.',
                        onRetry: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Design System'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Profile updated successfully.'), findsOneWidget);
      expect(find.text('No entries yet'), findsOneWidget);
      expect(find.text('Unable to load records right now.'), findsOneWidget);

      // Verify destructive button uses error color, distinct from coral.
      final primaryBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save Changes'),
      );
      final destructiveBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete'),
      );
      final primaryBg = primaryBtn.style?.backgroundColor?.resolve({});
      final destructiveBg = destructiveBtn.style?.backgroundColor?.resolve({});
      expect(primaryBg, AppTokens.coralAccent);
      expect(destructiveBg, ColorConst.errorDarkBlueGrey);
      expect(destructiveBg, isNot(AppTokens.coralAccent));

      await tester.runAsync(() async {
        final boundary =
            shotKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File(
            '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch/phase_a_design_system.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      });
    },
  );
}
