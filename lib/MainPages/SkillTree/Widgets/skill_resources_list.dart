import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_item.dart';

class SkillResouresList extends StatelessWidget {
  const SkillResouresList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (state.resources.isNotEmpty) {
          // Filter the resources based on skillTreeIds containing the skill id
          final filteredResources = state.resources
              .where(
                (element) =>
                    element?.skillTreeIds?.contains(state.skill?.id) ?? false,
              )
              .toList();

          // Check if the filtered list is not empty
          if (filteredResources.isNotEmpty) {
            return Wrap(
              alignment: WrapAlignment.center,
              runSpacing: 4,
              children: filteredResources
                  .map(
                    (e) => ResourcesItem(
                      resource: e!,
                      isResourceList: false,
                    ),
                  )
                  .toList(),
            );
          } else {
            return const Text('No Resources Found');
          }
        } else {
          return const Text('No Resources Found');
        }
      },
    );
  }
}
