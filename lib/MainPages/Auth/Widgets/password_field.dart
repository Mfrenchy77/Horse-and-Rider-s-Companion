import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({required this.isConfirmation, super.key});
  final bool isConfirmation;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  static const _debounce = Duration(milliseconds: 5000);
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  final _focusNode = FocusNode();
  bool _showError = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _validateNow();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleValidation() {
    _timer?.cancel();
    _showError = false;
    _timer = Timer(_debounce, _validateNow);
  }

  void _validateNow() {
    if (mounted) {
      setState(() => _showError = true);
      _fieldKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LoginCubit>();
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        return TextFormField(
          key: _fieldKey,
          focusNode: _focusNode,
          autovalidateMode: AutovalidateMode.disabled,
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (value) {
            if (_focusNode.hasFocus) {
              if (state.pageStatus == LoginPageStatus.login) {
                cubit.logInWithCredentials();
              } else if (widget.isConfirmation &&
                  state.pageStatus == LoginPageStatus.register) {
                cubit.signUpFormSubmitted(context: context);
              }
              _focusNode.unfocus();
            }
          },
          onChanged: (value) {
            widget.isConfirmation
                ? cubit.confirmedPasswordChanged(value)
                : cubit.passwordChanged(value);
            _scheduleValidation();
          },
          validator: (value) {
            if (!_showError) return null;
            if (widget.isConfirmation) {
              return state.password
                  .confirmValitator(state.password.value, value ?? '');
            }
            return state.password.validator(value ?? '');
          },
          obscureText: !state.isPasswordVisible,
          decoration: InputDecoration(
            labelStyle: const TextStyle(color: Colors.white54),
            labelText: widget.isConfirmation ? 'Re-Enter Password' : 'Password',
            hintText: widget.isConfirmation
                ? 'Confirm your password'
                : 'Enter your password',
            hintStyle: const TextStyle(color: Colors.white54),
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
