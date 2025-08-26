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

  /// If true, show list-only elements (ratings row/buttons).
  final bool isResourceList;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final isDark = SharedPrefs().isDarkMode;

        // Avoid mutating the incoming model in a widget; ensure non-null list
        final resourceForUi = resource.usersWhoRated == null
            ? resource.copyWith(usersWhoRated: <BaseListItem>[])
            : resource;

        // Ensure we have a "current user rating item" if already present
        final currentUserId = state.usersProfile?.email ?? '';
        resourceForUi.usersWhoRated?.firstWhere(
          (e) => e.id == currentUserId,
          orElse: () => BaseListItem(id: currentUserId),
        );

        return MaxWidthBox(
          maxWidth: 600,
          child: Stack(
            children: [
              InkWell(
                onTap: () {
                  // Web-friendly URL + browser history:
                  final id = resource.id ?? '';
                  if (id.isEmpty) {
                    cubit.createError('Missing resource id');
                    return;
                  }
                  context.goNamed(
                    ResourceCommentPage.name,
                    pathParameters: {
                      ResourceCommentPage.pathParams: id,
                    },
                  );
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
                        // Ratings (list only)
                        Visibility(
                          visible: isResourceList,
                          child: RatingsBar(
                            isNew: cubit.isNewResource(resourceForUi),
                            resource: resourceForUi,
                          ),
                        ),
                        Divider(
                          color: isDark ? Colors.white : Colors.black,
                          endIndent: 5,
                          indent: 5,
                        ),
                        // Info bar (handles title/description/image and edit menu)
                        ResourceInfoBar(
                          key: const Key('ResourceInfoBar'),
                          resource: resourceForUi,
                        ),
                        smallGap(),
                        Divider(
                          color: isDark ? Colors.white : Colors.black,
                          endIndent: 5,
                          indent: 5,
                        ),
                        // Rating buttons (list only)
                        Visibility(
                          visible: isResourceList,
                          child: ResourceRatingButtons(
                            key: const Key('ResourceRatingButtons'),
                            resource: resourceForUi,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: cubit.isNewResource(resourceForUi),
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
