import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/resources_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/support_message_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/create_resource_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/resource_update_skills_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/save_resource_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class ResourceRatingButtons extends StatelessWidget {
  const ResourceRatingButtons({
    super.key,
    required this.resource,
    this.canOpenComments = true,
  });

  final Resource resource;
  final bool canOpenComments;
  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accentColor(context);
    final muted = AppTokens.secondaryTextColor(context);
    final cubit = context.read<AppCubit>();
    final (isGuest, hasHorse, isPositive, isNegative) = context.select(
      (AppCubit c) => (
        c.state.isGuest,
        c.state.horseProfile != null,
        c.isRatingPositive(resource),
        c.isRatingNegative(resource),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recommend Button
        Expanded(
          flex: 5,
          child: IconButton(
            tooltip: 'Recommend',
            onPressed: isGuest
                ? null
                : () {
                    cubit.reccomendResource(resource: resource);
                  },
            icon: Icon(isPositive ? Icons.thumb_up : Icons.thumb_up_outlined),
            color: isPositive ? accent : muted,
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
            onPressed: isGuest
                ? null
                : () {
                    cubit.dontReccomendResource(resource: resource);
                  },
            icon: Icon(
              isNegative ? Icons.thumb_down : Icons.thumb_down_outlined,
            ),
            color: isNegative ? accent : muted,
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
            onPressed: canOpenComments
                ? () {
                    context.pushNamed(
                      ResourceCommentPage.name,
                      pathParameters: {
                        ResourceCommentPage.pathParams: resource.id ?? '',
                      },
                    );
                  }
                : null,
            icon: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.comment),
                  smallGap(),
                  Text(
                    resource.comments == null
                        ? '0'
                        : resource.comments!.length.toString(),
                  ),
                ],
              ),
            ),
            color: muted,
          ),
        ),
        // Assosiated Skills Button
        Expanded(
          flex: 5,
          child: Builder(
            builder: (context) {
              final button = IconButton(
                tooltip: 'Associated skills',
                onPressed: () {
                  showAppGlassDialog<void>(
                    context: context,
                    builder: (_) => UpdateResourceSkills(resource: resource),
                  );
                },
                icon: hasHorse
                    ? const Icon(HorseAndRiderIcons.horseSkillIcon)
                    : const Icon(HorseAndRiderIcons.riderSkillIcon),
                color: muted,
              );
              if (canOpenComments) return button;
              return ValueListenableBuilder<bool>(
                valueListenable: ResourcesSpotlightTour.isTourActive,
                builder: (context, tourActive, child) => KeyedSubtree(
                  key: tourActive
                      ? ResourcesSpotlightTour.associatedSkillsButtonKey
                      : null,
                  child: child!,
                ),
                child: button,
              );
            },
          ),
        ),
        // pop up overflow menu with resource actions
        Visibility(
          visible: !isGuest,
          child: PopupMenuButton<String>(
            key: Key('resourceOverflowMenu_${resource.id ?? 'unknown'}'),
            icon: Icon(Icons.more_vert, color: muted),
            onSelected: (value) {
              final appState = cubit.state;
              switch (value) {
                case 'EditResource':
                  final profile = appState.usersProfile;
                  if (profile == null) return;
                  showAppGlassDialog<void>(
                    context: context,
                    builder: (_) => CreateResourcDialog(
                      skills: appState.allSkills,
                      userProfile: profile,
                      resource: resource,
                    ),
                  );
                  break;
                case 'Report':
                  showAppGlassDialog<void>(
                    context: context,
                    builder: (context) => const SupportMessageDialog(),
                  );
                  break;
              }
            },
            itemBuilder: (context) {
              final appState = cubit.state;
              final canEdit =
                  !appState.isGuest &&
                  appState.usersProfile != null &&
                  cubit.canEditResource(resource);
              return <PopupMenuEntry<String>>[
                if (canEdit)
                  const PopupMenuItem<String>(
                    value: 'EditResource',
                    child: Text('Edit Resource'),
                  ),
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
  }
}
