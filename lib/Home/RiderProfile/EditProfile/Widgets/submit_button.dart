import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Cubit/edit_rider_profile_cubit.dart';

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
            Navigator.pop(context);
          },
          child: state.status == SubmissionStatus.inProgress
              ? const CircularProgressIndicator()
              : Text(state.user != null ? 'Create Profile' : 'Submit'),
        );
      },
    );
  }
}
