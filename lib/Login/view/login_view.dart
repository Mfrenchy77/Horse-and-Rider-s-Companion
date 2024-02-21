import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/auth_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/email_field.dart';
import 'package:horseandriderscompanion/CommonWidgets/forgot_link.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/google_login_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/password_field.dart';
import 'package:horseandriderscompanion/CommonWidgets/registration_link.dart';
import 'package:horseandriderscompanion/Login/cubit/login_cubit.dart';

Widget loginView() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const EmailField(),
      gap(),
      const PasswordField(isConfirmation: false),
      gap(),
      const AuthButton(),
      gap(),
      _signInAsGuest(),
      gap(),
      const RegistationLink(),
      gap(),
      const ForgotPasswordLink(),
      gap(),
      const GoogleLoginButton(),
    ],
  );
}

/// Login as Guest
Widget _signInAsGuest() {
  return SizedBox(
    width: double.infinity,
    child: BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        return TextButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            context.read<LoginCubit>().logInAsGuest();
          },
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Sign in as Guest',
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    ),
  );
}
