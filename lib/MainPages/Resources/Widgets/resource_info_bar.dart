import 'dart:convert';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/create_resource_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_image.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_web_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/Settings/resource_layout.dart';
import 'package:horseandriderscompanion/Utilities/resource_urls.dart';

/// A stable tag for the single shared resource-summary transition.
///
/// Both the resource list and comments header render [ResourceInfoBar], so a
/// single Hero around this entire widget keeps the complete summary together
/// during forward and reverse navigation.
String resourceInfoHeroTag(Resource resource) {
  final title = resource.name?.trim();
  return 'resource-info-${resource.id ?? resource.url ?? title ?? 'untitled'}';
}

class ResourceInfoBar extends StatelessWidget {
  const ResourceInfoBar({super.key, required this.resource});
  final Resource resource;

  bool get _isArticle => resource.type == ResourceType.article;

  String _titleOrUntitled() {
    final t = resource.name?.trim();
    return (t == null || t.isEmpty) ? 'Untitled' : t;
  }

  /// Prefer coverImageUrl for articles; otherwise thumbnail.
  String? _primaryImageUrl() {
    if (_isArticle) {
      return (resource.coverImageUrl?.isNotEmpty ?? false)
          ? resource.coverImageUrl
          : (resource.thumbnail?.isNotEmpty ?? false)
          ? resource.thumbnail
          : null;
    }
    return (resource.thumbnail?.isNotEmpty ?? false)
        ? resource.thumbnail
        : null;
  }

  /// Plain-text snippet for articles (from stored Quill Delta).
  String _articleSnippet() {
    final jsonStr = resource.content;
    if (jsonStr == null || jsonStr.trim().isEmpty) return 'Article';
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return 'Article';
      final doc = Document.fromJson(decoded);
      final plain = doc.toPlainText().trim();
      return plain.isEmpty ? 'Article' : plain;
    } catch (_) {
      return 'Article';
    }
  }

  void _openLinkOrArticle(BuildContext context) {
    final cubit = context.read<AppCubit>();
    if (_isArticle) {
      final id = resource.id;
      if (id == null || id.isEmpty) {
        cubit.createError('Missing article id');
        return;
      }
      context.pushNamed(
        ResourceCommentPage.name,
        pathParameters: {ResourceCommentPage.pathParams: id},
      );
      return;
    }

    final link = resource.url;
    if (youtubeWatchUri(link) != null ||
        shouldOpenResourceExternally(
          link,
          blocksEmbedding: resource.blocksEmbedding,
        )) {
      cubit.openResource(url: link);
    } else if (link != null && link.isNotEmpty) {
      context.goNamed(
        ResourceWebPage.name,
        pathParameters: {
          ResourceWebPage.urlPathParams: link,
          ResourceWebPage.titlePathParams: _titleOrUntitled(),
        },
        queryParameters: {
          if (resource.id case final id? when id.isNotEmpty)
            ResourceWebPage.resourceIdQueryParam: id,
        },
      );
    } else {
      cubit.createError('No URL provided');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: resourceInfoHeroTag(resource),
      // A linear rectangle tween prevents the Hero from arcing away from the
      // card when it returns from the comments page.
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      child: Material(
        type: MaterialType.transparency,
        child: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) {
            final cubit = context.read<AppCubit>();
            final imageUrl = _primaryImageUrl();
            final title = _titleOrUntitled();
            final isVideo =
                !_isArticle && youtubeWatchUri(resource.url) != null;

            final description = _isArticle
                ? _articleSnippet()
                : resource.description?.trim() ?? '';
            final source = _isArticle
                ? resource.authorName?.trim() ?? ''
                : resourceWebUri(resource.url)?.host ?? '';
            final skillIds = resource.skillTreeIds.toSet();
            final skills = state.allSkills.whereType<Skill>().where(
              (skill) => skillIds.contains(skill.id),
            );

            final image = InkWell(
              key: const Key('ResourceImage'),
              onLongPress: () => cubit.openResource(url: resource.url),
              onTap: () => _openLinkOrArticle(context),
              child: Tooltip(
                message: _isArticle
                    ? 'Read article'
                    : isVideo
                    ? 'Watch on YouTube'
                    : (resource.url?.isNotEmpty ?? false)
                    ? 'Open link'
                    : 'No link',
                child: LayoutBuilder(
                  builder: (context, constraints) => SizedBox(
                    height: (constraints.maxWidth * 9 / 16).clamp(120.0, 240.0),
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        ResourceImage(
                          url: imageUrl ?? '',
                          resourceUrl: resource.url,
                          borderRadius: BorderRadius.zero,
                        ),
                        if (isVideo)
                          const Center(
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              child: Icon(Icons.play_arrow),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            final details = Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Visibility(
                        visible:
                            cubit.canEditResource(resource) && state.isEdit,
                        child: PopupMenuButton<String>(
                          itemBuilder: (BuildContext menuContext) => const [
                            PopupMenuItem<String>(
                              value: 'Edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem<String>(
                              value: 'Delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (String value) {
                            switch (value) {
                              case 'Edit':
                                if (state.usersProfile != null) {
                                  showModalBottomSheet<
                                    CreateResourceDialogCubit
                                  >(
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    context: context,
                                    builder: (context) => CreateResourcDialog(
                                      skills: state.allSkills,
                                      userProfile: state.usersProfile!,
                                      resource: resource,
                                    ),
                                  );
                                } else {
                                  cubit.createError(
                                    'You are not authorized'
                                    ' to edit until logged in.',
                                  );
                                }
                                break;
                              case 'Delete':
                                cubit.deleteResource(resource);
                                break;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (source.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final skill in skills)
                          ActionChip(
                            avatar: const Icon(Icons.link, size: 16),
                            tooltip: 'Open ${skill.skillName} in Skill Tree',
                            onPressed: () => SkillTreeView.openSkill(
                              GoRouter.of(context),
                              skill.id,
                            ),
                            label: Text(
                              skill.skillName,
                              overflow: TextOverflow.ellipsis,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 7,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );

            final layout = ResourceLayoutScope.of(context);
            return LayoutBuilder(
              builder: (context, constraints) {
                if (layout == ResourceLayout.horizontal &&
                    constraints.maxWidth >= 480) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: constraints.maxWidth * .4, child: image),
                      Expanded(child: details),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [image, details],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
