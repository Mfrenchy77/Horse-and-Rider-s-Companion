import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_view.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});
  static const path = '/Resources';
  static const guestResources = 'GuestResources';
  static const horseResources = 'HorseResources';
  static const userProfileResourceName = 'UserProfileResourcePage';
  static const horseProfileResourceName = 'HorseProfileResourcePage';
  static const guestProfileResourceName = 'GuestProfileResourcePage';
  @override
  Widget build(BuildContext context) {
    return 
    // const NavigatorView(
    //   child:
       const ResourcesView(
        key: Key('resourcesView'),
      // ),
    );
  }
}
