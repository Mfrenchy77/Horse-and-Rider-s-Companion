import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';

class NameField extends StatelessWidget {
  const NameField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        return TextFormField(
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (value) =>
              context.read<LoginCubit>().nameChanged(value.trim()),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your Name';
            }

            return null;
          },
          decoration: const InputDecoration(
            labelStyle: TextStyle(color: Colors.white54),
            labelText: 'Name',
            hintStyle: TextStyle(color: Colors.white54),
            hintText: 'Enter your Full Name',
            prefixIcon: Icon(Icons.person_outline, color: Colors.white54),
            border: UnderlineInputBorder(),
          ),
        );
      },
    );
  }
}
