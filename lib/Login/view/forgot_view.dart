// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/login_link.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/CommonWidgets/registration_link.dart';
import 'package:horseandriderscompanion/Login/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/utils/MyConstants/COLOR_CONST.dart';
import 'package:horseandriderscompanion/utils/view_utils.dart';

Widget forgotView({
  required BuildContext context,
  required LoginState state,
  required bool isSmallScreen,
}) {
  if (state.forgotEmailSent) {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: HorseAndRidersTheme().getTheme().colorScheme.primary,
          duration: const Duration(seconds: 15),
          action: SnackBarAction(
            label: 'Open Email',
            onPressed: () => context
                .read<LoginCubit>()
                .openEmailApp(context: context, email: state.email.value),
          ),
          content: const Text(
            'Password reset email sent',
            textAlign: TextAlign.center,
          ),
        ),
      );
    });
    return Center(
      child: Card(
        color: ColorConst.cardDark,
        elevation: 5,
        margin: const EdgeInsets.only(left: 20, right: 20, top: 42),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Logo(
                screenName:
                    'Please check ${state.email.value} for a link to reset your password',
                forceDark: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.read<LoginCubit>().openEmailApp(
                            email: state.email.value,
                            context: context,
                          ),
                      child: const Text('Open Email'),
                    ),
                  ),
                  smallGap(),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          context.read<LoginCubit>().clearForgotEmailSent(),
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  } else {
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
                    const Logo(
                      screenName: 'Forgot Password',
                      forceDark: true,
                    ),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Form(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _emailField(context: context, state: state),
                            gap(),
                            _submitButton(context: context, state: state),
                            gap(),
                            const RegistationLink(),
                            gap(),
                            const LoginLink(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : //large screen
        Card(
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
                            screenName: 'Forgot Password',
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
                                  _emailField(context: context, state: state),
                                  gap(),
                                  _submitButton(
                                    context: context,
                                    state: state,
                                  ),
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
                    const RegistationLink(),
                    gap(),
                    const LoginLink(),
                  ],
                ),
              ),
            ),
          );
  }
}

Widget _emailField({required BuildContext context, required LoginState state}) {
  return TextFormField(
    style: const TextStyle(color: Colors.white),
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
      labelStyle: const TextStyle(
        color: Colors.white54,
      ),
      labelText: 'Email',
      hintStyle: const TextStyle(
        color: Colors.white54,
      ),
      hintText: 'Enter your email',
      errorText: state.email.invalid ? 'invalid email' : null,
      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
      border: const UnderlineInputBorder(),
    ),
  );
}

Widget _submitButton({
  required BuildContext context,
  required LoginState state,
}) {
  //FIXME(mfrenchy77):
  //this might cause an issue with the button color
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
            onPressed: !state.email.valid
                ? null
                : () => context.read<LoginCubit>().sendForgotPasswordEmail(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
}
