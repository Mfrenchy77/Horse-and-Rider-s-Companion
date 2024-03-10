import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/Utilities/Constants/color_constants.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorConst.backgroundDark,
        //back button loggin out the user
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: cubit.logOutRequested,
        ),
      ),
      backgroundColor: ColorConst.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Logo(forceDark: true, screenName: 'Loading...'),
            gap(),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
