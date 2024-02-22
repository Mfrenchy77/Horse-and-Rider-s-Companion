import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Auth/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/utils/view_utils.dart';

class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        return TextFormField(
          style: const TextStyle(
            color: Colors.white,
          ),
          textInputAction: TextInputAction.next,
          onChanged: cubit.emailChanged,
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
      },
    );
  }
}
