import 'package:authentication_repository/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_view.dart';
import 'package:horseandriderscompanion/MainPages/Auth/cubit/login_cubit.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  static const routeName = '/';
  static const name = 'AuthPage';

  static Page<void> page() => const MaterialPage<void>(child: AuthPage());
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (context) => const AuthPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(context.read<AuthenticationRepository>()),
      child: const AuthView(),
    );
  }
}
