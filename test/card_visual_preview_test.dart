import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_entry_card.dart';

import 'support/app_test_harness.dart';

void main() {
  testWidgets('Card appearance preview', (tester) async {
    tester.view.physicalSize = const Size(1100, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final themes = HorseAndRidersTheme();
    await tester.pumpWidget(MaterialApp(home: RepaintBoundary(
      key: const Key('preview'),
      child: Row(children: [
        for (final theme in [themes.getDarkTheme(), themes.getLightTheme()])
          Expanded(child: Theme(data: theme, child: Builder(builder: (context) {
            return Material(color: theme.scaffoldBackgroundColor, child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(theme.brightness == Brightness.dark ? 'Dark theme' : 'Light theme', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 24),
                GradientCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('About', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    const Text('Matt is a horse trainer and instructor who helps riders build confidence and develop a thoughtful partnership with their horses.'),
                    TextButton(onPressed: () {}, child: const Text('Read full bio')),
                  ]))),
                const SizedBox(height: 16),
                GradientCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Owned horses', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [for (final name in ['Valero', 'Navarro']) ActionChip(label: Text(name), onPressed: () {})]),
                  ]))),
                const SizedBox(height: 24),
                Text('Logbook', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                LogbookEntryCard(title: 'Flatwork session', metadata: 'Training · Nov 13, 2026', icon: Icons.directions_run, preview: 'Worked on rhythm and relaxed transitions.', onTap: () {}),
                LogbookEntryCard(title: 'Basic health check', metadata: 'Activity · Nov 12, 2026', icon: Icons.history, onTap: () {}),
              ]),
            ));
          }))),
      ]),
    )));
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const Key('preview')), matchesGoldenFile('/tmp/profile-card-preview.png'));
  });
}
