// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/create_resource_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/ratings_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_rating_buttons.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:super_banners/super_banners.dart';

class ResourcesItem extends StatelessWidget {
  const ResourcesItem({
    super.key,
    required this.resource,
    required this.isResourceList,
  });
  final Resource resource;
  final bool isResourceList;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        BaseListItem? newRatingUser = BaseListItem(
          id: state.usersProfile?.email ?? '',
          isCollapsed: false,
          isSelected: false,
        );
        final isDark = SharedPrefs().isDarkMode;
        final newList = <BaseListItem?>[newRatingUser];

        final user = resource.usersWhoRated?.firstWhere(
          (element) => element?.id == state.usersProfile?.email,
          orElse: BaseListItem.new,
        );
        if (resource.usersWhoRated != null) {
          if (user != null) {
            newRatingUser = user;
          } else {
            newRatingUser = newRatingUser;
          }
        } else {
          resource.usersWhoRated = newList;
        }
        return MaxWidthBox(
          maxWidth: 600,
          child: Stack(
            children: [
              InkWell(
                onTap: () {
                  /// This is where we will go to resource screen
                  debugPrint('Goto Resource: ${resource.name}');
                },
                child: Tooltip(
                  message: 'Show Resource and Comments for: ${resource.name}',
                  child: Card(
                    elevation: 8,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ///   Ratings
                          Visibility(
                            visible: isResourceList,
                            child: RatingsBar(
                              isNew: cubit.isNewResource(resource),
                              resource: resource,
                              rater: newRatingUser,
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
                                visible: state.isEdit,
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
                                        state.usersProfile != null
                                            ? showDialog<CreateResourcDialog>(
                                                context: context,
                                                builder: (context) =>
                                                    CreateResourcDialog(
                                                  skills: state.allSkills,
                                                  userProfile:
                                                      state.usersProfile!,
                                                  resource: resource,
                                                ),
                                              )
                                            : cubit.createError(
                                                'You Are Not Authorized To Edit Until Logged In',
                                              );

                                        break;
                                      case 'Delete':
                                        cubit.deleteResource(
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
                          SizedBox(
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
                                      constraints: BoxConstraints.loose(
                                        const Size.fromHeight(300),
                                      ),
                                      child: Text(
                                        maxLines: 7,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        resource.description ?? '',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),

                                ///   Image
                                InkWell(
                                  onTap: () =>
                                      cubit.openResource(url: resource.url),
                                  child: Tooltip(
                                    message: 'Go to: ${resource.url}',
                                    child: Expanded(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: FadeInImage.assetNetwork(
                                          placeholder:
                                              'assets/horse_logo_and_text_dark.png',
                                          image: resource.thumbnail ?? '',
                                          fit: BoxFit.cover,
                                          fadeInDuration:
                                              const Duration(milliseconds: 500),
                                          imageErrorBuilder:
                                              (context, error, stackTrace) {
                                            debugPrint(
                                              'Error loading NetworkImage: $error',
                                            );
                                            return Image.asset(
                                              'assets/horse_logo_and_text_dark.png',
                                            );
                                          },
                                        ),
                                      ),
                                    ),
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
                          Visibility(
                            visible: isResourceList,
                            child: ResourceRatingButtons(
                              key: const Key('rating_buttons'),
                              resource: resource,
                              rater: newRatingUser,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: cubit.isNewResource(resource),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: CornerBanner(
                    bannerColor: Colors.blue,
                    elevation: 4,
                    child: Text('New'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
