import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/forgot_link.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/google_login_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/CommonWidgets/registration_link.dart';
import 'package:horseandriderscompanion/Login/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/utils/MyConstants/my_const.dart';
import 'package:horseandriderscompanion/utils/view_utils.dart';

Widget loginView({
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
                  const Logo(screenName: 'Login', forceDark: true),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Form(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _emailField(
                            context: context,
                            state: state,
                          ),
                          gap(),
                          _passwordField(context: context, state: state),
                          gap(),
                          _submitButton(context: context, state: state),
                          gap(),
                          _signInAsGuest(context: context),
                          gap(),
                          const RegistationLink(),
                          gap(),
                          const ForgotPasswordLink(),
                          gap(),
                          const GoogleLoginButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      :
      //large screen
      Row(
          children: [
            // const ResponsiveVisibility(
            //   hiddenConditions: [
            //     Condition.smallerThan(name: DESKTOP),
            //   ],
            //   child: Expanded(
            //     child: SizedBox(),
            //   ),
            // ),
            Expanded(
              flex: 10,
              child: Card(
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Expanded(
                              flex: 2,
                              child: SizedBox(),
                            ),
                            const Expanded(
                              flex: 5,
                              child: Logo(
                                forceDark: true,
                                screenName: 'Login',
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _emailField(
                                    context: context,
                                    state: state,
                                  ),
                                  gap(),
                                  _passwordField(
                                    context: context,
                                    state: state,
                                  ),
                                  gap(),
                                  _submitButton(context: context, state: state),
                                  gap(),
                                ],
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: SizedBox(),
                            ),
                          ],
                        ),
                        gap(),
                        _signInAsGuest(context: context),
                        gap(),
                        const RegistationLink(),
                        gap(),
                        const ForgotPasswordLink(),
                        gap(),
                        const GoogleLoginButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            //    const ResponsiveVisibility(
            //     hiddenConditions: [
            //       Condition.smallerThan(name: DESKTOP),
            //     ],
            //     child: Expanded(
            //       child: SizedBox(),
            //     ),
            //   ),
          ],
        );
}

    /// Login as Guest
Widget _signInAsGuest({required BuildContext context}) {
  return SizedBox(
    width: double.infinity,
    child: TextButton(
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
    ),
  );
}

Widget _emailField({
  required BuildContext context,
  required LoginState state,
}) {
  return TextFormField(
    style: const TextStyle(
      color: Colors.white,
    ),
    textInputAction: TextInputAction.next,
    onChanged: (email) => context.read<LoginCubit>().emailChanged(email),
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
      iconColor: Colors.white54,
      labelStyle: const TextStyle(
        color: Colors.white54,
      ),
      labelText: 'Email',
      hintText: 'Enter your email',
      hintStyle: const TextStyle(
        color: Colors.white54,
      ),
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
    style: const TextStyle(
      color: Colors.white,
    ),
    textInputAction: TextInputAction.send,
    onFieldSubmitted: (value) => value.isNotEmpty
        ? context.read<LoginCubit>().logInWithCredentials()
        : null,
    onChanged: (value) => context.read<LoginCubit>().passwordChanged(value),
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
      labelText: 'Password',
      labelStyle: const TextStyle(
        color: Colors.white54,
      ),
      hintText: 'Enter your password',
      hintStyle: const TextStyle(
        color: Colors.white54,
      ),
      prefixIcon: const Icon(
        Icons.lock_outline_rounded,
        color: Colors.white54,
      ),
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
                    context.read<LoginCubit>().logInWithCredentials();
                  },
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Login',
                style: TextStyle(fontSize: 16),
              ),
            ),
            // onPressed: () {
            //   if (state.status.isValidated) {
            //    ;
            //   }
            //   else return null:
            // },
          ),
        );
}
