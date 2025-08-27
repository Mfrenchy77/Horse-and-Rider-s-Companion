import 'dart:convert';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/create_resource_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_image.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_web_page.dart';

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

  // ── Hero tags (must match on both screens) ────────────────────────────────
  String _heroTagImage() =>
      'resource-image-${resource.id ?? resource.url ?? _titleOrUntitled()}';
  String _heroTagTitle() =>
      'resource-title-${resource.id ?? resource.url ?? _titleOrUntitled()}';
  String _heroTagDesc() =>
      'resource-desc-${resource.id ?? resource.url ?? _titleOrUntitled()}';

  // During flight, use the DESTINATION widget's style/child to avoid style pops.
  // Docs: consider a custom flightShuttleBuilder when inherited styles differ.
  // https://api.flutter.dev/flutter/widgets/Hero-class.html
  Widget _textFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final toHero = toContext.widget as Hero;
    // Wrap with transparent Material so text renders correctly while flying.
    return Material(
      type: MaterialType.transparency,
      child: toHero.child,
    );
  }

  void _openLinkOrArticle(BuildContext context) {
    final cubit = context.read<AppCubit>();
    if (_isArticle) {
      final id = resource.id;
      if (id == null || id.isEmpty) {
        cubit.createError('Missing article id');
        return;
      }
      context.goNamed(
        ResourceCommentPage.name,
        pathParameters: {ResourceCommentPage.pathParams: id},
      );
      return;
    }

    final link = resource.url;
    if (link != null && link.isNotEmpty) {
      context.goNamed(
        ResourceWebPage.name,
        pathParameters: {
          ResourceWebPage.urlPathParams: link,
          ResourceWebPage.titlePathParams: _titleOrUntitled(),
        },
      );
    } else {
      cubit.createError('No URL provided');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final imageUrl = _primaryImageUrl();
        final title = _titleOrUntitled();

        final leftText = _isArticle
            ? _articleSnippet()
            : (resource.description?.trim().isNotEmpty ?? false)
                ? resource.description!.trim()
                : (resource.url?.trim().isNotEmpty ?? false)
                    ? resource.url!.trim()
                    : '';

        return Column(
          children: [
            // ── Title + edit menu (Title has Hero) ───────────────────────────
            Row(
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  flex: 4,
                  child: Hero(
                    tag: _heroTagTitle(),
                    flightShuttleBuilder: _textFlightShuttle,
                    // Wrap text in transparent Material so default text style/ink are preserved
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: cubit.canEditResource(resource) && state.isEdit,
                  child: PopupMenuButton<String>(
                    itemBuilder: (BuildContext menuContext) => const [
                      PopupMenuItem<String>(value: 'Edit', child: Text('Edit')),
                      PopupMenuItem<String>(
                        value: 'Delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (String value) {
                      switch (value) {
                        case 'Edit':
                          if (state.usersProfile != null) {
                            showModalBottomSheet<CreateResourceDialogCubit>(
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
                            cubit.createError('You are not authorized'
                                ' to edit until logged in.');
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
            gap(),

            // ── Body + image/cover (Desc + Image each with Hero) ─────────────
            SizedBox(
              height: 150,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Description/snippet side
                  Flexible(
                    fit: FlexFit.tight,
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints.loose(const Size.fromHeight(300)),
                        child: Hero(
                          tag: _heroTagDesc(),
                          flightShuttleBuilder: _textFlightShuttle,
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              leftText,
                              maxLines: 7, // keep same maxLines for smoothness
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Image / Cover
                  InkWell(
                    key: const Key('ResourceImage'),
                    onLongPress: () => cubit.openResource(url: resource.url),
                    onTap: () => _openLinkOrArticle(context),
                    child: Tooltip(
                      message: _isArticle
                          ? 'Read article'
                          : (resource.url?.isNotEmpty ?? false)
                              ? 'Open link'
                              : 'No link',
                      child: Hero(
                        tag: _heroTagImage(),
                        child: MaxWidthBox(
                          maxWidth: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ResourceImage(url: imageUrl ?? ''),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
