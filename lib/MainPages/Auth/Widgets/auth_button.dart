import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        return state.status.isSubmissionInProgress
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: !state.status.isValidated
                      ? null
                      : () => _handleClick(
                            state: state,
                            cubit: cubit,
                            context: context,
                          ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      _getButtonText(state.pageStatus),
                      style: const TextStyle(fontSize: 16),
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
    case LoginPageStatus.awitingEmailVerification:
      break;
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
    case LoginPageStatus.awitingEmailVerification:
      return 'Awaiting Email Verification';
    case LoginPageStatus.login:
      return 'Login';
    case LoginPageStatus.register:
      return 'Register';
    case LoginPageStatus.forgot:
      return 'Send Email';
  }
}
