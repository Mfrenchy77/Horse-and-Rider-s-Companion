import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class SkillsTextButton extends StatelessWidget {
  const SkillsTextButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    return TextButton(
      onPressed: cubit.navigateToSkillsList,
      child: Text(
        'Skills',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w200,
          fontSize: 24,
          color: // if theme is dark white else black
              HorseAndRidersTheme().isDarkTheme() ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
