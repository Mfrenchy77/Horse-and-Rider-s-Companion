import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_card.dart';

class RiderListOfProfiles extends StatelessWidget {
  const RiderListOfProfiles({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Column(
          children: [
            Visibility(
              visible: state.viewingProfile?.instructors?.isNotEmpty ??
                  state.usersProfile?.instructors?.isNotEmpty ??
                  false,
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
                        children: state.viewingProfile != null
                            ? state.viewingProfile?.instructors
                                    ?.map(
                                      (e) => ProfileCard(baseItem: e),
                                    )
                                    .toList() ??
                                []
                            : state.usersProfile?.instructors
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
              visible: state.viewingProfile?.students?.isNotEmpty ??
                  state.usersProfile?.students?.isNotEmpty ??
                  false,
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
                      ...state.viewingProfile?.students
                              ?.map(
                                (e) => ProfileCard(baseItem: e),
                              )
                              .toList() ??
                          state.usersProfile?.students
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
              visible: state.viewingProfile?.ownedHorses?.isNotEmpty ??
                  state.usersProfile?.ownedHorses?.isNotEmpty ??
                  false,
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
                      ...state.viewingProfile?.ownedHorses
                              ?.map(
                                (e) => ProfileCard(baseItem: e),
                              )
                              .toList() ??
                          state.usersProfile?.ownedHorses
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
            //student horses
            Visibility(
              visible: state.viewingProfile?.studentHorses?.isNotEmpty ??
                  state.usersProfile?.studentHorses?.isNotEmpty ??
                  false,
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
                      ...state.viewingProfile?.studentHorses
                              ?.map(
                                (e) => ProfileCard(baseItem: e),
                              )
                              .toList() ??
                          state.usersProfile?.studentHorses
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
      },
    );
  }
}
