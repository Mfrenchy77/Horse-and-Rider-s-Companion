import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/profile_design_tokens.dart';

class RiderListOfProfiles extends StatelessWidget {
  const RiderListOfProfiles({super.key, required this.profile});
  final RiderProfile profile;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppCubit>().state;
    final isOwnProfile =
        !app.isGuest && app.usersProfile?.email == profile.email;
    final ownedHorses = profile.ownedHorses ?? const <BaseListItem>[];
    final archivedHorses = isOwnProfile
        ? (profile.archivedHorses ?? const <BaseListItem>[])
        : const <BaseListItem>[];
    final students = profile.students ?? const <BaseListItem>[];
    final studentHorses = profile.studentHorses ?? const <BaseListItem>[];
    final instructors = profile.instructors ?? const <BaseListItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ownedHorses.isNotEmpty) ...[
          _HorsePhotoSection(
            title: 'Owned horses',
            horses: ownedHorses,
          ),
          const SizedBox(height: 16),
        ],
        if (students.isNotEmpty) ...[
          _PersonListSection(
            title: 'Students',
            people: students,
          ),
          const SizedBox(height: 16),
        ],
        if (studentHorses.isNotEmpty) ...[
          _HorsePhotoSection(
            title: 'Student horses',
            horses: studentHorses,
          ),
          const SizedBox(height: 16),
        ],
        if (instructors.isNotEmpty) ...[
          _PersonListSection(
            title: 'Instructors',
            people: instructors,
          ),
          const SizedBox(height: 16),
        ],
        if (archivedHorses.isNotEmpty) ...[
          _HorsePhotoSection(
            title: 'Archived horses',
            horses: archivedHorses,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _HorsePhotoSection extends StatelessWidget {
  const _HorsePhotoSection({
    required this.title,
    required this.horses,
  });

  final String title;
  final List<BaseListItem> horses;

  @override
  Widget build(BuildContext context) {
    final preview = horses.take(3).toList();
    return ProfileSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionHeader(
            title: title,
            actionLabel: horses.length > 3 ? 'View All' : null,
            showArrow: true,
            onAction: horses.length > 3
                ? () => _showAllDialog(
                      context,
                      title: title,
                      items: horses,
                      isHorse: true,
                    )
                : null,
          ),
          const SizedBox(height: 10),
          if (preview.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No horses.',
                style: TextStyle(
                  color: ProfileTokens.secondaryTextColor(context),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 260) {
                  return Column(
                    children: [
                      for (final item in preview) ...[
                        SizedBox(
                          height: 132,
                          child: _HorsePhotoCard(item: item),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: i < preview.length
                            ? AspectRatio(
                                aspectRatio: 0.86,
                                child: _HorsePhotoCard(item: preview[i]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HorsePhotoCard extends StatelessWidget {
  const _HorsePhotoCard({required this.item});

  final BaseListItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final photo = item.imageUrl?.trim() ?? '';
    final name = (item.name ?? '').trim();
    final radius = BorderRadius.circular(ProfileTokens.horseCardRadius);

    final placeholder = ColoredBox(
      color: isDark
          ? const Color(0xFF153137)
          : theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Image.asset(
            'assets/horse_logo.png',
            width: 44,
            height: 44,
            color: isDark
                ? Colors.white.withValues(alpha: 0.36)
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            excludeFromSemantics: true,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: 'Open horse profile for $name',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: isDark
                ? ProfileTokens.cardBorderDark
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => _openItem(context, item, isHorse: true),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo.isEmpty)
                    placeholder
                  else
                    Image.network(
                      photo,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return placeholder;
                      },
                      errorBuilder: (_, _, _) => placeholder,
                    ),
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x33051013),
                            Color(0xE0061215),
                          ],
                          stops: [0.35, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 9,
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Color(0x99000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonListSection extends StatelessWidget {
  const _PersonListSection({required this.title, required this.people});

  final String title;
  final List<BaseListItem> people;

  @override
  Widget build(BuildContext context) {
    final preview = people.take(3).toList();
    return ProfileSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionHeader(
            title: title,
            actionLabel: people.length > 3 ? 'View All' : null,
            showArrow: true,
            onAction: people.length > 3
                ? () => _showAllDialog(
                      context,
                      title: title,
                      items: people,
                      isHorse: false,
                    )
                : null,
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < preview.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? ProfileTokens.cardBorderDark
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            _PersonRow(item: preview[i]),
          ],
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.item});

  final BaseListItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = item.name ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () =>
          _openItem(context, item, isHorse: !(item.isCollapsed ?? true)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              ProfilePhoto(size: 38, profilePicUrl: item.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? ProfileTokens.primaryTextDark
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ProfileTokens.secondaryTextColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openItem(
  BuildContext context,
  BaseListItem item, {
  required bool isHorse,
}) {
  final id = item.id;
  if (id == null || id.isEmpty) return;
  final collapsed = item.isCollapsed;
  final openAsRider = collapsed ?? !isHorse;
  if (openAsRider) {
    context.pushNamed(
      ViewingProfilePage.name,
      pathParameters: {ViewingProfilePage.pathParams: id},
    );
  } else {
    debugPrint('Sending to HorseProfilePage: $id');
    context.pushNamed(
      HorseProfilePage.name,
      pathParameters: {HorseProfilePage.pathParams: id},
    );
  }
}

Future<void> _showAllDialog(
  BuildContext context, {
  required String title,
  required List<BaseListItem> items,
  required bool isHorse,
}) {
  return showAppGlassDialog<void>(
    context: context,
    builder: (dialogContext) => AppGlassDialog(
      scrollable: false,
      title: Text(title, style: ProfileTokens.sectionTitleStyle(dialogContext)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 420),
        child: isHorse
            ? GridView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (ctx, index) =>
                    _HorsePhotoCard(item: items[index]),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, index) => _PersonRow(item: items[index]),
              ),
      ),
      actions: [
        AppOutlinedButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          label: 'Close',
        ),
      ],
    ),
  );
}
