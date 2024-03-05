import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_tile.dart';

/// Widget showing the list of items in the profile
class ProfileList extends StatelessWidget {
  const ProfileList({
    super.key,
    required this.list,
  });

/// The list of items to display, can be Instructors, Students,
/// Owned Horses or Student Horses
  final List<BaseListItem> list;
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final baseItem = list[index];
        return Center(
          child: ProfileTile(
            baseItem: baseItem,
          ),
        );
      },
    );
  }
}
