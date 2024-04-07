import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_card.dart';

class HorseInstructors extends StatelessWidget {
  const HorseInstructors({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return state.horseProfile?.instructors == null
            ? const SizedBox.shrink()
            : state.horseProfile!.instructors!.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const Text(
                        'Instructors',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      smallGap(),
                      Wrap(
                        children: [
                          for (final BaseListItem instructor
                              in state.horseProfile?.instructors ?? [])
                            ProfileCard(
                              baseItem: instructor,
                            ),
                        ],
                      ),
                    ],
                  );
      },
    );
  }
}
