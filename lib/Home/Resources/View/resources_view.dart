// ignore_for_file: cast_nullable_to_non_nullable

import 'package:auto_size_text/auto_size_text.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/responsive_appbar.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:horseandriderscompanion/utils/my_formatter.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResourcesView extends StatelessWidget {
  const ResourcesView({
    super.key,
    required this.state,
    required this.homeCubit,
    required this.usersProfile,
  });
  final HomeState state;
  final HomeCubit homeCubit;
  final RiderProfile? usersProfile;
  bool isEditor() => usersProfile?.editor ?? false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: homeCubit.skillTreeNavigationSelected,
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        actions: _appBarActions(
          homeCubit: homeCubit,
          context: context,
          usersProfile: usersProfile,
        ),
        title: Text(
          state.resourcesSortStatus == ResourcesSortStatus.oldest
              ? 'Resources - Oldest'
              : state.resourcesSortStatus == ResourcesSortStatus.mostRecommended
                  ? 'Resources - Most Recommended'
                  : state.resourcesSortStatus == ResourcesSortStatus.recent
                      ? 'Resources - Most Recent'
                      : 'Resources - Saved',
          style: const TextStyle(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 4,
            children: state.resources!
                .map(
                  (e) => _resourceItemASmall(
                    state: state,
                    resource: e!,
                    homeCubit: homeCubit,
                    context: context,
                    riderProfile: usersProfile,
                    usersWhoRated: e.usersWhoRated,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

List<Widget> _appBarActions({
  required HomeCubit homeCubit,
  required RiderProfile? usersProfile,
  required BuildContext context,
}) {
  final isMobile = ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET);
  final isTabletOrLarger = ResponsiveBreakpoints.of(context).largerThan(TABLET);
  return [
    if (isMobile)
      PopupMenuButton<String>(
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'Add', child: Text('Add')),
          const PopupMenuItem<String>(value: 'Edit', child: Text('Edit')),
          const PopupMenuItem<String>(value: 'Sort', child: Text('Sort')),
        ],
        onSelected: (value) {
          switch (value) {
            case 'Add':
              homeCubit.createOrEditResource(
                resource: null,
                context: context,
              );
              break;
            case 'Edit':
              homeCubit.toggleIsEditState();
              break;
            case 'Sort':
              homeCubit.openSortDialog(context);
              break;
          }
        },
      ),
    if (isTabletOrLarger)
      Visibility(
        visible: usersProfile?.editor ?? false,
        child: Row(
          children: [
            Tooltip(
              message: 'Add Resource',
              child: IconButton(
                onPressed: () => context
                    .read<HomeCubit>()
                    .createOrEditResource(resource: null, context: context),
                icon: const Icon(
                  Icons.add,
                ),
              ),
            ),
            smallGap(),
          ],
        ),
      ),
    if (isTabletOrLarger)
      Visibility(
        visible: usersProfile?.editor ?? false,
        child: Row(
          children: [
            Tooltip(
              message: 'Edit Resource',
              child: IconButton(
                onPressed: () => homeCubit.toggleIsEditState(),
                icon: const Icon(
                  Icons.edit,
                ),
              ),
            ),
            smallGap(),
          ],
        ),
      ),
    if (isTabletOrLarger)
      Row(
        children: [
          Tooltip(
            message: 'Sort Resources',
            child: IconButton(
              onPressed: () => homeCubit.openSortDialog(context),
              icon: const Icon(
                Icons.sort,
              ),
            ),
          ),
          smallGap(),
        ],
      ),
  ];
}

///   List of Resources
Widget _resourcesListView({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
  required RiderProfile? riderProfile,
  required List<Resource?>? resources,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  debugPrint('Screen Width: $screenWidth');
  return screenWidth > 1500
      ? GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          itemCount: resources?.length,
          itemBuilder: (BuildContext context, int index) {
            final resource = resources?[index];
            return _resourceItem(
              homeCubit: homeCubit,
              usersWhoRated: resource?.usersWhoRated,
              context: context,
              resource: resource as Resource,
              riderProfile: riderProfile,
              state: state,
            );
          },
        )
      : ListView.builder(
          shrinkWrap: true,
          itemCount: resources?.length,
          itemBuilder: (BuildContext context, int index) {
            final resource = resources?[index];
            return _resourceItem(
              homeCubit: homeCubit,
              usersWhoRated: resource?.usersWhoRated,
              context: context,
              resource: resource as Resource,
              riderProfile: riderProfile,
              state: state,
            );
          },
        );
}

///   Widget for Resource Item
Widget _resourceItem({
  required HomeState state,
  required Resource resource,
  required HomeCubit homeCubit,
  required BuildContext context,
  required RiderProfile? riderProfile,
  required List<BaseListItem?>? usersWhoRated,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    child: screenWidth < 600
        ? _resourceItemASmall(
            state: state,
            resource: resource,
            homeCubit: homeCubit,
            context: context,
            riderProfile: riderProfile,
            usersWhoRated: usersWhoRated,
          )
        : screenWidth < 1000
            ? _resourceItemMedium(
                state: state,
                resource: resource,
                homeCubit: homeCubit,
                context: context,
                riderProfile: riderProfile,
                usersWhoRated: usersWhoRated,
              )
            : _resourceItemLarge(
                state: state,
                resource: resource,
                homeCubit: homeCubit,
                context: context,
                riderProfile: riderProfile,
                usersWhoRated: usersWhoRated,
              ),
  );
}

///Resource Item for Large Screens
Widget _resourceItemLarge({
  required HomeState state,
  required Resource resource,
  required HomeCubit homeCubit,
  required BuildContext context,
  required RiderProfile? riderProfile,
  required List<BaseListItem?>? usersWhoRated,
}) {
  BaseListItem? newRatingUser = BaseListItem(
    id: riderProfile?.email as String,
    isCollapsed: false,
    isSelected: false,
  );

  // Get the screen height
  final isDark = SharedPrefs().isDarkMode;
  final newList = <BaseListItem?>[newRatingUser];
  final user = usersWhoRated?.firstWhere(
    (element) => element?.id == riderProfile?.email,
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
    maxWidth: 1100,
    child: Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ///   Ratings
            _ratingsBar(
              resource: resource,
              rater: newRatingUser,
              context: context,
            ),
            Divider(
              color: isDark ? Colors.white : Colors.black,
              endIndent: 5,
              indent: 5,
            ),

            /// Image
            Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/horse_logo_and_text_dark.png',
                image: '${resource.thumbnail}',
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 500),
                imageErrorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading NetworkImage: $error');
                  return Image.asset('assets/horse_logo_and_text_dark.png');
                },
              ),
            ),

            ///   Info
            AutoSizeText(
              minFontSize: 28,
              textAlign: TextAlign.center,
              '${resource.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            gap(),
            Flexible(
              child: AutoSizeText(
                minFontSize: 16,
                textAlign: TextAlign.center,
                '${resource.description}',
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            gap(),

            ///   Rating Buttons
            Divider(
              color: isDark ? Colors.white : Colors.black,
              endIndent: 5,
              indent: 5,
            ),
            _ratingButtons(
              state: state,
              context: context,
              resource: resource,
              homeCubit: homeCubit,
              rater: newRatingUser,
              riderProfile: riderProfile as RiderProfile,
            ),
          ],
        ),
      ),
    ),
  );
}

