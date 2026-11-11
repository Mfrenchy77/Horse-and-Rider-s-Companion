import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/primary_rider_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/profile_layout.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Utilities/skill_level_audit.dart';

class RiderProfileView extends StatefulWidget {
  const RiderProfileView({required this.profile, super.key});

  final RiderProfile profile;

  static const double mediumBreakpoint = 600;
  static const double largeBreakpoint = ProfileLayout.largeBreakpoint;

  @override
  State<RiderProfileView> createState() => _RiderProfileViewState();
}

class _RiderProfileViewState extends State<RiderProfileView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  // drawer open/close are handled by Scaffold.onDrawerChanged now

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: profile.email == state.usersProfile?.email
                ? Builder(
                    builder: (context) => IconButton(
                      icon: AnimatedIcon(
                        icon: AnimatedIcons.menu_close,
                        progress: _iconController,
                      ),
                      key: const Key('HamburgerIcon'),
                      onPressed: () {
                        final scaffold = Scaffold.of(context);
                        // toggle drawer: if open, close it; otherwise open it
                        if (scaffold.isDrawerOpen) {
                          Navigator.pop(context);
                        } else {
                          scaffold.openDrawer();
                        }
                      },
                    ),
                  )
                : null,
            title: Text(
              profile.email == state.usersProfile?.email
                  ? 'My profile'
                  : 'Rider profile',
            ),
            actions: const [
              ProfileSearchButton(key: Key('RiderSearchButton')),
              RiderProfileOverFlowMenu(key: Key('RiderProfileOverFlowMenu')),
            ],
          ),
          // synchronize icon animation with drawer open/close (including
          // user drag) via onDrawerChanged
          onDrawerChanged: (isOpen) {
            if (isOpen) {
              _iconController.forward();
            } else {
              _iconController.reverse();
            }
          },
          drawer: profile.email == state.usersProfile?.email
              ? const UserProfileDrawer()
              : null,
          body: Builder(
            builder: (context) {
              final skills = GradientCard(
                key: const Key('riderSkills'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Skills',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () =>
                                context.goNamed(SkillTreePage.name),
                            child: const Text('Explore Skill Tree'),
                          ),
                        ],
                      ),
                      _DeprecatedSkillsCleanupCard(profile: profile),
                      ProfileSkills(
                        skillLevels: profile.skillLevels,
                        key: const Key('ProfileSkills'),
                      ),
                    ],
                  ),
                ),
              );
              final identity = PrimaryRiderView(
                profile: profile,
                key: const Key('ProfileView'),
              );
              return ProfileLayout(
                identity: identity,
                skills: skills,
                wideKey: const Key('riderProfileWide'),
                compactKey: const Key('riderProfileCompact'),
              );
            },
          ),
        );
      },
    );
  }
}

class _DeprecatedSkillsCleanupCard extends StatelessWidget {
  const _DeprecatedSkillsCleanupCard({required this.profile});

  final RiderProfile profile;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.allSkills != current.allSkills ||
          previous.usersProfile != current.usersProfile ||
          previous.viewingProfile != current.viewingProfile,
      builder: (context, state) {
        if (state.allSkills.whereType<Skill>().isEmpty) {
          return const SizedBox.shrink();
        }

        final audit = SkillLevelAudit.evaluate(
          profileSkillLevels: profile.skillLevels,
          allSkills: state.allSkills,
        );
        final isOwner = profile.email == state.usersProfile?.email;
        if (!audit.isCatalogReady ||
            audit.deprecatedLevels.isEmpty ||
            !isOwner) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final warningTextColor = theme.colorScheme.onErrorContainer;
        final sampleNames = audit.deprecatedLevels
            .take(3)
            .map((level) => level.skillName)
            .join(', ');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: warningTextColor,
              ),
              title: Text(
                'Remove deprecated skills',
                style: TextStyle(color: warningTextColor),
              ),
              subtitle: Text(
                sampleNames.isEmpty
                    ? 'We found ${audit.deprecatedLevels.length} skills that '
                          'no longer exist in the catalog.'
                    : 'Found ${audit.deprecatedLevels.length} deprecated '
                          'skill(s): $sampleNames',
                style: TextStyle(color: warningTextColor),
              ),
              trailing: FilledButton.tonal(
                onPressed: () {
                  context.read<AppCubit>().removeDeprecatedSkillLevels(
                    profile: profile,
                    deprecatedLevels: audit.deprecatedLevels,
                  );
                },
                child: const Text('Delete'),
              ),
            ),
          ),
        );
      },
    );
  }
}
