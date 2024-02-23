import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Cubit/edit_rider_profile_cubit.dart';

class RiderBio extends StatelessWidget {
  const RiderBio({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
      builder: (context, state) {
        return TextFormField(
          onChanged: (value) => context
              .read<EditRiderProfileCubit>()
              .riderBioChanged(value: value),
          keyboardType: TextInputType.multiline,
          maxLines: 12,
          minLines: 3,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          initialValue: state.bio,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Write a short bio about yourself',
            icon: Icon(Icons.person),
          ),
        );
      },
    );
  }
}
