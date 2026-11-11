import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';

class GuestProfile extends StatelessWidget {
  const GuestProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final needsProfile = !state.isGuest && state.user.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: [
          const ProfileSearchButton(key: Key('GuestSearchButton')),
          IconButton(
            key: const Key('GuestTutorialButton'),
            tooltip: 'Tutorial',
            icon: const Icon(Icons.school),
            onPressed: () => context.read<AppCubit>().showOnboardingNow(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GradientCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          needsProfile
                              ? 'Set up your rider profile'
                              : 'Welcome to Horse & Rider’s Companion',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          needsProfile
                              ? 'Add your name and tell the community '
                                    'about yourself.'
                              : 'Explore skills and resources for you and '
                                    'your horse. Create an account to track '
                                    'your progress, '
                                    'keep a logbook and share what helps.',
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (needsProfile)
                              FilledButton(
                                onPressed: () => showDialog<void>(
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
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final skills = _ExploreCard(
                      icon: Icons.account_tree_outlined,
                      title: 'Skill Tree',
                      description:
                          'Find groundwork and riding skills to practise.',
                      onTap: () => context.goNamed(SkillTreePage.name),
                    );
                    final resources = _ExploreCard(
                      icon: Icons.auto_stories_outlined,
                      title: 'Resources',
                      description:
                          'Find articles, videos and guides linked to skills.',
                      onTap: () => context.goNamed(ResourcesPage.name),
                    );
                    return constraints.maxWidth >= 640
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: skills),
                              const SizedBox(width: 12),
                              Expanded(child: resources),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              skills,
                              const SizedBox(height: 12),
                              resources,
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
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
  Widget build(BuildContext context) => GradientCard(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: 12),
            Text(
              'Explore $title',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    ),
  );
}
