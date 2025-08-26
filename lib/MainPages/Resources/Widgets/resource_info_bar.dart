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

  /// Prefer coverImageUrl for articles; otherwise thumbnail;
  ///  for links use thumbnail if present.
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

  /// Convert the stored Quill Delta JSON (resource.content)
  ///  into a plain-text snippet.
  /// Safe fallback to "Article" on any error or empty content.
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

        // Choose what to show in the left text column:
        final leftText = _isArticle
            ? _articleSnippet() // <-- article body preview
            : (resource.description?.trim().isNotEmpty ?? false
                ? resource.description!.trim()
                : (resource.url?.trim().isNotEmpty ?? false
                    ? resource.url!.trim()
                    : ''));

        return Column(
          children: [
            // Title + edit menu
            Row(
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  flex: 4,
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
                            showModalBottomSheet<CreateResourcDialog>(
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

            // Body + image/cover
            SizedBox(
              height: 150,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Body/Description (7-line preview)
                  Flexible(
                    fit: FlexFit.tight,
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints.loose(const Size.fromHeight(300)),
                        child: Text(
                          leftText,
                          maxLines: 7,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                  // Image / Cover (tap opens link or article)
                  InkWell(
                    key: const Key('ResourceImage'),
                    onLongPress: () => cubit.openResource(url: resource.url),
                    onTap: () => _openLinkOrArticle(context),
                    child: Tooltip(
                      message: _isArticle
                          ? 'Read article'
                          : (resource.url?.isNotEmpty ?? false
                              ? 'Open link'
                              : 'No link'),
                      child: MaxWidthBox(
                        maxWidth: 200,
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
