// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/ratings_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_info_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_rating_buttons.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
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
        final newList = <BaseListItem>[newRatingUser];

        final user = resource.usersWhoRated?.firstWhere(
          (element) => element.id == state.usersProfile?.email,
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
                  debugPrint('Goto Resource: ${resource.name}');
                  context.goNamed(
                    ResourceCommentPage.name,
                    pathParameters: {
                      ResourceCommentPage.pathParams: resource.id!,
                    },
                  );
                  //cubit.navigateToResourceComments(resource);
                },
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
                          ),
                        ),
                        Divider(
                          color: isDark ? Colors.white : Colors.black,
                          endIndent: 5,
                          indent: 5,
                        ),

                        ///   Info
                        ResourceInfoBar(
                          resource: resource,
                          key: const Key('ResourceInfoBar'),
                        ),
                        smallGap(),
                        Divider(
                          color: isDark ? Colors.white : Colors.black,
                          endIndent: 5,
                          indent: 5,
                        ),
                        Visibility(
                          visible: isResourceList,
                          child: ResourceRatingButtons(
                            key: const Key('ResourceRatingButtons'),
                            resource: resource,
                          ),
                        ),
                      ],
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
