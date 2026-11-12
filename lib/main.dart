import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:horseandriderscompanion/App/View/app.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() async {
    // Create repositories
    final messagesRepository = MessagesRepository();
    final skillTreeRepository = SkillTreeRepository();
    final resourcesRepository = ResourcesRepository();
    final riderProfileRepository = RiderProfileRepository();
    final horseProfileRepository = HorseProfileRepository();

    // Auth repo—uses FirebaseAuth + GoogleSignIn singleton
    final authenticationRepository = AuthenticationRepository(
      firebaseAuth: FirebaseAuth.instance,
    );

    // Load user settings
    final settingsController = SettingsController(SettingsService());
    await settingsController.loadSettings();

    // Build the root widget
    return App(
      messagesRepository: messagesRepository,
      settingsController: settingsController,
      skillTreeRepository: skillTreeRepository,
      resourcesRepository: resourcesRepository,
      riderProfileRepository: riderProfileRepository,
      horseProfileRepository: horseProfileRepository,
      authenticationRepository: authenticationRepository,
    );
  });
}
