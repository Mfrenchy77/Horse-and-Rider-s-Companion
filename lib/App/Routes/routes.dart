import 'package:flutter/widgets.dart';

import 'package:horseandriderscompanion/App/Bloc/app_bloc.dart';
import 'package:horseandriderscompanion/Home/Home/View/home_page.dart';
import 'package:horseandriderscompanion/Login/view/login_page.dart';

List<Page<dynamic>> onGenerateAppViewPages(
  AppStatus state,
  List<Page<dynamic>> pages,
) {
  switch (state) {
    case AppStatus.authenticated:
      return [HomePage.page()];
    case AppStatus.unauthenticated:
      return [LoginPage.page()];
  }
}
