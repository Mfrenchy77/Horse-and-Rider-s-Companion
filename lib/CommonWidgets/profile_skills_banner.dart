import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

class ProfileSkillsBanner extends StatelessWidget {
  const ProfileSkillsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).appBarTheme.backgroundColor ??
                    Colors.white,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Skills',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w200,
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
