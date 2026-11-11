import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/log_book_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_card.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/profile_cover.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';

class HorseProfilePrimaryView extends StatelessWidget {
  const HorseProfilePrimaryView({super.key, required this.horseProfile});

  final HorseProfile horseProfile;

  @override
  Widget build(BuildContext context) {
    final instructors = horseProfile.instructors ?? const <BaseListItem>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        ProfileCover(
          key: const Key('horseIdentity'),
          name: horseProfile.name,
          photoUrl: horseProfile.picUrl,
          locationName: horseProfile.locationName,
          photoKey: const Key('horseCoverPhoto'),
          status: switch (horseProfile.archiveStatus) {
            'deceased' => 'Archived · Deceased',
            'archived' => 'Archived',
            _ => null,
          },
        ),
        _HorseDetails(horse: horseProfile),
        Align(
          alignment: Alignment.centerLeft,
          child: LogBookButton(
            profile: null,
            horseProfile: horseProfile,
            key: const Key('logBookButton'),
          ),
        ),
        ConnectionPanel(horse: horseProfile),
        if (instructors.isNotEmpty)
          GradientCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text(
                    'Instructors',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final instructor in instructors)
                        ProfileCard(baseItem: instructor),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HorseDetails extends StatelessWidget {
  const _HorseDetails({required this.horse});

  final HorseProfile horse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birth = horse.dateOfBirth;
    final height = horse.height;
    final ownerId = horse.currentOwnerId.trim();
    final owner = horse.currentOwnerName?.trim() ?? '';
    final details = <String, String?>{
      'Nickname': horse.nickname,
      'Breed': horse.breed,
      'Color': horse.color,
      'Gender': horse.gender,
      if (height != null && height > 0)
        'Height': SharedPrefs().isHeightInHands
            ? '${cmToHands(height)}.${cmToHandsRemainder(height)} hands'
            : '$height cm',
      if (birth != null) ...{
        'Age': '${DateTime.now().year - birth.year} years',
        'Date of birth': MaterialLocalizations.of(
          context,
        ).formatMediumDate(birth),
      },
    };
    final fields = [
      for (final field in details.entries)
        if (field.value?.trim().isNotEmpty ?? false)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 3,
            children: [
              Text(
                field.key,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(field.value!.trim(), style: theme.textTheme.bodyLarge),
            ],
          ),
    ];
    final hasOwner =
        ownerId.isNotEmpty &&
        ownerId != 'NONE' &&
        owner.isNotEmpty &&
        owner != 'NONE';
    if (!hasOwner && fields.isEmpty) return const SizedBox.shrink();

    return GradientCard(
      key: const Key('horseDetails'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text('About', style: theme.textTheme.titleLarge),
            if (hasOwner)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('currentOwner'),
                  onPressed: () {
                    final cubit = context.read<AppCubit>();
                    if (cubit.state.usersProfile?.email == ownerId) {
                      cubit.createMessage('You are the owner of this horse.');
                    } else {
                      context.goNamed(
                        ViewingProfilePage.name,
                        pathParameters: {
                          ViewingProfilePage.pathParams: ownerId,
                        },
                      );
                    }
                  },
                  child: Text('Owner · $owner'),
                ),
              ),
            if (fields.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth >= 264 &&
                          MediaQuery.textScalerOf(context).scale(16) <= 22
                      ? 2
                      : 1;
                  const gap = 16.0;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final field in fields)
                        SizedBox(width: width, child: field),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
