import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({
    required this.isConfirmation,
    super.key,
  });
  final bool isConfirmation;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LoginCubit>();
    final passwordFocusNode = FocusNode();

    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        return TextFormField(
          focusNode: passwordFocusNode,
          style: const TextStyle(
            color: Colors.white,
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (value) {
            if (passwordFocusNode.hasFocus) {
              if (state.pageStatus == LoginPageStatus.login) {
                cubit.logInWithCredentials();
              } else if (isConfirmation &&
                  state.pageStatus == LoginPageStatus.register) {
                cubit.signUpFormSubmitted(context: context);
              }
              passwordFocusNode.unfocus();
            }
          },
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
            hintText: isConfirmation
                ? 'Confirm your password'
                : 'Enter your password',
            hintStyle: const TextStyle(
              color: Colors.white54,
            ),
            prefixIcon:
                const Icon(Icons.lock_outline_rounded, color: Colors.white54),
            suffixIcon: IconButton(
              icon: Icon(
                state.isPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: cubit.togglePasswordVisible,
            ),
          ),
        );
      },
    );
  }
}
