import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/Utilities/navigation_utils.dart';

class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
      builder: (context, state) {
        final cubit = context.read<EditRiderProfileCubit>();
        return FilledButton(
          onPressed: () {
            state.user != null
                ? cubit.createRiderProfile()
                : cubit.updateRiderProfile();
            safePop(context);
          },
          child: state.status == SubmissionStatus.inProgress
              ? const CircularProgressIndicator()
              : Text(state.user != null ? 'Create Profile' : 'Submit'),
        );
      },
    );
  }
}
