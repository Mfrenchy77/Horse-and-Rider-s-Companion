// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/forgot_link.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/login_link.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/Login/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/utils/MyConstants/COLOR_CONST.dart';
import 'package:horseandriderscompanion/utils/view_utils.dart';

Widget registerView({
  required BuildContext context,
  required LoginState state,
  required bool isSmallScreen,
}) {
  return isSmallScreen
      ? Card(
          color: ColorConst.cardDark,
          margin: const EdgeInsets.only(left: 20, right: 20, top: 42),
          elevation: 5,
          child: SingleChildScrollView(
            reverse: true,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Logo(screenName: 'Register', forceDark: true),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Form(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _nameField(context: context, state: state),
                          gap(),
                          _emailField(context: context, state: state),
                          gap(),
                          _passwordField(context: context, state: state),
                          gap(),
                          _confirmPasswordField(context: context, state: state),
                          gap(),
                          _submitButton(context: context, state: state),
                          gap(),
                          const LoginLink(),
                          gap(),
                          const ForgotPasswordLink(),
                          gap(),
                          _googleLoginButton(context: context, state: state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      : Card(
        color: ColorConst.cardDark,
          margin: const EdgeInsets.only(left: 20, right: 20, top: 42),
          elevation: 5,
          child: SingleChildScrollView(
            reverse: true,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: SizedBox(),
                      ),
                      const Expanded(
                        flex: 5,
                        child: Logo(
                          screenName: 'Register',
                          forceDark: true,
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: Form(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _nameField(context: context, state: state),
                                gap(),
                                _emailField(context: context, state: state),
                                gap(),
                                _passwordField(context: context, state: state),
                                gap(),
                                _confirmPasswordField(
                                  context: context,
                                  state: state,
                                ),
                                gap(),
                                _submitButton(context: context, state: state),
                                gap(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: SizedBox(),
                      ),
                    ],
                  ),
                  const LoginLink(),
                  smallGap(),
                  const ForgotPasswordLink(),
                  gap(),
                  _googleLoginButton(context: context, state: state),
                ],
              ),
            ),
          ),
        );
}

Widget _nameField({required BuildContext context, required LoginState state}) {
  return TextFormField(
    style: const TextStyle(color: Colors.white),
    keyboardType: TextInputType.name,
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.next,
    onChanged: (value) => context.read<LoginCubit>().nameChanged(value.trim()),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter your Name';
      }

      return null;
    },
    decoration: const InputDecoration(
      labelStyle: TextStyle(color: Colors.white54),
      labelText: 'Name',
      hintStyle: TextStyle(color: Colors.white54),
      hintText: 'Enter your Full Name',
      prefixIcon: Icon(Icons.person_outline, color: Colors.white54),
      border: UnderlineInputBorder(),
    ),
  );
}

Widget _emailField({required BuildContext context, required LoginState state}) {
  return TextFormField(
    style: const TextStyle(color: Colors.white),
    textInputAction: TextInputAction.next,
    onChanged: (email) => context.read<LoginCubit>().emailChanged(email.trim()),
    keyboardType: TextInputType.emailAddress,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter some text';
      }
      if (!ViewUtils.isEmailValid(value)) {
        return 'Please enter a valid email';
      }
      return null;
    },
    decoration: InputDecoration(
      labelStyle: const TextStyle(color: Colors.white54),
      labelText: 'Email',
      hintStyle: const TextStyle(color: Colors.white54),
      hintText: 'Enter your email',
      errorText: state.email.invalid ? 'invalid email' : null,
      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
      border: const UnderlineInputBorder(),
    ),
  );
}

Widget _passwordField({
  required BuildContext context,
  required LoginState state,
}) {
  return TextFormField(
    style: const TextStyle(color: Colors.white),
    textInputAction: TextInputAction.next,
    onChanged: (value) =>
        context.read<LoginCubit>().passwordChanged(value.trim()),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter some text';
      }

      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
      return null;
    },
    obscureText: !state.isPasswordVisible,
    decoration: InputDecoration(
      labelStyle: const TextStyle(color: Colors.white54),
      labelText: 'Password',
      hintStyle: const TextStyle(color: Colors.white54),
      hintText: 'Enter your password',
      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white54),
      border: const UnderlineInputBorder(),
      suffixIcon: IconButton(
        icon: Icon(
          state.isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          color: Colors.white54,
        ),
        onPressed: () {
          // ignore: avoid_print
          print('show/hide password');
          context.read<LoginCubit>().togglePasswordVisible();
        },
      ),
    ),
  );
}

Widget _confirmPasswordField({
  required BuildContext context,
  required LoginState state,
}) {
  return TextFormField(
    style: const TextStyle(color: Colors.white),
    textInputAction: TextInputAction.done,
    onChanged: (value) =>
        context.read<LoginCubit>().confirmedPasswordChanged(value.trim()),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter some text';
      }

      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
      return null;
    },
    obscureText: !state.isPasswordVisible,
    decoration: InputDecoration(
      labelStyle: const TextStyle(color: Colors.white54),
      labelText: 'Re-Enter Password',
      hintStyle: const TextStyle(color: Colors.white54),
      hintText: 'Confirm your password',
      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white54),
      border: const UnderlineInputBorder(),
      suffixIcon: IconButton(
        icon: Icon(
          state.isPasswordVisible ? Icons.visibility_off : Icons.visibility,
        color: Colors.white54,),
        onPressed: () {
          // ignore: avoid_print
          print('show/hide password');
          context.read<LoginCubit>().togglePasswordVisible();
        },
      ),
    ),
  );
}

Widget _submitButton({
  required BuildContext context,
  required LoginState state,
}) {
  return state.status.isSubmissionInProgress
      ? const CircularProgressIndicator()
      : SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: !state.status.isValidated
                ? null
                : () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    context
                        .read<LoginCubit>()
                        .signUpFormSubmitted(context: context);
                  },
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Register',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
}

///   Widget that has a button that sends you to Google autherization link
Widget _googleLoginButton({
  required BuildContext context,
  required LoginState state,
}) {
  return Column(
    children: [
      const Text('Login with Google Account', style: TextStyle(color: Colors.white54),),
      IconButton(
        color: Colors.white54,
        onPressed: () => context.read<LoginCubit>().logInWithGoogle(),
        icon: Image.asset(
          'assets/google_icon.png',
          height: 30,
          width: 30,
        ),
      ),
    ],
  );
}
