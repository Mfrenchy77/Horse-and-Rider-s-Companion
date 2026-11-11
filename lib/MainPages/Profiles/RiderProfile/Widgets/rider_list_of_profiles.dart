import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_card.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';

class RiderListOfProfiles extends StatelessWidget {
  const RiderListOfProfiles({super.key, required this.profile});
  final RiderProfile profile;

  @override
  Widget build(BuildContext context) {
    final groups = {
      'Owned horses': profile.ownedHorses,
      'Students': profile.students,
      'Student horses': profile.studentHorses,
      'Instructors': profile.instructors,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups.entries)
          if (group.value?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.key,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in group.value!)
                            ProfileCard(baseItem: item),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
