import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/MainPages/Home/cubit/home_cubit.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.baseItem});
  final BaseListItem baseItem;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final homeCubit = context.read<AppCubit>();
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
              onTap: () => baseItem.isCollapsed!
                  ? homeCubit.gotoProfilePage(
                      context: context,
                      toBeViewedEmail: baseItem.id ?? '',
                    )
                  : context.read<AppCubit>().horseProfileSelected(
                        id: baseItem.id ?? '',
                      ),
            ),
          ),
        );
      },
    );
  }
}
