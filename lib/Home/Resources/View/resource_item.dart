// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:horseandriderscompanion/utils/my_formatter.dart';
import 'package:responsive_framework/max_width_box.dart';

Widget resourceItem({
  required HomeState state,
  required Resource resource,
  required HomeCubit homeCubit,
  required BuildContext context,
  required List<BaseListItem?>? usersWhoRated,
  required bool isResourceList,
}) {
  BaseListItem? newRatingUser = BaseListItem(
    id: state.usersProfile?.email ?? '',
    isCollapsed: false,
    isSelected: false,
  );
  final isDark = SharedPrefs().isDarkMode;
  final newList = <BaseListItem?>[newRatingUser];

  final user = usersWhoRated?.firstWhere(
    (element) => element?.id == state.usersProfile?.email,
    orElse: BaseListItem.new,
  );
  if (usersWhoRated != null) {
    if (user != null) {
      newRatingUser = user;
    } else {
      newRatingUser = newRatingUser;
    }
  } else {
    usersWhoRated = newList;
  }
  return MaxWidthBox(
    maxWidth: 600,
    child: Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ///   Ratings
            Visibility(
              visible: isResourceList,
              child: _ratingsBar(
                resource: resource,
                rater: newRatingUser,
                context: context,
              ),
            ),
            Divider(
              color: isDark ? Colors.white : Colors.black,
              endIndent: 5,
              indent: 5,
            ),

            ///   Info
            Row(
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  flex: 4,
                  child: Text(
                    textAlign: TextAlign.center,
                    '${resource.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Visibility(
                  visible: state.isEditState,
                  child: PopupMenuButton<String>(
                    itemBuilder: (BuildContext menuContext) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (String value) {
                      switch (value) {
                        case 'Edit':
                          homeCubit.createOrEditResource(
                            resource: resource,
                            context: context,
                          );
                          break;
                        case 'Delete':
                          homeCubit.deleteResource(
                            resource,
                          );
                          break;
                      }
                    },
                  ),
                ),
              ],
            ),
            gap(),
            InkWell(
              onTap: () {
                homeCubit.openResource(url: resource.url);
              },
              child: SizedBox(
                height: 150,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      fit: FlexFit.tight,
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8),

                        ///   Description
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints.loose(const Size.fromHeight(300)),
                          child: Text(
                            maxLines: 7,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            '${resource.description}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),

                    ///   Image
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/horse_logo_and_text_dark.png',
                          image: resource.thumbnail ?? '',
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 500),
                          imageErrorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading NetworkImage: $error');
                            return Image.asset(
                              'assets/horse_logo_and_text_dark.png',
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(
              color: isDark ? Colors.white : Colors.black,
              endIndent: 5,
              indent: 5,
            ),
            Visibility(
              visible: isResourceList,
              child: _ratingButtons(
                state: state,
                context: context,
                resource: resource,
                homeCubit: homeCubit,
                rater: newRatingUser,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _ratingsBar({
  required Resource? resource,
  required BaseListItem? rater,
  required BuildContext context,
}) {
  if (resource != null) {
    final isDark = SharedPrefs().isDarkMode;

    final isSelected =
        (rater?.isCollapsed ?? false) || (rater?.isSelected ?? false);

    return Row(
      children: [
        Text(
          maxLines: 1,
          '${resource.rating}',
          style: TextStyle(
            fontSize: 14,
            color: isSelected
                ? HorseAndRidersTheme().getTheme().colorScheme.primary
                : isDark
                    ? Colors.grey
                    : Colors.black54,
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            'Submitted by: ${resource.lastEditBy}',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade200 : Colors.black54,
            ),
          ),
        ),
        Text(
          maxLines: 1,
          calculateTimeDifferenceBetween(
            referenceDate: resource.lastEditDate ?? DateTime.now(),
          ),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade200 : Colors.black54,
          ),
        ),
      ],
    );
  } else {
    debugPrint('Resource ${resource?.name} problem');
    return const Text('Ooops...something went Wrong');
  }
}

Widget _ratingButtons({
  required HomeCubit homeCubit,
  required BaseListItem? rater,
  required Resource? resource,
  required BuildContext context,
  required HomeState state,
}) {
  if (resource != null) {
    var isPositiveSelected = false;
    var isNegativeSelected = false;

    isNegativeSelected = rater?.isCollapsed ?? false;
    isPositiveSelected = rater?.isSelected ?? false;

    final isDark = SharedPrefs().isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recommend Button
        Expanded(
          flex: 5,
          child: IconButton(
            onPressed: state.isGuest
                ? null
                : () {
                    homeCubit.reccomendResource(resource: resource);
                  },
            icon: Icon(
              isPositiveSelected ? Icons.thumb_up : Icons.thumb_up_outlined,
            ),
            color: isPositiveSelected
                ? HorseAndRidersTheme().getTheme().colorScheme.primary
                : isDark
                    ? Colors.grey.shade300
                    : Colors.black54,
          ),
        ),
        // Save Button
        Expanded(
          flex: 5,
          child: _saveResourceButton(
            state: state,
            resource: resource,
            homeCubit: homeCubit,
          ),
        ),
        // Dont Recommend Button
        Expanded(
          flex: 5,
          child: IconButton(
            onPressed: state.isGuest
                ? null
                : () {
                    homeCubit.dontReccomendResource(resource: resource);
                  },
            icon: Icon(
              isNegativeSelected ? Icons.thumb_down : Icons.thumb_down_outlined,
            ),
            color: isNegativeSelected
                ? HorseAndRidersTheme().getTheme().colorScheme.primary
                : isDark
                    ? Colors.grey.shade300
                    : Colors.black54,
          ),
        ),

        Expanded(
          flex: 5,
          child: IconButton(
            onPressed: () {
              ///  Show the skills associated with this resource
              showDialog<AlertDialog>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Associated Skills for:'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(resource.name ?? ''),
                        gap(),
                        Wrap(
                          alignment: WrapAlignment.center,
                          runSpacing: 4,
                          children: homeCubit
                                  .getSkillsForResource(
                                    ids: resource.skillTreeIds,
                                  )
                                  ?.map(
                                    (e) => TextButton(
                                      onPressed: () {
                                        homeCubit.skillSelected(skill: e);
                                        debugPrint('Skill: ${e?.skillName}');
                                        Navigator.pop(context);
                                      },
                                      child: Text(e?.skillName ?? ''),
                                    ),
                                  )
                                  .toList() ??
                              [const Text('No Skills Found')],
                        ),
                        gap(),
                        const Text('Add or Remove Skills from this Resource'),
                        gap(),
                        const Divider(),
                        smallGap(),
                        Wrap(
                          spacing: 8,
                          children: homeCubit
                                  .getAllSkills()
                                  ?.map(
                                    (e) => FilterChip(
                                      label: Text(e?.skillName ?? ''),
                                      selected: resource.skillTreeIds
                                              ?.contains(e?.id) ??
                                          false,
                                      onSelected: (value) {
                                      
                                        homeCubit.addResourceToSkill(
                                          resource: resource,
                                          skill: e,
                                        );
                                      },
                                    ),
                                  )
                                  .toList() ??
                              [const Text('No Skills Found')],
                        ),
                        gap(),
                        TextButton(
                          onPressed: () {
                            debugPrint(
                              'Add Skill for Resource ${resource.name}',
                            );
                          },
                          child: const Text('Add Skill'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: state.horseProfile == null
                ? const Icon(HorseAndRiderIcons.riderSkillIcon)
                : const Icon(HorseAndRiderIcons.horseSkillIcon),
            color: isDark ? Colors.grey.shade300 : Colors.black54,
          ),
        ),
      ],
    );
  } else {
    return const Text('');
  }
}

Widget _saveResourceButton({
  required HomeState state,
  required Resource resource,
  required HomeCubit homeCubit,
}) {
  final isDark = SharedPrefs().isDarkMode;
  // if the state.usersProfile.savedResources contains the resource.id
  final isSaved = state.usersProfile?.savedResourcesList
          ?.firstWhere(
            (element) => element == resource.id,
            orElse: () => '',
          )
          .isNotEmpty ??
      false;

  return IconButton(
    onPressed: state.isGuest
        ? null
        : () {
            homeCubit.saveResource(resource: resource);
          },
    icon: isSaved
        ? const Icon(Icons.favorite)
        : const Icon(Icons.favorite_border),
    color: isSaved
        ? Colors.red
        : isDark
            ? Colors.grey.shade300
            : Colors.black54,
  );
}
