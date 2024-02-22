// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Auth/Widgets/auth_button.dart';
import 'package:horseandriderscompanion/Auth/Widgets/email_field.dart';
import 'package:horseandriderscompanion/Auth/Widgets/forgot_link.dart';
import 'package:horseandriderscompanion/Auth/Widgets/google_login_button.dart';
import 'package:horseandriderscompanion/Auth/Widgets/login_link.dart';
import 'package:horseandriderscompanion/Auth/Widgets/name_field.dart';
import 'package:horseandriderscompanion/Auth/Widgets/password_field.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';

Widget registerView() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const NameField(),
      gap(),
      const EmailField(),
      gap(),
      const PasswordField(isConfirmation: false),
      gap(),
      const PasswordField(isConfirmation: true),
      gap(),
      const AuthButton(),
      gap(),
      const LoginLink(),
      gap(),
      const ForgotPasswordLink(),
      gap(),
      const GoogleLoginButton(),
    ],
  );
}
