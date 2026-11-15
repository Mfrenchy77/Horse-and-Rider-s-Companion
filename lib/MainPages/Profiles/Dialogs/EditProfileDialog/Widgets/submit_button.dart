import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';

class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
      builder: (context, state) {
        final cubit = context.read<EditRiderProfileCubit>();
        final isInProgress = state.status == SubmissionStatus.inProgress;
        return FilledButton(
          onPressed: isInProgress
              ? null
              : () {
                  if (state.user != null) {
                    cubit.createRiderProfile();
                  } else {
                    cubit.updateRiderProfile();
                  }
                },
          child: isInProgress
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(state.user != null ? 'Create Profile' : 'Submit'),
        );
      },
    );
  }
}
