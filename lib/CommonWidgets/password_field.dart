import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Login/cubit/login_cubit.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({
    required this.isConfirmation,
    super.key,
  });
  final bool isConfirmation;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        return TextFormField(
          style: const TextStyle(
            color: Colors.white,
          ),
          textInputAction:
              isConfirmation ? TextInputAction.send : TextInputAction.next,
          onFieldSubmitted: (value) => value.isNotEmpty
              ? handleEnter(
                  cubit: cubit,
                  isConfirmation: isConfirmation,
                  state: state,
                  context: context,
                )
              : null,
          onChanged: (value) => isConfirmation
              ? cubit.confirmedPasswordChanged(value)
              : cubit.passwordChanged(value),
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
            labelText: isConfirmation ? 'Re-Enter Password' : 'Password',
            labelStyle: const TextStyle(
              color: Colors.white54,
            ),
            hintText:
                isConfirmation ? 'Confirm you password' : 'Enter your password',
            hintStyle: const TextStyle(
              color: Colors.white54,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white54,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                state.isPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: () {
                // ignore: avoid_print
                debugPrint('show/hide password');
                cubit.togglePasswordVisible();
              },
            ),
          ),
        );
      },
    );
  }
}

/// Handle the password field when the user presses enter
void handleEnter({
  required LoginCubit cubit,
  required bool isConfirmation,
  required LoginState state,
  required BuildContext context,
}) {
  // if page status is login then log in with credentials
  // if confirmation is true then log in with sign up
  // else move to next field
  state.pageStatus == LoginPageStatus.login
      ? cubit.logInWithCredentials()
      : isConfirmation
          ? cubit.signUpFormSubmitted(context: context)
          : FocusScope.of(context).nextFocus();
}
