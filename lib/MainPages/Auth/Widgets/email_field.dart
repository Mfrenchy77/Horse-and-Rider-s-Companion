import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';

class EmailField extends StatefulWidget {
  const EmailField({super.key});

  @override
  State<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<EmailField> {
  static const _debounce = Duration(milliseconds: 5000);
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  final _focusNode = FocusNode();
  bool _showError = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _validateNow();
      }
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
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        return TextFormField(
          key: _fieldKey,
          focusNode: _focusNode,
          autovalidateMode: AutovalidateMode.disabled,
          autofocus: state.pageStatus == LoginPageStatus.login ||
              state.pageStatus == LoginPageStatus.forgot,
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.next,
          onChanged: (v) {
            cubit.emailChanged(v);
            _scheduleValidation();
          },
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (!_showError) return null;
            return state.email.validator(value ?? '');
          },
          decoration: const InputDecoration(
            iconColor: Colors.white54,
            labelStyle: TextStyle(color: Colors.white54),
            labelText: 'Email',
            hintText: 'Enter your email',
            hintStyle: TextStyle(color: Colors.white54),
            prefixIcon: Icon(Icons.email_outlined, color: Colors.white54),
            border: UnderlineInputBorder(),
          ),
        );
      },
    );
  }
}