///  Widget for Resource Item Medium screens
Widget _resourceItemMedium({
  required HomeState state,
  required Resource resource,
  required HomeCubit homeCubit,
  required BuildContext context,
  required RiderProfile? riderProfile,
  required List<BaseListItem?>? usersWhoRated,
}) {
  BaseListItem? newRatingUser = BaseListItem(
    id: riderProfile?.email as String,
    isCollapsed: false,
    isSelected: false,
  );
  final scaler = ResponsiveScaler();
  final isDark = SharedPrefs().isDarkMode;
  final newList = <BaseListItem?>[newRatingUser];
  final user = usersWhoRated?.firstWhere(
    (element) => element?.id == riderProfile?.email,
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
    maxWidth: 900,
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ratingsBar(
              resource: resource,
              rater: newRatingUser,
              context: context,
            ),
            Divider(
              color: isDark ? Colors.white : Colors.black,
              endIndent: 5,
              indent: 5,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///   Image
                Container(
                  width: 300,
                  height: 300,
                  margin: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/horse_logo_and_text_dark.png',
                    image: '${resource.thumbnail}',
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 500),
                    imageErrorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading NetworkImage: $error');
                      return Image.asset('assets/horse_logo_and_text_dark.png');
                    },
                  ),
                ),

                ///   Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${resource.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: scaler.responsiveTextSize(context, 20),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      gap(),
                      Text(
                        '${resource.description}',
                        style: TextStyle(
                          fontSize: scaler.responsiveTextSize(context, 15),
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            gap(),
            Divider(
              color: isDark ? Colors.white : Colors.black,
              endIndent: 5,
              indent: 5,
            ),
            _ratingButtons(
              state: state,
              context: context,
              resource: resource,
              homeCubit: homeCubit,
              rater: newRatingUser,
              riderProfile: riderProfile as RiderProfile,
            ),
          ],
        ),
      ),
    ),
  );
}

