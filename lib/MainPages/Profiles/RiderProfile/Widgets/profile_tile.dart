import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';

/// A tile to display a horse or rider profile.
class ProfileTile extends StatelessWidget {
  const ProfileTile({super.key, required this.baseItem});
  final BaseListItem baseItem;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final homeCubit = context.read<AppCubit>();
        return SizedBox(
          width: 200,
          child: ListTile(
            leading: ProfilePhoto(
              size: 45,
              profilePicUrl: baseItem.imageUrl,
            ),
            title: Text(
              baseItem.name ?? '',
              textAlign: TextAlign.center,
            ),
            onTap: () => baseItem.isCollapsed!
                ? homeCubit.gotoProfilePage(
                    context: context,
                    toBeViewedEmail: baseItem.id ?? '',
                  )
                : homeCubit.horseProfileSelected(
                    id: baseItem.id ?? '',
                  ),
          ),
        );
      },
    );
  }
}
