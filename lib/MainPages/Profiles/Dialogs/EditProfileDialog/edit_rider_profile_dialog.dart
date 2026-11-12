// ignore_for_file: lines_longer_than_80_chars

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/form_page_body.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Widgets/bio.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Widgets/cancel_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Widgets/name.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Widgets/profile_photo.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Widgets/rider_website.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Widgets/submit_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Widgets/trainer_question.dart';

/// Dialog to edit the rider's profile, if the user is registering for the
/// first time [user] will not be null and we will use the user's information
/// to prefill the form. Otherwise, we will use the [riderProfile] to prefill
/// the form.
class EditRiderProfileDialog extends StatelessWidget {
  const EditRiderProfileDialog({
    super.key,
    required this.onProfileUpdated,
    required this.riderProfile,
    this.user,
  });

  final RiderProfile? riderProfile;
  final User? user;
  final void Function() onProfileUpdated;
  @override
  Widget build(BuildContext context) {
    debugPrint('EditRiderProfileDialog');
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => KeysRepository()),
        RepositoryProvider(create: (context) => CloudRepository()),
        RepositoryProvider(create: (context) => RiderProfileRepository()),
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
              onProfileUpdated();
              Navigator.of(context).pop();
            }
            if (state.isError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(state.error),
                  ),
                );
            }
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: ThemedAppBar(
              automaticallyImplyLeading: user == null,
              title: Text(
                user != null
                    ? 'Finish setting up your Profile'
                    : 'Edit Profile',
              ),
            ),
            body: FormPageBody(
              maxWidth: 640,
              child: Form(
                child: Column(
                  children: [
                    const ProfilePhoto(key: Key('profilePhoto')),
                    gap(),
                    const RiderName(key: Key('riderName')),
                    gap(),
                    const RiderBio(key: Key('riderBio')),
                    gap(),
                    const RiderWebsite(key: Key('riderWebsite')),
                    gap(),
                    // const RiderLocation(
                    //   key: Key('riderLocation'),
                    // ),
                    // gap(),
                    const TrainerQuestion(key: Key('trainerQuestion')),
                    const SizedBox(height: 24),
                    OverflowBar(
                      alignment: MainAxisAlignment.end,
                      overflowAlignment: OverflowBarAlignment.end,
                      spacing: 8,
                      overflowSpacing: 8,
                      children: [
                        Visibility(
                          visible: user == null,
                          child: const CancelButton(key: Key('cancelButton')),
                        ),
                        const SubmitButton(key: Key('submitButton')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
