import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        return state.status == FormStatus.submitting
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canClick(state, cubit)
                      ? null
                      : () {
                          _handleClick(
                            state: state,
                            cubit: cubit,
                            context: context,
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      _getButtonText(state.pageStatus),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
      },
    );
  }
}

/// Handles the diffent state of the button
void _handleClick({
  required LoginState state,
  required LoginCubit cubit,
  required BuildContext context,
}) {
  switch (state.pageStatus) {
    case LoginPageStatus.login:
      cubit.logInWithCredentials();
      break;
    case LoginPageStatus.register:
      cubit.signUpFormSubmitted(context: context);
      break;
    case LoginPageStatus.forgot:
      cubit.sendForgotPasswordEmail();
      break;
  }
}

/// Text for the button
String _getButtonText(LoginPageStatus pageStatus) {
  switch (pageStatus) {
    case LoginPageStatus.login:
      return 'Login';
    case LoginPageStatus.register:
      return 'Register';
    case LoginPageStatus.forgot:
      return 'Send Email';
  }
}

bool _canClick(LoginState state, LoginCubit cubit) {
  switch (state.pageStatus) {
    case LoginPageStatus.forgot:
      // Disable unless email is valid
      return state.email.isNotValid;
    case LoginPageStatus.register:
      // Require valid name, email, password, and confirmed password
      final disabled = state.name.isNotValid ||
          state.email.isNotValid ||
          state.password.isNotValid ||
          state.confirmedPassword.isNotValid;
      return disabled;
    case LoginPageStatus.login:
      // Require valid email and password
      return !cubit.isEmailAndPasswordValid();
  }
}
