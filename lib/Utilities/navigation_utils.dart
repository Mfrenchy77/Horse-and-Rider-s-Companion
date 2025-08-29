import 'package:flutter/widgets.dart';

/// Safely pop a route if possible.
///
/// Use this from widgets that may be presented as overlays (dialogs, drawers,
/// etc.) to avoid accidentally popping the last page off the app's navigator
/// stack which can cause routing assertions (eg. GoRouter "no pages left").
void safePop(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}
