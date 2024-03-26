// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/auth_button.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_field.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/login_link.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/registration_link.dart';

Widget forgotView() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const EmailField(
        key: Key('FprgotViewEmail'),
      ),
      gap(),
      const AuthButton(
        key: Key('ForgotViewAuthButton'),
      ),
      gap(),
      const RegistationLink(
        key: Key('ForgotViewRegistrationLink'),
      ),
      gap(),
      const LoginLink(
        key: Key('ForgotViewLoginLink'),
      ),
    ],
  );
}
