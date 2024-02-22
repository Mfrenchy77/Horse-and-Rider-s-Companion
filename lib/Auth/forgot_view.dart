// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Auth/Widgets/auth_button.dart';
import 'package:horseandriderscompanion/Auth/Widgets/email_field.dart';
import 'package:horseandriderscompanion/Auth/Widgets/login_link.dart';
import 'package:horseandriderscompanion/Auth/Widgets/registration_link.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';

Widget forgotView() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const EmailField(),
      gap(),
      const AuthButton(),
      gap(),
      const RegistationLink(),
      gap(),
      const LoginLink(),
    ],
  );
}
