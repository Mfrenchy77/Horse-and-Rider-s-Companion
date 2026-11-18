import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/onboarding_prefs.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/profile_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/primary_rider_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_list_of_profiles.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/profile_layout.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MenuController _overflowMenuController = MenuController();
  late final ProfileSpotlightHooks _tourHooks;
  bool _inviteDismissedInSession = false;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _tourHooks = ProfileSpotlightHooks(
      openOverflowMenu: () {
        if (mounted && !_overflowMenuController.isOpen) {
          _overflowMenuController.open();
        }
      },
      closeOverflowMenu: () {
        if (mounted && _overflowMenuController.isOpen) {
          _overflowMenuController.close();
        }
      },
      openDrawer: () {
        if (mounted && !(_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      closeDrawer: () {
        if (mounted && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
          _scaffoldKey.currentState?.closeDrawer();
        }
      },
    );
  }

  @override
  void dispose() {
    if (identical(ProfileSpotlightTour.riderHooks, _tourHooks)) {
      ProfileSpotlightTour.riderHooks = null;
    }
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
        final viewerEmail = state.usersProfile?.email;
        final isOwnProfile =
            !state.isGuest &&
            viewerEmail != null &&
            viewerEmail.toLowerCase() == profile.email.toLowerCase();
        final isCoachViewingStudent =
            !isOwnProfile &&
            !state.isGuest &&
            viewerEmail != null &&
            instructor != null &&
            instructor.coach == viewerEmail.toLowerCase();
        if (isOwnProfile) {
          ProfileSpotlightTour.riderHooks = _tourHooks;
        }
        final userKey = viewerEmail ?? state.user.id;
        String? routePath;
        try {
          routePath = GoRouterState.of(context).uri.path;
        } catch (_) {
          routePath = null;
        }
        final isRootProfileRoute =
            routePath == null || routePath == ProfilePage.path;
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
        final showInvitation =
            isOwnProfile &&
            !_inviteDismissedInSession &&
            isRootProfileRoute &&
            isCurrentRoute &&
            OnboardingPrefs.shouldShowProfileInvitation(
              profile: profile,
              userKey: userKey,
            );
        final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: isDarkTheme ? ProfileTokens.midnightBase : null,
          appBar: ThemedAppBar(
            leading: isOwnProfile
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
            title: Text(isOwnProfile ? 'My profile' : 'Rider profile'),
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: ProfileSpotlightTour.isTourActive,
                builder: (context, tourActive, child) => KeyedSubtree(
                  key: (isOwnProfile && tourActive)
                      ? ProfileSpotlightTour.riderSearchButtonKey
                      : null,
                  child: child!,
                ),
                child: const ProfileSearchButton(key: Key('RiderSearchButton')),
              ),
              if (isOwnProfile)
                RiderProfileOverFlowMenu(
                  key: const Key('RiderProfileOverFlowMenu'),
                  menuController: _overflowMenuController,
                ),
            ],
          ),
          // synchronize icon animation with drawer open/close (including
          // user drag) via onDrawerChanged
          onDrawerChanged: (isOpen) {
            if (MediaQuery.disableAnimationsOf(context)) {
              _iconController.value = isOpen ? 1.0 : 0.0;
            } else if (isOpen) {
              _iconController.forward();
            } else {
              _iconController.reverse();
            }
          },
          drawer: isOwnProfile ? const UserProfileDrawer() : null,
          body: Builder(
            builder: (context) {
              final skills = ValueListenableBuilder<bool>(
                valueListenable: ProfileSpotlightTour.isTourActive,
                builder: (context, tourActive, child) => KeyedSubtree(
                  key: (isOwnProfile && tourActive)
                      ? ProfileSpotlightTour.riderSkillsSectionKey
                      : null,
                  child: child!,
                ),
                child: ProfileSurfaceCard(
                  key: const Key('riderSkills'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileSectionHeader(
                        title: 'Skills',
                        actionLabel: isCoachViewingStudent
                            ? 'Open student Skill Tree'
                            : 'Explore Skill Tree',
                        showArrow: true,
                        onAction: () {
                          context.read<AppCubit>()
                            ..setSkillSubject(isForRider: true)
                            ..navigateToSkillsList();
                          context.goNamed(SkillTreePage.name);
                        },
                      ),
                      const SizedBox(height: 8),
                      _DeprecatedSkillsCleanupCard(profile: profile),
                      ProfileSkills(
                        skillLevels: profile.skillLevels,
                        subject: SkillSubject.rider,
                        profileDocId: profile.email,
                        key: const Key('ProfileSkills'),
                      ),
                    ],
                  ),
                ),
              );

              final invitationBanner = showInvitation
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ProfileTourInvitationCard(
                        onStartTour: () {
                          unawaited(
                            OnboardingPrefs.setInviteState(
                              tour: OnboardingTourId.profile,
                              userKey: userKey,
                              state: OnboardingInviteState.accepted,
                            ),
                          );
                          setState(() => _inviteDismissedInSession = true);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            unawaited(ProfileSpotlightTour.start(context));
                          });
                        },
                        onDismiss: () {
                          unawaited(
                            OnboardingPrefs.setInviteState(
                              tour: OnboardingTourId.profile,
                              userKey: userKey,
                              state: OnboardingInviteState.deferred,
                            ),
                          );
                          setState(() => _inviteDismissedInSession = true);
                        },
                      ),
                    )
                  : const SizedBox.shrink();

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              invitationBanner,
                              Row(
                                key: const Key('riderProfileWide'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: PrimaryRiderView(
                                      profile: profile,
                                      key: const Key('ProfileView'),
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
                        if (showInvitation)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: invitationBanner,
                          ),
                        PrimaryRiderView(
                          profile: profile,
                          key: const Key('ProfileView'),
                          edgeToEdgeCover: true,
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

              return AppScaffoldBackdrop(child: content);
            },
          ),
        );
      },
    );
  }
}

class _ProfileTourInvitationCard extends StatelessWidget {
  const _ProfileTourInvitationCard({
    required this.onStartTour,
    required this.onDismiss,
  });

  final VoidCallback onStartTour;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTokens.accentColor(context);

    return AppSurfaceCard(
      key: const Key('profileTourInvitationCard'),
      useDoubleGradient: true,
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppTokens.spaceSm,
        children: [
          Row(
            children: [
              Icon(Icons.explore_outlined, size: 20, color: accent),
              const SizedBox(width: AppTokens.spaceSm),
              Expanded(
                child: Text(
                  'Make the most of your profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTokens.primaryTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Your profile brings your riding progress, horses, training '
            'records, and connections together. Want a quick guided tour?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTokens.secondaryTextColor(context),
            ),
          ),
          Wrap(
            spacing: AppTokens.spaceSm,
            runSpacing: AppTokens.spaceSm,
            children: [
              FilledButton(
                key: const Key('profileTourInviteAccept'),
                onPressed: onStartTour,
                child: const Text('Show me around'),
              ),
              AppOutlinedButton(
                key: const Key('profileTourInviteDismiss'),
                label: 'Not now',
                onPressed: onDismiss,
              ),
            ],
          ),
        ],
      ),
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
