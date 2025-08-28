import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/auth_button.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/email_field.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/forgot_link.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/google_login_button.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/password_field.dart';
import 'package:horseandriderscompanion/MainPages/Auth/Widgets/registration_link.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';

Widget loginView() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const EmailField(
        key: Key('LoginEmailField'),
      ),
      gap(),
      const PasswordField(
        isConfirmation: false,
        key: Key('LoginViewPasswordField'),
      ),
      gap(),
      const AuthButton(
        key: Key('LoginViewAuthButton'),
      ),
      gap(),
      _signInAsGuest(),
      gap(),
      const RegistrationLink(
        key: Key('LoginViewRegistrationLink'),
      ),
      gap(),
      const ForgotPasswordLink(
        key: Key('LoginViewForgotPasswordLink'),
      ),
      gap(),
      const GoogleLoginButton(
        key: Key('LoginViewGoogleLoginButton'),
      ),
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
