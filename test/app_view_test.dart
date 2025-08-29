import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/View/app.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AppView builds with router and shows home', (tester) async {
    // Prepare shared preferences for SettingsService
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();

    final controller = SettingsController(SettingsService());
    await controller.loadSettings();

    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const Text('Home!'),
        ),
      ],
    );

    await tester
        .pumpWidget(AppView(settingsController: controller, router: router));
    await tester.pumpAndSettle();

    expect(find.text('Home!'), findsOneWidget);
  });
}
