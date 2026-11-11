// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/ratings_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_info_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_rating_buttons.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Utilities/resource_urls.dart';
import 'package:super_banners/super_banners.dart';

class ResourcesItem extends StatelessWidget {
  const ResourcesItem({
    super.key,
    required this.resource,
    required this.isResourceList,
    this.fromSkillTree = false,
  });

  final Resource resource;

  /// If true, show list-only elements (ratings row/buttons).
  final bool isResourceList;
  final bool fromSkillTree;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final isNew =
            resource.lastEditDate != null && cubit.isNewResource(resource);

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

        final isVideo =
            resource.type != ResourceType.article &&
            youtubeWatchUri(resource.url) != null;

        void openComments() {
          final id = resource.id ?? '';
          if (id.isEmpty) {
            cubit.createError('Missing resource id');
            return;
          }
          if (fromSkillTree) {
            cubit.selectResource(resource);
            context.goNamed(
              ResourceCommentPage.name,
              pathParameters: {ResourceCommentPage.pathParams: id},
            );
            return;
          }
          context.pushNamed(
            ResourceCommentPage.name,
            pathParameters: {ResourceCommentPage.pathParams: id},
          );
        }

        return MaxWidthBox(
          maxWidth: 600,
          child: Stack(
            children: [
              InkWell(
                onTap: isVideo
                    ? () => cubit.openResource(url: resource.url)
                    : openComments,
                child: GradientCard(
                  elevation: 8,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResourceInfoBar(
                        key: const Key('ResourceInfoBar'),
                        resource: resourceForUi,
                      ),
                      if (isResourceList)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Column(
                            children: [
                              const Divider(),
                              RatingsBar(isNew: isNew, resource: resourceForUi),
                              ResourceRatingButtons(
                                key: const Key('ResourceRatingButtons'),
                                resource: resourceForUi,
                              ),
                            ],
                          ),
                        ),
                      if (isVideo && !isResourceList && resource.id != null)
                        Center(
                          child: TextButton(
                            onPressed: openComments,
                            child: const Text('Comments'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: isNew,
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
