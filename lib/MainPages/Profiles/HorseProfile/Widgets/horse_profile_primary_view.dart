import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/log_book_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_sale_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_card.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/profile_cover.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';
import 'package:super_banners/super_banners.dart';

class HorseProfilePrimaryView extends StatelessWidget {
  const HorseProfilePrimaryView({super.key, required this.horseProfile});

  final HorseProfile horseProfile;

  @override
  Widget build(BuildContext context) {
    final instructors = horseProfile.instructors ?? const <BaseListItem>[];
    final forSale =
        !horseProfile.isArchived && horseProfile.saleListing != null;
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
          ribbon: forSale
              ? const CornerBanner(
                  bannerColor: Color(0xFF1565C0),
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    child: Text(
                      'FOR SALE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: LogBookButton(
            profile: null,
            horseProfile: horseProfile,
            key: const Key('logBookButton'),
          ),
        ),
        if (forSale) HorseSalePanel(horse: horseProfile),
        _HorseDetails(key: ValueKey(horseProfile.id), horse: horseProfile),
        if (instructors.isNotEmpty)
          AppSurfaceCard(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                const AppSectionHeader(title: 'Instructors'),
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
        ConnectionPanel(horse: horseProfile),
      ],
    );
  }
}

class _HorseDetails extends StatefulWidget {
  const _HorseDetails({required this.horse, super.key});

  final HorseProfile horse;

  @override
  State<_HorseDetails> createState() => _HorseDetailsState();
}

class _HorseDetailsState extends State<_HorseDetails> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final horse = widget.horse;
    final theme = Theme.of(context);
    final birth = horse.dateOfBirth;
    final height = horse.height;
    final ownerId = horse.currentOwnerId.trim();
    final owner = horse.currentOwnerName?.trim() ?? '';
    final summary = <String, String?>{
      'Breed': horse.breed,
      'Gender': horse.gender,
      'Age': birth == null ? null : '${DateTime.now().year - birth.year} years',
    };
    final additional = <String, String?>{
      'Nickname': horse.nickname,
      'Color': horse.color,
      if (height != null && height > 0)
        'Height': SharedPrefs().isHeightInHands
            ? '${cmToHands(height)}.${cmToHandsRemainder(height)} hands'
            : '$height cm',
      if (birth != null) ...{
        'Date of birth': MaterialLocalizations.of(
          context,
        ).formatMediumDate(birth),
      },
    };
    final hasSummary = summary.values.any(
      (value) => value?.trim().isNotEmpty ?? false,
    );
    final canExpand =
        hasSummary &&
        additional.values.any((value) => value?.trim().isNotEmpty ?? false);
    final fields = [
      for (final field in [
        ...summary.entries,
        if (!hasSummary || _expanded) ...additional.entries,
      ])
        if (field.value?.trim().isNotEmpty ?? false)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 3,
            children: [
              Text(
                field.key,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
              Text(
                field.value!.trim(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTokens.primaryTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
    ];
    final hasOwner =
        ownerId.isNotEmpty &&
        ownerId != 'NONE' &&
        owner.isNotEmpty &&
        owner != 'NONE';
    if (!hasOwner && fields.isEmpty) return const SizedBox.shrink();

    return AppSurfaceCard(
      key: const Key('horseDetails'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const AppSectionHeader(title: 'About'),
          if (hasOwner)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('currentOwner'),
                icon: Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: AppTokens.accentColor(context),
                ),
                onPressed: () {
                  final cubit = context.read<AppCubit>();
                  if (cubit.state.usersProfile?.email == ownerId) {
                    cubit.createMessage('You are the owner of this horse.');
                  } else {
                    context.pushNamed(
                      ViewingProfilePage.name,
                      pathParameters: {ViewingProfilePage.pathParams: ownerId},
                    );
                  }
                },
                label: Text('Owner · $owner'),
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
          if (canExpand)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_expanded ? 'Show less' : 'Show more details'),
              ),
            ),
        ],
      ),
    );
  }
}
