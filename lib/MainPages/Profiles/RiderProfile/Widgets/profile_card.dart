import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
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
        final cubit = context.read<AppCubit>();
        return SizedBox(
          width: 200,
          child: Card(
            elevation: 8,
            child: ListTile(
              leading: ProfilePhoto(
                size: 45,
                profilePicUrl: baseItem.imageUrl,
              ),
              title: Text(
                baseItem.name ?? '',
                textAlign: TextAlign.center,
              ),
              onTap: () {
                if (baseItem.isCollapsed!) {
                  cubit.setLoading();
                  context.pushNamed<bool>(
                    ViewingProfilePage.name,
                    pathParameters: {
                      ViewingProfilePage.pathParams: baseItem.id!,
                    },
                  ).then((value) {
                    cubit.resetFromHorseProfile();
                    debugPrint('Returned from ViewingProfilePage: $value');
                  });
                } else {
                  cubit.setLoading();
                  debugPrint('Sending to HorseProfilePage: ${baseItem.id}');
                  context.pushNamed(
                    HorseProfilePage.name,
                    pathParameters: {
                      HorseProfilePage.pathParams: baseItem.id!,
                    },
                  ).then((value) {
                    cubit.resetFromHorseProfile();
                    debugPrint('Returned from HorseProfilePage: $value');
                  });
                }
              },
              // : cubit.horseProfileSelected(
              //     id: baseItem.id ?? '',
              //   ),
            ),
          ),
        );
      },
    );
  }
}
