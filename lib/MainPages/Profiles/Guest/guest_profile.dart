import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/guest_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class GuestProfile extends StatelessWidget {
  const GuestProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final needsProfile = !state.isGuest && state.user.isNotEmpty;
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: ThemedAppBar(
        title: Semantics(
          label: "Horse & Rider's Companion",
          child: const AppTitle(key: Key('guestAppBarWordmark')),
        ),
        actions: [
          const ProfileSearchButton(key: Key('GuestSearchButton')),
          IconButton(
            key: const Key('GuestTutorialButton'),
            tooltip: 'Tutorial',
            icon: const Icon(Icons.school),
            onPressed: () {
              if (GuestSpotlightTour.skillTreeNavKey.currentContext != null) {
                GuestSpotlightTour.start(context);
              } else {
                context.read<AppCubit>().showOnboardingNow();
              }
            },
          ),
        ],
      ),
      body: SizedBox.expand(
        child: AppScaffoldBackdrop(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? AppTokens.spaceMd : AppTokens.spaceLg,
              vertical: AppTokens.spaceLg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppTokens.spaceMd,
                  children: [
                    AppSurfaceCard(
                      key: const Key('guestWelcomeCard'),
                      useDoubleGradient: true,
                      padding: EdgeInsets.all(
                        isCompact ? AppTokens.spaceMd : AppTokens.spaceLg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            needsProfile
                                ? 'Set up your rider profile'
                                : 'Welcome to Horse & Rider’s Companion',
                            style: AppTokens.sectionTitleStyle(
                              context,
                            ).copyWith(fontSize: isCompact ? 22 : 26),
                          ),
                          const SizedBox(height: AppTokens.spaceSm + 2),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Text(
                              needsProfile
                                  ? 'Add your name and tell the community '
                                        'about yourself.'
                                  : 'Explore horsemanship skills and curated '
                                        'educational resources for you and '
                                        'your horse. Create an account anytime '
                                        'to track progress, keep a logbook, '
                                        'and share what helps.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppTokens.secondaryTextColor(context),
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTokens.spaceLg),
                          Wrap(
                            spacing: AppTokens.spaceSm + 4,
                            runSpacing: AppTokens.spaceSm,
                            children: [
                              if (needsProfile)
                                FilledButton(
                                  onPressed: () => showAppGlassDialog<void>(
                                    context: context,
                                    builder: (_) => EditRiderProfileDialog(
                                      user: state.user,
                                      riderProfile: null,
                                      onProfileUpdated: () {},
                                    ),
                                  ),
                                  child: const Text('Set up profile'),
                                )
                              else ...[
                                FilledButton(
                                  key: const Key('guestCreateAccount'),
                                  onPressed: () => context.goNamed(
                                    AuthPage.name,
                                    queryParameters: {'mode': 'register'},
                                  ),
                                  child: const Text('Create account'),
                                ),
                                OutlinedButton(
                                  key: const Key('guestSignIn'),
                                  onPressed: () => context.goNamed(
                                    AuthPage.name,
                                    queryParameters: {'mode': 'login'},
                                  ),
                                  child: const Text('Sign in'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final skills = _ExploreCard(
                          key: const Key('guestExploreSkillTreeCard'),
                          icon: HorseAndRiderIcons.horseSkillIcon,
                          title: 'Skill Tree',
                          description:
                              'Browse groundwork, in-hand, and riding skills '
                              'across difficulty levels.',
                          onTap: () => context.goNamed(SkillTreePage.name),
                        );
                        final resources = _ExploreCard(
                          key: const Key('guestExploreResourcesCard'),
                          icon: HorseAndRiderIcons.resourcesIcon,
                          title: 'Resources',
                          description:
                              'Discover articles, videos, and training guides '
                              'linked directly to skills.',
                          onTap: () => context.goNamed(ResourcesPage.name),
                        );
                        final dictionary = _ExploreCard(
                          key: const Key('guestExploreDictionary'),
                          icon: Icons.menu_book_outlined,
                          title: 'Equestrian Dictionary',
                          description:
                              'Explore plain-language horsemanship terms '
                              'across English, Western, trail, and groundwork.',
                          onTap: () => context.push('/Dictionary'),
                        );
                        if (constraints.maxWidth >= 860) {
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: AppTokens.spaceMd,
                              children: [
                                Expanded(child: skills),
                                Expanded(child: resources),
                                Expanded(child: dictionary),
                              ],
                            ),
                          );
                        }
                        if (constraints.maxWidth >= 640) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: AppTokens.spaceMd,
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing: AppTokens.spaceMd,
                                  children: [
                                    Expanded(child: skills),
                                    Expanded(child: resources),
                                  ],
                                ),
                              ),
                              dictionary,
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppTokens.spaceMd,
                          children: [skills, resources, dictionary],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTokens.accentColor(context);
    final radius = BorderRadius.circular(AppTokens.radiusLg);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: radius,
        hoverColor: AppTokens.hoverOverlay(context),
        highlightColor: AppTokens.pressOverlay(context),
        focusColor: AppTokens.focusOverlay(context),
        splashColor: AppTokens.pressOverlay(context),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spaceSm + 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                    child: Icon(icon, color: accent, size: 26),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: accent,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceMd),
              Text(
                'Explore $title',
                style: AppTokens.sectionTitleStyle(
                  context,
                ).copyWith(fontSize: 20),
              ),
              const SizedBox(height: AppTokens.spaceSm),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
