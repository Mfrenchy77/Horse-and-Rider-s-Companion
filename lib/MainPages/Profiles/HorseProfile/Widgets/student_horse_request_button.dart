import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class StudentHorseRequestButton extends StatelessWidget {
  const StudentHorseRequestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        final isOwnerOrGuest = cubit.isOwner() || state.isGuest;
        final isTrainer = state.usersProfile?.isTrainer ?? false;
        final isStudentHorse = cubit.isStudentHorse();

        if (!isOwnerOrGuest && isTrainer) {
          return Tooltip(
            message: isStudentHorse
                ? 'Remove Horse as Student'
                : 'Request to be Student Horse',
            child: ElevatedButton.icon(
              icon: const Icon(HorseAndRiderIcons.horseIconAdd),
              onPressed: cubit.requestToBeStudentHorse,
              label: Text(
                isStudentHorse
                    ? 'Remove Horse as Student'
                    : 'Request to be Student Horse',
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
