import 'package:authentication_repository/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Login/cubit/login_cubit.dart';
import 'package:horseandriderscompanion/Login/view/auth_view.dart';
import 'package:horseandriderscompanion/utils/MyConstants/COLOR_CONST.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const routeName = '/login';

  static Page<void> page() => const MaterialPage<void>(child: LoginPage());
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (context) => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConst.backgroundDark,
      body: BlocProvider(
        create: (_) => LoginCubit(context.read<AuthenticationRepository>()),
        child: const AuthView(),
      ),
    );
  }
}
