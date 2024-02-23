// ignore_for_file: lines_longer_than_80_chars

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Widgets/bio.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Widgets/cancel_button.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Widgets/name.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Widgets/profile_photo.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Widgets/rider_location.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Widgets/rider_website.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Widgets/submit_button.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Widgets/trainer_question.dart';

/// Dialog to edit the rider's profile, if the user is registering for the
/// first time [user] will not be null and we will use the user's information
/// to prefill the form. Otherwise, we will use the [riderProfile] to prefill
/// the form.
class EditRiderProfileDialog extends StatelessWidget {
  const EditRiderProfileDialog({
    super.key,
    required this.riderProfile,
    this.user,
  });
  final RiderProfile? riderProfile;
  final User? user;
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => KeysRepository(),
        ),
        RepositoryProvider(
          create: (context) => CloudRepository(),
        ),
        RepositoryProvider(
          create: (context) => RiderProfileRepository(),
        ),
      ],
      child: BlocProvider(
        create: (context) => EditRiderProfileCubit(
          user: user,
          keysRepository: context.read<KeysRepository>(),
          cloudRepository: context.read<CloudRepository>(),
          riderProfile: riderProfile,
          riderProfileRepository: context.read<RiderProfileRepository>(),
        ),
        child: BlocListener<EditRiderProfileCubit, EditRiderProfileState>(
          listener: (context, state) {
            if (state.status == SubmissionStatus.success) {
              Navigator.pop(context);
            }
            if (state.isError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(state.error),
                  ),
                ).closed.then((_) {
                  context.read<EditRiderProfileCubit>().clearError();
                });
            }
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: AlertDialog(
              // not dismissible to prevent the user from closing the dialog
              // before the submission is complete

              scrollable: true,
              title: Text(
                user != null
                    ? 'Finish setting up your Profile'
                    : 'Edit Profile',
              ),
              content: Padding(
                padding: const EdgeInsets.all(8),
                child: Form(
                  child: Column(
                    children: [
                      const ProfilePhoto(
                        key: Key('profilePhoto'),
                      ),
                      gap(),
                      const RiderName(
                        key: Key('riderName'),
                      ),
                      gap(),
                      const RiderBio(
                        key: Key('riderBio'),
                      ),
                      gap(),
                      const RiderWebsite(
                        key: Key('riderWebsite'),
                      ),
                      gap(),
                      const RiderLocation(
                        key: Key('riderLocation'),
                      ),
                      gap(),
                      const TrainerQuestion(
                        key: Key('trainerQuestion'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Visibility(
                  visible: user == null,
                  child: const CancelButton(
                    key: Key('cancelButton'),
                  ),
                ),
                const SubmitButton(
                  key: Key('submitButton'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
