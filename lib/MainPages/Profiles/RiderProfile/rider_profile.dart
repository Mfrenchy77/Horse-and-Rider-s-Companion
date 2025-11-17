import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills_banner.dart';
import 'package:horseandriderscompanion/CommonWidgets/skills_text_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/primary_rider_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/requests_badge_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/Utilities/skill_level_audit.dart';
// Removed dependency on a shared GlobalKey to avoid duplicate key issues

class RiderProfileView extends StatefulWidget {
  const RiderProfileView({
    required this.profile,
    super.key,
  });

  final RiderProfile profile;

  static const double mediumBreakpoint = 600;
  static const double largeBreakpoint = 1024;

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
            title: const AppTitle(key: Key('appTitle')),
            actions: [
              const ProfileSearchButton(key: Key('RiderSearchButton')),
              // Show requests badge for the owner viewing their own profile
              if (profile.email == state.usersProfile?.email)
                const RequestsBadgeButton(),
              const RiderProfileOverFlowMenu(
                key: Key('RiderProfileOverFlowMenu'),
              ),
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;

              if (screenWidth >= RiderProfileView.largeBreakpoint) {
                // Split layout: profile left, skills right
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ListView(
                        children: [
                          PrimaryRiderView(
                            profile: profile,
                            key: const Key('ProfileView'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ListView(
                        children: [
                          const ProfileSkillsBanner(
                            key: Key('ProfileSkillsBanner'),
                          ),
                          gap(),
                          _DeprecatedSkillsCleanupCard(profile: profile),
                          ProfileSkills(
                            skillLevels: profile.skillLevels,
                            key: const Key('ProfileSkills'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Single column layout
              return SingleChildScrollView(
                child: Column(
                  children: [
                    PrimaryRiderView(
                      profile: profile,
                      key: const Key('ProfileView'),
                    ),
                    const SkillsTextButton(key: Key('SkillsTextButton')),
                    gap(),
                    _DeprecatedSkillsCleanupCard(profile: profile),
                    ProfileSkills(
                      skillLevels: profile.skillLevels,
                      key: const Key('ProfileSkills'),
                    ),
                  ],
                ),
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