///   Widget for Resource Item small
Widget _resourceItemASmall({
  required HomeState state,
  required Resource resource,
  required HomeCubit homeCubit,
  required BuildContext context,
  required RiderProfile? riderProfile,
  required List<BaseListItem?>? usersWhoRated,
}) {
  BaseListItem? newRatingUser = BaseListItem(
    id: riderProfile?.email as String,
    isCollapsed: false,
    isSelected: false,
  );
  final isDark = SharedPrefs().isDarkMode;
  final newList = <BaseListItem?>[newRatingUser];
  final user = usersWhoRated?.firstWhere(
    (element) => element?.id == riderProfile?.email,
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
      //color: COLOR_CONST.DEFAULT,
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ///   Ratings
            _ratingsBar(
              resource: resource,
              rater: newRatingUser,
              context: context,
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
                  child: AutoSizeText(
                    minFontSize: 20,
                    textAlign: TextAlign.center,
                    '${resource.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Visibility(
                  visible: state.isResourcesEdit,
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
              child: Row(
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
                        child: AutoSizeText(
                          maxLines: 2,
                          minFontSize: 16,
                          textAlign: TextAlign.center,
                          '${resource.description}',
                          style: const TextStyle(),
                        ),
                      ),
                    ),
                  ),

                  ///   Image
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/horse_logo_and_text_dark.png',
                      image: '${resource.thumbnail}',
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 500),
                      imageErrorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading NetworkImage: $error');
                        return Image.asset(
                            'assets/horse_logo_and_text_dark.png',);
                      },
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: isDark ? Colors.white : Colors.black,
              endIndent: 5,
              indent: 5,
            ),
            _ratingButtons(
              state: state,
              context: context,
              resource: resource,
              homeCubit: homeCubit,
              rater: newRatingUser,
              riderProfile: riderProfile as RiderProfile,
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
    var isSelected = false;
    final isDark = SharedPrefs().isDarkMode;
    if (rater?.isCollapsed != null && rater?.isSelected != null) {
      if (rater?.isCollapsed == true || rater?.isSelected == true) {
        isSelected = true;
      }
    } else {
      isSelected = false;
    }

    return Row(
      children: [
        AutoSizeText(
          minFontSize: 14,
          textScaleFactor: 1.1,
          maxLines: 1,
          '${resource.rating}',
          style: TextStyle(
            color: isSelected
                ? HorseAndRidersTheme().getTheme().colorScheme.primary
                : isDark
                    ? Colors.grey
                    : Colors.black54,
          ),
        ),
        Expanded(
          flex: 5,
          child: AutoSizeText(
            'Submitted by: ${resource.lastEditBy}',
            minFontSize: 14,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey.shade200 : Colors.black54,
            ),
          ),
        ),
        AutoSizeText(
          minFontSize: 14,
          maxLines: 1,
          calculateTimeDifferenceBetween(
            referenceDate: resource.lastEditDate as DateTime,
          ),
          style: TextStyle(
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
  required RiderProfile riderProfile,
  required BaseListItem? rater,
  required Resource? resource,
  required BuildContext context,
  required HomeState state,
}) {
  if (resource != null) {
    var isPositiveSelected = false;
    var isNegativeSelected = false;
    if (rater?.isCollapsed != null && rater?.isCollapsed == true) {
      isNegativeSelected = true;
    } else {
      isNegativeSelected = false;
    }

    if (rater?.isSelected != null) {
      if (rater?.isSelected == true) {
        isPositiveSelected = true;
      }
    } else {
      isPositiveSelected = false;
    }
    final isDark = SharedPrefs().isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 5,
          child: IconButton(
            onPressed: () {
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
        Expanded(
          flex: 5,
          child: SaveResourceButton(
            resource: resource,
            homeCubit: homeCubit,
            riderProfile: riderProfile,
          ),
        ),
        Expanded(
          flex: 5,
          child: IconButton(
            onPressed: () {
              context
                  .read<HomeCubit>()
                  .dontReccomendResource(resource: resource);
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
      ],
    );
  } else {
    return const Text('');
  }
}

class SaveResourceButton extends StatefulWidget {
  const SaveResourceButton({
    super.key,
    required this.resource,
    required this.homeCubit,
    required this.riderProfile,
  });
  final Resource resource;
  final HomeCubit homeCubit;
  final RiderProfile riderProfile;
  @override
  State<SaveResourceButton> createState() => _SaveResourceButtonState();
}

class _SaveResourceButtonState extends State<SaveResourceButton> {
  bool isSaved = false;
  final isDark = SharedPrefs().isDarkMode;
  @override
  Widget build(BuildContext context) {
    if (widget.riderProfile.savedResourcesList != null) {
      if (widget.riderProfile.savedResourcesList!
          .contains(widget.resource.id)) {
        isSaved = true;
      }
      //  else {
      //   isSaved = false;
      // }
    }
    return IconButton(
      onPressed: () {
        setState(() {
          isSaved = !isSaved;
          widget.homeCubit.saveResource(resource: widget.resource);
        });
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
}
