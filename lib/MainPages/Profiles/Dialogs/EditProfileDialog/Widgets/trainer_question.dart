import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';

class TrainerQuestion extends StatelessWidget {
  const TrainerQuestion({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
      builder: (context, state) {
        final cubit = context.read<EditRiderProfileCubit>();
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            children: [
              Checkbox(
                value: state.isTrainer,
                onChanged: (value) => cubit.toggleTrainerStatus(),
              ),
              const Expanded(
                flex: 6,
                child: Text(
                  'Are you a Trainer/Instructor?',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
