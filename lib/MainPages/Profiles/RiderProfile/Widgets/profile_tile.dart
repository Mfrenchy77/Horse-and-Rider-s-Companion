import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';

/// A tile to display a horse or rider profile.
class ProfileTile extends StatelessWidget {
  const ProfileTile({super.key, required this.baseItem});
  final BaseListItem baseItem;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return SizedBox(
          width: 200,
          child: Tooltip(
            message: baseItem.name,
            child: ListTile(
              leading: Hero(
                transitionOnUserGestures: true,
                tag: baseItem.imageUrl ?? '',
                child: ProfilePhoto(
                  size: 45,
                  profilePicUrl: baseItem.imageUrl,
                ),
              ),
              title: Hero(
                transitionOnUserGestures: true,
                tag: baseItem.name!,
                child: Text(
                  baseItem.name ?? '',
                  textAlign: TextAlign.center,
                ),
              ),
              onTap: () {
                if (baseItem.isCollapsed!) {
                  // cubit.setLoading();
                  context.goNamed(
                    ViewingProfilePage.name,
                    pathParameters: {
                      ViewingProfilePage.pathParams: baseItem.id!,
                    },
                  );
                } else {
                  // cubit.setLoading();
                  debugPrint('Sending to HorseProfilePage: ${baseItem.id}');
                  context.goNamed(
                    HorseProfilePage.name,
                    pathParameters: {
                      HorseProfilePage.pathParams: baseItem.id!,
                    },
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
