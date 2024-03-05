import 'package:flutter/widgets.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile_page.dart';

List<Page<dynamic>> onGenerateAppViewPages(
  AppStatus state,
  List<Page<dynamic>> pages,
) {
  switch (state) {
    case AppStatus.authenticated:
      debugPrint('Routes: Authenticated');
      return [RiderProfilePage.page()];
    // return [HomePage.page()];
    case AppStatus.unauthenticated:
      debugPrint('Routes: Unauthenticated');
      return [AuthPage.page()];
  }
}
