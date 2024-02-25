import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Profile/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';

class RiderName extends StatelessWidget {
  const RiderName({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
      builder: (context, state) {
        final cubit = context.read<EditRiderProfileCubit>();
        return TextFormField(
          onChanged: (value) => cubit.riderNameChanged(value: value),
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          initialValue: state.riderName,
          decoration: const InputDecoration(
            labelText: "Rider's Name",
            hintText: "Enter Rider's Name",
            icon: Icon(Icons.person),
          ),
        );
      },
    );
  }
}
