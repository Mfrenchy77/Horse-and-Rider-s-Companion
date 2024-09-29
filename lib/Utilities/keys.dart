import 'package:flutter/material.dart';

/// Class to keep the GlobalKeys for the app
class Keys {
  static final GlobalKey<ScaffoldState> riderProfileScaffoldKey =
      GlobalKey<ScaffoldState>(debugLabel: 'RiderProfileScaffold');
  static final GlobalKey<ScaffoldState> hamburgerKey =
      GlobalKey(debugLabel: 'HamburgerIcon');
  static final GlobalKey logBookKey = GlobalKey(debugLabel: 'LogBook');
  static final GlobalKey profileSearchKey =
      GlobalKey(debugLabel: 'ProfileSearch');
  //messages key
  static final GlobalKey messagesKey = GlobalKey(debugLabel: 'Messages');
  //settings key
  static final GlobalKey settingsKey = GlobalKey(debugLabel: 'Settings');
  static final GlobalKey drawerContentKey =
      GlobalKey(debugLabel: 'DrawerContent');
  static final GlobalKey searchIconKey = GlobalKey(debugLabel: 'SearchIcon');
  static final GlobalKey skillTreeTabKey =
      GlobalKey(debugLabel: 'SkillTreeTab');
  static final GlobalKey resourcesTabKey =
      GlobalKey(debugLabel: 'ResourcesTab');

  static final profileSearchDialogKey =
      GlobalKey(debugLabel: 'ProfileSearchDialog');
  // Add other keys as needed
}
