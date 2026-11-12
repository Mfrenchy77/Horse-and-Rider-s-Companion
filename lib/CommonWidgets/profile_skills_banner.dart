import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';

class ProfileSkillsBanner extends StatelessWidget {
  const ProfileSkillsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.appBarTheme.backgroundColor ?? Colors.white,
                  gradient: theme.extension<SurfaceGradients>()?.chrome,
                ),
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
