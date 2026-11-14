import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Onboarding for a newly signed-in user.
/// Shows overview tabs and returns 'finish' when the user taps Finish.
class UserOnboardingDialog extends StatefulWidget {
  const UserOnboardingDialog({super.key, this.onSkip});

  final VoidCallback? onSkip;

  @override
  State<UserOnboardingDialog> createState() => _UserOnboardingDialogState();
}

class _UserOnboardingDialogState extends State<UserOnboardingDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final cubit = context.read<AppCubit>();
      switch (_tabController.index) {
        case 0:
          cubit.changeIndex(0);
          break;
        case 1:
          cubit.changeIndex(1);
          break;
        case 2:
          cubit.changeIndex(2);
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.of(context).pop('finish');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dialogContent = SizedBox(
      width: 440,
      height: 360,
      child: Column(
        children: [
          TabBar(
            key: const Key('user_onboarding_tab_bar'),
            controller: _tabController,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Skill Tree'),
              Tab(text: 'Resources'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _Pane(
                  title: 'Your Profile',
                  description:
                      'Add your name, photo, website and bio. Link horses'
                      ' and manage contacts.',
                  icon: Icons.person,
                ),
                _Pane(
                  title: 'Skill Tree',
                  description:
                      'Track progress, verify levels, and keep notes across rider/horse skills.',
                  icon: Icons.account_tree,
                ),
                _Pane(
                  title: 'Resources',
                  description:
                      'Save, rate and discuss resources. Get session ideas'
                      ' tailored to you.',
                  icon: Icons.menu_book,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dialogActions = <Widget>[
      TextButton(
        key: const Key('user_onboarding_skip'),
        onPressed: () {
          widget.onSkip?.call();
          Navigator.of(context).pop();
        },
        child: const Text('Skip'),
      ),
      ElevatedButton(
        key: const Key('user_onboarding_finish'),
        onPressed: _finish,
        child: const Text('Finish & Edit Profile'),
      ),
    ];

    return AppGlassDialog(
      key: const Key('user_onboarding_dialog'),
      title: const Text('Welcome! Let’s set you up'),
      maxWidth: 640,
      content: dialogContent,
      actions: dialogActions,
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({
    required this.title,
    required this.description,
    required this.icon,
  });
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
