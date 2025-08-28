import 'package:flutter/material.dart';

/// Class to keep the GlobalKeys for the app

class Keys {
//Drawer Keys
// logout key
  // Use non-final so tests can reset keys between runs and avoid
  // "Multiple widgets used the same GlobalKey" when creating
  // multiple app instances in the same test process.
  static GlobalKey logoutKey = GlobalKey(debugLabel: 'Logout');
  static GlobalKey logBookKey = GlobalKey(debugLabel: 'LogBook');
  static GlobalKey settingsKey = GlobalKey(debugLabel: 'Settings');
  static GlobalKey messagesKey = GlobalKey(debugLabel: 'Messages');
  static GlobalKey profileSearchKey = GlobalKey(debugLabel: 'ProfileSearch');

//Profile Keys
  static GlobalKey<ScaffoldState> riderProfileScaffoldKey =
      GlobalKey<ScaffoldState>(debugLabel: 'RiderProfileScaffold');
  static GlobalKey<ScaffoldState> hamburgerKey =
      GlobalKey(debugLabel: 'HamburgerIcon');

//LogBook Keys
// add log entry key
  static GlobalKey addLogEntryKey = GlobalKey(debugLabel: 'AddLogEntry');
  static GlobalKey logSortKey = GlobalKey(debugLabel: 'Sort');

//Search Dialog Keys
  //messages key
  //settings key
  static GlobalKey drawerContentKey = GlobalKey(debugLabel: 'DrawerContent');
  static GlobalKey searchIconKey = GlobalKey(debugLabel: 'SearchIcon');
  static GlobalKey skillTreeTabKey = GlobalKey(debugLabel: 'SkillTreeTab');
  static GlobalKey resourcesTabKey = GlobalKey(debugLabel: 'ResourcesTab');

  static GlobalKey profileSearchDialogKey =
      GlobalKey(debugLabel: 'ProfileSearchDialog');

  /// Reset all keys to fresh instances. Call from tests' setUp/tearDown
  /// when tests create multiple app/widget instances in the same process.
  static void reset() {
    logoutKey = GlobalKey(debugLabel: 'Logout');
    logBookKey = GlobalKey(debugLabel: 'LogBook');
    settingsKey = GlobalKey(debugLabel: 'Settings');
    messagesKey = GlobalKey(debugLabel: 'Messages');
    profileSearchKey = GlobalKey(debugLabel: 'ProfileSearch');

    riderProfileScaffoldKey =
        GlobalKey<ScaffoldState>(debugLabel: 'RiderProfileScaffold');
    hamburgerKey = GlobalKey(debugLabel: 'HamburgerIcon');

    addLogEntryKey = GlobalKey(debugLabel: 'AddLogEntry');
    logSortKey = GlobalKey(debugLabel: 'Sort');

    drawerContentKey = GlobalKey(debugLabel: 'DrawerContent');
    searchIconKey = GlobalKey(debugLabel: 'SearchIcon');
    skillTreeTabKey = GlobalKey(debugLabel: 'SkillTreeTab');
    resourcesTabKey = GlobalKey(debugLabel: 'ResourcesTab');
    profileSearchDialogKey = GlobalKey(debugLabel: 'ProfileSearchDialog');
  }
  // Add other keys as needed
}
