import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/primary_rider_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_list_of_profiles.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/profile_layout.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/profile_design_tokens.dart';
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
    final connections = context.watch<ConnectionsCubit?>()?.state;
    final instructor = connections?.instructorFor(profile.email);
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Scaffold(
          appBar: ThemedAppBar(
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
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final skills = ProfileSurfaceCard(
                key: const Key('riderSkills'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileSectionHeader(
                      title: 'Skills',
                      actionLabel: instructor == null
                          ? 'Explore Skill Tree'
                          : 'Open student Skill Tree',
                      showArrow: true,
                      onAction: () => context.goNamed(SkillTreePage.name),
                    ),
                    const SizedBox(height: 8),
                    _DeprecatedSkillsCleanupCard(profile: profile),
                    ProfileSkills(
                      skillLevels: profile.skillLevels,
                      key: const Key('ProfileSkills'),
                    ),
                  ],
                ),
              );

              final content = LayoutBuilder(
                builder: (context, constraints) {
                  final isWide =
                      constraints.maxWidth >= RiderProfileView.largeBreakpoint;
                  if (isWide) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1320),
                          child: Row(
                            key: const Key('riderProfileWide'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: PrimaryRiderView(
                                  profile: profile,
                                  key: const Key('ProfileView'),
                                  edgeToEdgeCover: false,
                                  includeLists: false,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    skills,
                                    const SizedBox(height: 16),
                                    RiderListOfProfiles(
                                      profile: profile,
                                      key: const Key('RiderListOfProfiles'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      key: const Key('riderProfileCompact'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrimaryRiderView(
                          profile: profile,
                          key: const Key('ProfileView'),
                          edgeToEdgeCover: true,
                          includeLists: true,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: skills,
                        ),
                      ],
                    ),
                  );
                },
              );

              if (!isDark) return content;

              return DecoratedBox(
                decoration: ProfileTokens.midnightBackdrop,
                child: DecoratedBox(
                  decoration: ProfileTokens.atmosphericOverlay(context),
                  child: content,
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
