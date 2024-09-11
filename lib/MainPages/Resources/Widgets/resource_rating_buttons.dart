import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/support_message_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/resource_update_skills_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/save_resource_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class ResourceRatingButtons extends StatelessWidget {
  const ResourceRatingButtons({
    super.key,
    required this.resource,
  });
  final Resource resource;
  @override
  Widget build(BuildContext context) {
    final isDark = SharedPrefs().isDarkMode;
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recommend Button
            Expanded(
              flex: 5,
              child: IconButton(
                tooltip: 'Recommend',
                onPressed: state.isGuest
                    ? null
                    : () {
                        cubit.reccomendResource(resource: resource);
                      },
                icon: Icon(
                  cubit.isRatingPositive(resource)
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                ),
                color: cubit.isRatingPositive(resource)
                    ? HorseAndRidersTheme().getTheme().colorScheme.primary
                    : isDark
                        ? Colors.grey.shade300
                        : Colors.black54,
              ),
            ),
            // Save Button
            Expanded(
              flex: 5,
              child: SaveResourceButton(
                key: const Key('save_resource_button'),
                resource: resource,
              ),
            ),
            // Dont Recommend Button
            Expanded(
              flex: 5,
              child: IconButton(
                tooltip: "Don't Recommend",
                onPressed: state.isGuest
                    ? null
                    : () {
                        cubit.dontReccomendResource(resource: resource);
                      },
                icon: Icon(
                  cubit.isRatingNegative(resource)
                      ? Icons.thumb_down
                      : Icons.thumb_down_outlined,
                ),
                color: cubit.isRatingNegative(resource)
                    ? HorseAndRidersTheme().getTheme().colorScheme.primary
                    : isDark
                        ? Colors.grey.shade300
                        : Colors.black54,
              ),
            ),
            // Number of Comments Button
            Expanded(
              flex: 5,
              child: IconButton(
                tooltip: resource.comments?.isEmpty ?? true
                    ? 'No Comments Yet'
                    : resource.comments?.length == 1
                        ? '1 Comment'
                        : '${resource.comments!.length} Comments',
                onPressed: () {
                  // Show the comments associated with this resource
                  context.goNamed(
                    ResourceCommentPage.name,
                    pathParameters: {
                      ResourceCommentPage.pathParams: resource.id ?? '',
                    },
                  );
                },
                icon: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.comment),
                    smallGap(),
                    Text(
                      resource.comments == null
                          ? '0'
                          : resource.comments!.length.toString(),
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade300 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                color: isDark ? Colors.grey.shade300 : Colors.black54,
              ),
            ),
            // Assosiated Skills Button
            Expanded(
              flex: 5,
              child: IconButton(
                tooltip: 'Assosiated Skills',
                onPressed: () {
                  //  Show the skills associated with this resource
                  showDialog<AlertDialog>(
                    context: context,
                    builder: (context) {
                      return UpdateResourceSkills(
                        resource: resource,
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
            // pop up overflow menu with the option to report the resource
            Visibility(
              visible: !state.isGuest,
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.grey.shade300 : Colors.black54,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'Report':
                      debugPrint('Report: ${resource.name}');
                      showDialog<AlertDialog>(
                        context: context,
                        builder: (context) => const SupportMessageDialog(),
                      );
                      break;
                  }
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Report',
                      child: Text('Report'),
                    ),
                  ];
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
