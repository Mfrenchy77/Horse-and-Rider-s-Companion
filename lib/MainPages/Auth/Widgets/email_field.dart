import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';

class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        return Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            autofocus: state.pageStatus == LoginPageStatus.login ||
                state.pageStatus == LoginPageStatus.forgot,
            style: const TextStyle(
              color: Colors.white,
            ),
            textInputAction: TextInputAction.next,
            onChanged: cubit.emailChanged,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              debugPrint('Validation: $value');
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              } else {
                return state.email.validator(value);
              }
            },
            decoration: const InputDecoration(
              iconColor: Colors.white54,
              labelStyle: TextStyle(
                color: Colors.white54,
              ),
              labelText: 'Email',
              hintText: 'Enter your email',
              hintStyle: TextStyle(
                color: Colors.white54,
              ),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.white54),
              border: UnderlineInputBorder(),
            ),
          ),
        );
      },
    );
  }
}
