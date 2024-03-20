import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_card.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_tile.dart';

class RiderListOfProfiles extends StatelessWidget {
  const RiderListOfProfiles({super.key, required this.profile});
  final RiderProfile profile;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible: profile.instructors?.isNotEmpty ?? false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  'Instructors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              smallGap(),
              Wrap(
                direction: Axis.vertical,
                spacing: 5,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  Column(
                    children: profile.instructors
                            ?.map((e) => ProfileCard(baseItem: e))
                            .toList() ??
                        [],
                  ),
                ],
              ),
            ],
          ),
        ),
        gap(),
        Visibility(
          visible: profile.students?.isNotEmpty ?? false,
          child: Column(
            children: [
              const Text(
                'Students',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              smallGap(),
              Wrap(
                direction: Axis.vertical,
                spacing: 5,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  ...profile.students
                          ?.map(
                            (e) => ProfileCard(baseItem: e),
                          )
                          .toList() ??
                      [],
                ],
              ),
            ],
          ),
        ),
        gap(),
        Visibility(
          visible: profile.ownedHorses?.isNotEmpty ?? false,
          child: Column(
            children: [
              const Text(
                'Owned Horses',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              smallGap(),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  ...profile.ownedHorses
                          ?.map(
                            (e) => DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.black54,
                                  width: .5,
                                ),
                              ),
                              child: ProfileTile(baseItem: e),
                            ),
                          )
                          .toList() ??
                      [],
                ],
              ),
            ],
          ),
        ),
        //student horses
        Visibility(
          visible: profile.studentHorses?.isNotEmpty ?? false,
          child: Column(
            children: [
              const Text(
                'Student Horses',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              smallGap(),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  ...profile.studentHorses
                          ?.map(
                            (e) => ProfileCard(baseItem: e),
                          )
                          .toList() ??
                      [],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
