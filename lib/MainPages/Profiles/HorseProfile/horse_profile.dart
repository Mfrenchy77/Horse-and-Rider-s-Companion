import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_primary_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/profile_layout.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';

class HorseProfileView extends StatelessWidget {
  const HorseProfileView({super.key, required this.horseProfile});

  final HorseProfile horseProfile;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Horse profile'),
      actions: const [
        ProfileSearchButton(key: Key('HorseSearchButton')),
        HorseProfileOverFlowMenu(key: Key('RiderProfileOverFlowMenu')),
      ],
    ),
    body: ProfileLayout(
      wideKey: const Key('horseProfileWide'),
      compactKey: const Key('horseProfileCompact'),
      identity: HorseProfilePrimaryView(
        horseProfile: horseProfile,
        key: const Key('HorseProfilePrimaryView'),
      ),
      skills: GradientCard(
        key: const Key('horseSkills'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Skills', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () {
                      context.read<AppCubit>().navigateToSkillsList();
                      context.goNamed(SkillTreePage.name);
                    },
                    child: const Text('Explore Skill Tree'),
                  ),
                ],
              ),
              ProfileSkills(
                key: const Key('ProfileSkills'),
                skillLevels: horseProfile.skillLevels,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
