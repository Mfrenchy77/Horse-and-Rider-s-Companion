import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Cubit/edit_rider_profile_cubit.dart';

class RiderWebsite extends StatelessWidget {
  const RiderWebsite({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
      builder: (context, state) {
        return TextFormField(
          onChanged: (value) => context
              .read<EditRiderProfileCubit>()
              .riderHomeUrlChanged(value: value),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          initialValue: state.homeUrl,
          decoration: const InputDecoration(
            labelText: 'Website',
            hintText: 'Enter your buisness website',
            icon: Icon(Icons.public),
          ),
        );
      },
    );
  }
}
