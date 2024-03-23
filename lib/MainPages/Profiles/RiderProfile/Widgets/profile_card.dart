import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.baseItem});
  final BaseListItem baseItem;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return
            // SizedBox(
            //   width: 200,
            //   child: Card(
            //     elevation: 8,
            //     child:
            ElevatedButton.icon(
          icon: Padding(
            padding: const EdgeInsets.fromLTRB(0,5,0,5),
            child: ProfilePhoto(
              size: 40,
              profilePicUrl: baseItem.imageUrl,
            ),
          ),
          label: Text(
            baseItem.name ?? '',
            textAlign: TextAlign.center,
          ),
          onPressed: () {
            if (baseItem.isCollapsed!) {
              // cubit.setLoading();
              context.goNamed(
                ViewingProfilePage.name,
                pathParameters: {
                  ViewingProfilePage.pathParams: baseItem.id!,
                },
              );
            } else {
              //cubit.setLoading();
              debugPrint('Sending to HorseProfilePage: ${baseItem.id}');
              context.goNamed(
                HorseProfilePage.name,
                pathParameters: {
                  HorseProfilePage.pathParams: baseItem.id!,
                },
              );
            }
          },
        );
        //   ),
        // );
      },
    );
  }
}
