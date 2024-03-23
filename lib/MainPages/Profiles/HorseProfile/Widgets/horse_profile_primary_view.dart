import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/log_book_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/current_owner.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_age.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_breed.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_color.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_date_of_birth.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_gender.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_height.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_location.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_nickname.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_name.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/student_horse_request_button.dart';

class HorseProfilePrimaryView extends StatelessWidget {
  const HorseProfilePrimaryView({super.key, required this.horseProfile});
  final HorseProfile horseProfile;
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    return Column(
      children: [
        const HorseProfileName(
          key: Key('horseProfileName'),
        ),
        gap(),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              const CurrentOwner(
                key: Key('currentOwner'),
              ),
              gap(),
              const HorseNickName(
                key: Key('horseNickName'),
              ),
              gap(),
              const HorseLocation(
                key: Key('horseLocation'),
              ),
              gap(),
              const HorseAge(
                key: Key('horseAge'),
              ),
              gap(),
              const HorseColor(
                key: Key('horseColor'),
              ),
              gap(),
              const HorseBreed(
                key: Key('horseBreed'),
              ),
              gap(),
              const HorseGender(
                key: Key('horseGender'),
              ),
              gap(),
              const HorseHeight(
                key: Key('horseHeight'),
              ),
              gap(),
              const HorseDateOfBirth(
                key: Key('horseDateOfBirth'),
              ),
              gap(),
              const StudentHorseRequestButton(
                key: Key('studentHorseRequestButton'),
              ),
              gap(),
              LogBookButton(
                profile:
                    cubit.state.viewingProfile ?? cubit.state.usersProfile,
                horseProfile: horseProfile,
                key: const Key('logBookButton'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
